import { createContext } from 'react';

/**
 * Only used for the development-time "GradientView outside ScreenGradient"
 * warning. Native code finds its host through the native view hierarchy.
 */
export const ScreenGradientContext = createContext(false);
