import QuartzCore
import UIKit

/// Implemented by the host component view so descendants can find their gradient host by walking
/// the UIKit superview chain.
@objc(RNScreenGradientHosting)
public protocol ScreenGradientHosting: AnyObject {
  var screenGradientHost: ScreenGradientHost { get }
}

/// Rendering core of `<ScreenGradient>`.
///
/// Owns the single logical gradient description, defined in the host view's bounds (its viewport).
/// Registered `GradientRenderer`s mirror this description in host coordinates and only differ by
/// where the host's origin lies in their own coordinate space.
///
/// Positions are refreshed from native signals only:
/// - host / gradient view `layoutSubviews` and `didMoveToWindow`,
/// - Fabric mount transactions (any React layout change),
/// - KVO on `contentOffset` of UIScrollViews that sit between a gradient view and the host.
@objc(RNScreenGradientHost)
public final class ScreenGradientHost: NSObject {
  private weak var hostView: UIView?

  private(set) var cgColors: [CGColor] = []
  private(set) var locations: [NSNumber]?
  private(set) var startPoint = CGPoint(x: 0, y: 0)
  private(set) var endPoint = CGPoint(x: 0, y: 1)

  private let renderers = NSHashTable<GradientRenderer>.weakObjects()
  private var scrollObservations: [ObjectIdentifier: ScrollObservation] = [:]

  @objc public init(hostView: UIView) {
    self.hostView = hostView
    super.init()
  }

  var view: UIView? { hostView }

  // MARK: - Gradient description

  @objc public func setColors(_ colors: [UIColor], locations: [NSNumber]?, start: CGPoint, end: CGPoint) {
    cgColors = colors.count == 1 ? [colors[0].cgColor, colors[0].cgColor] : colors.map(\.cgColor)
    self.locations = (locations?.count == cgColors.count) ? locations : nil
    startPoint = start
    endPoint = end
    for renderer in renderers.allObjects {
      renderer.applyGradient()
    }
  }

  // MARK: - Native triggers

  /// Host bounds changed (rotation, resize): gradient size and every mapping change.
  @objc public func hostDidLayout() {
    updateAllPositions()
  }

  /// A Fabric mount transaction completed: any ancestor of any gradient view may have moved.
  @objc public func mountingTransactionDidMount() {
    updateAllPositions()
  }

  @objc public func updateAllPositions() {
    for renderer in renderers.allObjects {
      renderer.updatePosition()
    }
  }

  // MARK: - Registry

  func register(_ renderer: GradientRenderer) {
    renderers.add(renderer)
    rebuildScrollObservations()
    renderer.applyGradient()
  }

  func unregister(_ renderer: GradientRenderer) {
    renderers.remove(renderer)
    rebuildScrollObservations()
  }

  /// Observes exactly the scroll views that lie between a registered gradient view and the host.
  /// Rebuilt only on (un)registration, never while scrolling.
  private func rebuildScrollObservations() {
    guard let hostView else {
      scrollObservations.removeAll()
      return
    }
    var needed: [ObjectIdentifier: UIScrollView] = [:]
    for renderer in renderers.allObjects {
      var current = renderer.view?.superview
      while let view = current, view !== hostView {
        if let scrollView = view as? UIScrollView {
          needed[ObjectIdentifier(scrollView)] = scrollView
        }
        current = view.superview
      }
    }
    for key in scrollObservations.keys where needed[key] == nil {
      scrollObservations.removeValue(forKey: key)
    }
    for (key, scrollView) in needed where scrollObservations[key] == nil {
      scrollObservations[key] = ScrollObservation(scrollView: scrollView) { [weak self] in
        self?.updateAllPositions()
      }
    }
  }
}

/// Synchronous KVO on `contentOffset`. UIScrollView sets it on every step of dragging,
/// deceleration, bouncing and animated `setContentOffset(_:animated:)`, on the main thread,
/// before Core Animation commits the frame.
private final class ScrollObservation {
  private var observation: NSKeyValueObservation?

  init(scrollView: UIScrollView, onChange: @escaping () -> Void) {
    observation = scrollView.observe(\.contentOffset, options: []) { _, _ in
      onChange()
    }
  }

  deinit {
    observation?.invalidate()
  }
}
