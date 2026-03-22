import SpriteKit

// MARK: - ショップシーン

class ShopScene: SKScene {

    // MARK: - 定数
    private let topBarH:  CGFloat = 56
    private let tabBarH:  CGFloat = 44
    private let cardW:    CGFloat   // 計算後に設定
    private let cardH:    CGFloat = 162
    private let colGap:   CGFloat = 10
    private let rowGap:   CGFloat = 10
    private let sideMargin: CGFloat = 14

    private var isPermanentTab = true
    private var cardNodes: [(node: SKNode, item: ShopItem)] = []

    // MARK: - init

    override init(size: CGSize) {
        let w = (size.width - sideMargin * 2 - colGap) / 2
        cardW = w
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    private let sideMargin_: CGFloat = 14  // 計算用ダミー（init前に使えないため）

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.13, alpha: 1.0)
        buildTopBar()
        buildTabBar()
        buildCards()
    }

    // MARK: - トップバー

    private func buildTopBar() {
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width, height: topBarH))
        bg.fillColor = UIColor(red: 0.06, green: 0.06, blue: 0.18, alpha: 1.0)
        bg.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.4)
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        bg.zPosition = 10
        addChild(bg)

        let back = SKLabelNode(text: "◀ 戻る")
        back.fontName = "HiraginoSans-W5"
        back.fontSize = 15
        back.fontColor = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        back.horizontalAlignmentMode = .left
        back.verticalAlignmentMode = .center
        back.position = CGPoint(x: 14, y: frame.height - topBarH / 2)
        back.zPosition = 11
        back.name = "backBtn"
        addChild(back)

        let title = SKLabelNode(text: "🛒 ショップ")
        title.fontName = "HiraginoSans-W6"
        title.fontSize = 17
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        title.zPosition = 11
        addChild(title)

        // 所持金表示（右端）
        let moneyLabel = SKLabelNode()
        moneyLabel.fontName = "HiraginoSans-W7"
        moneyLabel.fontSize = 14
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .right
        moneyLabel.verticalAlignmentMode = .center
        moneyLabel.position = CGPoint(x: frame.width - 12, y: frame.height - topBarH / 2)
        moneyLabel.zPosition = 11
        moneyLabel.name = "moneyLabel"
        moneyLabel.text = "¥\(formatMoney(GameManager.shared.money))"
        addChild(moneyLabel)
    }

    // MARK: - タブバー

    private func buildTabBar() {
        let tabY = frame.height - topBarH - tabBarH / 2
        let tabW = frame.width / 2

        for (i, label) in ["🔧 永続強化", "⏱ 時限ブースト"].enumerated() {
            let bg = SKShapeNode(rectOf: CGSize(width: tabW - 4, height: tabBarH - 6), cornerRadius: 8)
            bg.position = CGPoint(x: tabW * CGFloat(i) + tabW / 2, y: tabY)
            bg.zPosition = 10
            bg.name = "tab_\(i)"
            bg.fillColor = i == 0
                ? UIColor(red: 0.25, green: 0.4, blue: 0.9, alpha: 0.9)
                : UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1.0)
            bg.strokeColor = .clear
            addChild(bg)

            let lbl = SKLabelNode(text: label)
            lbl.fontName = "HiraginoSans-W6"
            lbl.fontSize = 13
            lbl.fontColor = i == 0 ? .white : UIColor(white: 0.6, alpha: 1.0)
            lbl.verticalAlignmentMode = .center
            lbl.position = bg.position
            lbl.zPosition = 11
            lbl.name = "tab_\(i)"
            addChild(lbl)
        }
    }

    private func updateTabAppearance() {
        for i in 0...1 {
            let isPerm = isPermanentTab
            let isActive = (i == 0) == isPerm
            children.compactMap { $0 as? SKShapeNode }.filter { $0.name == "tab_\(i)" }.forEach {
                $0.fillColor = isActive
                    ? UIColor(red: 0.25, green: 0.4, blue: 0.9, alpha: 0.9)
                    : UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1.0)
            }
            children.compactMap { $0 as? SKLabelNode }.filter { $0.name == "tab_\(i)" }.forEach {
                $0.fontColor = isActive ? .white : UIColor(white: 0.6, alpha: 1.0)
            }
        }
    }

    // MARK: - カード生成

    private func buildCards() {
        // 既存のカードを削除
        cardNodes.forEach { $0.node.removeFromParent() }
        cardNodes = []

        let items = isPermanentTab ? ShopCatalog.permanentItems : ShopCatalog.boostItems
        let startY = frame.height - topBarH - tabBarH - 10

        for (i, item) in items.enumerated() {
            let col = i % 2
            let row = i / 2
            let x = sideMargin + cardW / 2 + CGFloat(col) * (cardW + colGap)
            let y = startY - cardH / 2 - CGFloat(row) * (cardH + rowGap)

            let card = makeCard(item: item)
            card.position = CGPoint(x: x, y: y)
            card.name = "card_\(item.id)"
            addChild(card)
            cardNodes.append((node: card, item: item))
        }
    }

    private func makeCard(item: ShopItem) -> SKNode {
        let gm = GameManager.shared
        let purchased = item.isPermanent && gm.hasUpgrade(item.id)
        let prereqMissing = item.requiresId != nil && !gm.hasUpgrade(item.requiresId!)
        let canAfford = gm.money >= item.cost
        let boostActive = !item.isPermanent && gm.isBoostActive(item.id)

        let container = SKNode()

        // 背景
        let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
        bg.fillColor = purchased
            ? UIColor(red: 0.08, green: 0.18, blue: 0.10, alpha: 0.95)
            : UIColor(red: 0.07, green: 0.07, blue: 0.20, alpha: 0.95)
        let strokeColor: UIColor
        if purchased          { strokeColor = UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.7) }
        else if prereqMissing { strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.4) }
        else if boostActive   { strokeColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.8) }
        else                  { strokeColor = UIColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 0.6) }
        bg.strokeColor = strokeColor
        bg.lineWidth = 1.5
        bg.name = "card_\(item.id)"
        container.addChild(bg)

        // アイコン
        let icon = SKLabelNode(text: item.icon)
        icon.fontSize = 36
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: cardH / 2 - 36)
        container.addChild(icon)

        // 名前
        let nameLbl = SKLabelNode(text: item.name)
        nameLbl.fontName = "HiraginoSans-W7"
        nameLbl.fontSize = 13
        nameLbl.fontColor = purchased ? UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1.0) : .white
        nameLbl.verticalAlignmentMode = .center
        nameLbl.position = CGPoint(x: 0, y: cardH / 2 - 70)
        container.addChild(nameLbl)

        // 説明文
        let descLbl = SKLabelNode(text: item.description)
        descLbl.fontName = "HiraginoSans-W3"
        descLbl.fontSize = 11
        descLbl.fontColor = UIColor(white: 0.7, alpha: 1.0)
        descLbl.verticalAlignmentMode = .center
        descLbl.position = CGPoint(x: 0, y: cardH / 2 - 90)
        container.addChild(descLbl)

        // 前提条件
        if prereqMissing, let req = item.requiresId {
            let reqName = ShopCatalog.permanentItems.first(where: { $0.id == req })?.name ?? req
            let reqLbl = SKLabelNode(text: "🔒 \(reqName)が必要")
            reqLbl.fontName = "HiraginoSans-W4"
            reqLbl.fontSize = 10
            reqLbl.fontColor = UIColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 0.9)
            reqLbl.verticalAlignmentMode = .center
            reqLbl.position = CGPoint(x: 0, y: cardH / 2 - 108)
            container.addChild(reqLbl)
        }

        // ボタンまたはステータス
        let btnY: CGFloat = -(cardH / 2 - 26)
        if purchased {
            let badge = SKLabelNode(text: "✅ 購入済み")
            badge.fontName = "HiraginoSans-W6"
            badge.fontSize = 12
            badge.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 1.0)
            badge.verticalAlignmentMode = .center
            badge.position = CGPoint(x: 0, y: btnY)
            container.addChild(badge)
        } else {
            let btnBg = SKShapeNode(rectOf: CGSize(width: cardW - 20, height: 32), cornerRadius: 10)
            btnBg.zPosition = 2
            btnBg.name = "buyBtn_\(item.id)"
            if prereqMissing || !canAfford {
                btnBg.fillColor = UIColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 0.7)
                btnBg.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.5)
            } else {
                btnBg.fillColor = UIColor(red: 0.3, green: 0.55, blue: 1.0, alpha: 0.9)
                btnBg.strokeColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.6)
            }
            btnBg.lineWidth = 1
            btnBg.position = CGPoint(x: 0, y: btnY)
            container.addChild(btnBg)

            let costText: String
            if boostActive {
                let remain = Int(gm.boostTimeRemaining(item.id))
                costText = "⏱ \(remain)秒 / ¥\(formatMoney(item.cost))"
            } else {
                costText = "¥\(formatMoney(item.cost))"
            }
            let btnLbl = SKLabelNode(text: costText)
            btnLbl.fontName = "HiraginoSans-W6"
            btnLbl.fontSize = 12
            btnLbl.fontColor = prereqMissing || !canAfford
                ? UIColor(white: 0.4, alpha: 1.0)
                : .white
            btnLbl.verticalAlignmentMode = .center
            btnLbl.position = CGPoint(x: 0, y: btnY)
            btnLbl.zPosition = 3
            btnLbl.name = "buyBtn_\(item.id)"
            container.addChild(btnLbl)
        }

        // アクティブブーストの光る枠
        if boostActive {
            let glow = SKShapeNode(rectOf: CGSize(width: cardW + 4, height: cardH + 4), cornerRadius: 15)
            glow.fillColor = .clear
            glow.strokeColor = UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 0.5)
            glow.lineWidth = 2
            glow.zPosition = -1
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.7),
                SKAction.fadeAlpha(to: 0.8, duration: 0.7)
            ])
            glow.run(SKAction.repeatForever(pulse))
            container.addChild(glow)
        }

        return container
    }

    // MARK: - タッチ

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)

        for node in nodes(at: loc) {
            guard let name = node.name else { continue }

            if name == "backBtn" { goBack(); return }

            if name == "tab_0" { isPermanentTab = true;  updateTabAppearance(); buildCards(); return }
            if name == "tab_1" { isPermanentTab = false; updateTabAppearance(); buildCards(); return }

            if name.hasPrefix("buyBtn_") {
                let id = String(name.dropFirst(7))
                let items = isPermanentTab ? ShopCatalog.permanentItems : ShopCatalog.boostItems
                if let item = items.first(where: { $0.id == id }) {
                    attemptPurchase(item)
                }
                return
            }
            if name.hasPrefix("card_") {
                let id = String(name.dropFirst(5))
                let items = isPermanentTab ? ShopCatalog.permanentItems : ShopCatalog.boostItems
                if let item = items.first(where: { $0.id == id }) {
                    attemptPurchase(item)
                }
                return
            }
        }
    }

    // MARK: - 購入処理

    private func attemptPurchase(_ item: ShopItem) {
        let gm = GameManager.shared
        if item.isPermanent && gm.hasUpgrade(item.id) { return }
        if let req = item.requiresId, !gm.hasUpgrade(req) {
            showToast("先に「\(ShopCatalog.permanentItems.first(where: { $0.id == req })?.name ?? "前提アップグレード")」が必要です")
            return
        }
        guard gm.money >= item.cost else {
            showToast("💸 お金が足りません (¥\(formatMoney(item.cost)) 必要)")
            return
        }

        let success = gm.buyShopItem(item)
        if success {
            buildCards()
            updateMoneyLabel()
            showPurchaseEffect(item: item)
        }
    }

    private func updateMoneyLabel() {
        if let lbl = childNode(withName: "moneyLabel") as? SKLabelNode {
            lbl.text = "¥\(formatMoney(GameManager.shared.money))"
        }
    }

    // MARK: - update (ブーストタイマー)

    override func update(_ currentTime: TimeInterval) {
        // 1秒ごとにブーストカードのタイマー表示を更新
        updateMoneyLabel()
        // ブーストタイマー更新（ブーストタブが開いている場合のみ）
        if !isPermanentTab {
            let gm = GameManager.shared
            for (card, item) in cardNodes {
                guard gm.isBoostActive(item.id) else { continue }
                let remain = Int(gm.boostTimeRemaining(item.id))
                // ボタンのコストラベルを更新
                func updateLabel(_ node: SKNode) {
                    for child in node.children {
                        if let lbl = child as? SKLabelNode, lbl.name == "buyBtn_\(item.id)" {
                            lbl.text = "⏱ \(remain)秒 / ¥\(formatMoney(item.cost))"
                        }
                        updateLabel(child)
                    }
                }
                updateLabel(card)
            }
        }
    }

    // MARK: - エフェクト

    private func showPurchaseEffect(item: ShopItem) {
        let label = SKLabelNode(text: "✨ \(item.name) 購入！")
        label.fontName = "HiraginoSans-W7"
        label.fontSize = 18
        label.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: frame.midY + 20)
        label.zPosition = 50
        label.setScale(0.7)
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.05, duration: 0.18),
                SKAction.fadeIn(withDuration: 0.18)
            ]),
            SKAction.wait(forDuration: 1.0),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.moveBy(x: 0, y: 25, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // 購入フラッシュ
        let flash = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.12), size: frame.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.zPosition = 49
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.35), SKAction.removeFromParent()]))
    }

    private func showToast(_ message: String) {
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width - 50, height: 40), cornerRadius: 10)
        bg.fillColor = UIColor(red: 0.12, green: 0.05, blue: 0.22, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7)
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.midY - 60)
        bg.zPosition = 60
        addChild(bg)

        let lbl = SKLabelNode(text: message)
        lbl.fontName = "HiraginoSans-W5"
        lbl.fontSize = 12
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.position = bg.position
        lbl.zPosition = 61
        addChild(lbl)

        let seq = SKAction.sequence([
            SKAction.wait(forDuration: 2.2),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ])
        bg.run(seq); lbl.run(seq)
    }

    // MARK: - 戻る

    private func goBack() {
        GameManager.shared.saveGame()
        let scene = GameScene(size: frame.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.1, alpha: 1.0)
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    // MARK: - フォーマット

    private func formatMoney(_ v: Double) -> String {
        if v >= 1_000_000_000_000 { return String(format: "%.2f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000      { return String(format: "%.2f億", v / 100_000_000) }
        if v >= 10_000           { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
