import NativeScreenGradient from './ScreenGradientNativeComponent';
import { ScreenGradientContext } from './ScreenGradientContext';
import type { GradientPoint, ScreenGradientProps } from './types';

const DEFAULT_START: GradientPoint = { x: 0, y: 0 };
const DEFAULT_END: GradientPoint = { x: 0, y: 1 };

export function ScreenGradient({
  start = DEFAULT_START,
  end = DEFAULT_END,
  children,
  ...rest
}: ScreenGradientProps) {
  return (
    <ScreenGradientContext.Provider value={true}>
      <NativeScreenGradient {...rest} start={start} end={end}>
        {children}
      </NativeScreenGradient>
    </ScreenGradientContext.Provider>
  );
}
