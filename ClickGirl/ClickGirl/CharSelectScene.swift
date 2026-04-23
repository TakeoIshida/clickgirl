import SpriteKit

class CharSelectScene: SKScene {

    private let gold   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
    private let darkBg = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1)
    private let gm     = GameManager.shared

    private var selectedCharId: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = darkBg
        selectedCharId  = gm.selectedImageIndex.keys.first ?? 0
        addTopBar()
        addCards()
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

        let title = SKLabelNode(text: "👤 メインキャラ選択")
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

        let hint = SKLabelNode(text: "解放済みキャラをメインに設定できます")
        hint.fontName  = "HiraginoSans-W3"
        hint.fontSize  = 11
        hint.fontColor = UIColor(white: 1, alpha: 0.40)
        hint.position  = CGPoint(x: frame.midX, y: frame.height - 62)
        addChild(hint)
    }

    // MARK: - カードグリッド
    private func addCards() {
        let employees = Employee.allEmployees.filter { $0.isHired }
        let allEmps   = Employee.allEmployees

        let cols: Int   = 3
        let pad:  CGFloat = 12
        let gap:  CGFloat = 8
        let cardW = (frame.width - pad * 2 - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let cardH = cardW * 1.52
        let topY  = frame.height - 78

        for (i, emp) in allEmps.enumerated() {
            let col = i % cols
            let row = i / cols
            let x   = pad + cardW * CGFloat(col) + gap * CGFloat(col) + cardW / 2
            let y   = topY - cardH * CGFloat(row) - gap * CGFloat(row) - cardH / 2

            let isHired    = emp.isHired
            let isSelected = emp.id == selectedCharId

            let card = makeCard(emp: emp, w: cardW, h: cardH,
                                isHired: isHired, isSelected: isSelected)
            card.position = CGPoint(x: x, y: y - 24)
            card.alpha    = 0
            addChild(card)

            card.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.055),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 24, duration: 0.25),
                    SKAction.fadeIn(withDuration: 0.25)
                ])
            ]))
        }
    }

    private func makeCard(emp: Employee, w: CGFloat, h: CGFloat,
                           isHired: Bool, isSelected: Bool) -> SKNode {
        let node = SKNode()
        node.name = "card_\(emp.id)"

        let fillCol   = isSelected ? UIColor(red: 0.10, green: 0.10, blue: 0.28, alpha: 1)
                                   : UIColor(red: 0.06, green: 0.06, blue: 0.18, alpha: 1)
        let strokeCol = isSelected ? gold
                      : isHired    ? UIColor(white: 1, alpha: 0.22)
                                   : UIColor(white: 1, alpha: 0.08)

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        bg.fillColor   = fillCol
        bg.strokeColor = strokeCol
        bg.lineWidth   = isSelected ? 2.5 : 1
        bg.name        = node.name
        node.addChild(bg)

        // 選択中グロー
        if isSelected {
            let glow = SKShapeNode(rectOf: CGSize(width: w + 8, height: h + 8), cornerRadius: 14)
            glow.fillColor   = .clear
            glow.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.32)
            glow.lineWidth   = 6
            glow.name        = node.name
            node.addChild(glow)
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.06, duration: 0.85),
                SKAction.fadeAlpha(to: 0.32, duration: 0.85)
            ])))
        }

        // キャラ画像 - UIImage でアスペクト比を正確に取得（SKTexture はシーン遷移直後にサイズ未取得のことがある）
        let imgIdx   = gm.selectedImageIndex[emp.id] ?? 0
        let imgName  = isHired ? emp.nobgImageName(at: imgIdx) : emp.imageNameNobg
        let tex      = SKTexture(imageNamed: imgName)

        let aspect: CGFloat
        if let uiImg = UIImage(named: imgName), uiImg.size.width > 0 {
            aspect = uiImg.size.height / uiImg.size.width
        } else {
            let ts = tex.size()
            aspect = ts.width > 0 ? ts.height / ts.width : 1.5
        }

        let maxImgW = w - 10
        let maxImgH = h * 0.62
        var imgW = maxImgW
        var imgH = imgW * aspect
        if imgH > maxImgH {
            imgH = maxImgH
            imgW = imgH / aspect
        }

        let img = SKSpriteNode(texture: tex, size: CGSize(width: imgW, height: imgH))
        img.position = CGPoint(x: 0, y: h * 0.08)
        img.alpha    = isHired ? 1.0 : 0.28
        img.name     = node.name
        node.addChild(img)

        // 未採用ロックアイコン
        if !isHired {
            let lock = SKLabelNode(text: "🔒")
            lock.fontSize = 22
            lock.verticalAlignmentMode = .center
            lock.position = CGPoint(x: 0, y: h * 0.08)
            lock.name     = node.name
            node.addChild(lock)
        }

        // 名前
        let name = SKLabelNode(text: emp.name)
        name.fontName  = "HiraginoSans-W6"
        name.fontSize  = min(w * 0.17, 14)
        name.fontColor = isSelected ? gold : isHired ? .white : UIColor(white: 1, alpha: 0.35)
        name.position  = CGPoint(x: 0, y: -h * 0.28)
        name.name      = node.name
        node.addChild(name)

        // 役職
        let role = SKLabelNode(text: emp.role)
        role.fontName  = "HiraginoSans-W3"
        role.fontSize  = min(w * 0.115, 10)
        role.fontColor = UIColor(white: 1, alpha: isHired ? 0.48 : 0.22)
        role.position  = CGPoint(x: 0, y: -h * 0.38)
        role.name      = node.name
        node.addChild(role)

        // 選択中バッジ
        if isSelected {
            let badge = SKShapeNode(rectOf: CGSize(width: w - 16, height: 18), cornerRadius: 9)
            badge.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.18)
            badge.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.5)
            badge.lineWidth   = 0.8
            badge.position    = CGPoint(x: 0, y: -h * 0.47)
            badge.name        = node.name
            node.addChild(badge)

            let badgeLbl = SKLabelNode(text: "✦  選択中  ✦")
            badgeLbl.fontName  = "HiraginoSans-W6"
            badgeLbl.fontSize  = 10
            badgeLbl.fontColor = gold
            badgeLbl.verticalAlignmentMode = .center
            badgeLbl.position  = CGPoint(x: 0, y: -h * 0.47)
            badgeLbl.name      = node.name
            node.addChild(badgeLbl)
        }

        return node
    }

    // MARK: - タップ処理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let name = atPoint(loc).name ?? ""

        if name == "backBtn" {
            let next = GameScene(size: size)
            next.scaleMode = scaleMode
            view?.presentScene(next, transition: SKTransition.push(with: .right, duration: 0.3))
            return
        }

        if name.hasPrefix("card_"), let id = Int(name.dropFirst(5)) {
            guard Employee.allEmployees.first(where: { $0.id == id })?.isHired == true else {
                showLockedToast()
                return
            }
            selectedCharId = id
            // GameManager に反映
            let imgIdx = gm.selectedImageIndex[id] ?? 0
            gm.selectedImageIndex = [id: imgIdx]
            gm.saveGame()

            // 再描画
            removeAllChildren()
            addTopBar()
            addCards()
        }
    }

    private func showLockedToast() {
        let toast = SKShapeNode(rectOf: CGSize(width: 220, height: 36), cornerRadius: 18)
        toast.fillColor   = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.85)
        toast.strokeColor = .clear
        toast.position    = CGPoint(x: frame.midX, y: 60)
        toast.alpha       = 0
        addChild(toast)

        let lbl = SKLabelNode(text: "先に採用してください")
        lbl.fontName  = "HiraginoSans-W3"
        lbl.fontSize  = 13
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        toast.addChild(lbl)

        toast.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))
    }
}
