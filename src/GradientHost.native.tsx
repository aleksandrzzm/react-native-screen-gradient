import { useContext, useMemo } from 'react';
import NativeGradientHost from './GradientHostNativeComponent';
import { DEFAULT_HOST_NAME, GradientHostContext } from './GradientHostContext';
import type { GradientHostProps, GradientPoint } from './types';

const DEFAULT_START: GradientPoint = { x: 0, y: 0 };
const DEFAULT_END: GradientPoint = { x: 0, y: 1 };

export function GradientHost({
  host = DEFAULT_HOST_NAME,
  start = DEFAULT_START,
  end = DEFAULT_END,
  children,
  ...rest
}: GradientHostProps) {
  const parentHosts = useContext(GradientHostContext);
  const hosts = useMemo(() => [...parentHosts, host], [parentHosts, host]);

  return (
    <GradientHostContext.Provider value={hosts}>
      <NativeGradientHost {...rest} host={host} start={start} end={end}>
        {children}
      </NativeGradientHost>
    </GradientHostContext.Provider>
  );
}
