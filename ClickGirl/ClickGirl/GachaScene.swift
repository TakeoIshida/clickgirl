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
    }

    // MARK: - 背景

    private func buildBackground() {
        for _ in 0..<55 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...2.2))
            s.fillColor   = UIColor(white: 1.0, alpha: CGFloat.random(in: 0.3...0.9))
            s.strokeColor = .clear
            s.position    = CGPoint(x: CGFloat.random(in: 0...frame.width),
                                    y: CGFloat.random(in: 0...frame.height))
            s.zPosition   = -5
            addChild(s)
            s.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.05...0.2), duration: CGFloat.random(in: 1...3)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0),  duration: CGFloat.random(in: 1...3))
            ])))
        }
        let grd = SKSpriteNode(color: UIColor(red: 0.18, green: 0.06, blue: 0.40, alpha: 0.50),
                               size: CGSize(width: frame.width, height: frame.height * 0.45))
        grd.position  = CGPoint(x: frame.midX, y: frame.height * 0.78)
        grd.zPosition = -4
        addChild(grd)
    }

    // MARK: - トップバー

    private func buildTopBar() {
        let h: CGFloat = 56
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width, height: h))
        bg.fillColor   = UIColor(red: 0.06, green: 0.03, blue: 0.18, alpha: 1.0)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 1.0, alpha: 0.4)
        bg.lineWidth   = 1
        bg.position    = CGPoint(x: frame.midX, y: frame.height - h / 2)
        bg.zPosition   = 10
        addChild(bg)

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
        moneyLabel.text = "¥\(formatMoney(gm.money))"
        addChild(moneyLabel)
    }

    // MARK: - 天井パネル

    private func buildInfoPanel() {
        let panelY = frame.height - 56 - 34
        let panelBg = SKShapeNode(rectOf: CGSize(width: frame.width - 20, height: 46), cornerRadius: 10)
        panelBg.fillColor   = UIColor(red: 0.08, green: 0.04, blue: 0.20, alpha: 0.92)
        panelBg.strokeColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.5)
        panelBg.lineWidth   = 1
        panelBg.position    = CGPoint(x: frame.midX, y: panelY)
        panelBg.zPosition   = 5
        addChild(panelBg)

        let pityRemain = 10 - (gm.gachaPityCount % 10)
        pityLabel = SKLabelNode(text: "天井まで あと \(pityRemain) 回  (10回でR以上確定)")
        pityLabel.fontName = "HiraginoSans-W5"; pityLabel.fontSize = 12
        pityLabel.fontColor = UIColor(red: 0.85, green: 0.75, blue: 1.0, alpha: 1.0)
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
        for i in 0...2 {
            let ring = SKShapeNode(circleOfRadius: CGFloat(88 + i * 28))
            ring.fillColor   = .clear
            ring.strokeColor = UIColor(red: 0.65, green: 0.25, blue: 1.0,
                                       alpha: CGFloat(0.12 - Double(i) * 0.03))
            ring.lineWidth   = CGFloat(10 - i * 3)
            ring.position    = CGPoint(x: frame.midX, y: orbY)
            ring.zPosition   = 0
            addChild(ring)
            ring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.25, duration: 1.6 + Double(i) * 0.4),
                SKAction.fadeAlpha(to: 1.0,  duration: 1.6 + Double(i) * 0.4)
            ])))
        }
        let orb = SKShapeNode(circleOfRadius: 78)
        orb.fillColor   = UIColor(red: 0.22, green: 0.07, blue: 0.52, alpha: 0.92)
        orb.strokeColor = UIColor(red: 0.85, green: 0.55, blue: 1.0,  alpha: 0.85)
        orb.lineWidth   = 2.5; orb.position = CGPoint(x: frame.midX, y: orbY)
        orb.zPosition   = 1;   orb.name = "orbNode"
        addChild(orb)

        let orbIcon = SKLabelNode(text: "✨")
        orbIcon.fontSize = 54; orbIcon.verticalAlignmentMode = .center
        orbIcon.position = CGPoint(x: frame.midX, y: orbY); orbIcon.zPosition = 2
        addChild(orbIcon)
        orbIcon.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 9.0)))

        let particleColors: [UIColor] = [
            UIColor(red: 0.85, green: 0.55, blue: 1.0, alpha: 0.9),
            UIColor(red: 0.50, green: 0.80, blue: 1.0, alpha: 0.9),
            UIColor(red: 1.00, green: 0.80, blue: 0.30, alpha: 0.9),
        ]
        for i in 0..<10 {
            let angle = CGFloat(i) / 10.0 * .pi * 2
            let dist  = CGFloat.random(in: 55...135)
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...4.0))
            p.fillColor = particleColors.randomElement()!; p.strokeColor = .clear
            p.position  = CGPoint(x: frame.midX + cos(angle) * dist, y: orbY + sin(angle) * dist)
            p.zPosition = 3
            addChild(p)
            p.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.5...1.2)),
                SKAction.fadeAlpha(to: 1.0, duration: CGFloat.random(in: 0.5...1.2))
            ])))
        }
    }

    // MARK: - 引くボタン

    private func buildPullButtons() {
        let btnW = (frame.width - 48.0) / 2
        let btnH: CGFloat = 58
        let btnY: CGFloat = 120
        let configs: [(x: CGFloat, icon: String, title: String, cost: Double, name: String)] = [
            (frame.width / 4.0,       "🎲", "1回ガチャ",  GachaCatalog.singleCost, "btn1"),
            (frame.width * 3.0 / 4.0, "🎰", "10連ガチャ", GachaCatalog.tenCost,   "btn10"),
        ]
        for cfg in configs {
            let bg = SKShapeNode(rectOf: CGSize(width: btnW, height: btnH), cornerRadius: 16)
            bg.fillColor   = UIColor(red: 0.28, green: 0.08, blue: 0.58, alpha: 0.92)
            bg.strokeColor = UIColor(red: 0.80, green: 0.50, blue: 1.0,  alpha: 0.80)
            bg.lineWidth   = 2; bg.position = CGPoint(x: cfg.x, y: btnY)
            bg.zPosition   = 5; bg.name = cfg.name
            addChild(bg)
            bg.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.run { bg.strokeColor = UIColor(red: 1.0, green: 0.75, blue: 1.0, alpha: 1.0) },
                SKAction.wait(forDuration: 1.6),
                SKAction.run { bg.strokeColor = UIColor(red: 0.80, green: 0.50, blue: 1.0, alpha: 0.80) },
                SKAction.wait(forDuration: 1.6)
            ])))

            for (pos, text, font, size, color): (CGPoint, String, String, CGFloat, UIColor) in [
                (CGPoint(x: cfg.x, y: btnY + 13), cfg.icon,            "",                    26, UIColor.white),
                (CGPoint(x: cfg.x, y: btnY - 4),  cfg.title,           "HiraginoSans-W7",     14, UIColor.white),
                (CGPoint(x: cfg.x, y: btnY - 20), "¥\(formatMoney(cfg.cost))",
                 "HiraginoSans-W5", 12, UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)),
            ] {
                let lbl = SKLabelNode(text: text)
                lbl.fontName = font; lbl.fontSize = size; lbl.fontColor = color
                lbl.verticalAlignmentMode = .center; lbl.position = pos
                lbl.zPosition = 6; lbl.name = cfg.name
                addChild(lbl)
            }
        }

        // 10連「1回分お得！」バッジ
        let badge = SKShapeNode(rectOf: CGSize(width: 66, height: 18), cornerRadius: 6)
        badge.fillColor = UIColor(red: 1.0, green: 0.25, blue: 0.5, alpha: 0.95)
        badge.strokeColor = .clear
        badge.position  = CGPoint(x: frame.width * 3.0 / 4.0 + btnW / 2 - 31, y: btnY + btnH / 2 + 2)
        badge.zPosition = 7
        addChild(badge)
        let badgeLbl = SKLabelNode(text: "1回分お得！")
        badgeLbl.fontName = "HiraginoSans-W7"; badgeLbl.fontSize = 9; badgeLbl.fontColor = .white
        badgeLbl.verticalAlignmentMode = .center; badgeLbl.position = badge.position
        badgeLbl.zPosition = 8
        addChild(badgeLbl)
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
            if name == "backBtn" { goBack();           return }
            if name == "btn1"    { pullGacha(count: 1);  return }
            if name == "btn10"   { pullGacha(count: 10); return }
        }
    }

    // MARK: - ガチャロジック

    private func pullGacha(count: Int) {
        let cost = count == 1 ? GachaCatalog.singleCost : GachaCatalog.tenCost
        guard gm.money >= cost else {
            showToast("💸 お金が足りません (¥\(formatMoney(cost)) 必要)")
            return
        }
        isAnimating = true
        gm.money -= cost

        let (cards, newPity) = GachaCatalog.draw(count: count, pityCount: gm.gachaPityCount)
        gm.gachaPityCount = newPity
        for card in cards { gm.addCard(card) }
        gm.saveGame()

        if let orb = childNode(withName: "orbNode") as? SKShapeNode {
            orb.run(SKAction.sequence([
                SKAction.run { orb.fillColor = UIColor(red: 1.0, green: 0.95, blue: 1.0, alpha: 1.0) },
                SKAction.wait(forDuration: 0.14),
                SKAction.run { orb.fillColor = UIColor(red: 0.22, green: 0.07, blue: 0.52, alpha: 0.92) }
            ]))
        }
        run(SKAction.wait(forDuration: 0.2)) { [weak self] in self?.showResults(cards) }
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

        let dim = SKSpriteNode(color: UIColor(red: 0.0, green: 0.0, blue: 0.04, alpha: 0.90),
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
        let pos = CGPoint(x: frame.midX, y: frame.midY + 50)
        let cardSize = CGSize(width: 185, height: 260)

        let backNode = makeCardBackNode(large: true)
        backNode.position = pos
        backNode.setScale(0)
        overlay.addChild(backNode)

        let frontNode = makeCardNode(card: card, large: true)
        frontNode.position = pos
        frontNode.alpha = 0
        overlay.addChild(frontNode)

        flipCardData = [(pos: pos, size: cardSize, back: backNode, front: frontNode, card: card, flipped: false)]

        // 裏面ポップイン
        backNode.run(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.14),
            SKAction.scale(to: 1.0,  duration: 0.07)
        ]))

        buildResultHint("タップしてめくろう！", in: overlay)
    }

    private func showTenResult(_ cards: [GachaCard], in overlay: SKNode) {
        // レイアウト: 3列×3行 + 最終1枚を中央 (3+3+3+1)
        let cols: Int        = 3
        let sidePad: CGFloat = 12
        let gapX: CGFloat    = 10
        let gapY: CGFloat    = 8

        // 縦方向の利用可能領域
        let btnAreaH: CGFloat = 115
        let topPad:   CGFloat = 65
        let availH = frame.height - btnAreaH - topPad

        // カードサイズ: 幅から算出し、4行収まるよう高さを上限クランプ
        let cardW = floor((frame.width - sidePad * 2 - gapX * CGFloat(cols - 1)) / CGFloat(cols))
        let cardH = min(floor(cardW * 1.58), floor((availH - gapY * 3) / 4))

        // 3列グリッドの開始X
        let totalW3 = CGFloat(cols) * cardW + CGFloat(cols - 1) * gapX
        let startX  = (frame.width - totalW3) / 2 + cardW / 2

        // グリッド全体（4行分）が利用可能領域に収まるよう縦中央寄せ
        let gridH  = 4 * (cardH + gapY) - gapY
        let startY = (btnAreaH + availH / 2) + gridH / 2 - cardH / 2

        for (i, card) in cards.enumerated() {
            let pos: CGPoint
            if i < 9 {
                // 行0〜2: 3列グリッド
                let x = startX + CGFloat(i % cols) * (cardW + gapX)
                let y = startY - CGFloat(i / cols) * (cardH + gapY)
                pos = CGPoint(x: x, y: y)
            } else {
                // 最後の1枚: 画面中央に配置
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

        // 全てめくる ボタン
        if !isFlippingAll && !flipCardData.allSatisfy({ $0.flipped }) {
            if nodes(at: loc).contains(where: { $0.name == "flipAllBtn" }) {
                flipAllCards(in: overlay)
                return
            }
        }

        // 個別カードタップ
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
            return  // 未めくりカードがある間は閉じない
        }

        // 全部めくり済み → 閉じる
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
        let pos = CGPoint(x: frame.midX, y: 70)
        let bg = SKShapeNode(rectOf: CGSize(width: 160, height: 42), cornerRadius: 14)
        bg.fillColor   = UIColor(red: 0.55, green: 0.15, blue: 0.90, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.85, green: 0.60, blue: 1.00, alpha: 0.90)
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
            SKAction.scale(to: 1.04, duration: 0.7),
            SKAction.scale(to: 1.0,  duration: 0.7)
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

    private func makeCardNode(card: GachaCard, large: Bool, smallW: CGFloat = 58, smallH: CGFloat = 88) -> SKNode {
        let w: CGFloat  = large ? 185 : smallW
        let h: CGFloat  = large ? 260 : smallH
        let fs: CGFloat = large ? 1.0 : smallW / 58   // フォントスケール
        let container   = SKNode()
        let c = card.rarity.labelColor

        // カード背景
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: large ? 18 : 9)
        bg.fillColor   = UIColor(red: c.r * 0.14, green: c.g * 0.10, blue: c.b * 0.25, alpha: 0.97)
        bg.strokeColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.92)
        bg.lineWidth   = large ? 2.5 : 1.5
        container.addChild(bg)

        if large {
            // ── 大カード ──────────────────────────────
            // キャラ画像（背景あり）
            let imgY: CGFloat = 20
            let imgH: CGFloat = h * 0.52
            let imgW: CGFloat = w - 8
            let charImg = SKSpriteNode(imageNamed: card.galleryImageName)
            charImg.size     = CGSize(width: imgW, height: imgH)
            charImg.position = CGPoint(x: 0, y: imgY)
            charImg.zPosition = 1
            container.addChild(charImg)

            // 画像が読み込めなかった場合のプレースホルダー
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

            // レアリティバッジ（上部）
            let rareBg = SKShapeNode(rectOf: CGSize(width: 58, height: 22), cornerRadius: 6)
            rareBg.fillColor   = UIColor(red: c.r * 0.5, green: c.g * 0.5, blue: c.b * 0.5, alpha: 0.9)
            rareBg.strokeColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.8)
            rareBg.lineWidth   = 1
            rareBg.position    = CGPoint(x: 0, y: h / 2 - 16); rareBg.zPosition = 3
            container.addChild(rareBg)
            let rareLbl = SKLabelNode(text: card.rarity.rawValue)
            rareLbl.fontName = "HiraginoSans-W8"; rareLbl.fontSize = 13
            rareLbl.fontColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
            rareLbl.verticalAlignmentMode = .center; rareLbl.position = rareBg.position
            rareLbl.zPosition = 4
            container.addChild(rareLbl)

            // キャラ名 + No.
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

            // 所持枚数 & 収益ボーナス
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
            // ── 小カード（10連グリッド）──────────────────
            let charImg = SKSpriteNode(imageNamed: card.galleryImageName)
            charImg.size     = CGSize(width: w - 4, height: h * 0.54)
            charImg.position = CGPoint(x: 0, y: 8 * fs)
            charImg.zPosition = 1
            container.addChild(charImg)

            // プレースホルダー
            if charImg.texture == nil || charImg.texture?.size() == CGSize.zero {
                charImg.color = UIColor(red: c.r * 0.3, green: c.g * 0.3, blue: c.b * 0.5, alpha: 1.0)
                charImg.colorBlendFactor = 1.0
            }

            // レアバッジ
            let rareLbl = SKLabelNode(text: card.rarity.rawValue)
            rareLbl.fontName = "HiraginoSans-W8"; rareLbl.fontSize = round(8 * fs)
            rareLbl.fontColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
            rareLbl.verticalAlignmentMode = .center
            rareLbl.position = CGPoint(x: 0, y: h / 2 - 9 * fs); rareLbl.zPosition = 3
            container.addChild(rareLbl)

            // キャラ名
            let nameLbl = SKLabelNode(text: card.charName)
            nameLbl.fontName = "HiraginoSans-W6"; nameLbl.fontSize = round(8 * fs)
            nameLbl.fontColor = .white; nameLbl.verticalAlignmentMode = .center
            nameLbl.position  = CGPoint(x: 0, y: -h / 2 + 18 * fs); nameLbl.zPosition = 3
            container.addChild(nameLbl)

            // NEW バッジ
            let count = gm.cardCount(charId: card.charId, imageIndex: card.imageIndex)
            if count == 1 {
                let newBg = SKShapeNode(rectOf: CGSize(width: 24 * fs, height: 12 * fs), cornerRadius: 4)
                newBg.fillColor = UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.95)
                newBg.strokeColor = .clear
                newBg.position   = CGPoint(x: w / 2 - 14 * fs, y: h / 2 - 20 * fs); newBg.zPosition = 4
                container.addChild(newBg)
                let newLbl = SKLabelNode(text: "NEW")
                newLbl.fontName = "HiraginoSans-W8"; newLbl.fontSize = round(7 * fs); newLbl.fontColor = .white
                newLbl.verticalAlignmentMode = .center; newLbl.position = newBg.position
                newLbl.zPosition = 5
                container.addChild(newLbl)
            }

            // 枚数
            let noLbl = SKLabelNode(text: "No.\(card.imageIndex + 1)")
            noLbl.fontName = "HiraginoSans-W3"; noLbl.fontSize = round(7 * fs)
            noLbl.fontColor = UIColor(white: 0.65, alpha: 1.0)
            noLbl.verticalAlignmentMode = .center
            noLbl.position = CGPoint(x: 0, y: -h / 2 + 8 * fs); noLbl.zPosition = 3
            container.addChild(noLbl)
        }

        // SR/SSR キラ粒子
        if card.rarity == .sr || card.rarity == .ssr {
            let n = card.rarity == .ssr ? 14 : 7
            for _ in 0..<n {
                let sp = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
                sp.fillColor   = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.9)
                sp.strokeColor = .clear
                sp.position    = CGPoint(x: CGFloat.random(in: -w/2...w/2),
                                         y: CGFloat.random(in: -h/2...h/2))
                sp.zPosition   = 2
                container.addChild(sp)
                sp.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.4...1.0)),
                    SKAction.fadeAlpha(to: 1.0, duration: CGFloat.random(in: 0.4...1.0))
                ])))
            }
        }
        return container
    }

    // MARK: - カード裏面

    private func makeCardBackNode(large: Bool, smallW: CGFloat = 58, smallH: CGFloat = 88) -> SKNode {
        let w: CGFloat = large ? 185 : smallW
        let h: CGFloat = large ? 260 : smallH
        let fs: CGFloat = large ? 1.0 : smallW / 58
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: large ? 18 : 9 * fs)
        bg.fillColor   = UIColor(red: 0.10, green: 0.04, blue: 0.28, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.00, alpha: 0.90)
        bg.lineWidth   = large ? 2.5 : 1.5
        container.addChild(bg)

        // 中央の星マーク
        let star = SKLabelNode(text: "✨")
        star.fontSize = large ? 52 : round(20 * fs)
        star.verticalAlignmentMode = .center
        star.position = CGPoint(x: 0, y: large ? 12 : 3 * fs)
        star.zPosition = 1
        container.addChild(star)
        star.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 6.0)))

        // テキスト
        let lbl = SKLabelNode(text: large ? "CLICK GIRL" : "CG")
        lbl.fontName = "HiraginoSans-W7"
        lbl.fontSize = large ? 13 : round(6 * fs)
        lbl.fontColor = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.75)
        lbl.verticalAlignmentMode = .center
        lbl.position = CGPoint(x: 0, y: large ? -50 : -22 * fs)
        lbl.zPosition = 1
        container.addChild(lbl)

        if large {
            // 装飾ひし形
            for i in -2...2 {
                let d = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
                d.fillColor   = UIColor(red: 0.50, green: 0.25, blue: 0.80, alpha: 0.35)
                d.strokeColor = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.30)
                d.lineWidth   = 1
                d.zRotation   = .pi / 4
                d.position    = CGPoint(x: CGFloat(i) * 26, y: -85)
                d.zPosition   = 1
                container.addChild(d)
            }
            // キラ粒子（背景）
            for _ in 0..<6 {
                let sp = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.0))
                sp.fillColor   = UIColor(red: 0.72, green: 0.45, blue: 1.0, alpha: 0.7)
                sp.strokeColor = .clear
                sp.position    = CGPoint(x: CGFloat.random(in: -80...80),
                                         y: CGFloat.random(in: -100...100))
                sp.zPosition   = 1
                container.addChild(sp)
                sp.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.6...1.4)),
                    SKAction.fadeAlpha(to: 0.9, duration: CGFloat.random(in: 0.6...1.4))
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
        shimmer.fillColor   = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.55)
        shimmer.strokeColor = .clear
        shimmer.position    = pos
        shimmer.zPosition   = 25
        shimmer.alpha       = 0
        overlay.addChild(shimmer)
        shimmer.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeAlpha(to: 0.55, duration: 0.04),
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - アニメーション

    private func spawnRarityFlash(card: GachaCard, in overlay: SKNode) {
        let c = card.rarity.labelColor
        let flash = SKSpriteNode(color: UIColor(red: c.r, green: c.g, blue: c.b, alpha: 0.28),
                                  size: frame.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY); flash.zPosition = 20
        overlay.addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.45), SKAction.removeFromParent()]))

        let cnt = card.rarity == .ssr ? 20 : 10
        for _ in 0..<cnt {
            let p = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            p.fillColor = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0); p.strokeColor = .clear
            p.position  = CGPoint(x: frame.midX, y: frame.midY); p.zPosition = 21
            overlay.addChild(p)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed = CGFloat.random(in: 90...260)
            let move  = SKAction.moveBy(x: cos(angle) * speed, y: sin(angle) * speed, duration: 0.6)
            move.timingMode = .easeOut
            p.run(SKAction.sequence([
                SKAction.group([move, SKAction.sequence([
                    SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.4)
                ])]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Helpers

    private func refreshMoneyLabel() { moneyLabel?.text = "¥\(formatMoney(gm.money))" }
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
        bg.fillColor = UIColor(red: 0.12, green: 0.05, blue: 0.22, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7); bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.midY - 60); bg.zPosition = 60
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
