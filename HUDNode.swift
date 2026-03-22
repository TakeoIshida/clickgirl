import SpriteKit

class HUDNode: SKNode {

    private let moneyLabel = SKLabelNode()
    private let incomeLabel = SKLabelNode()
    private let companyLabel = SKLabelNode()
    private var bgNode: SKShapeNode!

    private let width: CGFloat

    init(width: CGFloat) {
        self.width = width
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // 背景グラデーション風パネル
        bgNode = SKShapeNode(rectOf: CGSize(width: width, height: 100), cornerRadius: 0)
        bgNode.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.92)
        bgNode.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.5)
        bgNode.lineWidth = 1.5
        bgNode.position = CGPoint(x: width / 2, y: 50)
        addChild(bgNode)

        // 会社名
        companyLabel.text = "株式会社 ClickGirl"
        companyLabel.fontName = "HiraginoSans-W3"
        companyLabel.fontSize = 13
        companyLabel.fontColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.7)
        companyLabel.horizontalAlignmentMode = .left
        companyLabel.position = CGPoint(x: 16, y: 80)
        addChild(companyLabel)

        // 💰 所持金
        moneyLabel.fontName = "HiraginoSans-W8"
        moneyLabel.fontSize = 32
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .left
        moneyLabel.position = CGPoint(x: 16, y: 42)
        addChild(moneyLabel)

        // 毎秒収益
        incomeLabel.fontName = "HiraginoSans-W3"
        incomeLabel.fontSize = 14
        incomeLabel.fontColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 0.9)
        incomeLabel.horizontalAlignmentMode = .left
        incomeLabel.position = CGPoint(x: 16, y: 20)
        addChild(incomeLabel)

        // 右側デコ: きらきら
        addGlowDecor()
    }

    private func addGlowDecor() {
        let star = SKLabelNode(text: "★")
        star.fontName = "HiraginoSans-W6"
        star.fontSize = 18
        star.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.8)
        star.position = CGPoint(x: width - 20, y: 55)
        addChild(star)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 0.9, duration: 0.8)
        ])
        star.run(SKAction.repeatForever(pulse))
    }

    func update(money: Double, incomePerSec: Double) {
        moneyLabel.text = "¥ \(formatMoney(money))"
        if incomePerSec > 0 {
            incomeLabel.text = "毎秒 +¥\(formatMoney(incomePerSec))"
        } else {
            incomeLabel.text = "社員を採用して自動収益を得よう"
        }
    }

    private func formatMoney(_ v: Double) -> String {
        if v >= 1_000_000_000_000 { return String(format: "%.2f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000      { return String(format: "%.2f億", v / 100_000_000) }
        if v >= 10_000           { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
