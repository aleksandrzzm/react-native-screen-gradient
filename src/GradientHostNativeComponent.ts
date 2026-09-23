import {
  codegenNativeComponent,
  type CodegenTypes,
  type ColorValue,
  type ViewProps,
} from 'react-native';

type Point = Readonly<{
  x: CodegenTypes.Float;
  y: CodegenTypes.Float;
}>;

export interface NativeProps extends ViewProps {
  host?: CodegenTypes.WithDefault<string, 'main'>;
  colors: ReadonlyArray<ColorValue>;
  locations?: ReadonlyArray<CodegenTypes.Float>;
  start?: Point;
  end?: Point;
}

export default codegenNativeComponent<NativeProps>('RNGradientHost');
