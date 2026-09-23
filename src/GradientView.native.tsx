import NativeGradientView from './GradientViewNativeComponent';
import {
  DEFAULT_HOST_NAME,
  useMissingHostWarning,
} from './GradientHostContext';
import type { GradientViewProps } from './types';

export function GradientView({
  hostName = DEFAULT_HOST_NAME,
  ...rest
}: GradientViewProps) {
  useMissingHostWarning('GradientView', hostName);

  return <NativeGradientView {...rest} hostName={hostName} />;
}
