import SpriteKit

class ZukanScene: SKScene {

    // MARK: - データ

    private struct CharInfo {
        let id: Int; let name: String; let prefix: String; let count: Int
    }
    private let chars: [CharInfo] = [
        CharInfo(id: 0, name: "カレン",  prefix: "karen",  count: 10),
        CharInfo(id: 1, name: "みさき", prefix: "misaki", count: 8),
        CharInfo(id: 2, name: "ゆき",   prefix: "yuki",   count: 10),
        CharInfo(id: 3, name: "りお",   prefix: "rio",    count: 3),
        CharInfo(id: 4, name: "あかり", prefix: "akari",  count: 8),
    ]

    private var currentCharIdx = 0
    private var currentImgIdx  = 0

    // MARK: - ノード
    private var mainImgNode    = SKSpriteNode()
    private var lockOverlayNode: SKNode?        // メイン画像のロックオーバーレイ
    private var countLabel     = SKLabelNode()
    private var setBtn         = SKShapeNode()
    private var setBtnLabel    = SKLabelNode()
    private var thumbContainer = SKNode()
    private var tabNodes: [SKNode] = []

    // MARK: - スワイプ
    private var swipeStart: CGPoint = .zero
    private var swipeTime:  TimeInterval = 0
    private var didSwipe = false

    // MARK: - レイアウト定数
    private var topBarH:   CGFloat { 56 }
    private var tabBarH:   CGFloat { 46 }
    private var thumbBarH: CGFloat { 90 }
    private var setBtnH:   CGFloat { 50 }
    private var imgAreaY:  CGFloat {
        frame.height - topBarH - tabBarH - imgAreaH / 2 - 8
    }
    private var imgAreaH: CGFloat {
        frame.height - topBarH - tabBarH - setBtnH - thumbBarH - 16
    }

    // MARK: - 便利メソッド

    private func isCharHired(_ charIdx: Int) -> Bool {
        let gm = GameManager.shared
        return gm.employees.first(where: { $0.id == chars[charIdx].id })?.isHired ?? false
    }

    private func isCurrentImageUnlocked() -> Bool {
        let char = chars[currentCharIdx]
        return ZukanConditions.isImageUnlocked(charId: char.id, imageIndex: currentImgIdx, gm: GameManager.shared)
    }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0)
        buildTopBar()
        buildTabBar()
        buildMainImageArea()
        buildSetButton()
        buildThumbBar()

        // 採用済みの最初のキャラを選択
        let firstHired = chars.firstIndex(where: { isCharHired($0.id) }) ?? 0
        currentCharIdx = firstHired
        currentImgIdx  = GameManager.shared.selectedImageIndex[chars[currentCharIdx].id] ?? 0
        refreshAll()
    }

    // トップバー
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

        let title = SKLabelNode(text: "キャラ図鑑")
        title.fontName = "HiraginoSans-W6"
        title.fontSize = 17
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        title.zPosition = 11
        addChild(title)
    }

    // キャラタブ（5キャラ対応: 最小幅を確保して均等配置）
    private func buildTabBar() {
        let minTabW: CGFloat = 70
        let tabW = max(frame.width / CGFloat(chars.count), minTabW)
        let tabY  = frame.height - topBarH - tabBarH / 2
        for (i, c) in chars.enumerated() {
            let node = SKNode()
            node.position = CGPoint(x: tabW * CGFloat(i) + tabW / 2, y: tabY)
            node.zPosition = 10
            node.name = "tab_\(i)"

            let bg = SKShapeNode(rectOf: CGSize(width: tabW - 4, height: tabBarH - 8), cornerRadius: 8)
            bg.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1.0)
            bg.strokeColor = .clear
            bg.name = "tab_\(i)"
            node.addChild(bg)

            let lbl = SKLabelNode(text: c.name)
            lbl.fontName = "HiraginoSans-W6"
            lbl.fontSize = 12
            lbl.fontColor = UIColor(white: 0.8, alpha: 1.0)
            lbl.verticalAlignmentMode = .center
            lbl.name = "tab_\(i)"
            node.addChild(lbl)

            addChild(node)
            tabNodes.append(node)
        }
    }

    // メイン画像エリア
    private func buildMainImageArea() {
        mainImgNode.position = CGPoint(x: frame.midX, y: imgAreaY)
        mainImgNode.zPosition = 5
        addChild(mainImgNode)

        // 矢印ヒント
        for (x, t) in [(CGFloat(16), "◀"), (frame.width - 16, "▶")] {
            let arrow = SKLabelNode(text: t)
            arrow.fontSize = 22
            arrow.fontColor = UIColor(white: 1.0, alpha: 0.25)
            arrow.verticalAlignmentMode = .center
            arrow.position = CGPoint(x: x, y: imgAreaY)
            arrow.zPosition = 6
            addChild(arrow)
        }

        countLabel.fontName = "HiraginoSans-W3"
        countLabel.fontSize = 12
        countLabel.fontColor = UIColor(white: 0.55, alpha: 1.0)
        countLabel.verticalAlignmentMode = .center
        countLabel.zPosition = 6
        addChild(countLabel)
    }

    // 設定ボタン
    private func buildSetButton() {
        let btnY = setBtnH / 2 + thumbBarH
        setBtn = SKShapeNode(rectOf: CGSize(width: frame.width - 48, height: 40), cornerRadius: 12)
        setBtn.position = CGPoint(x: frame.midX, y: btnY)
        setBtn.zPosition = 10
        setBtn.name = "setBtn"
        addChild(setBtn)

        setBtnLabel.fontName = "HiraginoSans-W6"
        setBtnLabel.fontSize = 14
        setBtnLabel.fontColor = .white
        setBtnLabel.verticalAlignmentMode = .center
        setBtnLabel.position = setBtn.position
        setBtnLabel.zPosition = 11
        setBtnLabel.name = "setBtn"
        addChild(setBtnLabel)
    }

    // サムネイルバー
    private func buildThumbBar() {
        thumbContainer.zPosition = 10
        addChild(thumbContainer)
    }

    // MARK: - リフレッシュまとめ

    private func refreshAll(animated: Bool = false) {
        refreshMainImage(animated: animated)
        refreshThumbs()
        refreshTabs()
        refreshSetBtn()
    }

    // MARK: - ロード

    private func loadChar(idx: Int) {
        guard isCharHired(idx) else {
            showToast("先に\(chars[idx].name)を採用してください 🔒")
            return
        }
        currentCharIdx = idx
        currentImgIdx  = GameManager.shared.selectedImageIndex[chars[idx].id] ?? 0
        refreshAll(animated: false)
    }

    // MARK: - 画像リフレッシュ

    private func refreshMainImage(animated: Bool = true) {
        let char    = chars[currentCharIdx]
        let unlocked = ZukanConditions.isImageUnlocked(charId: char.id, imageIndex: currentImgIdx, gm: GameManager.shared)
        let name    = "\(char.prefix)_\(currentImgIdx)"
        let tex     = SKTexture(imageNamed: name)

        let apply = { [weak self] in
            guard let self = self else { return }

            self.mainImgNode.texture = tex
            let w = self.frame.width - 24
            let ratio = tex.size().height / max(tex.size().width, 1)
            let h = min(w * ratio, self.imgAreaH)
            self.mainImgNode.size = CGSize(width: w, height: h)

            self.countLabel.text  = "\(self.currentImgIdx + 1) / \(char.count)"
            self.countLabel.position = CGPoint(
                x: self.frame.midX,
                y: self.imgAreaY - self.mainImgNode.size.height / 2 - 12
            )

            // ロックオーバーレイ更新
            self.lockOverlayNode?.removeFromParent()
            self.lockOverlayNode = nil

            if !unlocked {
                let overlay = self.makeLockOverlay(
                    size: self.mainImgNode.size,
                    condText: ZukanConditions.conditionText(charId: char.id, imageIndex: self.currentImgIdx)
                )
                overlay.position = CGPoint(x: self.frame.midX, y: self.imgAreaY)
                overlay.zPosition = 7
                self.addChild(overlay)
                self.lockOverlayNode = overlay

                // ロック時はダーク化
                self.mainImgNode.color = UIColor.black
                self.mainImgNode.colorBlendFactor = 0.65
            } else {
                self.mainImgNode.colorBlendFactor = 0.0
            }
        }

        if animated {
            mainImgNode.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0, duration: 0.12),
                SKAction.run(apply),
                SKAction.fadeAlpha(to: 1.0, duration: 0.12)
            ]))
            lockOverlayNode?.removeFromParent()
            lockOverlayNode = nil
        } else {
            apply()
        }
    }

    /// ロックオーバーレイノードを作成
    private func makeLockOverlay(size: CGSize, condText: String) -> SKNode {
        let node = SKNode()

        let lockIcon = SKLabelNode(text: "🔒")
        lockIcon.fontSize = 44
        lockIcon.verticalAlignmentMode = .center
        lockIcon.position = CGPoint(x: 0, y: 20)
        node.addChild(lockIcon)

        let cond = SKLabelNode(text: condText)
        cond.fontName = "HiraginoSans-W4"
        cond.fontSize = 13
        cond.fontColor = UIColor(white: 0.85, alpha: 0.9)
        cond.verticalAlignmentMode = .center
        cond.position = CGPoint(x: 0, y: -24)
        node.addChild(cond)

        let hint = SKLabelNode(text: "解放条件")
        hint.fontName = "HiraginoSans-W3"
        hint.fontSize = 11
        hint.fontColor = UIColor(white: 0.6, alpha: 0.8)
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -42)
        node.addChild(hint)

        return node
    }

    private func refreshThumbs() {
        thumbContainer.removeAllChildren()
        let char  = chars[currentCharIdx]
        let gm    = GameManager.shared
        let thumbW: CGFloat = 70
        let thumbH: CGFloat = thumbW * (9.0 / 16.0)
        let gap:    CGFloat = 6
        let totalW = CGFloat(char.count) * (thumbW + gap) - gap
        let startX = max(thumbW / 2 + 8, (frame.width - totalW) / 2 + thumbW / 2)
        let thumbY: CGFloat = thumbBarH / 2

        for i in 0..<char.count {
            let unlocked = ZukanConditions.isImageUnlocked(charId: char.id, imageIndex: i, gm: gm)
            let tex   = SKTexture(imageNamed: "\(char.prefix)_\(i)")
            let thumb = SKSpriteNode(texture: tex, size: CGSize(width: thumbW, height: thumbH))
            thumb.position = CGPoint(x: startX + CGFloat(i) * (thumbW + gap), y: thumbY)
            thumb.name     = "thumb_\(i)"

            if !unlocked {
                // ロック: 暗くする
                thumb.color = UIColor.black
                thumb.colorBlendFactor = 0.7
                thumb.alpha = 0.5
            } else {
                thumb.alpha = i == currentImgIdx ? 1.0 : 0.5
            }
            thumbContainer.addChild(thumb)

            // 選択中のボーダー
            if i == currentImgIdx {
                let border = SKShapeNode(rectOf: CGSize(width: thumbW + 4, height: thumbH + 4), cornerRadius: 4)
                border.fillColor   = .clear
                border.strokeColor = unlocked
                    ? UIColor(red: 0.7, green: 0.4, blue: 1.0, alpha: 1.0)
                    : UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 0.8)
                border.lineWidth   = 2
                border.position    = thumb.position
                thumbContainer.addChild(border)
            }

            // ロックアイコン（サムネイル上）
            if !unlocked {
                let lk = SKLabelNode(text: "🔒")
                lk.fontSize = 14
                lk.verticalAlignmentMode = .center
                lk.position = CGPoint(x: startX + CGFloat(i) * (thumbW + gap), y: thumbY)
                lk.name = "thumb_\(i)"
                thumbContainer.addChild(lk)
            }
        }
    }

    private func refreshTabs() {
        for (i, node) in tabNodes.enumerated() {
            let hired = isCharHired(i)
            let active = i == currentCharIdx

            node.children.compactMap { $0 as? SKShapeNode }.forEach {
                if active {
                    $0.fillColor = UIColor(red: 0.25, green: 0.45, blue: 0.9, alpha: 0.9)
                } else if !hired {
                    $0.fillColor = UIColor(red: 0.12, green: 0.05, blue: 0.12, alpha: 1.0)
                } else {
                    $0.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 1.0)
                }
            }
            node.children.compactMap { $0 as? SKLabelNode }.forEach {
                if active {
                    $0.fontColor = .white
                    $0.text = chars[i].name
                } else if !hired {
                    $0.fontColor = UIColor(white: 0.35, alpha: 1.0)
                    $0.text = "🔒 " + chars[i].name
                } else {
                    $0.fontColor = UIColor(white: 0.6, alpha: 1.0)
                    $0.text = chars[i].name
                }
            }
        }
    }

    private func refreshSetBtn() {
        let char     = chars[currentCharIdx]
        let unlocked = isCurrentImageUnlocked()
        let isSet    = (GameManager.shared.selectedImageIndex[char.id] ?? 0) == currentImgIdx

        if !unlocked {
            setBtn.fillColor   = UIColor(red: 0.2, green: 0.1, blue: 0.2, alpha: 0.7)
            setBtn.strokeColor = UIColor(red: 0.5, green: 0.2, blue: 0.5, alpha: 0.5)
            setBtn.lineWidth   = 1.5
            setBtnLabel.text   = "🔒 " + ZukanConditions.conditionText(charId: char.id, imageIndex: currentImgIdx)
            setBtnLabel.fontSize = 12
        } else if isSet {
            setBtn.fillColor   = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 0.9)
            setBtn.strokeColor = UIColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 0.6)
            setBtn.lineWidth   = 1.5
            setBtnLabel.text   = "✅ この画像を設定中"
            setBtnLabel.fontSize = 14
        } else {
            setBtn.fillColor   = UIColor(red: 0.55, green: 0.2, blue: 0.8, alpha: 0.9)
            setBtn.strokeColor = UIColor(red: 0.9, green: 0.5, blue: 1.0, alpha: 0.6)
            setBtn.lineWidth   = 1.5
            setBtnLabel.text   = "✨ この画像をメインに設定"
            setBtnLabel.fontSize = 14
        }
    }

    // MARK: - タッチ

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        swipeStart = t.location(in: self)
        swipeTime  = t.timestamp
        didSwipe   = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let dx = t.location(in: self).x - swipeStart.x
        if abs(dx) > 30 { didSwipe = true }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        let dx  = loc.x - swipeStart.x
        let dy  = loc.y - swipeStart.y
        let dt  = t.timestamp - swipeTime

        // スワイプ（メイン画像エリア内のみ）
        if didSwipe && abs(dx) > abs(dy) && dt < 0.45 {
            let imgTop    = imgAreaY + mainImgNode.size.height / 2
            let imgBottom = imgAreaY - mainImgNode.size.height / 2
            if loc.y < imgTop + 20 && loc.y > imgBottom - 20 {
                let char = chars[currentCharIdx]
                if dx < 0 { currentImgIdx = min(currentImgIdx + 1, char.count - 1) }
                else       { currentImgIdx = max(currentImgIdx - 1, 0) }
                refreshMainImage()
                refreshThumbs()
                refreshSetBtn()
            }
            return
        }

        // タップ
        guard abs(dx) < 12 && abs(dy) < 12 else { return }
        for node in nodes(at: loc) {
            guard let name = node.name else { continue }
            if name == "backBtn" { goBack(); return }
            if name == "setBtn"  { setImage(); return }
            if name.hasPrefix("tab_"),
               let i = Int(name.dropFirst(4)) {
                loadChar(idx: i)
                return
            }
            if name.hasPrefix("thumb_"),
               let i = Int(name.dropFirst(6)) {
                currentImgIdx = i
                refreshMainImage()
                refreshThumbs()
                refreshSetBtn()
                return
            }
        }
    }

    // MARK: - アクション

    private func setImage() {
        guard isCurrentImageUnlocked() else {
            let char = chars[currentCharIdx]
            showToast("解放条件: \(ZukanConditions.conditionText(charId: char.id, imageIndex: currentImgIdx)) 🔒")
            return
        }
        let char = chars[currentCharIdx]
        GameManager.shared.setSelectedImage(charId: char.id, index: currentImgIdx)
        refreshSetBtn()

        // フラッシュ
        let flash = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.25), size: frame.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.zPosition = 50
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
    }

    private func goBack() {
        let scene = GameScene(size: frame.size)
        scene.scaleMode      = .resizeFill
        scene.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.1, alpha: 1.0)
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    // MARK: - トースト表示

    private func showToast(_ message: String) {
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width - 60, height: 40), cornerRadius: 10)
        bg.fillColor = UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7)
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = 100
        addChild(bg)

        let lbl = SKLabelNode(text: message)
        lbl.fontName = "HiraginoSans-W5"
        lbl.fontSize = 12
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.position = bg.position
        lbl.zPosition = 101
        addChild(lbl)

        let seq = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ])
        bg.run(seq)
        lbl.run(seq)
    }
}
