import SpriteKit

class RankingScene: SKScene {

    private let gold   = UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 1)
    private let silver = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
    private let bronze = UIColor(red: 0.8,  green: 0.5,  blue: 0.2,  alpha: 1)
    private let darkBg = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1)

    // ダミーデータ（実装時はGameCenterまたはサーバーから取得）
    private let rankings: [(rank: Int, name: String, score: Double)] = [
        (1, "ゲスト_7823", 999_999_999),
        (2, "ゲスト_4512", 754_320_000),
        (3, "ゲスト_1190", 512_000_000),
        (4, "ゲスト_3301", 388_000_000),
        (5, "ゲスト_9900", 200_000_000),
        (6, "ゲスト_0042", 150_000_000),
        (7, "ゲスト_5511",  80_000_000),
    ]
    private var myRank:  Int    { 42 }
    private var myScore: Double { GameManager.shared.totalEarned }

    override func didMove(to view: SKView) {
        backgroundColor = darkBg
        addTopBar()
        addMyRankBanner()
        addRankList()
    }

    // MARK: - TopBar
    private func addTopBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: frame.width, height: 54))
        bar.fillColor   = UIColor(red: 0.05, green: 0.05, blue: 0.16, alpha: 0.95)
        bar.strokeColor = .clear
        bar.position    = CGPoint(x: frame.midX, y: frame.height - 27)
        addChild(bar)

        let line = SKShapeNode(rectOf: CGSize(width: frame.width, height: 1.5))
        line.fillColor   = gold
        line.strokeColor = .clear
        line.position    = CGPoint(x: frame.midX, y: frame.height - 54)
        addChild(line)

        let title = SKLabelNode(text: "🏆 ランキング")
        title.fontName  = "HiraginoSans-W6"
        title.fontSize  = 17
        title.fontColor = .white
        title.position  = CGPoint(x: frame.midX, y: frame.height - 33)
        addChild(title)

        let back = SKLabelNode(text: "◀ 戻る")
        back.fontName  = "HiraginoSans-W3"
        back.fontSize  = 14
        back.fontColor = gold
        back.horizontalAlignmentMode = .left
        back.position  = CGPoint(x: 16, y: frame.height - 33)
        back.name      = "backBtn"
        addChild(back)
    }

    // MARK: - 自分の順位バナー
    private func addMyRankBanner() {
        let w = frame.width - 32
        let banner = SKNode()
        banner.position = CGPoint(x: frame.midX, y: frame.height - 88)

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: 52), cornerRadius: 12)
        bg.fillColor   = UIColor(red: 0.3, green: 0.1, blue: 0.5, alpha: 0.28)
        bg.strokeColor = UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 0.7)
        bg.lineWidth   = 1.5
        banner.addChild(bg)

        let glow = SKShapeNode(rectOf: CGSize(width: w + 8, height: 60), cornerRadius: 14)
        glow.fillColor   = .clear
        glow.strokeColor = UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 0.28)
        glow.lineWidth   = 6
        banner.addChild(glow)
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.05, duration: 1.0),
            SKAction.fadeAlpha(to: 0.28, duration: 1.0)
        ])))

        let rankLbl = SKLabelNode(text: "🏅 あなたの順位: \(myRank)位")
        rankLbl.fontName  = "HiraginoSans-W6"
        rankLbl.fontSize  = 15
        rankLbl.fontColor = UIColor(red: 0.85, green: 0.6, blue: 1.0, alpha: 1)
        rankLbl.position  = CGPoint(x: 0, y: 9)
        banner.addChild(rankLbl)

        let scoreLbl = SKLabelNode(text: "累計収益: ✦\(formatNum(myScore))")
        scoreLbl.fontName  = "HiraginoSans-W3"
        scoreLbl.fontSize  = 12
        scoreLbl.fontColor = UIColor(white: 1, alpha: 0.55)
        scoreLbl.position  = CGPoint(x: 0, y: -12)
        banner.addChild(scoreLbl)

        addChild(banner)
    }

    // MARK: - ランクリスト
    private func addRankList() {
        let w    = frame.width - 32
        let rowH: CGFloat = 54
        let startY = frame.height - 156

        for (i, entry) in rankings.enumerated() {
            let row = makeRankRow(entry: entry, w: w, h: rowH)
            let finalY = startY - CGFloat(i) * (rowH + 6)
            row.position = CGPoint(x: frame.midX, y: finalY + 20)
            row.alpha = 0
            addChild(row)

            row.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.07),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.moveBy(x: 0, y: -20, duration: 0.25)
                ])
            ]))
        }
    }

    private func makeRankRow(entry: (rank: Int, name: String, score: Double),
                              w: CGFloat, h: CGFloat) -> SKNode {
        let node = SKNode()

        let (fillCol, strokeCol): (UIColor, UIColor) = {
            switch entry.rank {
            case 1: return (UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 0.14),
                            UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 0.75))
            case 2: return (UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.10),
                            UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.55))
            case 3: return (UIColor(red: 0.8,  green: 0.5,  blue: 0.2,  alpha: 0.10),
                            UIColor(red: 0.8,  green: 0.5,  blue: 0.2,  alpha: 0.55))
            default: return (UIColor(white: 1,  alpha: 0.04),
                             UIColor(white: 1,  alpha: 0.10))
            }
        }()

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 10)
        bg.fillColor   = fillCol
        bg.strokeColor = strokeCol
        bg.lineWidth   = 1
        node.addChild(bg)

        let medals = ["🥇", "🥈", "🥉"]
        let medalText = entry.rank <= 3 ? medals[entry.rank - 1] : "\(entry.rank)位"
        let rankLbl = SKLabelNode(text: medalText)
        rankLbl.fontName  = "HiraginoSans-W6"
        rankLbl.fontSize  = entry.rank <= 3 ? 22 : 13
        rankLbl.verticalAlignmentMode   = .center
        rankLbl.horizontalAlignmentMode = .left
        rankLbl.position = CGPoint(x: -w / 2 + 16, y: 0)
        node.addChild(rankLbl)

        let nameLbl = SKLabelNode(text: entry.name)
        nameLbl.fontName  = "HiraginoSans-W3"
        nameLbl.fontSize  = 14
        nameLbl.fontColor = .white
        nameLbl.verticalAlignmentMode   = .center
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.position = CGPoint(x: -w / 2 + 62, y: 0)
        node.addChild(nameLbl)

        let scoreLbl = SKLabelNode(text: "✦\(formatNum(entry.score))")
        scoreLbl.fontName  = "HiraginoSans-W6"
        scoreLbl.fontSize  = 14
        scoreLbl.fontColor = entry.rank == 1 ? gold : UIColor(white: 0.9, alpha: 1)
        scoreLbl.verticalAlignmentMode   = .center
        scoreLbl.horizontalAlignmentMode = .right
        scoreLbl.position = CGPoint(x: w / 2 - 14, y: 0)
        node.addChild(scoreLbl)

        return node
    }

    // MARK: - ユーティリティ
    private func formatNum(_ v: Double) -> String {
        if v >= 100_000_000_000 { return String(format: "%.1f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000     { return String(format: "%.1f億", v / 100_000_000) }
        if v >= 10_000          { return String(format: "%.0f万", v / 10_000) }
        return String(format: "%.0f", v)
    }

    // MARK: - タップ処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        guard atPoint(loc).name == "backBtn" else { return }
        view?.presentScene(
            TitleScene(size: size),
            transition: SKTransition.push(with: .right, duration: 0.3)
        )
    }
}
