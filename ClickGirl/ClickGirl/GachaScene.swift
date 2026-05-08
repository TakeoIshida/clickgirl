import SpriteKit

class GachaScene: SKScene {

    private let gm = GameManager.shared
    private var moneyLabel: SKLabelNode!
    private var pityLabel:  SKLabelNode!
    private var isAnimating = false
    private var resultsOverlay: SKNode?
    private var flipCardData: [(pos: CGPoint, size: CGSize, back: SKNode, front: SKNode, card: GachaCard, flipped: Bool)] = []
    private var flipAllBtnNode: SKNode?
    private var resultHintLabel: SKLabelNode?
    private var isFlippingAll = false

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.02, blue: 0.14, alpha: 1.0)
        buildBackground()
        buildTopBar()
        buildInfoPanel()
        buildGachaOrb()
        buildPullButtons()
        startShootingStars()
    }

    // MARK: - 背景

    private func buildBackground() {
        // 星
        for _ in 0..<65 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...2.5))
            s.fillColor   = UIColor(white: 1.0, alpha: CGFloat.random(in: 0.4...1.0))
            s.strokeColor = .clear
            s.position    = CGPoint(x: CGFloat.random(in: 0...frame.width),
                                    y: CGFloat.random(in: 0...frame.height))
            s.zPosition   = -5
            addChild(s)
            s.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: CGFloat.random(in: 1.0...3.5)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0),  duration: CGFloat.random(in: 1.0...3.5))
            ])))
        }

        // 星雲グラデーション（上部）
        let nebula1 = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height * 0.50))
        nebula1.fillColor   = UIColor(red: 0.20, green: 0.05, blue: 0.45, alpha: 0.45)
        nebula1.strokeColor = .clear
        nebula1.position    = CGPoint(x: frame.midX, y: frame.height * 0.78)
        nebula1.zPosition   = -4
        addChild(nebula1)

        // 星雲（下部アクセント）
        let nebula2 = SKShapeNode(rectOf: CGSize(width: frame.width * 0.7, height: frame.height * 0.25))
        nebula2.fillColor   = UIColor(red: 0.08, green: 0.02, blue: 0.35, alpha: 0.30)
        nebula2.strokeColor = .clear
        nebula2.position    = CGPoint(x: frame.midX, y: frame.height * 0.15)
        nebula2.zPosition   = -4
        addChild(nebula2)
    }

    // 流れ星を繰り返し生成
    private func startShootingStars() {
        let spawn = SKAction.run { [weak self] in self?.spawnShootingStar() }
        let wait  = SKAction.wait(forDuration: 2.8, withRange: 2.0)
        run(SKAction.repeatForever(SKAction.sequence([spawn, wait])))
    }

    private func spawnShootingStar() {
        let startX = CGFloat.random(in: frame.width * 0.1...frame.width)
        let startY = CGFloat.random(in: frame.height * 0.55...frame.height)
        let length = CGFloat.random(in: 55...100)
        let angle  = CGFloat.random(in: -0.55 ... -0.30)

        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: -length, y: -length * 0.45))
        let trail = SKShapeNode(path: path)
        trail.strokeColor = UIColor(white: 1.0, alpha: 0.85)
        trail.lineWidth   = CGFloat.random(in: 1.0...2.2)
        trail.lineCap     = .round
        trail.position    = CGPoint(x: startX, y: startY)
        trail.zPosition   = -3
        trail.alpha       = 0
        addChild(trail)

        let dx = cos(angle) * frame.width * 0.55
        let dy = sin(angle) * frame.width * 0.55
        trail.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.08),
            SKAction.group([
                SKAction.moveBy(x: dx, y: dy, duration: 0.55),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.fadeOut(withDuration: 0.30)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - トップバー

    private func buildTopBar() {
        let h: CGFloat = 56
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width, height: h))
        bg.fillColor   = UIColor(red: 0.06, green: 0.02, blue: 0.20, alpha: 1.0)
        bg.strokeColor = .clear
        bg.position    = CGPoint(x: frame.midX, y: frame.height - h / 2)
        bg.zPosition   = 10
        addChild(bg)

        // ゴールドアクセントライン
        let line = SKShapeNode(rectOf: CGSize(width: frame.width, height: 1.5))
        line.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.7)
        line.strokeColor = .clear
        line.position    = CGPoint(x: frame.midX, y: frame.height - h)
        line.zPosition   = 11
        addChild(line)
        let glow = SKShapeNode(rectOf: CGSize(width: frame.width, height: 6))
        glow.fillColor   = UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 0.18)
        glow.strokeColor = .clear
        glow.position    = CGPoint(x: frame.midX, y: frame.height - h)
        glow.zPosition   = 10
        addChild(glow)

        let back = SKLabelNode(text: "◀ 戻る")
        back.fontName = "HiraginoSans-W5"; back.fontSize = 15
        back.fontColor = UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1.0)
        back.horizontalAlignmentMode = .left; back.verticalAlignmentMode = .center
        back.position = CGPoint(x: 14, y: frame.height - h / 2)
        back.zPosition = 11; back.name = "backBtn"
        addChild(back)

        let title = SKLabelNode(text: "🎰 ガチャ")
        title.fontName = "HiraginoSans-W7"; title.fontSize = 18
        title.fontColor = UIColor(red: 1.0, green: 0.85, blue: 1.0, alpha: 1.0)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: frame.midX, y: frame.height - h / 2)
        title.zPosition = 11
        addChild(title)

        moneyLabel = SKLabelNode()
        moneyLabel.fontName = "HiraginoSans-W7"; moneyLabel.fontSize = 14
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .right; moneyLabel.verticalAlignmentMode = .center
        moneyLabel.position = CGPoint(x: frame.width - 12, y: frame.height - h / 2)
        moneyLabel.zPosition = 11; moneyLabel.name = "moneyLabel"
        moneyLabel.text = "✦\(formatMoney(gm.money))  券\(gm.gachaTickets)"
        addChild(moneyLabel)
    }

    // MARK: - 天井パネル

    private func buildInfoPanel() {
        let panelY = frame.height - 56 - 34
        let panelBg = SKShapeNode(rectOf: CGSize(width: frame.width - 20, height: 46), cornerRadius: 10)
        panelBg.fillColor   = UIColor(red: 0.08, green: 0.04, blue: 0.22, alpha: 0.95)
        panelBg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 0.45)
        panelBg.lineWidth   = 1
        panelBg.position    = CGPoint(x: frame.midX, y: panelY)
        panelBg.zPosition   = 5
        addChild(panelBg)

        let pityRemain = 10 - (gm.gachaPityCount % 10)
        pityLabel = SKLabelNode(text: "天井まで あと \(pityRemain) 回  (10回でR以上確定)")
        pityLabel.fontName = "HiraginoSans-W5"; pityLabel.fontSize = 12
        pityLabel.fontColor = UIColor(red: 0.88, green: 0.78, blue: 1.0, alpha: 1.0)
        pityLabel.verticalAlignmentMode = .center
        pityLabel.position = CGPoint(x: frame.midX, y: panelY + 9)
        pityLabel.zPosition = 6; pityLabel.name = "pityLabel"
        addChild(pityLabel)

        let rateLabel = SKLabelNode(text: "SSR 2%  ／  SR 8%  ／  R 30%  ／  N 60%")
        rateLabel.fontName = "HiraginoSans-W3"; rateLabel.fontSize = 10
        rateLabel.fontColor = UIColor(white: 0.50, alpha: 1.0)
        rateLabel.verticalAlignmentMode = .center
        rateLabel.position = CGPoint(x: frame.midX, y: panelY - 11)
        rateLabel.zPosition = 6
        addChild(rateLabel)
    }

    // MARK: - ガチャオーブ

    private func buildGachaOrb() {
        let orbY = frame.height * 0.52

        // 光線ビーム（8本、ゆっくり回転）
        let raysNode = SKNode()
        raysNode.position = CGPoint(x: frame.midX, y: orbY)
        raysNode.zPosition = -1
        addChild(raysNode)
        for i in 0..<8 {
            let angle = CGFloat(i) / 8.0 * .pi * 2
            let rayPath = CGMutablePath()
            rayPath.move(to: CGPoint(x: cos(angle) * 90, y: sin(angle) * 90))
            rayPath.addLine(to: CGPoint(x: cos(angle) * 175, y: sin(angle) * 175))
            let ray = SKShapeNode(path: rayPath)
            ray.strokeColor = UIColor(red: 0.72, green: 0.35, blue: 1.0, alpha: CGFloat.random(in: 0.08...0.22))
            ray.lineWidth   = CGFloat.random(in: 6...14)
            ray.lineCap     = .round
            raysNode.addChild(ray)
        }
        raysNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 18.0)))

        // 外輪3本（パルス）
        for i in 0...2 {
            let ring = SKShapeNode(circleOfRadius: CGFloat(88 + i * 28))
            ring.fillColor   = .clear
            ring.strokeColor = UIColor(red: 0.65, green: 0.25, blue: 1.0,
                                       alpha: CGFloat(0.14 - Double(i) * 0.03))
            ring.lineWidth   = CGFloat(10 - i * 3)
            ring.position    = CGPoint(x: frame.midX, y: orbY)
            ring.zPosition   = 0
            addChild(ring)
            ring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.18, duration: 1.6 + Double(i) * 0.4),
                SKAction.fadeAlpha(to: 1.0,  duration: 1.6 + Double(i) * 0.4)
            ])))
        }

        // オーブ本体
        let orb = SKShapeNode(circleOfRadius: 78)
        orb.fillColor   = UIColor(red: 0.22, green: 0.06, blue: 0.55, alpha: 0.94)
        orb.strokeColor = UIColor(red: 0.88, green: 0.55, blue: 1.0,  alpha: 0.90)
        orb.lineWidth   = 3.0
        orb.position    = CGPoint(x: frame.midX, y: orbY)
        orb.zPosition   = 1; orb.name = "orbNode"
        addChild(orb)

        // 内側ハイライト（上部）
        let highlight = SKShapeNode(circleOfRadius: 32)
        highlight.fillColor   = UIColor(white: 1.0, alpha: 0.10)
        highlight.strokeColor = .clear
        highlight.position    = CGPoint(x: frame.midX - 14, y: orbY + 20)
        highlight.zPosition   = 2
        addChild(highlight)

        // 中央アイコン
        let orbIcon = SKLabelNode(text: "✨")
        orbIcon.fontSize = 52; orbIcon.verticalAlignmentMode = .center
        orbIcon.position = CGPoint(x: frame.midX, y: orbY); orbIcon.zPosition = 3
        addChild(orbIcon)
        orbIcon.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 8.0)))

        // オーブのパルスグロー
        orb.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run { orb.strokeColor = UIColor(red: 1.0, green: 0.70, blue: 1.0, alpha: 1.0) },
            SKAction.wait(forDuration: 1.4),
            SKAction.run { orb.strokeColor = UIColor(red: 0.88, green: 0.55, blue: 1.0, alpha: 0.90) },
            SKAction.wait(forDuration: 1.4)
        ])))

        // 軌道パーティクル（8個、オーブを周回）
        let orbitNode = SKNode()
        orbitNode.position = CGPoint(x: frame.midX, y: orbY)
        orbitNode.zPosition = 3
        addChild(orbitNode)

        let orbitColors: [UIColor] = [
            UIColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 0.9),
            UIColor(red: 0.50, green: 0.80, blue: 1.0, alpha: 0.9),
            UIColor(red: 1.00, green: 0.80, blue: 0.30, alpha: 0.9),
            UIColor(red: 1.00, green: 0.55, blue: 0.75, alpha: 0.9),
        ]
        for i in 0..<8 {
            let angle    = CGFloat(i) / 8.0 * .pi * 2
            let orbitR   = CGFloat.random(in: 92...148)
            let pRadius  = CGFloat.random(in: 2.0...4.5)
            let p        = SKShapeNode(circleOfRadius: pRadius)
            p.fillColor  = orbitColors[i % orbitColors.count]
            p.strokeColor = .clear
            p.position   = CGPoint(x: cos(angle) * orbitR, y: sin(angle) * orbitR)
            orbitNode.addChild(p)

            let baseAlpha = CGFloat.random(in: 0.6...1.0)
            p.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.08, duration: CGFloat.random(in: 0.4...1.1)),
                SKAction.fadeAlpha(to: baseAlpha, duration: CGFloat.random(in: 0.4...1.1))
            ])))
        }
        let orbitDuration = Double.random(in: 12.0...18.0)
        orbitNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: orbitDuration)))

        // 外周フローティングスパークル（12個）
        let particleColors: [UIColor] = [
            UIColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 0.9),
            UIColor(red: 0.50, green: 0.80, blue: 1.0, alpha: 0.9),
            UIColor(red: 1.00, green: 0.80, blue: 0.30, alpha: 0.9),
        ]
        for i in 0..<12 {
            let angle = CGFloat(i) / 12.0 * .pi * 2
            let dist  = CGFloat.random(in: 50...130)
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            p.fillColor   = particleColors.randomElement()!
            p.strokeColor = .clear
            p.position    = CGPoint(x: frame.midX + cos(angle) * dist, y: orbY + sin(angle) * dist)
            p.zPosition   = 2
            addChild(p)
            p.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.05, duration: CGFloat.random(in: 0.5...1.3)),
                SKAction.fadeAlpha(to: 1.0,  duration: CGFloat.random(in: 0.5...1.3))
            ])))
        }
    }

    // MARK: - 引くボタン

    private func buildPullButtons() {
        let btnW = (frame.width - 48.0) / 2
        let btnH: CGFloat = 62
        let btnY: CGFloat = 120
        let singleCostText = gm.gachaTickets > 0 ? "ガチャ券\(gm.gachaTickets)枚" : "✦\(formatMoney(GachaCatalog.singleCost))"
        let configs: [(x: CGFloat, icon: String, title: String, costText: String, name: String)] = [
            (frame.width / 4.0,       "🎲", "1回ガチャ",  singleCostText, "btn1"),
            (frame.width * 3.0 / 4.0, "🎰", "10連ガチャ", "✦\(formatMoney(GachaCatalog.tenCost))", "btn10"),
        ]
        for cfg in configs {
            // ドロップシャドウ
            let shadow = SKShapeNode(rectOf: CGSize(width: btnW + 4, height: btnH + 4), cornerRadius: 18)
            shadow.fillColor   = UIColor(red: 0.45, green: 0.10, blue: 0.80, alpha: 0.30)
            shadow.strokeColor = .clear
            shadow.position    = CGPoint(x: cfg.x + 2, y: btnY - 4)
            shadow.zPosition   = 4
            addChild(shadow)

            // ボタン本体
            let bg = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 16)
            bg.fillColor   = UIColor(red: 0.28, green: 0.08, blue: 0.60, alpha: 0.95)
            bg.strokeColor = UIColor(red: 0.82, green: 0.52, blue: 1.0,  alpha: 0.85)
            bg.lineWidth   = 2.5
            bg.position    = CGPoint(x: cfg.x, y: btnY)
            bg.zPosition   = 5; bg.name = cfg.name
            addChild(bg)

            // ボーダーパルス
            bg.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.run { bg.strokeColor = UIColor(red: 1.0, green: 0.78, blue: 1.0, alpha: 1.0) },
                SKAction.wait(forDuration: 1.5),
                SKAction.run { bg.strokeColor = UIColor(red: 0.82, green: 0.52, blue: 1.0, alpha: 0.85) },
                SKAction.wait(forDuration: 1.5)
            ])))

            // シマー（光の走り）
            let shimmerMask = SKCropNode()
            shimmerMask.maskNode = SKShapeNode(rectOf: CGSize(width: btnW - 4, height: btnH - 4), cornerRadius: 14)
            shimmerMask.position = CGPoint(x: cfg.x, y: btnY)
            shimmerMask.zPosition = 6
            addChild(shimmerMask)

            let shimmer = SKShapeNode(rectOf: CGSize(width: 30, height: btnH))
            shimmer.fillColor   = UIColor(white: 1.0, alpha: 0.18)
            shimmer.strokeColor = .clear
            shimmer.position    = CGPoint(x: -btnW, y: 0)
            shimmerMask.addChild(shimmer)
            shimmer.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveTo(x: -btnW / 2 - 15, duration: 0),
                SKAction.wait(forDuration: Double.random(in: 2.2...3.5)),
                SKAction.moveTo(x: btnW / 2 + 15, duration: 0.55)
            ])))

            // ラベル群
            for (pos, text, font, size, color): (CGPoint, String, String, CGFloat, UIColor) in [
                (CGPoint(x: cfg.x, y: btnY + 16), cfg.icon, "",                 28, UIColor.white),
                (CGPoint(x: cfg.x, y: btnY - 2),  cfg.title, "HiraginoSans-W7", 14, UIColor.white),
                (CGPoint(x: cfg.x, y: btnY - 19), cfg.costText,
                 "HiraginoSans-W5", 12, UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)),
            ] {
                let lbl = SKLabelNode(text: text)
                lbl.fontName = font; lbl.fontSize = size; lbl.fontColor = color
                lbl.verticalAlignmentMode = .center; lbl.position = pos
                lbl.zPosition = 7; lbl.name = cfg.name
                addChild(lbl)
            }
        }

        // 10連「1回分お得！」バッジ
        let badgeX = frame.width * 3.0 / 4.0 + (frame.width - 48.0) / 4.0 - 2
        let badgeY = btnY + btnH / 2 + 2
        let badge  = SKShapeNode(rectOf: CGSize(width: 70, height: 19), cornerRadius: 7)
        badge.fillColor   = UIColor(red: 1.0, green: 0.22, blue: 0.50, alpha: 0.97)
        badge.strokeColor = UIColor(red: 1.0, green: 0.60, blue: 0.80, alpha: 0.80)
        badge.lineWidth   = 1
        badge.position    = CGPoint(x: badgeX, y: badgeY)
        badge.zPosition   = 8
        addChild(badge)
        badge.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.6),
            SKAction.scale(to: 1.0,  duration: 0.6)
        ])))

        let badgeLbl = SKLabelNode(text: "1回分お得！")
        badgeLbl.fontName = "HiraginoSans-W7"; badgeLbl.fontSize = 9.5
        badgeLbl.fontColor = .white
        badgeLbl.verticalAlignmentMode = .center
        badgeLbl.position = badge.position; badgeLbl.zPosition = 9
        addChild(badgeLbl)

        // 無料ガチャボタン（リワード広告）
        let freeBtn = SKNode()
        freeBtn.name     = "btnFreeGacha"
        freeBtn.position = CGPoint(x: frame.midX, y: 58)
        freeBtn.zPosition = 5

        let freeBg = SKShapeNode(rectOf: CGSize(width: frame.width - 60, height: 36), cornerRadius: 18)
        freeBg.fillColor   = UIColor(red: 0.10, green: 0.28, blue: 0.12, alpha: 0.92)
        freeBg.strokeColor = UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.8)
        freeBg.lineWidth   = 1.5
        freeBg.name        = "btnFreeGacha"
        freeBtn.addChild(freeBg)

        let freeLbl = SKLabelNode(text: "📺  動画を見て無料ガチャ")
        freeLbl.fontName  = "HiraginoSans-W6"
        freeLbl.fontSize  = 13
        freeLbl.fontColor = UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 1)
        freeLbl.verticalAlignmentMode = .center
        freeLbl.name = "btnFreeGacha"
        freeBtn.addChild(freeLbl)

        // 広告未準備時はグレーアウト
        if !AdManager.shared.isRewardedReady {
            freeBg.fillColor   = UIColor(white: 0.2, alpha: 0.5)
            freeBg.strokeColor = UIColor(white: 0.5, alpha: 0.3)
            freeLbl.fontColor  = UIColor(white: 0.5, alpha: 0.7)
        }

        addChild(freeBtn)
    }

    // MARK: - タッチ

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)

        if resultsOverlay != nil {
            handleResultTap(at: loc)
            return
        }
        guard !isAnimating else { return }
        for node in nodes(at: loc) {
            guard let name = node.name else { continue }
            if name == "backBtn"      { goBack();              return }
            if name == "btn1"         { pullGacha(count: 1);   return }
            if name == "btn10"        { pullGacha(count: 10);  return }
            if name == "btnFreeGacha" { pullFreeGacha();        return }
        }
    }

    // MARK: - ガチャロジック

    private func pullFreeGacha() {
        guard let rootVC = view?.window?.rootViewController else { return }
        AdManager.shared.showRewarded(
            from: rootVC,
            onRewarded: { [weak self] in
                guard let self else { return }
                let (cards, newPity) = GachaCatalog.draw(count: 1, pityCount: self.gm.gachaPityCount)
                self.gm.gachaPityCount = newPity
                for card in cards { self.gm.addCard(card) }
                self.gm.recordGachaPull(count: 1)
                self.gm.saveGame()
                self.isAnimating = true
                self.showResults(cards)
            },
            onNotReady: { [weak self] in
                self?.showToast("📺 広告の準備中です。少し待ってからもう一度どうぞ")
            }
        )
    }

    private func pullGacha(count: Int) {
        let usesTicket = count == 1 && gm.gachaTickets > 0
        let cost = count == 1 ? GachaCatalog.singleCost : GachaCatalog.tenCost
        guard usesTicket || gm.money >= cost else {
            showToast("💸 お金が足りません (✦\(formatMoney(cost)) 必要)")
            return
        }
        isAnimating = true
        if usesTicket {
            gm.gachaTickets -= 1
        } else {
            gm.money -= cost
        }

        let (cards, newPity) = GachaCatalog.draw(count: count, pityCount: gm.gachaPityCount)
        gm.gachaPityCount = newPity
        for card in cards { gm.addCard(card) }
        gm.recordGachaPull(count: count)
        gm.saveGame()
        moneyLabel.text = "✦\(formatMoney(gm.money))  券\(gm.gachaTickets)"

        if let orb = childNode(withName: "orbNode") as? SKShapeNode {
            orb.run(SKAction.sequence([
                SKAction.run { orb.fillColor = UIColor(red: 1.0, green: 0.95, blue: 1.0, alpha: 1.0) },
                SKAction.scale(to: 1.15, duration: 0.10),
                SKAction.scale(to: 1.0,  duration: 0.08),
                SKAction.run { orb.fillColor = UIColor(red: 0.22, green: 0.06, blue: 0.55, alpha: 0.94) }
            ]))
        }
        run(SKAction.wait(forDuration: 0.22)) { [weak self] in self?.showResults(cards) }
    }

    // MARK: - 結果表示

    private func showResults(_ cards: [GachaCard]) {
        flipCardData = []
        flipAllBtnNode = nil
        resultHintLabel = nil
        isFlippingAll = false

        let overlay = SKNode()
        overlay.zPosition = 30
        addChild(overlay)
        resultsOverlay = overlay

        let dim = SKSpriteNode(color: UIColor(red: 0.0, green: 0.0, blue: 0.06, alpha: 0.92),
                               size: frame.size)
        dim.position = CGPoint(x: frame.midX, y: frame.midY); dim.zPosition = -1
        overlay.addChild(dim)

        if cards.count == 1 {
            showSingleResult(cards[0], in: overlay)
        } else {
            showTenResult(cards, in: overlay)
        }
    }

    private func showSingleResult(_ card: GachaCard, in overlay: SKNode) {
        // 画面幅に応じてカードサイズをスケール（iPhone: ~185pt / iPad: ~280pt）
        let largeW = min(frame.width * 0.48, 280)
        let largeH = largeW * (260.0 / 185.0)
        let pos = CGPoint(x: frame.midX, y: frame.midY + 50)
        let cardSize = CGSize(width: largeW, height: largeH)

        let backNode = makeCardBackNode(large: true, largeW: largeW, largeH: largeH)
        backNode.position = pos
        backNode.setScale(0)
        overlay.addChild(backNode)

        let frontNode = makeCardNode(card: card, large: true, largeW: largeW, largeH: largeH)
        frontNode.position = pos
        frontNode.alpha = 0
        overlay.addChild(frontNode)

        flipCardData = [(pos: pos, size: cardSize, back: backNode, front: frontNode, card: card, flipped: false)]

        backNode.run(SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.15),
            SKAction.scale(to: 1.0,  duration: 0.08)
        ]))

        buildResultHint("タップしてめくろう！", in: overlay)
    }

    private func showTenResult(_ cards: [GachaCard], in overlay: SKNode) {
        let cols: Int        = 3
        let sidePad: CGFloat = 12
        let gapX: CGFloat    = 10
        let gapY: CGFloat    = 8

        let btnAreaH: CGFloat = 115
        let topPad:   CGFloat = 65
        let availH = frame.height - btnAreaH - topPad

        let cardW = floor((frame.width - sidePad * 2 - gapX * CGFloat(cols - 1)) / CGFloat(cols))
        let cardH = min(floor(cardW * 1.58), floor((availH - gapY * 3) / 4))

        let totalW3 = CGFloat(cols) * cardW + CGFloat(cols - 1) * gapX
        let startX  = (frame.width - totalW3) / 2 + cardW / 2

        let gridH  = 4 * (cardH + gapY) - gapY
        let startY = (btnAreaH + availH / 2) + gridH / 2 - cardH / 2

        for (i, card) in cards.enumerated() {
            let pos: CGPoint
            if i < 9 {
                let x = startX + CGFloat(i % cols) * (cardW + gapX)
                let y = startY - CGFloat(i / cols) * (cardH + gapY)
                pos = CGPoint(x: x, y: y)
            } else {
                pos = CGPoint(x: frame.midX, y: startY - 3 * (cardH + gapY))
            }

            let backNode = makeCardBackNode(large: false, smallW: cardW, smallH: cardH)
            backNode.position = pos
            backNode.setScale(0)
            overlay.addChild(backNode)

            backNode.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.08),
                SKAction.scale(to: 1.15, duration: 0.12),
                SKAction.scale(to: 1.0,  duration: 0.09)
            ]))

            let frontNode = makeCardNode(card: card, large: false, smallW: cardW, smallH: cardH)
            frontNode.position = pos
            frontNode.alpha = 0
            overlay.addChild(frontNode)

            flipCardData.append((pos: pos, size: CGSize(width: cardW, height: cardH),
                                 back: backNode, front: frontNode, card: card, flipped: false))
        }

        buildFlipAllButton(in: overlay)
        buildResultHint("カードをタップしてめくろう", in: overlay)
    }

    // MARK: - インタラクティブめくり

    private func handleResultTap(at loc: CGPoint) {
        guard let overlay = resultsOverlay else { return }

        if !isFlippingAll && !flipCardData.allSatisfy({ $0.flipped }) {
            if nodes(at: loc).contains(where: { $0.name == "flipAllBtn" }) {
                flipAllCards(in: overlay)
                return
            }
        }

        if !flipCardData.allSatisfy({ $0.flipped }) {
            for i in 0..<flipCardData.count where !flipCardData[i].flipped {
                let entry = flipCardData[i]
                let rect = CGRect(x: entry.pos.x - entry.size.width / 2,
                                  y: entry.pos.y - entry.size.height / 2,
                                  width: entry.size.width, height: entry.size.height)
                if rect.contains(loc) {
                    flipCard(at: i, in: overlay)
                    return
                }
            }
            return
        }

        closeResultsOverlay()
    }

    private func flipCard(at index: Int, in overlay: SKNode) {
        guard index < flipCardData.count, !flipCardData[index].flipped else { return }
        flipCardData[index].flipped = true
        let entry = flipCardData[index]
        let large = entry.size.width > 100

        entry.back.run(SKAction.scaleX(to: 0, duration: 0.13))
        entry.front.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.13),
            SKAction.run { entry.front.alpha = 1; entry.front.xScale = 0 },
            SKAction.scaleX(to: large ? 1.08 : 1.05, duration: 0.13),
            SKAction.scaleX(to: 1.0, duration: 0.05),
            SKAction.run { [weak self] in
                guard let self else { return }
                if entry.card.rarity == .sr || entry.card.rarity == .ssr {
                    self.spawnRarityFlash(card: entry.card, in: overlay)
                }
                self.checkAllFlipped(in: overlay)
            }
        ]))
        spawnFlipShimmer(at: entry.pos, in: overlay, delay: 0.06, large: large, cardSize: entry.size)
    }

    private func flipAllCards(in overlay: SKNode) {
        guard !isFlippingAll else { return }
        isFlippingAll = true
        flipAllBtnNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        flipAllBtnNode = nil

        var delay = 0.0
        let unflipped = flipCardData.indices.filter { !flipCardData[$0].flipped }
        for i in unflipped {
            flipCardData[i].flipped = true
            let entry = flipCardData[i]
            let large = entry.size.width > 100

            entry.back.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.scaleX(to: 0, duration: 0.10)
            ]))
            entry.front.run(SKAction.sequence([
                SKAction.wait(forDuration: delay + 0.10),
                SKAction.run { entry.front.alpha = 1; entry.front.xScale = 0 },
                SKAction.scaleX(to: large ? 1.08 : 1.05, duration: 0.10),
                SKAction.scaleX(to: 1.0, duration: 0.04),
                SKAction.run { [weak self] in
                    guard let self else { return }
                    if entry.card.rarity == .sr || entry.card.rarity == .ssr {
                        self.spawnRarityFlash(card: entry.card, in: overlay)
                    }
                }
            ]))
            spawnFlipShimmer(at: entry.pos, in: overlay, delay: delay + 0.05, large: large, cardSize: entry.size)
            delay += 0.12
        }

        run(SKAction.wait(forDuration: delay + 0.35)) { [weak self] in
            guard let self else { return }
            self.showCloseHint(in: overlay)
        }
    }

    private func checkAllFlipped(in overlay: SKNode) {
        guard flipCardData.allSatisfy({ $0.flipped }) else { return }
        flipAllBtnNode?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        flipAllBtnNode = nil
        showCloseHint(in: overlay)
    }

    private func buildFlipAllButton(in overlay: SKNode) {
        let pos = CGPoint(x: frame.midX, y: 72)

        // 外側グロー
        let glowRing = SKShapeNode(rectOf: CGSize(width: 172, height: 50), cornerRadius: 16)
        glowRing.fillColor   = .clear
        glowRing.strokeColor = UIColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 0.45)
        glowRing.lineWidth   = 6
        glowRing.position    = pos
        glowRing.zPosition   = 34
        glowRing.name        = "flipAllBtn"
        overlay.addChild(glowRing)
        glowRing.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 0.75),
            SKAction.fadeAlpha(to: 0.85, duration: 0.75)
        ])))

        let bg = SKShapeNode(rectOf: CGSize(width: 164, height: 44), cornerRadius: 14)
        bg.fillColor   = UIColor(red: 0.52, green: 0.14, blue: 0.90, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.88, green: 0.62, blue: 1.00, alpha: 0.92)
        bg.lineWidth   = 2
        bg.position    = pos
        bg.zPosition   = 35
        bg.name        = "flipAllBtn"
        overlay.addChild(bg)

        let lbl = SKLabelNode(text: "✨ 全てめくる")
        lbl.fontName = "HiraginoSans-W7"
        lbl.fontSize = 15
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.position  = pos
        lbl.zPosition = 36
        lbl.name      = "flipAllBtn"
        overlay.addChild(lbl)

        bg.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.65),
            SKAction.scale(to: 1.0,  duration: 0.65)
        ])))
        flipAllBtnNode = bg
    }

    private func buildResultHint(_ text: String, in overlay: SKNode) {
        resultHintLabel?.removeFromParent()
        let lbl = SKLabelNode(text: text)
        lbl.fontName = "HiraginoSans-W3"
        lbl.fontSize = 13
        lbl.fontColor = UIColor(white: 0.45, alpha: 1.0)
        lbl.verticalAlignmentMode = .center
        lbl.position = CGPoint(x: frame.midX, y: 28)
        lbl.zPosition = 35
        overlay.addChild(lbl)
        lbl.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])))
        resultHintLabel = lbl
    }

    private func showCloseHint(in overlay: SKNode) {
        buildResultHint("タップで閉じる", in: overlay)
        isFlippingAll = false
    }

    private func closeResultsOverlay() {
        guard let overlay = resultsOverlay else { return }
        overlay.run(SKAction.sequence([
            SKAction.group([SKAction.fadeOut(withDuration: 0.25),
                            SKAction.scale(to: 0.92, duration: 0.25)]),
            SKAction.removeFromParent()
        ]))
        resultsOverlay = nil
        flipCardData = []
        flipAllBtnNode = nil
        resultHintLabel = nil
        isFlippingAll = false
        isAnimating = false
        refreshMoneyLabel()
        refreshPityLabel()
    }

    // MARK: - カードノード生成

    private func makeCardNode(card: GachaCard, large: Bool, smallW: CGFloat = 58, smallH: CGFloat = 88, largeW: CGFloat = 185, largeH: CGFloat = 260) -> SKNode {
        let w: CGFloat  = large ? largeW : smallW
        let h: CGFloat  = large ? largeH : smallH
        let fs: CGFloat = large ? 1.0 : smallW / 58
        let container   = SKNode()
        let c = card.rarity.labelColor

        // カード背景
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: large ? 18 : 9)
        bg.fillColor   = UIColor(red: c.r * 0.14, green: c.g * 0.10, blue: c.b * 0.25, alpha: 0.97)
        bg.strokeColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.92)
        bg.lineWidth   = large ? 2.5 : 1.5
        container.addChild(bg)

        // SR/SSR: 角デコ（大カードのみ）
        if large && (card.rarity == .sr || card.rarity == .ssr) {
            for (dx, dy): (CGFloat, CGFloat) in [(-w/2+10, h/2-10), (w/2-10, h/2-10),
                                                  (-w/2+10, -h/2+10), (w/2-10, -h/2+10)] {
                let dot = SKShapeNode(circleOfRadius: 3.5)
                dot.fillColor   = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.85)
                dot.strokeColor = .clear
                dot.position    = CGPoint(x: dx, y: dy)
                dot.zPosition   = 1
                container.addChild(dot)
            }
        }

        if large {
            let imgY: CGFloat = 20
            let maxImgW: CGFloat = w - 8
            let maxImgH: CGFloat = h * 0.52
            let imgName = card.galleryImageName
            let aspect: CGFloat
            if let ui = UIImage(named: imgName), ui.size.width > 0 {
                aspect = ui.size.height / ui.size.width
            } else {
                aspect = SKTexture(imageNamed: imgName).size().height / max(1, SKTexture(imageNamed: imgName).size().width)
            }
            var imgW = maxImgW
            var imgH = imgW * aspect
            if imgH > maxImgH { imgH = maxImgH; imgW = imgH / aspect }
            let charImg = SKSpriteNode(imageNamed: imgName)
            charImg.size     = CGSize(width: imgW, height: imgH)
            charImg.position = CGPoint(x: 0, y: imgY)
            charImg.zPosition = 1
            container.addChild(charImg)

            if charImg.texture == nil || charImg.texture?.size() == CGSize.zero {
                charImg.color = UIColor(red: c.r * 0.3, green: c.g * 0.3, blue: c.b * 0.5, alpha: 1.0)
                charImg.colorBlendFactor = 1.0
                let placeholderLbl = SKLabelNode(text: card.charName)
                placeholderLbl.fontName = "HiraginoSans-W7"; placeholderLbl.fontSize = 22
                placeholderLbl.fontColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
                placeholderLbl.verticalAlignmentMode = .center
                placeholderLbl.position = CGPoint(x: 0, y: imgY)
                placeholderLbl.zPosition = 2
                container.addChild(placeholderLbl)
            }

            // レアリティバッジ（グロー付き）
            let rareBg = SKShapeNode(rectOf: CGSize(width: 62, height: 23), cornerRadius: 7)
            rareBg.fillColor   = UIColor(red: c.r * 0.45, green: c.g * 0.45, blue: c.b * 0.45, alpha: 0.92)
            rareBg.strokeColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.85)
            rareBg.lineWidth   = 1.5
            rareBg.position    = CGPoint(x: 0, y: h / 2 - 16); rareBg.zPosition = 3
            container.addChild(rareBg)

            if card.rarity == .ssr {
                rareBg.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.run { rareBg.fillColor = UIColor(red: c.r * 0.65, green: c.g * 0.65, blue: c.b * 0.30, alpha: 0.95) },
                    SKAction.wait(forDuration: 0.5),
                    SKAction.run { rareBg.fillColor = UIColor(red: c.r * 0.45, green: c.g * 0.45, blue: c.b * 0.45, alpha: 0.92) },
                    SKAction.wait(forDuration: 0.5)
                ])))
            }

            let rareLbl = SKLabelNode(text: card.rarity.rawValue)
            rareLbl.fontName = "HiraginoSans-W8"; rareLbl.fontSize = 13
            rareLbl.fontColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
            rareLbl.verticalAlignmentMode = .center; rareLbl.position = rareBg.position
            rareLbl.zPosition = 4
            container.addChild(rareLbl)

            let nameLbl = SKLabelNode(text: card.charName)
            nameLbl.fontName = "HiraginoSans-W7"; nameLbl.fontSize = 16
            nameLbl.fontColor = .white; nameLbl.verticalAlignmentMode = .center
            nameLbl.position  = CGPoint(x: 0, y: -h / 2 + 55); nameLbl.zPosition = 3
            container.addChild(nameLbl)

            let noLbl = SKLabelNode(text: "No.\(card.imageIndex + 1)")
            noLbl.fontName = "HiraginoSans-W4"; noLbl.fontSize = 11
            noLbl.fontColor = UIColor(white: 0.7, alpha: 1.0)
            noLbl.verticalAlignmentMode = .center
            noLbl.position = CGPoint(x: 0, y: -h / 2 + 38); noLbl.zPosition = 3
            container.addChild(noLbl)

            let count = gm.cardCount(charId: card.charId, imageIndex: card.imageIndex)
            let isNew = (count == 1)
            let bonusText = String(format: "+%.0f%%", card.rarity.incomeBonus * 100)
            let countText = isNew ? "✨ NEW！  収益 \(bonusText)" : "\(count)枚目  累計ボーナス \(bonusText)/枚"
            let countLbl  = SKLabelNode(text: countText)
            countLbl.fontName  = "HiraginoSans-W6"
            countLbl.fontSize  = isNew ? 13 : 10
            countLbl.fontColor = isNew
                ? UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
                : UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0)
            countLbl.verticalAlignmentMode = .center
            countLbl.position = CGPoint(x: 0, y: -h / 2 + 20); countLbl.zPosition = 3
            container.addChild(countLbl)

        } else {
            let smallImgName = card.galleryImageName
            let smallAspect: CGFloat
            if let ui = UIImage(named: smallImgName), ui.size.width > 0 {
                smallAspect = ui.size.height / ui.size.width
            } else {
                let ts = SKTexture(imageNamed: smallImgName).size()
                smallAspect = ts.width > 0 ? ts.height / ts.width : 1.5
            }
            let maxSW = w - 4; let maxSH = h * 0.54
            var sW = maxSW; var sH = sW * smallAspect
            if sH > maxSH { sH = maxSH; sW = sH / smallAspect }
            let charImg = SKSpriteNode(imageNamed: smallImgName)
            charImg.size     = CGSize(width: sW, height: sH)
            charImg.position = CGPoint(x: 0, y: 8 * fs)
            charImg.zPosition = 1
            container.addChild(charImg)

            if charImg.texture == nil || charImg.texture?.size() == CGSize.zero {
                charImg.color = UIColor(red: c.r * 0.3, green: c.g * 0.3, blue: c.b * 0.5, alpha: 1.0)
                charImg.colorBlendFactor = 1.0
            }

            let rareLbl = SKLabelNode(text: card.rarity.rawValue)
            rareLbl.fontName = "HiraginoSans-W8"; rareLbl.fontSize = round(8 * fs)
            rareLbl.fontColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
            rareLbl.verticalAlignmentMode = .center
            rareLbl.position = CGPoint(x: 0, y: h / 2 - 9 * fs); rareLbl.zPosition = 3
            container.addChild(rareLbl)

            let nameLbl = SKLabelNode(text: card.charName)
            nameLbl.fontName = "HiraginoSans-W6"; nameLbl.fontSize = round(8 * fs)
            nameLbl.fontColor = .white; nameLbl.verticalAlignmentMode = .center
            nameLbl.position  = CGPoint(x: 0, y: -h / 2 + 18 * fs); nameLbl.zPosition = 3
            container.addChild(nameLbl)

            let count = gm.cardCount(charId: card.charId, imageIndex: card.imageIndex)
            if count == 1 {
                let newBg = SKShapeNode(rectOf: CGSize(width: 24 * fs, height: 12 * fs), cornerRadius: 4)
                newBg.fillColor   = UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.95)
                newBg.strokeColor = .clear
                newBg.position    = CGPoint(x: w / 2 - 14 * fs, y: h / 2 - 20 * fs); newBg.zPosition = 4
                container.addChild(newBg)
                let newLbl = SKLabelNode(text: "NEW")
                newLbl.fontName = "HiraginoSans-W8"; newLbl.fontSize = round(7 * fs); newLbl.fontColor = .white
                newLbl.verticalAlignmentMode = .center; newLbl.position = newBg.position
                newLbl.zPosition = 5
                container.addChild(newLbl)
            }

            let noLbl = SKLabelNode(text: "No.\(card.imageIndex + 1)")
            noLbl.fontName = "HiraginoSans-W3"; noLbl.fontSize = round(7 * fs)
            noLbl.fontColor = UIColor(white: 0.65, alpha: 1.0)
            noLbl.verticalAlignmentMode = .center
            noLbl.position = CGPoint(x: 0, y: -h / 2 + 8 * fs); noLbl.zPosition = 3
            container.addChild(noLbl)
        }

        // SR/SSR キラ粒子
        if card.rarity == .sr || card.rarity == .ssr {
            let n = card.rarity == .ssr ? 16 : 8
            for _ in 0..<n {
                let sp = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
                sp.fillColor   = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.9)
                sp.strokeColor = .clear
                sp.position    = CGPoint(x: CGFloat.random(in: -w/2...w/2),
                                         y: CGFloat.random(in: -h/2...h/2))
                sp.zPosition   = 2
                container.addChild(sp)
                sp.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.08, duration: CGFloat.random(in: 0.35...0.95)),
                    SKAction.fadeAlpha(to: 1.0,  duration: CGFloat.random(in: 0.35...0.95))
                ])))
            }
        }
        return container
    }

    // MARK: - カード裏面

    private func makeCardBackNode(large: Bool, smallW: CGFloat = 58, smallH: CGFloat = 88, largeW: CGFloat = 185, largeH: CGFloat = 260) -> SKNode {
        let w: CGFloat  = large ? largeW : smallW
        let h: CGFloat  = large ? largeH : smallH
        let fs: CGFloat = large ? 1.0 : smallW / 58
        let container   = SKNode()

        // 外枠グロー
        if large {
            let outerGlow = SKShapeNode(rectOf: CGSize(width: w + 8, height: h + 8), cornerRadius: 22)
            outerGlow.fillColor   = .clear
            outerGlow.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.35)
            outerGlow.lineWidth   = 6
            outerGlow.zPosition   = -1
            outerGlow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.10, duration: 1.2),
                SKAction.fadeAlpha(to: 0.70, duration: 1.2)
            ])))
            container.addChild(outerGlow)
        }

        // カード本体
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: large ? 18 : 9 * fs)
        bg.fillColor   = UIColor(red: 0.10, green: 0.04, blue: 0.30, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.00, alpha: 0.92)
        bg.lineWidth   = large ? 2.5 : 1.5
        container.addChild(bg)

        if large {
            // 内側パターン（格子状光沢ライン）
            for i in -3...3 {
                let hLine = SKShapeNode(rectOf: CGSize(width: w - 18, height: 0.8))
                hLine.fillColor   = UIColor(red: 0.55, green: 0.30, blue: 0.90, alpha: 0.10)
                hLine.strokeColor = .clear
                hLine.position    = CGPoint(x: 0, y: CGFloat(i) * 28)
                hLine.zPosition   = 1
                container.addChild(hLine)
            }

            // コーナー装飾
            for (dx, dy): (CGFloat, CGFloat) in [(-w/2+16, h/2-16), (w/2-16, h/2-16),
                                                  (-w/2+16, -h/2+16), (w/2-16, -h/2+16)] {
                let corner = SKShapeNode(rectOf: CGSize(width: 12, height: 12), cornerRadius: 3)
                corner.fillColor   = UIColor(red: 0.55, green: 0.28, blue: 0.85, alpha: 0.50)
                corner.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.55)
                corner.lineWidth   = 1
                corner.zRotation   = .pi / 4
                corner.position    = CGPoint(x: dx, y: dy)
                corner.zPosition   = 1
                container.addChild(corner)
            }
        }

        // 中央の星マーク
        let star = SKLabelNode(text: "✨")
        star.fontSize = large ? 52 : round(20 * fs)
        star.verticalAlignmentMode = .center
        star.position  = CGPoint(x: 0, y: large ? 14 : 3 * fs)
        star.zPosition = 2
        container.addChild(star)
        star.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 5.5)))

        // テキスト
        let lbl = SKLabelNode(text: large ? "CLICK GIRL" : "CG")
        lbl.fontName  = "HiraginoSans-W7"
        lbl.fontSize  = large ? 13 : round(6 * fs)
        lbl.fontColor = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.75)
        lbl.verticalAlignmentMode = .center
        lbl.position  = CGPoint(x: 0, y: large ? -52 : -22 * fs)
        lbl.zPosition = 2
        container.addChild(lbl)

        if large {
            // 下部ダイヤ装飾
            for i in -2...2 {
                let d = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
                d.fillColor   = UIColor(red: 0.50, green: 0.25, blue: 0.82, alpha: 0.40)
                d.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.0,  alpha: 0.35)
                d.lineWidth   = 1
                d.zRotation   = .pi / 4
                d.position    = CGPoint(x: CGFloat(i) * 26, y: -85)
                d.zPosition   = 2
                container.addChild(d)
            }
            // キラ粒子（背景）
            for _ in 0..<8 {
                let sp = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.2))
                sp.fillColor   = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.7)
                sp.strokeColor = .clear
                sp.position    = CGPoint(x: CGFloat.random(in: -80...80),
                                          y: CGFloat.random(in: -105...105))
                sp.zPosition   = 1
                container.addChild(sp)
                sp.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.08, duration: CGFloat.random(in: 0.5...1.5)),
                    SKAction.fadeAlpha(to: 0.90, duration: CGFloat.random(in: 0.5...1.5))
                ])))
            }
        }
        return container
    }

    // MARK: - フリップシマー

    private func spawnFlipShimmer(at pos: CGPoint, in overlay: SKNode, delay: Double, large: Bool, cardSize: CGSize? = nil) {
        let w: CGFloat = cardSize != nil ? cardSize!.width + 6 : (large ? 195 : 62)
        let h: CGFloat = cardSize != nil ? cardSize!.height + 6 : (large ? 270 : 92)
        let shimmer = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: large ? 20 : 10)
        shimmer.fillColor   = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.60)
        shimmer.strokeColor = .clear
        shimmer.position    = pos
        shimmer.zPosition   = 25
        shimmer.alpha       = 0
        overlay.addChild(shimmer)
        shimmer.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeAlpha(to: 0.60, duration: 0.04),
            SKAction.fadeOut(withDuration: 0.20),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - レアリティフラッシュ

    private func spawnRarityFlash(card: GachaCard, in overlay: SKNode) {
        let c   = card.rarity.labelColor
        let isSSR = card.rarity == .ssr

        // 画面フラッシュ
        let flash = SKSpriteNode(color: UIColor(red: c.r, green: c.g, blue: c.b,
                                                alpha: isSSR ? 0.45 : 0.28),
                                  size: frame.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY); flash.zPosition = 20
        overlay.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: isSSR ? 0.60 : 0.45),
            SKAction.removeFromParent()
        ]))

        // SSR: 二重フラッシュ（白→カラー）
        if isSSR {
            let whiteFlash = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.50), size: frame.size)
            whiteFlash.position = CGPoint(x: frame.midX, y: frame.midY); whiteFlash.zPosition = 22
            overlay.addChild(whiteFlash)
            whiteFlash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.22),
                SKAction.removeFromParent()
            ]))

            // 放射状光線
            for i in 0..<12 {
                let angle = CGFloat(i) / 12.0 * .pi * 2
                let rayPath = CGMutablePath()
                rayPath.move(to: CGPoint(x: frame.midX, y: frame.midY))
                rayPath.addLine(to: CGPoint(x: frame.midX + cos(angle) * frame.height,
                                             y: frame.midY + sin(angle) * frame.height))
                let ray = SKShapeNode(path: rayPath)
                ray.strokeColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.30)
                ray.lineWidth   = CGFloat.random(in: 8...22)
                ray.zPosition   = 19
                overlay.addChild(ray)
                ray.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.50),
                    SKAction.removeFromParent()
                ]))
            }
        }

        // パーティクルバースト
        let cnt = isSSR ? 28 : 12
        for _ in 0..<cnt {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: isSSR ? 3.5...7.0 : 2.5...5.5))
            p.fillColor   = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
            p.strokeColor = .clear
            p.position    = CGPoint(x: frame.midX, y: frame.midY); p.zPosition = 21
            overlay.addChild(p)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: isSSR ? 130...320 : 85...240)
            let move  = SKAction.moveBy(x: cos(angle) * speed, y: sin(angle) * speed,
                                         duration: isSSR ? 0.75 : 0.60)
            move.timingMode = .easeOut
            p.run(SKAction.sequence([
                SKAction.group([move, SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.fadeOut(withDuration: isSSR ? 0.50 : 0.35)
                ])]),
                SKAction.removeFromParent()
            ]))
        }

        // SSR: 画面揺れ演出（オーバーレイ全体をわずかに揺らす）
        if isSSR {
            overlay.run(SKAction.sequence([
                SKAction.moveBy(x: -6, y: 3,  duration: 0.04),
                SKAction.moveBy(x: 8,  y: -5, duration: 0.04),
                SKAction.moveBy(x: -5, y: 4,  duration: 0.04),
                SKAction.moveBy(x: 4,  y: -2, duration: 0.04),
                SKAction.move(to: .zero, duration: 0.06)
            ]))
        }
    }

    // MARK: - Helpers

    private func refreshMoneyLabel() { moneyLabel?.text = "✦\(formatMoney(gm.money))" }
    private func refreshPityLabel() {
        let remain = 10 - (gm.gachaPityCount % 10)
        pityLabel?.text = "天井まで あと \(remain) 回  (10回でR以上確定)"
    }

    private func goBack() {
        gm.saveGame()
        let scene = GameScene(size: frame.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.1, alpha: 1.0)
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    private func showToast(_ message: String) {
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width - 50, height: 42), cornerRadius: 10)
        bg.fillColor   = UIColor(red: 0.12, green: 0.05, blue: 0.22, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7); bg.lineWidth = 1
        bg.position    = CGPoint(x: frame.midX, y: frame.midY - 60); bg.zPosition = 60
        addChild(bg)
        let lbl = SKLabelNode(text: message)
        lbl.fontName = "HiraginoSans-W5"; lbl.fontSize = 12; lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center; lbl.position = bg.position; lbl.zPosition = 61
        addChild(lbl)
        let seq = SKAction.sequence([SKAction.wait(forDuration: 2.2),
                                     SKAction.fadeOut(withDuration: 0.4),
                                     SKAction.removeFromParent()])
        bg.run(seq); lbl.run(seq)
    }

    private func formatMoney(_ v: Double) -> String {
        if v >= 1_000_000_000_000 { return String(format: "%.2f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000       { return String(format: "%.2f億", v / 100_000_000) }
        if v >= 10_000            { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
