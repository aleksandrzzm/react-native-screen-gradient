import { useMemo } from 'react';
import NativeGradientMaskSvg from './GradientMaskSvgNativeComponent';
import {
  DEFAULT_HOST_NAME,
  useMissingHostWarning,
} from './GradientHostContext';
import { collectPaths } from './svg/collectPaths';
import { encodePaths, parseViewBox } from './svg/encodePaths';
import type { GradientMaskSvgProps } from './types';

/**
 * Renders its `<Path>` children filled / stroked with the GradientHost gradient.
 * Path data is converted once per change of the path props, never while scrolling.
 */
export function GradientMaskSvg({
  hostName = DEFAULT_HOST_NAME,
  viewBox,
  children,
  ...rest
}: GradientMaskSvgProps) {
  useMissingHostWarning('GradientMaskSvg', hostName);

  const paths = collectPaths(children);
  const pathsKey = JSON.stringify(paths);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const pathData = useMemo(() => encodePaths(paths), [pathsKey]);
  const viewBoxData = useMemo(() => parseViewBox(viewBox), [viewBox]);

  return (
    <NativeGradientMaskSvg
      {...rest}
      hostName={hostName}
      pathData={pathData}
      viewBox={viewBoxData}
    />
  );
}
