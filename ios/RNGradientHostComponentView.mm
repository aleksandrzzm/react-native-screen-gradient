#import "RNGradientHostComponentView.h"

#import <React/RCTConversions.h>
#import <React/RCTMountingTransactionObserving.h>

#import <react/renderer/components/ScreenGradientViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/ScreenGradientViewSpec/Props.h>
#import <react/renderer/components/ScreenGradientViewSpec/RCTComponentViewHelpers.h>

#import "RNGradientSwift.h"

using namespace facebook::react;

@interface RNGradientHostComponentView () <RNGradientHosting, RCTMountingTransactionObserving>
@end

@implementation RNGradientHostComponentView {
  RNGradientHost *_host;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNGradientHostComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const RNGradientHostProps>();
    _props = defaultProps;
    _host = [[RNGradientHost alloc] initWithHostView:self];
  }
  return self;
}

- (RNGradientHost *)gradientHost
{
  return _host;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<RNGradientHostProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<RNGradientHostProps const>(props);

  if (oldViewProps.host != newViewProps.host) {
    _host.name = [NSString stringWithUTF8String:newViewProps.host.c_str()];
  }

  if (oldViewProps.colors != newViewProps.colors || oldViewProps.locations != newViewProps.locations ||
      oldViewProps.start.x != newViewProps.start.x || oldViewProps.start.y != newViewProps.start.y ||
      oldViewProps.end.x != newViewProps.end.x || oldViewProps.end.y != newViewProps.end.y) {
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:newViewProps.colors.size()];
    for (const auto &color : newViewProps.colors) {
      UIColor *uiColor = RCTUIColorFromSharedColor(color);
      [colors addObject:uiColor ?: UIColor.clearColor];
    }
    NSMutableArray<NSNumber *> *locations = nil;
    if (!newViewProps.locations.empty()) {
      locations = [NSMutableArray arrayWithCapacity:newViewProps.locations.size()];
      for (const auto location : newViewProps.locations) {
        [locations addObject:@(location)];
      }
    }
    [_host setColors:colors
           locations:locations
               start:CGPointMake(newViewProps.start.x, newViewProps.start.y)
                 end:CGPointMake(newViewProps.end.x, newViewProps.end.y)];
  }

  [super updateProps:props oldProps:oldProps];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [_host hostDidLayout];
}

#pragma mark - RCTMountingTransactionObserving

- (void)mountingTransactionDidMount:(const MountingTransaction &)transaction
               withSurfaceTelemetry:(const SurfaceTelemetry &)surfaceTelemetry
{
  [_host mountingTransactionDidMount];
}

@end
