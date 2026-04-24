import SpriteKit

class TitleScene: SKScene {

    private let gold   = UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 1)
    private let darkBg = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1)

    override func didMove(to view: SKView) {
        backgroundColor = darkBg
        addStars()
        addLogo()
        addCharacter()
        addStartButton()
        addBottomButtons()
    }

    // MARK: - 星パーティクル
    private func addStars() {
        for _ in 0..<60 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor   = .white
            star.strokeColor = .clear
            star.alpha    = CGFloat.random(in: 0.2...0.8)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: 0...frame.height)
            )
            addChild(star)
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.8...2.0)),
                SKAction.fadeAlpha(to: 0.8, duration: CGFloat.random(in: 0.8...2.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    // MARK: - ロゴ
    private func addLogo() {
        let container = SKNode()
        container.position = CGPoint(x: frame.midX, y: frame.height * 0.76)

        let panel = SKShapeNode(rectOf: CGSize(width: 290, height: 72), cornerRadius: 14)
        panel.fillColor   = UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 0.92)
        panel.strokeColor = UIColor(red: 1.0,  green: 0.85, blue: 0.2,  alpha: 0.8)
        panel.lineWidth   = 1.5
        container.addChild(panel)

        let glow = SKShapeNode(rectOf: CGSize(width: 300, height: 82), cornerRadius: 16)
        glow.fillColor   = .clear
        glow.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.14)
        glow.lineWidth   = 7
        container.addChild(glow)

        let title = SKLabelNode(text: "CLICK GIRL")
        title.fontName  = "AvenirNext-Bold"
        title.fontSize  = 36
        title.fontColor = gold
        title.verticalAlignmentMode = .center
        title.position  = CGPoint(x: 0, y: 4)
        container.addChild(title)

        let sub = SKLabelNode(text: "株式会社")
        sub.fontName  = "HiraginoSans-W3"
        sub.fontSize  = 13
        sub.fontColor = UIColor(white: 1.0, alpha: 0.55)
        sub.verticalAlignmentMode = .center
        sub.position  = CGPoint(x: 0, y: -20)
        container.addChild(sub)

        for (dx, dy) in [(-143.0, 35.0), (143.0, 35.0), (-143.0, -35.0), (143.0, -35.0)] {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.7)
            dot.strokeColor = .clear
            dot.position    = CGPoint(x: dx, y: dy)
            container.addChild(dot)
        }

        // ✦ パルス
        let star = SKLabelNode(text: "✦")
        star.fontName  = "AvenirNext-Bold"
        star.fontSize  = 11
        star.fontColor = gold
        star.position  = CGPoint(x: -130, y: 10)
        container.addChild(star)
        star.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 1.2),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ])))

        addChild(container)
    }

    // MARK: - キャラ立ち絵
    private func addCharacter() {
        let imgName = "airi_2_nobg"
        let tex = SKTexture(imageNamed: imgName)

        // UIImageでアスペクト比を正確に取得（SKTexture.size()はシーン遷移直後に(1,1)を返す場合がある）
        let ratio: CGFloat
        if let ui = UIImage(named: imgName), ui.size.width > 0 {
            ratio = ui.size.height / ui.size.width
        } else {
            let s = tex.size()
            ratio = s.width > 0 ? s.height / s.width : 1.47
        }

        // aspectFit: 幅70%を基準に高さ上限46%でクランプし、はみ出す場合は幅も縮小
        let maxW = frame.width * 0.70
        let maxH = frame.height * 0.46
        var charW = maxW
        var charH = charW * ratio
        if charH > maxH {
            charH = maxH
            charW = charH / ratio
        }

        let char = SKSpriteNode(texture: tex, size: CGSize(width: charW, height: charH))
        char.position = CGPoint(x: frame.midX, y: frame.height * 0.45)
        addChild(char)

        char.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y:  8, duration: 2.5),
            SKAction.moveBy(x: 0, y: -8, duration: 2.5)
        ])))

        let glow = SKShapeNode(ellipseOf: CGSize(width: charW * 0.55, height: 14))
        glow.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.10)
        glow.strokeColor = .clear
        glow.position    = CGPoint(x: frame.midX, y: char.position.y - charH * 0.48)
        addChild(glow)
    }

    // MARK: - スタートボタン
    private func addStartButton() {
        let btn = SKNode()
        btn.name     = "startBtn"
        btn.position = CGPoint(x: frame.midX, y: frame.height * 0.18)

        let bg = SKShapeNode(rectOf: CGSize(width: 248, height: 52), cornerRadius: 26)
        bg.fillColor   = UIColor(red: 0.08, green: 0.08, blue: 0.25, alpha: 1)
        bg.strokeColor = gold
        bg.lineWidth   = 1.5
        bg.name        = "startBtn"
        btn.addChild(bg)

        let glowRing = SKShapeNode(rectOf: CGSize(width: 260, height: 64), cornerRadius: 32)
        glowRing.fillColor   = .clear
        glowRing.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.4)
        glowRing.lineWidth   = 5
        glowRing.name        = "startBtn"
        btn.addChild(glowRing)
        glowRing.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.05, duration: 0.9),
            SKAction.fadeAlpha(to: 0.4,  duration: 0.9)
        ])))

        let lbl = SKLabelNode(text: "▶  タップしてはじめる")
        lbl.fontName  = "AvenirNext-DemiBold"
        lbl.fontSize  = 17
        lbl.fontColor = gold
        lbl.verticalAlignmentMode = .center
        lbl.name = "startBtn"
        btn.addChild(lbl)

        addChild(btn)
    }

    // MARK: - 下部ボタン（ランキング・設定）
    private func addBottomButtons() {
        let items: [(String, String, CGFloat)] = [
            ("🏆 ランキング", "rankBtn",    frame.midX - 88),
            ("⚙  設定",      "settingBtn", frame.midX + 88),
        ]
        for (title, name, x) in items {
            let btn = SKNode()
            btn.name     = name
            btn.position = CGPoint(x: x, y: frame.height * 0.08)

            let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 34), cornerRadius: 10)
            bg.fillColor   = UIColor(white: 1, alpha: 0.05)
            bg.strokeColor = UIColor(white: 1, alpha: 0.18)
            bg.lineWidth   = 1
            bg.name        = name
            btn.addChild(bg)

            let lbl = SKLabelNode(text: title)
            lbl.fontName  = "HiraginoSans-W3"
            lbl.fontSize  = 13
            lbl.fontColor = .white
            lbl.verticalAlignmentMode = .center
            lbl.name = name
            btn.addChild(lbl)

            addChild(btn)
        }
    }

    override func willMove(from view: SKView) {
        removeAllActions()
    }

    // MARK: - タップ処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let name = atPoint(loc).name ?? ""
        switch name {
        case "startBtn":
            let next = GameScene(size: size)
            next.scaleMode = scaleMode
            view?.presentScene(next, transition: .fade(withDuration: 0.5))
        case "rankBtn":
            let next = RankingScene(size: size)
            next.scaleMode = scaleMode
            view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.3))
        case "settingBtn":
            let next = SettingScene(size: size)
            next.scaleMode = scaleMode
            view?.presentScene(next, transition: SKTransition.push(with: .left, duration: 0.3))
        default: break
        }
    }
}
