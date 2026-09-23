#import "RNGradientViewComponentView.h"

#import <React/RCTBorderDrawing.h>
#import <React/RCTConversions.h>

#import <react/renderer/components/ScreenGradientViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/ScreenGradientViewSpec/Props.h>
#import <react/renderer/components/ScreenGradientViewSpec/RCTComponentViewHelpers.h>

#import "RNGradientSwift.h"

using namespace facebook::react;

@interface RNGradientViewComponentView () <RNGradientRendering>
@end

@implementation RNGradientViewComponentView {
  RNGradientRenderer *_renderer;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNGradientViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNGradientViewProps>();
    _props = defaultProps;
    _renderer = [[RNGradientRenderer alloc] initWithView:self];
  }
  return self;
}

- (RNGradientRenderer *)gradientRenderer
{
  return _renderer;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNGradientViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNGradientViewProps const>(props);

  if (oldViewProps.hostName != newViewProps.hostName) {
    _renderer.hostName = [NSString stringWithUTF8String:newViewProps.hostName.c_str()];
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
  [self updateGradientClip];
  [_renderer viewDidLayout];
}

- (void)finalizeUpdates:(RNComponentViewUpdateMask)updateMask
{
  [super finalizeUpdates:updateMask];
  [self updateGradientClip];
}

- (void)prepareForRecycle
{
  [super prepareForRecycle];
  [_renderer prepareForRecycle];
}

- (void)updateGradientClip
{
  const auto borderMetrics = _props->resolveBorderMetrics(_layoutMetrics);
  const auto &radii = borderMetrics.borderRadii;
  const auto &widths = borderMetrics.borderWidths;
  CALayerCornerCurve cornerCurve =
      borderMetrics.borderCurves.topLeft == BorderCurve::Continuous ? kCACornerCurveContinuous : kCACornerCurveCircular;

  if (radii.isUniform() && widths.isUniform() && widths.left == 0) {
    [_renderer setClipWithCornerRadius:radii.topLeft.horizontal cornerCurve:cornerCurve path:nil];
    return;
  }

  RCTCornerRadii cornerRadii = {
      .topLeftHorizontal = (CGFloat)radii.topLeft.horizontal,
      .topLeftVertical = (CGFloat)radii.topLeft.vertical,
      .topRightHorizontal = (CGFloat)radii.topRight.horizontal,
      .topRightVertical = (CGFloat)radii.topRight.vertical,
      .bottomLeftHorizontal = (CGFloat)radii.bottomLeft.horizontal,
      .bottomLeftVertical = (CGFloat)radii.bottomLeft.vertical,
      .bottomRightHorizontal = (CGFloat)radii.bottomRight.horizontal,
      .bottomRightVertical = (CGFloat)radii.bottomRight.vertical,
  };
  UIEdgeInsets borderInsets = RCTUIEdgeInsetsFromEdgeInsets(widths);
  CGRect paddingBox = UIEdgeInsetsInsetRect(self.bounds, borderInsets);
  CGPathRef path = RCTPathCreateWithRoundedRect(paddingBox, RCTGetCornerInsets(cornerRadii, borderInsets), NULL, NO);
  [_renderer setClipWithCornerRadius:0 cornerCurve:cornerCurve path:path];
  CGPathRelease(path);
}

@end
