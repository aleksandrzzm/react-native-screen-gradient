import {
  codegenNativeComponent,
  type CodegenTypes,
  type ViewProps,
} from 'react-native';

export interface NativeProps extends ViewProps {
  hostName?: CodegenTypes.WithDefault<string, 'main'>;
  pathData: ReadonlyArray<CodegenTypes.Float>;
  viewBox?: ReadonlyArray<CodegenTypes.Float>;
}

export default codegenNativeComponent<NativeProps>('RNGradientMaskSvg');
