import { createContext, useContext, useEffect } from 'react';

export const DEFAULT_HOST_NAME = 'main';

/**
 * Names of the ancestor GradientHosts. Only used for the development-time
 * "outside GradientHost" warning; native code finds its host through the
 * native view hierarchy.
 */
export const GradientHostContext = createContext<ReadonlyArray<string>>([]);

export function useMissingHostWarning(component: string, hostName: string) {
  const hostNames = useContext(GradientHostContext);
  const found = hostNames.includes(hostName);

  useEffect(() => {
    if (__DEV__ && !found) {
      console.warn(
        hostName === DEFAULT_HOST_NAME
          ? `${component} must be inside GradientHost.`
          : `${component} must be inside GradientHost (host="${hostName}").`
      );
    }
  }, [component, hostName, found]);
}
