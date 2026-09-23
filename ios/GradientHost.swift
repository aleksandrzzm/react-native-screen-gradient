import QuartzCore
import UIKit

@objc(RNGradientHosting)
public protocol GradientHosting: AnyObject {
  var gradientHost: GradientHost { get }
}

@objc(RNGradientRendering)
public protocol GradientRendering: AnyObject {
  var gradientRenderer: GradientRenderer { get }
}

@objc(RNGradientHost)
public final class GradientHost: NSObject {
  @objc public static let defaultName = "main"

  private weak var hostView: UIView?

  @objc public var name: String = GradientHost.defaultName {
    didSet {
      guard name != oldValue, let hostView, hostView.window != nil else { return }
      Self.resolveRenderers(in: hostView)
    }
  }

  private static func resolveRenderers(in view: UIView) {
    for subview in view.subviews {
      if let rendering = subview as? GradientRendering {
        rendering.gradientRenderer.resolveHost()
      }
      resolveRenderers(in: subview)
    }
  }

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


  @objc public func setColors(_ colors: [UIColor], locations: [NSNumber]?, start: CGPoint, end: CGPoint) {
    cgColors = colors.count == 1 ? [colors[0].cgColor, colors[0].cgColor] : colors.map(\.cgColor)
    self.locations = (locations?.count == cgColors.count) ? locations : nil
    startPoint = start
    endPoint = end
    for renderer in renderers.allObjects {
      renderer.applyGradient()
    }
  }


  @objc public func hostDidLayout() {
    updateAllPositions()
  }

  @objc public func mountingTransactionDidMount() {
    updateAllPositions()
  }

  @objc public func updateAllPositions() {
    for renderer in renderers.allObjects {
      renderer.updatePosition()
    }
  }


  func register(_ renderer: GradientRenderer) {
    renderers.add(renderer)
    rebuildScrollObservations()
    renderer.applyGradient()
  }

  func unregister(_ renderer: GradientRenderer) {
    renderers.remove(renderer)
    rebuildScrollObservations()
  }

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
