import { describe, expect, it } from '@jest/globals';
import { createElement, Fragment } from 'react';
import { collectPaths } from '../svg/collectPaths';
import {
  encodePaths,
  FLAG_EVEN_ODD,
  FLAG_FILL,
  FLAG_STROKE,
  parseViewBox,
} from '../svg/encodePaths';
import { CLOSE, CUBIC, LINE, MOVE, parsePathData } from '../svg/parsePathData';
import { Path } from '../Path';

function round(values: number[]) {
  return values.map((value) => Math.round(value * 1000) / 1000 + 0);
}

describe('parsePathData', () => {
  it('handles absolute and relative lines, H/V and close', () => {
    expect(parsePathData('M10 10 L20 10 l0 10 H5 v-5 z')).toEqual([
      MOVE,
      10,
      10,
      LINE,
      20,
      10,
      LINE,
      20,
      20,
      LINE,
      5,
      20,
      LINE,
      5,
      15,
      CLOSE,
    ]);
  });

  it('treats extra moveTo pairs as lineTo', () => {
    expect(parsePathData('m1 1 2 2 3 3')).toEqual([
      MOVE,
      1,
      1,
      LINE,
      3,
      3,
      LINE,
      6,
      6,
    ]);
    expect(parsePathData('M1 1 2 2')).toEqual([MOVE, 1, 1, LINE, 2, 2]);
  });

  it('parses compact numbers', () => {
    expect(parsePathData('M.5.5L-1-2l1e1,1E-1')).toEqual([
      MOVE,
      0.5,
      0.5,
      LINE,
      -1,
      -2,
      LINE,
      9,
      -1.9,
    ]);
  });

  it('starts a relative command after close at the subpath start', () => {
    expect(parsePathData('M10 10 L20 10 Z l5 5')).toEqual([
      MOVE,
      10,
      10,
      LINE,
      20,
      10,
      CLOSE,
      LINE,
      15,
      15,
    ]);
  });

  it('reflects cubic control points for S', () => {
    expect(parsePathData('M0 0 C0 10 10 10 10 0 S20 -10 20 0')).toEqual([
      MOVE,
      0,
      0,
      CUBIC,
      0,
      10,
      10,
      10,
      10,
      0,
      CUBIC,
      10,
      -10,
      20,
      -10,
      20,
      0,
    ]);
  });

  it('converts Q/T to cubics', () => {
    expect(round(parsePathData('M0 0 Q3 3 6 0 T12 0'))).toEqual([
      MOVE,
      0,
      0,
      CUBIC,
      2,
      2,
      4,
      2,
      6,
      0,
      CUBIC,
      8,
      -2,
      10,
      -2,
      12,
      0,
    ]);
  });

  it('approximates a half circle arc with two cubics ending exactly', () => {
    const out = parsePathData('M0 0 A10 10 0 0 1 20 0');
    expect(out[0]).toBe(MOVE);
    expect(out.filter((_, i) => i % 7 === 3)).toEqual([CUBIC, CUBIC]);
    expect(out.slice(-2)).toEqual([20, 0]);
    // Midpoint of the arc (end of first segment) is the top of the circle (sweep=1 → y<0).
    expect(round(out.slice(8, 10))).toEqual([10, -10]);
  });

  it('parses packed arc flags', () => {
    const out = parsePathData('M0 0a10 10 0 0020 0');
    expect(out.slice(-2)).toEqual([20, 0]);
    // sweep=0 → arc goes below (y>0).
    expect(round(out.slice(8, 10))).toEqual([10, 10]);
  });

  it('scales up radii that are too small', () => {
    const out = parsePathData('M0 0 A1 1 0 0 1 20 0');
    expect(round(out.slice(8, 10))).toEqual([10, -10]);
  });

  it('stops at the first error and requires an initial moveTo', () => {
    expect(parsePathData('M0 0 L10 10 L oops')).toEqual([
      MOVE,
      0,
      0,
      LINE,
      10,
      10,
    ]);
    expect(parsePathData('L10 10')).toEqual([]);
  });
});

describe('collectPaths / encodePaths', () => {
  it('reads Path-like children, flattening fragments', () => {
    const paths = collectPaths([
      createElement(Path, { d: 'M0 0 L1 1', fillRule: 'evenodd' }),
      createElement(
        Fragment,
        null,
        createElement(Path, {
          d: 'M0 0 L2 2',
          fill: 'none',
          stroke: 'black',
          strokeWidth: '3',
          strokeLinecap: 'round',
          strokeLinejoin: 'bevel',
        })
      ),
      createElement('View', { d: 42 }),
    ]);
    expect(paths).toHaveLength(2);
    expect(encodePaths(paths)).toEqual([
      FLAG_FILL + FLAG_EVEN_ODD,
      1,
      0,
      0,
      4,
      6,
      MOVE,
      0,
      0,
      LINE,
      1,
      1,
      FLAG_STROKE,
      3,
      1,
      2,
      4,
      6,
      MOVE,
      0,
      0,
      LINE,
      2,
      2,
    ]);
  });

  it('skips paths that are neither filled nor stroked', () => {
    const paths = collectPaths(
      createElement(Path, { d: 'M0 0 L1 1', fill: 'none' })
    );
    expect(encodePaths(paths)).toEqual([]);
  });

  it('parses viewBox', () => {
    expect(parseViewBox('0 0 24 24')).toEqual([0, 0, 24, 24]);
    expect(parseViewBox('-1,-1,2,2')).toEqual([-1, -1, 2, 2]);
    expect(parseViewBox('0 0 0 24')).toEqual([]);
    expect(parseViewBox(undefined)).toEqual([]);
  });
});
