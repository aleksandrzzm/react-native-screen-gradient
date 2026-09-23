import QuartzCore
import UIKit

@objc(RNGradientRenderer)
public final class GradientRenderer: NSObject {
  private weak var ownerView: UIView?
  private weak var host: GradientHost?

  @objc public var hostName: String = GradientHost.defaultName {
    didSet {
      if hostName != oldValue {
        resolveHost()
      }
    }
  }

  private let clipLayer = CALayer()
  private let gradientLayer = CAGradientLayer()

  private var pathMaskLayer: CALayer?
  private var viewBox: CGRect?

  private var lastHostSize = CGSize.zero
  private var lastOrigin = CGPoint(x: CGFloat.nan, y: CGFloat.nan)
  private var lastTransform = CGAffineTransform.identity

  private static let zPosition: CGFloat = -1023.5

  private static let disabledActions: [String: CAAction] = [
    "bounds": NSNull(), "position": NSNull(), "transform": NSNull(), "anchorPoint": NSNull(),
    "colors": NSNull(), "locations": NSNull(), "startPoint": NSNull(), "endPoint": NSNull(),
    "frame": NSNull(), "cornerRadius": NSNull(), "path": NSNull(), "hidden": NSNull(),
    "sublayers": NSNull(), "contents": NSNull(), "mask": NSNull(), "sublayerTransform": NSNull(),
    "lineWidth": NSNull(), "fillColor": NSNull(), "strokeColor": NSNull(),
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

  @objc public func viewDidMoveToWindow() {
    resolveHost()
  }

  @objc public func viewDidLayout() {
    guard let view = ownerView else { return }
    if clipLayer.superlayer !== view.layer {
      view.layer.insertSublayer(clipLayer, at: 0)
    }
    clipLayer.frame = view.layer.bounds
    clipLayer.mask?.frame = clipLayer.bounds
    updateViewBoxTransform()
    updatePosition()
  }

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

  @objc public func setMaskPaths(_ data: [NSNumber], viewBox box: [NSNumber]) {
    let container = pathMaskLayer ?? CALayer()
    container.actions = Self.disabledActions
    container.sublayers = SvgPathDecoder.decode(data.map { CGFloat(truncating: $0) }).map { item in
      let shape = CAShapeLayer()
      shape.actions = Self.disabledActions
      shape.path = item.path
      shape.fillRule = item.evenOdd ? .evenOdd : .nonZero
      shape.fillColor = item.fill ? UIColor.black.cgColor : nil
      shape.strokeColor = item.stroke ? UIColor.black.cgColor : nil
      shape.lineWidth = item.strokeWidth
      shape.lineCap = item.lineCap
      shape.lineJoin = item.lineJoin
      shape.miterLimit = item.miterLimit
      return shape
    }
    pathMaskLayer = container
    clipLayer.mask = container
    container.frame = clipLayer.bounds

    if box.count == 4, box[2].doubleValue > 0, box[3].doubleValue > 0 {
      viewBox = CGRect(
        x: box[0].doubleValue, y: box[1].doubleValue,
        width: box[2].doubleValue, height: box[3].doubleValue)
    } else {
      viewBox = nil
    }
    updateViewBoxTransform()
  }

  private func updateViewBoxTransform() {
    guard let container = pathMaskLayer else { return }
    let bounds = clipLayer.bounds
    guard let box = viewBox, bounds.width > 0, bounds.height > 0 else {
      container.sublayerTransform = CATransform3DIdentity
      return
    }
    let scale = min(bounds.width / box.width, bounds.height / box.height)
    var transform = CGAffineTransform(
      translationX: (bounds.width - box.width * scale) / 2,
      y: (bounds.height - box.height * scale) / 2)
    transform = transform.scaledBy(x: scale, y: scale)
    transform = transform.translatedBy(x: -box.minX, y: -box.minY)
    container.sublayerTransform = CATransform3DMakeAffineTransform(transform)
  }

  @objc public func prepareForRecycle() {
    detachFromHost()
  }

  @objc public func resolveHost() {
    guard let view = ownerView, view.window != nil else {
      detachFromHost()
      return
    }
    var current = view.superview
    var found: GradientHost?
    while let candidate = current {
      if let hosting = candidate as? GradientHosting, hosting.gradientHost.name == hostName {
        found = hosting.gradientHost
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
    gradientLayer.startPoint = host.startPoint
    gradientLayer.endPoint = host.endPoint
  }

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

enum SvgPathDecoder {
  struct Item {
    let path: CGPath
    let fill: Bool
    let evenOdd: Bool
    let stroke: Bool
    let strokeWidth: CGFloat
    let lineCap: CAShapeLayerLineCap
    let lineJoin: CAShapeLayerLineJoin
    let miterLimit: CGFloat
  }

  private static let headerLength = 6
  private static let caps: [CAShapeLayerLineCap] = [.butt, .round, .square]
  private static let joins: [CAShapeLayerLineJoin] = [.miter, .round, .bevel]

  static func decode(_ data: [CGFloat]) -> [Item] {
    var items: [Item] = []
    var i = 0
    while i + headerLength <= data.count {
      let flags = Int(data[i])
      let strokeWidth = data[i + 1]
      let cap = caps[safe: Int(data[i + 2])] ?? .butt
      let join = joins[safe: Int(data[i + 3])] ?? .miter
      let miterLimit = data[i + 4]
      let end = min(data.count, i + headerLength + Int(data[i + 5]))
      i += headerLength

      let path = CGMutablePath()
      commands: while i < end {
        switch Int(data[i]) {
        case 0 where i + 2 < end:
          path.move(to: CGPoint(x: data[i + 1], y: data[i + 2]))
          i += 3
        case 1 where i + 2 < end:
          path.addLine(to: CGPoint(x: data[i + 1], y: data[i + 2]))
          i += 3
        case 2 where i + 6 < end:
          path.addCurve(
            to: CGPoint(x: data[i + 5], y: data[i + 6]),
            control1: CGPoint(x: data[i + 1], y: data[i + 2]),
            control2: CGPoint(x: data[i + 3], y: data[i + 4]))
          i += 7
        case 3:
          path.closeSubpath()
          i += 1
        default:
          break commands
        }
      }
      i = end
      items.append(
        Item(
          path: path,
          fill: flags & 1 != 0,
          evenOdd: flags & 2 != 0,
          stroke: flags & 4 != 0,
          strokeWidth: strokeWidth,
          lineCap: cap,
          lineJoin: join,
          miterLimit: miterLimit))
    }
    return items
  }
}

extension Array {
  fileprivate subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
