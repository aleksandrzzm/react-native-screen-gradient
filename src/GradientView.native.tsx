import { useContext, useEffect } from 'react';
import NativeGradientView from './GradientViewNativeComponent';
import { ScreenGradientContext } from './ScreenGradientContext';
import type { GradientViewProps } from './types';

export function GradientView(props: GradientViewProps) {
  const insideScreenGradient = useContext(ScreenGradientContext);

  useEffect(() => {
    if (__DEV__ && !insideScreenGradient) {
      console.warn('GradientView must be inside ScreenGradient.');
    }
  }, [insideScreenGradient]);

  return <NativeGradientView {...props} />;
}
