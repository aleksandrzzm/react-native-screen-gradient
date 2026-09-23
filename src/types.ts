import type { ColorValue, ViewProps } from 'react-native';

export type GradientPoint = {
  /** Fraction of the ScreenGradient viewport width, 0..1. */
  x: number;
  /** Fraction of the ScreenGradient viewport height, 0..1. */
  y: number;
};

export type ScreenGradientProps = ViewProps & {
  colors: ReadonlyArray<ColorValue>;
  locations?: ReadonlyArray<number>;
  start?: GradientPoint;
  end?: GradientPoint;
};

export type GradientViewProps = ViewProps;
