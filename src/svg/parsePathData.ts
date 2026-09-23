/**
 * SVG path data → absolute, normalized commands:
 *
 *   0 x y                  moveTo
 *   1 x y                  lineTo
 *   2 x1 y1 x2 y2 x y      cubic bezier
 *   3                      close
 *
 * H/V become lineTo, Q/T/S become cubics, arcs are approximated by cubics
 * (at most 90° per segment). Parsing stops at the first error, like browsers do.
 */
export const MOVE = 0;
export const LINE = 1;
export const CUBIC = 2;
export const CLOSE = 3;

const NUMBER = /[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/y;
const COMMANDS = 'MmZzLlHhVvCcSsQqTtAa';

class Scanner {
  private index = 0;

  constructor(private readonly source: string) {}

  private skipSeparators() {
    while (this.index < this.source.length) {
      const ch = this.source.charCodeAt(this.index);
      // space, tab, LF, CR, FF, comma
      if (
        ch === 32 ||
        ch === 9 ||
        ch === 10 ||
        ch === 13 ||
        ch === 12 ||
        ch === 44
      ) {
        this.index++;
      } else {
        break;
      }
    }
  }

  atEnd(): boolean {
    this.skipSeparators();
    return this.index >= this.source.length;
  }

  /** Consumes and returns a command letter, or null if the next token is not one. */
  readCommand(): string | null {
    this.skipSeparators();
    const ch = this.source[this.index];
    if (ch !== undefined && COMMANDS.includes(ch)) {
      this.index++;
      return ch;
    }
    return null;
  }

  hasNumber(): boolean {
    this.skipSeparators();
    const ch = this.source[this.index];
    return ch !== undefined && '+-.0123456789'.includes(ch);
  }

  readNumber(): number {
    this.skipSeparators();
    NUMBER.lastIndex = this.index;
    const match = NUMBER.exec(this.source);
    if (!match) {
      throw new ParseStop();
    }
    this.index = NUMBER.lastIndex;
    return Number(match[0]);
  }

  /** Arc flags may be written without separators ("a1 1 0 00 1 1"). */
  readFlag(): boolean {
    this.skipSeparators();
    const ch = this.source[this.index];
    if (ch === '0' || ch === '1') {
      this.index++;
      return ch === '1';
    }
    throw new ParseStop();
  }
}

class ParseStop extends Error {}

export function parsePathData(d: string): number[] {
  const out: number[] = [];
  const scanner = new Scanner(d);

  let x = 0;
  let y = 0;
  let startX = 0;
  let startY = 0;
  // Last cubic / quadratic control point, for S and T reflection.
  let controlX = 0;
  let controlY = 0;
  let previous = '';
  let hasSubpath = false;

  try {
    while (!scanner.atEnd()) {
      let command = scanner.readCommand();
      if (command === null) {
        if (!previous || !scanner.hasNumber() || previous === 'Z') {
          break;
        }
        // Implicit repetition; coordinates after a moveTo are lineTos.
        command = previous === 'M' ? 'L' : previous === 'm' ? 'l' : previous;
      }
      const upper = command.toUpperCase();
      const relative = command !== upper;
      const baseX = relative ? x : 0;
      const baseY = relative ? y : 0;

      if (upper !== 'M' && !hasSubpath) {
        // Path data must begin with a moveTo.
        break;
      }

      switch (upper) {
        case 'M': {
          x = baseX + scanner.readNumber();
          y = baseY + scanner.readNumber();
          startX = x;
          startY = y;
          hasSubpath = true;
          out.push(MOVE, x, y);
          break;
        }
        case 'L': {
          x = baseX + scanner.readNumber();
          y = baseY + scanner.readNumber();
          out.push(LINE, x, y);
          break;
        }
        case 'H': {
          x = baseX + scanner.readNumber();
          out.push(LINE, x, y);
          break;
        }
        case 'V': {
          y = baseY + scanner.readNumber();
          out.push(LINE, x, y);
          break;
        }
        case 'C': {
          const x1 = baseX + scanner.readNumber();
          const y1 = baseY + scanner.readNumber();
          const x2 = baseX + scanner.readNumber();
          const y2 = baseY + scanner.readNumber();
          x = baseX + scanner.readNumber();
          y = baseY + scanner.readNumber();
          out.push(CUBIC, x1, y1, x2, y2, x, y);
          controlX = x2;
          controlY = y2;
          break;
        }
        case 'S': {
          const reflect = isCubic(previous);
          const x1 = reflect ? 2 * x - controlX : x;
          const y1 = reflect ? 2 * y - controlY : y;
          const x2 = baseX + scanner.readNumber();
          const y2 = baseY + scanner.readNumber();
          x = baseX + scanner.readNumber();
          y = baseY + scanner.readNumber();
          out.push(CUBIC, x1, y1, x2, y2, x, y);
          controlX = x2;
          controlY = y2;
          break;
        }
        case 'Q': {
          const qx = baseX + scanner.readNumber();
          const qy = baseY + scanner.readNumber();
          const endX = baseX + scanner.readNumber();
          const endY = baseY + scanner.readNumber();
          pushQuadratic(out, x, y, qx, qy, endX, endY);
          x = endX;
          y = endY;
          controlX = qx;
          controlY = qy;
          break;
        }
        case 'T': {
          const reflect = isQuadratic(previous);
          const qx = reflect ? 2 * x - controlX : x;
          const qy = reflect ? 2 * y - controlY : y;
          const endX = baseX + scanner.readNumber();
          const endY = baseY + scanner.readNumber();
          pushQuadratic(out, x, y, qx, qy, endX, endY);
          x = endX;
          y = endY;
          controlX = qx;
          controlY = qy;
          break;
        }
        case 'A': {
          const rx = scanner.readNumber();
          const ry = scanner.readNumber();
          const rotation = scanner.readNumber();
          const largeArc = scanner.readFlag();
          const sweep = scanner.readFlag();
          const endX = baseX + scanner.readNumber();
          const endY = baseY + scanner.readNumber();
          pushArc(out, x, y, rx, ry, rotation, largeArc, sweep, endX, endY);
          x = endX;
          y = endY;
          break;
        }
        case 'Z': {
          out.push(CLOSE);
          x = startX;
          y = startY;
          break;
        }
      }
      previous = upper === 'Z' ? 'Z' : command;
    }
  } catch (error) {
    if (!(error instanceof ParseStop)) {
      throw error;
    }
  }

  return out;
}

function isCubic(command: string) {
  return 'CcSs'.includes(command) && command !== '';
}

function isQuadratic(command: string) {
  return 'QqTt'.includes(command) && command !== '';
}

function pushQuadratic(
  out: number[],
  x0: number,
  y0: number,
  qx: number,
  qy: number,
  x: number,
  y: number
) {
  out.push(
    CUBIC,
    x0 + (2 / 3) * (qx - x0),
    y0 + (2 / 3) * (qy - y0),
    x + (2 / 3) * (qx - x),
    y + (2 / 3) * (qy - y),
    x,
    y
  );
}

function vectorAngle(ux: number, uy: number, vx: number, vy: number) {
  return Math.atan2(ux * vy - uy * vx, ux * vx + uy * vy);
}

/** SVG 1.1 implementation notes F.6.5 (endpoint → center) + cubic approximation. */
function pushArc(
  out: number[],
  x1: number,
  y1: number,
  rxIn: number,
  ryIn: number,
  rotationDeg: number,
  largeArc: boolean,
  sweep: boolean,
  x2: number,
  y2: number
) {
  if (x1 === x2 && y1 === y2) {
    return;
  }
  let rx = Math.abs(rxIn);
  let ry = Math.abs(ryIn);
  if (rx === 0 || ry === 0) {
    out.push(LINE, x2, y2);
    return;
  }

  const phi = (rotationDeg * Math.PI) / 180;
  const cos = Math.cos(phi);
  const sin = Math.sin(phi);

  const dx = (x1 - x2) / 2;
  const dy = (y1 - y2) / 2;
  const x1p = cos * dx + sin * dy;
  const y1p = -sin * dx + cos * dy;

  const lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
  if (lambda > 1) {
    const scale = Math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
  }

  const rx2 = rx * rx;
  const ry2 = ry * ry;
  const numerator = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p;
  const denominator = rx2 * y1p * y1p + ry2 * x1p * x1p;
  let coefficient =
    denominator === 0 ? 0 : Math.sqrt(Math.max(0, numerator / denominator));
  if (largeArc === sweep) {
    coefficient = -coefficient;
  }
  const cxp = (coefficient * rx * y1p) / ry;
  const cyp = (-coefficient * ry * x1p) / rx;
  const cx = cos * cxp - sin * cyp + (x1 + x2) / 2;
  const cy = sin * cxp + cos * cyp + (y1 + y2) / 2;

  const ux = (x1p - cxp) / rx;
  const uy = (y1p - cyp) / ry;
  const vx = (-x1p - cxp) / rx;
  const vy = (-y1p - cyp) / ry;
  const theta1 = vectorAngle(1, 0, ux, uy);
  let deltaTheta = vectorAngle(ux, uy, vx, vy);
  if (!sweep && deltaTheta > 0) {
    deltaTheta -= 2 * Math.PI;
  } else if (sweep && deltaTheta < 0) {
    deltaTheta += 2 * Math.PI;
  }

  const segments = Math.max(
    1,
    Math.ceil(Math.abs(deltaTheta) / (Math.PI / 2) - 1e-9)
  );
  const delta = deltaTheta / segments;
  const t = (4 / 3) * Math.tan(delta / 4);

  const mapX = (px: number, py: number) => cx + cos * rx * px - sin * ry * py;
  const mapY = (px: number, py: number) => cy + sin * rx * px + cos * ry * py;

  let theta = theta1;
  for (let i = 0; i < segments; i++) {
    const cos1 = Math.cos(theta);
    const sin1 = Math.sin(theta);
    const theta2 = theta + delta;
    const cos2 = Math.cos(theta2);
    const sin2 = Math.sin(theta2);

    const c1x = cos1 - t * sin1;
    const c1y = sin1 + t * cos1;
    const c2x = cos2 + t * sin2;
    const c2y = sin2 - t * cos2;
    const last = i === segments - 1;

    out.push(
      CUBIC,
      mapX(c1x, c1y),
      mapY(c1x, c1y),
      mapX(c2x, c2y),
      mapY(c2x, c2y),
      last ? x2 : mapX(cos2, sin2),
      last ? y2 : mapY(cos2, sin2)
    );
    theta = theta2;
  }
}
