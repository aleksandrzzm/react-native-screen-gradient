import { Children, Fragment, isValidElement, type ReactNode } from 'react';
import type { NormalizedPath } from './encodePaths';

const CAPS: Record<string, number> = { butt: 0, round: 1, square: 2 };
const JOINS: Record<string, number> = { miter: 0, round: 1, bevel: 2 };

function isPaintNone(value: unknown) {
  return value === 'none' || value === 'transparent';
}

function toNumber(value: unknown, fallback: number) {
  const number = typeof value === 'string' ? parseFloat(value) : value;
  return typeof number === 'number' && Number.isFinite(number)
    ? number
    : fallback;
}

/**
 * Reads the props of direct `<Path>`-like children (anything with a string `d`
 * prop, including react-native-svg's Path). Fragments and arrays are flattened.
 * Custom components that *render* a Path are not visible here.
 */
export function collectPaths(
  children: ReactNode,
  out: NormalizedPath[] = []
): NormalizedPath[] {
  Children.forEach(children, (child) => {
    if (!isValidElement(child)) {
      return;
    }
    const props = child.props as Record<string, unknown>;
    if (child.type === Fragment) {
      collectPaths(props.children as ReactNode, out);
      return;
    }
    if (typeof props.d !== 'string') {
      return;
    }
    const stroke = props.stroke !== undefined && !isPaintNone(props.stroke);
    out.push({
      d: props.d,
      fill: !isPaintNone(props.fill),
      evenOdd: props.fillRule === 'evenodd',
      stroke,
      strokeWidth: toNumber(props.strokeWidth, 1),
      strokeCap: CAPS[String(props.strokeLinecap)] ?? 0,
      strokeJoin: JOINS[String(props.strokeLinejoin)] ?? 0,
      miterLimit: toNumber(props.strokeMiterlimit, 4),
    });
  });
  return out;
}
