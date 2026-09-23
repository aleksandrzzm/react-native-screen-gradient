import { parsePathData } from './parsePathData';

/**
 * Flat encoding shared with native code (Android GradientMaskSvgView.kt,
 * iOS GradientRenderer.swift). Per path:
 *
 *   flags, strokeWidth, strokeCap, strokeJoin, miterLimit, commandLength,
 *   ...commands (see parsePathData.ts)
 *
 * flags: 1 = fill, 2 = even-odd fill rule, 4 = stroke
 * strokeCap: 0 butt, 1 round, 2 square
 * strokeJoin: 0 miter, 1 round, 2 bevel
 */
export const PATH_HEADER_LENGTH = 6;

export const FLAG_FILL = 1;
export const FLAG_EVEN_ODD = 2;
export const FLAG_STROKE = 4;

export type NormalizedPath = {
  d: string;
  fill: boolean;
  evenOdd: boolean;
  stroke: boolean;
  strokeWidth: number;
  strokeCap: number;
  strokeJoin: number;
  miterLimit: number;
};

export function encodePaths(paths: ReadonlyArray<NormalizedPath>): number[] {
  const out: number[] = [];
  for (const path of paths) {
    if (!path.fill && !path.stroke) {
      continue;
    }
    const commands = parsePathData(path.d);
    if (commands.length === 0) {
      continue;
    }
    // Bit flags; they are distinct powers of two, so addition sets bits.
    const flags =
      (path.fill ? FLAG_FILL : 0) +
      (path.evenOdd ? FLAG_EVEN_ODD : 0) +
      (path.stroke ? FLAG_STROKE : 0);
    out.push(
      flags,
      path.strokeWidth,
      path.strokeCap,
      path.strokeJoin,
      path.miterLimit,
      commands.length
    );
    for (const value of commands) {
      out.push(value);
    }
  }
  return out;
}

/** "minX minY width height" → [minX, minY, width, height], or [] if invalid. */
export function parseViewBox(viewBox: string | undefined): number[] {
  if (!viewBox) {
    return [];
  }
  const values = viewBox
    .trim()
    .split(/[\s,]+/)
    .map(Number);
  if (
    values.length !== 4 ||
    values.some((value) => !Number.isFinite(value)) ||
    values[2]! <= 0 ||
    values[3]! <= 0
  ) {
    return [];
  }
  return values;
}
