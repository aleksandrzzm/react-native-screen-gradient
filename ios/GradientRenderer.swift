import QuartzCore
import UIKit

/// Rendering core of `<GradientView>`.
///
/// Why one CAGradientLayer per GradientView: a CALayer can have only one superlayer and there is no
/// public API to display one layer in several places (portal layers are private). Masking a single
/// host-level layer would put the gradient outside the GradientView's z-order and clipping (it must
/// sit below the GradientView's children, inside the scroll content, under overlapping siblings).
///
/// So each GradientView gets a layer node, but it is *not* an independent gradient: its bounds are
/// the host's bounds, its colors/locations/start/end are the host's, and it is placed with the
/// host→view affine transform. Every GradientView therefore shows a window into the same gradient,
/// clipped to the view's own shape. Moving it is a pure Core Animation geometry change
/// (no re-rasterization, implicit animations disabled).
@objc(RNScreenGradientRenderer)
public final class GradientRenderer: NSObject {
  private weak var ownerView: UIView?
  private weak var host: ScreenGradientHost?

  /// Clips the gradient to the view's (rounded) bounds without clipping the view's children.
  private let clipLayer = CALayer()
  private let gradientLayer = CAGradientLayer()

  private var lastHostSize = CGSize.zero
  private var lastOrigin = CGPoint(x: CGFloat.nan, y: CGFloat.nan)
  private var lastTransform = CGAffineTransform.identity

  /// Just above RCTViewComponentView's background color layer (-1024) and below its border layer.
  private static let zPosition: CGFloat = -1023.5

  private static let disabledActions: [String: CAAction] = [
    "bounds": NSNull(), "position": NSNull(), "transform": NSNull(), "anchorPoint": NSNull(),
    "colors": NSNull(), "locations": NSNull(), "startPoint": NSNull(), "endPoint": NSNull(),
    "frame": NSNull(), "cornerRadius": NSNull(), "path": NSNull(), "hidden": NSNull(),
    "sublayers": NSNull(), "contents": NSNull(), "mask": NSNull(),
  ]

  var view: UIView? { ownerView }

  @objc public init(view: UIView) {
    ownerView = view
    super.init()
    clipLayer.masksToBounds = true
    clipLayer.zPosition = Self.zPosition
    clipLayer.actions = Self.disabledActions
    clipLayer.isHidden = true
    gradientLayer.anchorPoint = .zero
    gradientLayer.actions = Self.disabledActions
    clipLayer.addSublayer(gradientLayer)
  }

  // MARK: - Lifecycle, driven by the component view

  @objc public func viewDidMoveToWindow() {
    guard let view = ownerView, view.window != nil else {
      detachFromHost()
      return
    }
    attachToHost()
  }

  @objc public func viewDidLayout() {
    guard let view = ownerView else { return }
    if clipLayer.superlayer !== view.layer {
      view.layer.insertSublayer(clipLayer, at: 0)
    }
    clipLayer.frame = view.layer.bounds
    clipLayer.mask?.frame = clipLayer.bounds
    updatePosition()
  }

  /// Shape of the view's padding box. `path == nil` means a plain (optionally rounded) rect.
  @objc public func setClip(cornerRadius: CGFloat, cornerCurve: CALayerCornerCurve, path: CGPath?) {
    clipLayer.cornerRadius = path == nil ? cornerRadius : 0
    clipLayer.cornerCurve = cornerCurve
    if let path {
      let mask = (clipLayer.mask as? CAShapeLayer) ?? CAShapeLayer()
      mask.actions = Self.disabledActions
      mask.frame = clipLayer.bounds
      mask.path = path
      clipLayer.mask = mask
    } else {
      clipLayer.mask = nil
    }
  }

  @objc public func prepareForRecycle() {
    detachFromHost()
  }

  // MARK: - Host

  private func attachToHost() {
    guard let view = ownerView else { return }
    var current = view.superview
    var found: ScreenGradientHost?
    while let candidate = current {
      if let hosting = candidate as? ScreenGradientHosting {
        found = hosting.screenGradientHost
        break
      }
      current = candidate.superview
    }
    if found === host {
      updatePosition()
      return
    }
    detachFromHost()
    guard let found else {
      // Not inside a ScreenGradient: draw nothing (the JS layer warns in development).
      return
    }
    host = found
    if clipLayer.superlayer !== view.layer {
      view.layer.insertSublayer(clipLayer, at: 0)
    }
    found.register(self)
    updatePosition()
  }

  private func detachFromHost() {
    host?.unregister(self)
    host = nil
    clipLayer.isHidden = true
    lastOrigin = CGPoint(x: CGFloat.nan, y: CGFloat.nan)
  }

  func applyGradient() {
    guard let host else { return }
    gradientLayer.colors = host.cgColors
    gradientLayer.locations = host.locations
    // CAGradientLayer's unit coordinates are relative to its bounds, which are the host's bounds,
    // so the host-viewport fractions from JS map 1:1.
    gradientLayer.startPoint = host.startPoint
    gradientLayer.endPoint = host.endPoint
  }

  /// Places the gradient layer so that host-viewport point P is drawn at the view-local point
  /// where P physically is: layer transform = (host → view) affine map.
  func updatePosition() {
    guard let view = ownerView, let host, let hostView = host.view, view.window != nil else {
      return
    }
    let bounds = hostView.bounds
    let size = bounds.size
    guard size.width > 0, size.height > 0, !host.cgColors.isEmpty else {
      clipLayer.isHidden = true
      return
    }

    // Three host points are enough to recover the full affine host→view mapping, including
    // scroll offsets, nested scroll views, layout offsets and transforms (e.g. inverted lists).
    let origin = hostView.convert(bounds.origin, to: view)
    let xAxis = hostView.convert(CGPoint(x: bounds.minX + size.width, y: bounds.minY), to: view)
    let yAxis = hostView.convert(CGPoint(x: bounds.minX, y: bounds.minY + size.height), to: view)
    let transform = CGAffineTransform(
      a: (xAxis.x - origin.x) / size.width,
      b: (xAxis.y - origin.y) / size.width,
      c: (yAxis.x - origin.x) / size.height,
      d: (yAxis.y - origin.y) / size.height,
      tx: 0,
      ty: 0
    )
    // clipLayer shares the view's bounds origin, so view coordinates are clip-layer coordinates.
    let position = CGPoint(x: origin.x - view.bounds.minX, y: origin.y - view.bounds.minY)

    if size != lastHostSize {
      gradientLayer.bounds = CGRect(origin: .zero, size: size)
      lastHostSize = size
    }
    if position != lastOrigin {
      gradientLayer.position = position
      lastOrigin = position
    }
    if transform != lastTransform {
      gradientLayer.setAffineTransform(transform)
      lastTransform = transform
    }
    clipLayer.isHidden = false
  }
}
