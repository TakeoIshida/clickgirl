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

        // 小アイコンボタン（ランキング・設定・キャラ選択）
        let iconBtns: [(String, String, CGFloat)] = [
            ("⚙",  "settingBtn",    width - 16),
            ("🏆", "rankBtn",       width - 44),
            ("👤", "charSelectBtn", width - 74),
        ]
        for (icon, name, x) in iconBtns {
            let bg = SKShapeNode(circleOfRadius: 13)
            bg.fillColor   = UIColor(white: 1, alpha: 0.07)
            bg.strokeColor = UIColor(white: 1, alpha: 0.18)
            bg.lineWidth   = 1
            bg.position    = CGPoint(x: x, y: 38)
            bg.name        = name
            addChild(bg)

            let lbl = SKLabelNode(text: icon)
            lbl.fontSize = 14
            lbl.verticalAlignmentMode = .center
            lbl.position = CGPoint(x: x, y: 38)
            lbl.name     = name
            addChild(lbl)
        }

        // ナビボタン 4つ（2列×2行）
        let btnW: CGFloat = 72
        let btnH: CGFloat = 26
        let col1X = width - 114
        let col2X = width - 40
        let btns: [(name: String, label: String, fill: UIColor, stroke: UIColor, x: CGFloat, y: CGFloat)] = [
            ("zukanBtn",  "📖 図鑑",
             UIColor(red: 0.28, green: 0.12, blue: 0.48, alpha: 0.92),
             UIColor(red: 0.68, green: 0.38, blue: 1.00, alpha: 0.72), col1X, 97),
            ("gachaBtn",  "🎰 ガチャ",
             UIColor(red: 0.34, green: 0.06, blue: 0.52, alpha: 0.92),
             UIColor(red: 0.88, green: 0.52, blue: 1.00, alpha: 0.75), col2X, 97),
            ("shopBtn",   "🛒 Shop",
             UIColor(red: 0.12, green: 0.32, blue: 0.18, alpha: 0.92),
             UIColor(red: 0.28, green: 0.88, blue: 0.40, alpha: 0.72), col1X, 66),
            ("officeBtn", "🏢 Office",
             UIColor(red: 0.18, green: 0.22, blue: 0.48, alpha: 0.92),
             UIColor(red: 0.38, green: 0.58, blue: 1.00, alpha: 0.72), col2X, 66),
        ]
        for btn in btns {
            let bg = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 9)
            bg.fillColor   = btn.fill
            bg.strokeColor = btn.stroke
            bg.lineWidth   = 1.5
            bg.position    = CGPoint(x: btn.x, y: btn.y)
            bg.name        = btn.name
            addChild(bg)

            let lbl = SKLabelNode(text: btn.label)
            lbl.fontName  = "HiraginoSans-W6"
            lbl.fontSize  = 11
            lbl.fontColor = .white
            lbl.verticalAlignmentMode = .center
            lbl.position  = bg.position
            lbl.name      = btn.name
            addChild(lbl)
        }

        // ガチャボタンにパルスグロー（注目を引く）
        let gachaGlow = SKShapeNode(rectOf: CGSize(width: btnW + 6, height: btnH + 6), cornerRadius: 12)
        gachaGlow.fillColor   = .clear
        gachaGlow.strokeColor = UIColor(red: 0.9, green: 0.55, blue: 1.0, alpha: 0.75)
        gachaGlow.lineWidth   = 2
        gachaGlow.position    = CGPoint(x: col2X, y: 97)
        gachaGlow.name        = "gachaBtn"
        addChild(gachaGlow)
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.9),
            SKAction.fadeAlpha(to: 1.0, duration: 0.9)
        ])
        gachaGlow.run(SKAction.repeatForever(glowPulse))

        addGlowDecor()
    }

    private func addGlowDecor() {
        // HUD下端のゴールドアクセントライン
        let accentLine = SKShapeNode(rectOf: CGSize(width: width, height: 1.5))
        accentLine.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.4)
        accentLine.strokeColor = .clear
        accentLine.position    = CGPoint(x: width / 2, y: 0)
        addChild(accentLine)

        // アクセントラインのグロー
        let lineGlow = SKShapeNode(rectOf: CGSize(width: width, height: 6))
        lineGlow.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.06)
        lineGlow.strokeColor = .clear
        lineGlow.position    = CGPoint(x: width / 2, y: -2)
        addChild(lineGlow)

        // 会社名左のミニ★デコ
        let star = SKLabelNode(text: "✦")
        star.fontName  = "HiraginoSans-W6"
        star.fontSize  = 10
        star.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.7)
        star.position  = CGPoint(x: 8, y: 101)
        addChild(star)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 1.2),
            SKAction.fadeAlpha(to: 0.85, duration: 1.2)
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
