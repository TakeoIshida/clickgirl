import SpriteKit
import UIKit

struct SceneAccessibilityItem {
    let nodeName: String
    let label: String
    let hint: String?
    let traits: UIAccessibilityTraits
    let activation: (() -> Bool)?

    init(nodeName: String,
         label: String,
         hint: String? = nil,
         traits: UIAccessibilityTraits = .button,
         activation: (() -> Bool)? = nil) {
        self.nodeName = nodeName
        self.label = label
        self.hint = hint
        self.traits = traits
        self.activation = activation
    }
}

private final class SceneActionAccessibilityElement: UIAccessibilityElement {
    var activation: (() -> Bool)?

    override func accessibilityActivate() -> Bool {
        activation?() ?? false
    }
}

enum SceneAccessibility {
    static func install(on view: SKView, scene: SKScene, items: [SceneAccessibilityItem]) {
        view.isAccessibilityElement = false
        view.accessibilityElements = items.compactMap { item in
            guard let node = largestVisibleNode(named: item.nodeName, in: scene),
                  let frame = frameInView(for: node, scene: scene) else { return nil }

            let element = SceneActionAccessibilityElement(accessibilityContainer: view)
            element.accessibilityLabel = item.label
            element.accessibilityIdentifier = item.nodeName
            element.accessibilityHint = item.hint
            element.accessibilityTraits = item.traits
            element.accessibilityFrameInContainerSpace = frame.insetBy(dx: -4, dy: -4)
            element.activation = item.activation
            return element
        }
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    static func clear(from view: SKView) {
        view.accessibilityElements = nil
    }

    private static func largestVisibleNode(named name: String, in scene: SKScene) -> SKNode? {
        var nodes: [SKNode] = []
        scene.enumerateChildNodes(withName: "//\(name)") { node, _ in
            if !node.isHidden && node.alpha > 0.01 { nodes.append(node) }
        }
        return nodes.max { lhs, rhs in
            area(of: lhs.calculateAccumulatedFrame()) < area(of: rhs.calculateAccumulatedFrame())
        }
    }

    private static func area(of rect: CGRect) -> CGFloat {
        max(0, rect.width) * max(0, rect.height)
    }

    private static func frameInView(for node: SKNode, scene: SKScene) -> CGRect? {
        guard let parent = node.parent else { return nil }
        let frame = node.calculateAccumulatedFrame()
        let points = [
            CGPoint(x: frame.minX, y: frame.minY),
            CGPoint(x: frame.maxX, y: frame.minY),
            CGPoint(x: frame.minX, y: frame.maxY),
            CGPoint(x: frame.maxX, y: frame.maxY)
        ].map { scene.convertPoint(toView: parent.convert($0, to: scene)) }

        guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
