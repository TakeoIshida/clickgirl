import SpriteKit

enum SettingReturnDestination {
    case title
    case game
}

class SettingScene: SKScene {

    private let gold   = UIColor(red: 1.0,  green: 0.85, blue: 0.2, alpha: 1)
    private let darkBg = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1)
    private let cardBg = UIColor(red: 0.07, green: 0.07, blue: 0.20, alpha: 1)

    private let returnDestination: SettingReturnDestination
    private var safeAreaTop: CGFloat = 0
    private var topBarH: CGFloat { 54 + safeAreaTop }

    override init(size: CGSize) {
        returnDestination = .title
        super.init(size: size)
    }

    init(size: CGSize, returnDestination: SettingReturnDestination) {
        self.returnDestination = returnDestination
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        returnDestination = .title
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        safeAreaTop = view.safeAreaInsets.top
        backgroundColor = darkBg
        rebuild()
    }

    private func rebuild() {
        removeAllChildren()
        addTopBar()
        addSettingsCard()
        addDangerZone()
        addVersionLabel()
    }

    // MARK: - TopBar
    private func addTopBar() {
        let contentY = frame.height - safeAreaTop - 27
        let bar = SKShapeNode(rectOf: CGSize(width: frame.width, height: topBarH))
        bar.fillColor   = UIColor(red: 0.05, green: 0.05, blue: 0.16, alpha: 0.95)
        bar.strokeColor = .clear
        bar.position    = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        addChild(bar)

        let line = SKShapeNode(rectOf: CGSize(width: frame.width, height: 1.5))
        line.fillColor   = gold
        line.strokeColor = .clear
        line.position    = CGPoint(x: frame.midX, y: frame.height - topBarH)
        addChild(line)

        let title = SKLabelNode(text: "⚙  設定")
        title.fontName  = "HiraginoSans-W6"
        title.fontSize  = 17
        title.fontColor = .white
        title.position  = CGPoint(x: frame.midX, y: contentY - 6)
        addChild(title)

        let back = SKLabelNode(text: "◀ 戻る")
        back.fontName  = "HiraginoSans-W3"
        back.fontSize  = 14
        back.fontColor = gold
        back.horizontalAlignmentMode = .left
        back.position  = CGPoint(x: 16, y: contentY - 6)
        back.name      = "backBtn"
        addChild(back)

        let backHitArea = SKSpriteNode(color: UIColor.white.withAlphaComponent(0.001),
                                       size: CGSize(width: 88, height: 44))
        backHitArea.position = CGPoint(x: 44, y: contentY)
        backHitArea.name = "backBtn"
        addChild(backHitArea)
    }

    // MARK: - 設定カード
    private func addSettingsCard() {
        let w    = frame.width - 32
        let rowH: CGFloat = 58
        let rows: [(icon: String, label: String, name: String)] = [
            ("🔊", "BGM", "bgmToggle"),
        ]

        let totalH = CGFloat(rows.count) * rowH
        let cardCY  = frame.height - topBarH - 58 - totalH / 2

        let card = SKShapeNode(rectOf: CGSize(width: w, height: totalH + 16), cornerRadius: 14)
        card.fillColor   = cardBg
        card.strokeColor = UIColor(white: 1, alpha: 0.10)
        card.lineWidth   = 1
        card.position    = CGPoint(x: frame.midX, y: cardCY)
        addChild(card)

        // セクションヘッダー
        let header = SKLabelNode(text: "✦  サウンド・システム  ✦")
        header.fontName  = "HiraginoSans-W3"
        header.fontSize  = 11
        header.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.55)
        header.position  = CGPoint(x: frame.midX, y: cardCY + totalH / 2 + 20)
        addChild(header)

        for (i, row) in rows.enumerated() {
            let yOff = totalH / 2 - CGFloat(i) * rowH - rowH / 2

            let icon = SKLabelNode(text: row.icon)
            icon.fontSize = 20
            icon.verticalAlignmentMode   = .center
            icon.horizontalAlignmentMode = .left
            icon.position = CGPoint(x: frame.midX - w / 2 + 16, y: cardCY + yOff)
            addChild(icon)

            let lbl = SKLabelNode(text: row.label)
            lbl.fontName  = "HiraginoSans-W3"
            lbl.fontSize  = 15
            lbl.fontColor = .white
            lbl.verticalAlignmentMode   = .center
            lbl.horizontalAlignmentMode = .left
            lbl.position = CGPoint(x: frame.midX - w / 2 + 52, y: cardCY + yOff)
            addChild(lbl)

            let toggle = makeToggle(isOn: AppSettings.shared.isBGMEnabled)
            toggle.name     = row.name
            toggle.position = CGPoint(x: frame.midX + w / 2 - 44, y: cardCY + yOff)
            addChild(toggle)

            if i < rows.count - 1 {
                let div = SKShapeNode(rectOf: CGSize(width: w - 24, height: 0.5))
                div.fillColor   = UIColor(white: 1, alpha: 0.07)
                div.strokeColor = .clear
                div.position    = CGPoint(x: frame.midX, y: cardCY + yOff - rowH / 2)
                addChild(div)
            }
        }
    }

    private func makeToggle(isOn: Bool) -> SKNode {
        let node  = SKNode()
        let trkW: CGFloat = 46
        let trkH: CGFloat = 26

        let track = SKShapeNode(rectOf: CGSize(width: trkW, height: trkH), cornerRadius: trkH / 2)
        track.fillColor   = isOn ? gold : UIColor(white: 0.28, alpha: 1)
        track.strokeColor = .clear
        node.addChild(track)

        let thumb = SKShapeNode(circleOfRadius: trkH / 2 - 2)
        thumb.fillColor   = .white
        thumb.strokeColor = .clear
        thumb.position    = CGPoint(x: isOn ? trkW / 2 - trkH / 2 : -(trkW / 2 - trkH / 2), y: 0)
        node.addChild(thumb)

        return node
    }

    // MARK: - データリセット
    private func addDangerZone() {
        let w  = frame.width - 32
        let btn = SKNode()
        btn.name     = "resetBtn"
        btn.position = CGPoint(x: frame.midX, y: frame.height * 0.24)

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: 52), cornerRadius: 12)
        bg.fillColor   = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.10)
        bg.strokeColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.45)
        bg.lineWidth   = 1.2
        bg.name        = "resetBtn"
        btn.addChild(bg)

        let lbl = SKLabelNode(text: "🗑  データをリセット")
        lbl.fontName  = "HiraginoSans-W3"
        lbl.fontSize  = 15
        lbl.fontColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
        lbl.verticalAlignmentMode = .center
        lbl.name = "resetBtn"
        btn.addChild(lbl)

        addChild(btn)
    }

    // MARK: - バージョン
    private func addVersionLabel() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        let ver = SKLabelNode(text: "バージョン: \(version) (\(build))")
        ver.fontName  = "HiraginoSans-W3"
        ver.fontSize  = 11
        ver.fontColor = UIColor(white: 1, alpha: 0.28)
        ver.position  = CGPoint(x: frame.midX, y: frame.height * 0.10)
        addChild(ver)
    }

    // MARK: - タップ処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let name = atPoint(loc).name ?? atPoint(loc).parent?.name ?? ""
        switch name {
        case "backBtn":
            let destination = makeReturnScene()
            destination.scaleMode = scaleMode
            view?.presentScene(destination, transition: SKTransition.push(with: .right, duration: 0.3))
        case "bgmToggle":
            AppSettings.shared.isBGMEnabled.toggle()
            rebuild()
        case "resetBtn":
            showResetConfirm()
        default: break
        }
    }

    func makeReturnScene() -> SKScene {
        switch returnDestination {
        case .title: return TitleScene(size: size)
        case .game: return GameScene(size: size)
        }
    }

    private func showResetConfirm() {
        // 暗転レイヤー
        let overlay = SKShapeNode(rectOf: CGSize(width: frame.width, height: frame.height))
        overlay.fillColor   = UIColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position    = CGPoint(x: frame.midX, y: frame.midY)
        overlay.name        = "overlay"
        overlay.zPosition   = 100
        addChild(overlay)

        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 160), cornerRadius: 16)
        panel.fillColor   = UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1)
        panel.strokeColor = UIColor(red: 0.9,  green: 0.2,  blue: 0.2,  alpha: 0.6)
        panel.lineWidth   = 1.5
        panel.position    = CGPoint(x: frame.midX, y: frame.midY)
        panel.name        = "overlay"
        panel.zPosition   = 101
        addChild(panel)

        let msg = SKLabelNode(text: "本当にリセットしますか？")
        msg.fontName  = "HiraginoSans-W6"
        msg.fontSize  = 15
        msg.fontColor = .white
        msg.position  = CGPoint(x: frame.midX, y: frame.midY + 30)
        msg.zPosition = 102
        msg.name      = "overlay"
        addChild(msg)

        let sub = SKLabelNode(text: "全データが失われます")
        sub.fontName  = "HiraginoSans-W3"
        sub.fontSize  = 12
        sub.fontColor = UIColor(white: 1, alpha: 0.55)
        sub.position  = CGPoint(x: frame.midX, y: frame.midY + 8)
        sub.zPosition = 102
        sub.name      = "overlay"
        addChild(sub)

        for (label, name, x, col) in [
            ("キャンセル", "cancelReset", frame.midX - 72, UIColor(white: 0.4, alpha: 1)),
            ("リセット",   "confirmReset", frame.midX + 72, UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1)),
        ] as [(String, String, CGFloat, UIColor)] {
            let btn = SKLabelNode(text: label)
            btn.fontName  = "HiraginoSans-W6"
            btn.fontSize  = 15
            btn.fontColor = col
            btn.position  = CGPoint(x: x, y: frame.midY - 38)
            btn.zPosition = 102
            btn.name      = name
            addChild(btn)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let name = atPoint(loc).name ?? ""
        switch name {
        case "cancelReset":
            children.filter { $0.name == "overlay" || $0.name == "cancelReset" || $0.name == "confirmReset" }
                    .forEach { $0.removeFromParent() }
            children.filter { ($0 as? SKLabelNode)?.text == "本当にリセットしますか？" ||
                              ($0 as? SKLabelNode)?.text == "全データが失われます" }
                    .forEach { $0.removeFromParent() }
        case "confirmReset":
            GameManager.shared.resetAll()
            rebuild()
        default: break
        }
    }
}
