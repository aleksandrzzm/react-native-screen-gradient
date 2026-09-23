#import "RNScreenGradientViewComponentView.h"

#import <React/RCTBorderDrawing.h>
#import <React/RCTConversions.h>

#import <react/renderer/components/ScreenGradientViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/ScreenGradientViewSpec/Props.h>
#import <react/renderer/components/ScreenGradientViewSpec/RCTComponentViewHelpers.h>

#import "RNScreenGradientSwift.h"

using namespace facebook::react;

@implementation RNScreenGradientViewComponentView {
  RNScreenGradientRenderer *_renderer;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNScreenGradientViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNScreenGradientViewProps>();
    _props = defaultProps;
    _renderer = [[RNScreenGradientRenderer alloc] initWithView:self];
  }
  return self;
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

/// Clips the gradient to the padding box (inside borders, following borderRadius), like a
/// background would be.
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
