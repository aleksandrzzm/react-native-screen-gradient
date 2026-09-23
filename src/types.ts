import type { ReactNode } from 'react';
import type { ColorValue, ViewProps } from 'react-native';

export type GradientPoint = {
  /** Fraction of the GradientHost width, 0..1. */
  x: number;
  /** Fraction of the GradientHost height, 0..1. */
  y: number;
};

export type GradientHostProps = ViewProps & {
  /** Name that GradientView / GradientMaskSvg refer to via `hostName`. Default "main". */
  host?: string;
  colors: ReadonlyArray<ColorValue>;
  locations?: ReadonlyArray<number>;
  start?: GradientPoint;
  end?: GradientPoint;
};

export type GradientViewProps = ViewProps & {
  /** Nearest ancestor GradientHost with this `host` name is used. Default "main". */
  hostName?: string;
};

export type GradientMaskSvgProps = Omit<ViewProps, 'children'> & {
  /** Nearest ancestor GradientHost with this `host` name is used. Default "main". */
  hostName?: string;
  /** "minX minY width height", scaled into the view like SVG's default xMidYMid meet. */
  viewBox?: string;
  /** `<Path>` elements (from this library or react-native-svg). */
  children?: ReactNode;
};

export type PathProps = {
  /** SVG path data. */
  d: string;
  /** "none" / "transparent" disable filling. Any other value fills with the gradient. */
  fill?: string;
  fillRule?: 'nonzero' | 'evenodd';
  /** Any value other than "none" / "transparent" strokes with the gradient. */
  stroke?: string;
  strokeWidth?: number | string;
  strokeLinecap?: 'butt' | 'round' | 'square';
  strokeLinejoin?: 'miter' | 'round' | 'bevel';
  strokeMiterlimit?: number | string;
};
