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
        // 背景パネル（120pt）
        bgNode = SKShapeNode(rectOf: CGSize(width: width, height: 120), cornerRadius: 0)
        bgNode.fillColor   = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.92)
        bgNode.strokeColor = UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 0.5)
        bgNode.lineWidth   = 1.5
        bgNode.position    = CGPoint(x: width / 2, y: 60)
        addChild(bgNode)

        // 会社名
        companyLabel.text     = "株式会社 ClickGirl"
        companyLabel.fontName = "HiraginoSans-W3"
        companyLabel.fontSize = 13
        companyLabel.fontColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.7)
        companyLabel.horizontalAlignmentMode = .left
        companyLabel.position = CGPoint(x: 16, y: 100)
        addChild(companyLabel)

        // 💰 所持金
        moneyLabel.fontName  = "HiraginoSans-W8"
        moneyLabel.fontSize  = 30
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .left
        moneyLabel.position  = CGPoint(x: 16, y: 60)
        addChild(moneyLabel)

        // 毎秒収益
        incomeLabel.fontName  = "HiraginoSans-W3"
        incomeLabel.fontSize  = 13
        incomeLabel.fontColor = UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 0.9)
        incomeLabel.horizontalAlignmentMode = .left
        incomeLabel.position  = CGPoint(x: 16, y: 38)
        addChild(incomeLabel)

        // ボタン4つを2行2列で並べる
        let btnW: CGFloat = 62
        let btnH: CGFloat = 22
        let col1X = width - 108
        let col2X = width - 44
        let btns: [(name: String, label: String, fill: UIColor, stroke: UIColor, x: CGFloat, y: CGFloat)] = [
            ("zukanBtn",  "📖 図鑑",
             UIColor(red: 0.30, green: 0.15, blue: 0.50, alpha: 0.9),
             UIColor(red: 0.70, green: 0.40, blue: 1.00, alpha: 0.7), col1X, 96),
            ("gachaBtn",  "🎰 ガチャ",
             UIColor(red: 0.35, green: 0.08, blue: 0.55, alpha: 0.9),
             UIColor(red: 0.85, green: 0.50, blue: 1.00, alpha: 0.7), col2X, 96),
            ("shopBtn",   "🛒 Shop",
             UIColor(red: 0.15, green: 0.35, blue: 0.20, alpha: 0.9),
             UIColor(red: 0.30, green: 0.90, blue: 0.40, alpha: 0.7), col1X, 68),
            ("officeBtn", "🏢 Office",
             UIColor(red: 0.20, green: 0.25, blue: 0.50, alpha: 0.9),
             UIColor(red: 0.40, green: 0.60, blue: 1.00, alpha: 0.7), col2X, 68),
        ]
        for btn in btns {
            let bg = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 7)
            bg.fillColor   = btn.fill
            bg.strokeColor = btn.stroke
            bg.lineWidth   = 1.5
            bg.position    = CGPoint(x: btn.x, y: btn.y)
            bg.name        = btn.name
            addChild(bg)

            let lbl = SKLabelNode(text: btn.label)
            lbl.fontName  = "HiraginoSans-W6"
            lbl.fontSize  = 10
            lbl.fontColor = .white
            lbl.verticalAlignmentMode = .center
            lbl.position  = bg.position
            lbl.name      = btn.name
            addChild(lbl)
        }

        addGlowDecor()
    }

    private func addGlowDecor() {
        let star = SKLabelNode(text: "★")
        star.fontName  = "HiraginoSans-W6"
        star.fontSize  = 16
        star.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.8)
        star.position  = CGPoint(x: width - 20, y: 40)
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
