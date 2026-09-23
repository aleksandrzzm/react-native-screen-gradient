#import "RNGradientMaskSvgComponentView.h"

#import <react/renderer/components/ScreenGradientViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/ScreenGradientViewSpec/Props.h>
#import <react/renderer/components/ScreenGradientViewSpec/RCTComponentViewHelpers.h>

#import "RNGradientSwift.h"

using namespace facebook::react;

static NSArray<NSNumber *> *RNGradientNumbersFromVector(const std::vector<Float> &values)
{
  NSMutableArray<NSNumber *> *numbers = [NSMutableArray arrayWithCapacity:values.size()];
  for (const auto value : values) {
    [numbers addObject:@(value)];
  }
  return numbers;
}

@interface RNGradientMaskSvgComponentView () <RNGradientRendering>
@end

@implementation RNGradientMaskSvgComponentView {
  RNGradientRenderer *_renderer;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNGradientMaskSvgComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNGradientMaskSvgProps>();
    _props = defaultProps;
    _renderer = [[RNGradientRenderer alloc] initWithView:self];
    [_renderer setMaskPaths:@[] viewBox:@[]];
  }
  return self;
}

- (RNGradientRenderer *)gradientRenderer
{
  return _renderer;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNGradientMaskSvgProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNGradientMaskSvgProps const>(props);

  if (oldViewProps.hostName != newViewProps.hostName) {
    _renderer.hostName = [NSString stringWithUTF8String:newViewProps.hostName.c_str()];
  }

  if (oldViewProps.pathData != newViewProps.pathData || oldViewProps.viewBox != newViewProps.viewBox) {
    [_renderer setMaskPaths:RNGradientNumbersFromVector(newViewProps.pathData)
                    viewBox:RNGradientNumbersFromVector(newViewProps.viewBox)];
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  [_renderer viewDidMoveToWindow];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [_renderer viewDidLayout];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_renderer prepareForRecycle];
}

@end
