import SpriteKit

// MARK: - 真上から見たオフィスレイヤー

class OfficeChibiLayer: SKNode {

    private let sceneWidth: CGFloat
    let layerH: CGFloat = 120          // 表示高さ（GameScene で使用）

    // デスク配置（5キャラ対応: 上段3・下段2）
    private lazy var deskSlots: [CGPoint] = [
        CGPoint(x: sceneWidth * 0.15, y: layerH * 0.78),
        CGPoint(x: sceneWidth * 0.38, y: layerH * 0.78),
        CGPoint(x: sceneWidth * 0.62, y: layerH * 0.78),
        CGPoint(x: sceneWidth * 0.85, y: layerH * 0.78),
        CGPoint(x: sceneWidth * 0.50, y: layerH * 0.30),
    ]

    // キャラの歩行可能範囲
    private var walkBounds: CGRect {
        CGRect(x: 12, y: 10, width: sceneWidth - 24, height: layerH - 20)
    }

    private var chibiNodes: [Int: TopDownChiib] = [:]

    init(sceneWidth: CGFloat) {
        self.sceneWidth = sceneWidth
        super.init()
        buildOffice()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - 上面視オフィス背景

    private func buildOffice() {
        // ── 床ベース ──
        let floorBg = SKShapeNode(rectOf: CGSize(width: sceneWidth, height: layerH))
        floorBg.fillColor = UIColor(red: 0.09, green: 0.09, blue: 0.20, alpha: 0.92)
        floorBg.strokeColor = UIColor(red: 0.25, green: 0.3, blue: 0.6, alpha: 0.5)
        floorBg.lineWidth = 1
        floorBg.position = CGPoint(x: sceneWidth / 2, y: layerH / 2)
        floorBg.zPosition = 0
        addChild(floorBg)

        // タイルグリッド
        let tileSize: CGFloat = 20
        let cols = Int(sceneWidth / tileSize) + 1
        let rows = Int(layerH / tileSize) + 1
        for c in 0...cols {
            let l = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.04),
                                 size: CGSize(width: 0.6, height: layerH))
            l.position = CGPoint(x: CGFloat(c) * tileSize, y: layerH / 2)
            l.zPosition = 1
            addChild(l)
        }
        for r in 0...rows {
            let l = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.04),
                                 size: CGSize(width: sceneWidth, height: 0.6))
            l.position = CGPoint(x: sceneWidth / 2, y: CGFloat(r) * tileSize)
            l.zPosition = 1
            addChild(l)
        }

        // 中央カーペット（通路）
        let carpet = SKShapeNode(rectOf: CGSize(width: sceneWidth - 60, height: 30), cornerRadius: 4)
        carpet.fillColor = UIColor(red: 0.12, green: 0.12, blue: 0.32, alpha: 0.55)
        carpet.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.7, alpha: 0.2)
        carpet.lineWidth = 0.5
        carpet.position = CGPoint(x: sceneWidth / 2, y: layerH * 0.34)
        carpet.zPosition = 1
        addChild(carpet)

        // デスク群
        for pt in deskSlots { addTopDownDesk(at: pt) }

        // 観葉植物
        addPlant(at: CGPoint(x: 10, y: layerH - 8))
        addPlant(at: CGPoint(x: sceneWidth - 10, y: layerH - 8))
    }

    // MARK: 真上視デスク

    private func addTopDownDesk(at pos: CGPoint) {
        let dW: CGFloat = 46, dH: CGFloat = 22

        // 机面
        let desk = SKShapeNode(rectOf: CGSize(width: dW, height: dH), cornerRadius: 2)
        desk.fillColor = UIColor(red: 0.38, green: 0.26, blue: 0.15, alpha: 0.88)
        desk.strokeColor = UIColor(red: 0.55, green: 0.40, blue: 0.22, alpha: 0.55)
        desk.lineWidth = 1
        desk.position = pos
        desk.zPosition = 3
        addChild(desk)

        // モニター（上端）
        let mon = SKShapeNode(rectOf: CGSize(width: 18, height: 11), cornerRadius: 2)
        mon.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.22, alpha: 0.95)
        mon.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.9, alpha: 0.55)
        mon.lineWidth = 1
        mon.position = CGPoint(x: pos.x, y: pos.y + dH / 2 - 5)
        mon.zPosition = 4
        addChild(mon)

        // スクリーン光
        let colors: [UIColor] = [
            UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.65),
            UIColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.65),
            UIColor(red: 0.9, green: 0.5, blue: 0.9, alpha: 0.65),
        ]
        let scr = SKShapeNode(rectOf: CGSize(width: 12, height: 7))
        scr.fillColor = colors.randomElement()!
        scr.strokeColor = .clear
        scr.position = CGPoint(x: pos.x, y: pos.y + dH / 2 - 5)
        scr.zPosition = 5
        addChild(scr)
        let glow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 1.2),
            SKAction.fadeAlpha(to: 0.85, duration: 1.2)
        ])
        scr.run(SKAction.repeatForever(glow))

        // キーボード（机中央）
        let kb = SKShapeNode(rectOf: CGSize(width: 14, height: 7), cornerRadius: 1)
        kb.fillColor = UIColor(red: 0.18, green: 0.18, blue: 0.32, alpha: 0.82)
        kb.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.55, alpha: 0.3)
        kb.lineWidth = 0.5
        kb.position = CGPoint(x: pos.x, y: pos.y - 1)
        kb.zPosition = 4
        addChild(kb)

        // コーヒーカップ（机右端）
        let cup = SKShapeNode(circleOfRadius: 3.5)
        cup.fillColor = UIColor(red: 0.55, green: 0.3, blue: 0.08, alpha: 0.88)
        cup.strokeColor = UIColor(red: 0.7, green: 0.4, blue: 0.15, alpha: 0.5)
        cup.lineWidth = 0.5
        cup.position = CGPoint(x: pos.x + dW / 2 - 7, y: pos.y - dH / 2 + 5)
        cup.zPosition = 4
        addChild(cup)

        // 椅子（机の下側）
        let chair = SKShapeNode(circleOfRadius: 8)
        chair.fillColor = UIColor(red: 0.18, green: 0.18, blue: 0.32, alpha: 0.8)
        chair.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.55, alpha: 0.5)
        chair.lineWidth = 1
        chair.position = CGPoint(x: pos.x, y: pos.y - dH / 2 - 10)
        chair.zPosition = 3
        addChild(chair)

        // 椅子背もたれ
        let back = SKShapeNode(rectOf: CGSize(width: 14, height: 4), cornerRadius: 2)
        back.fillColor = UIColor(red: 0.14, green: 0.14, blue: 0.28, alpha: 0.9)
        back.strokeColor = .clear
        back.position = CGPoint(x: pos.x, y: pos.y - dH / 2 - 3)
        back.zPosition = 4
        addChild(back)
    }

    // MARK: 観葉植物（上面）

    private func addPlant(at pos: CGPoint) {
        let pot = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
        pot.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.12, alpha: 0.85)
        pot.strokeColor = .clear
        pot.position = pos
        pot.zPosition = 3
        addChild(pot)

        let leafAngles: [Double] = [0, 1.2, 2.5, 3.8, 5.1]
        for angle in leafAngles {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 8, height: 5))
            leaf.fillColor = UIColor(red: 0.18, green: 0.58, blue: 0.22, alpha: 0.82)
            leaf.strokeColor = UIColor(red: 0.1, green: 0.4, blue: 0.12, alpha: 0.4)
            leaf.lineWidth = 0.5
            leaf.zRotation = CGFloat(angle)
            leaf.position = CGPoint(x: pos.x + cos(CGFloat(angle)) * 5,
                                    y: pos.y + sin(CGFloat(angle)) * 4)
            leaf.zPosition = 4
            addChild(leaf)
        }
    }

    // MARK: - Chibi 更新

    func refresh(employees: [Employee]) {
        let hiredIds = Set(employees.filter { $0.isHired }.map { $0.id })

        for (id, worker) in chibiNodes where !hiredIds.contains(id) {
            worker.dismiss { worker.removeFromParent() }
            chibiNodes.removeValue(forKey: id)
        }

        for emp in employees where emp.isHired {
            guard chibiNodes[emp.id] == nil else { continue }
            let home = deskSlots.indices.contains(emp.id)
                ? deskSlots[emp.id]
                : CGPoint(x: sceneWidth / 2, y: CGFloat(30 + emp.id * 20))
            let w = TopDownChiib(emp: emp, bounds: walkBounds, home: home)
            w.position = home
            w.alpha = 0
            addChild(w)
            w.run(SKAction.fadeIn(withDuration: 0.5))
            chibiNodes[emp.id] = w
            w.startBehavior()
        }
    }
}

// MARK: - 真上視キャラ（ドット表示）

private class TopDownChiib: SKNode {

    let emp: Employee
    private let walkArea: CGRect
    private let home: CGPoint
    private var balloon: SKNode?

    // デフォルメキャラの表示サイズ（縦長画像 784×1176 に合わせて縮小）
    private let chibiW: CGFloat = 36
    private var chibiH: CGFloat = 24

    init(emp: Employee, bounds: CGRect, home: CGPoint) {
        self.emp = emp
        self.walkArea = bounds
        self.home = home
        super.init()
        buildChibi()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: デフォルメキャラ組み立て

    private func buildChibi() {
        let imgName = GameManager.shared.selectedNobgImageName(for: emp.id)
        let nobgName = imgName.isEmpty ? "\(emp.charPrefix)_0_nobg" : imgName
        let selectedIdx = GameManager.shared.selectedImageIndex[emp.id] ?? 0
        // nobg 画像が存在しない場合は通常画像にフォールバック
        let texName = UIImage(named: nobgName) != nil ? nobgName : "\(emp.charPrefix)_\(selectedIdx)"
        let tex = SKTexture(imageNamed: texName)

        // UIImage でアスペクト比を確実に取得（SKTexture はシーン復帰直後にサイズ未取得の場合あり）
        let ratio: CGFloat
        if let img = UIImage(named: texName), img.size.width > 0 {
            ratio = img.size.height / img.size.width
        } else {
            let s = tex.size()
            ratio = s.width > 0 ? s.height / s.width : 1.4
        }
        chibiH = max(chibiW * ratio, 20)

        // 足元の楕円影
        let shadow = SKShapeNode(ellipseOf: CGSize(width: chibiW * 0.75, height: 5))
        shadow.fillColor = UIColor(white: 0, alpha: 0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: 1)
        shadow.zPosition = 1
        addChild(shadow)

        // キャラクタースプライト（縦に少し伸ばしてデフォルメ感を強調）
        let sprite = SKSpriteNode(texture: tex,
                                  size: CGSize(width: chibiW, height: chibiH * 1.35))
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        sprite.position = CGPoint(x: 0, y: 2)
        sprite.name = "chibiSprite"
        sprite.zPosition = 5
        addChild(sprite)

        // 名前タグ（足元）
        let tag = SKLabelNode(text: emp.name)
        tag.fontName = "HiraginoSans-W5"
        tag.fontSize = 7
        tag.fontColor = UIColor(white: 0.95, alpha: 0.82)
        tag.verticalAlignmentMode = .top
        tag.position = CGPoint(x: 0, y: 1)
        tag.zPosition = 7
        addChild(tag)
    }

    // MARK: 入退場

    func dismiss(completion: @escaping () -> Void) {
        removeAllActions()
        run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 0.3, duration: 0.35)
            ]),
            SKAction.run(completion)
        ]))
    }

    // MARK: 行動ループ

    func startBehavior() {
        scheduleNext(after: Double.random(in: 0.5...2.5))
    }

    private func scheduleNext(after delay: Double) {
        run(SKAction.wait(forDuration: delay)) { [weak self] in
            self?.chooseAction()
        }
    }

    private func chooseAction() {
        guard parent != nil else { return }
        switch Int.random(in: 0...6) {
        case 0, 1, 2:
            walkToRandom()
        case 3:
            walkTo(dest: home) { [weak self] in    // デスクに戻る
                self?.showBalloon(from: ["💻", "⌨️", "📊"].randomElement()!, duration: 1.6)
                self?.scheduleNext(after: 2.5)
            }
        case 4:
            showBalloon(from: ["💡", "🤔", "😊"].randomElement()!, duration: 1.4)
            scheduleNext(after: 2.2)
        default:
            scheduleNext(after: Double.random(in: 1.0...2.5))
        }
    }

    // MARK: 移動（2D）

    private func walkToRandom() {
        let tx = CGFloat.random(in: walkArea.minX...walkArea.maxX)
        let ty = CGFloat.random(in: walkArea.minY...walkArea.maxY)
        walkTo(dest: CGPoint(x: tx, y: ty)) { [weak self] in
            self?.scheduleNext(after: Double.random(in: 0.8...3.0))
        }
    }

    private func walkTo(dest: CGPoint, completion: @escaping () -> Void) {
        let dist = hypot(dest.x - position.x, dest.y - position.y)
        let dur  = Double(dist / 65)

        // スプライトを進行方向に向ける
        if abs(dest.x - position.x) > 4 {
            if let sprite = childNode(withName: "chibiSprite") as? SKSpriteNode {
                sprite.xScale = dest.x < position.x ? -1 : 1
            }
        }

        // 歩きボブ（上下に細かく揺れる）
        let bob = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 1.2, duration: 0.12),
            SKAction.moveBy(x: 0, y: -1.2, duration: 0.12)
        ]))
        run(bob, withKey: "walkBob")

        let move = SKAction.move(to: dest, duration: max(dur, 0.3))
        move.timingMode = .easeInEaseOut
        run(move) { [weak self] in
            self?.removeAction(forKey: "walkBob")
            completion()
        }
    }

    // MARK: 吹き出し

    private func showBalloon(from text: String, duration: Double) {
        balloon?.removeFromParent()
        let b = SKNode()
        b.zPosition = 20

        let bg = SKShapeNode(rectOf: CGSize(width: 20, height: 20), cornerRadius: 5)
        bg.fillColor = UIColor(white: 1.0, alpha: 0.88)
        bg.strokeColor = UIColor(white: 0.6, alpha: 0.5)
        bg.lineWidth = 0.8
        b.addChild(bg)

        let lbl = SKLabelNode(text: text)
        lbl.fontSize = 12
        lbl.verticalAlignmentMode = .center
        b.addChild(lbl)

        b.position = CGPoint(x: 12, y: 18)
        b.setScale(0)
        addChild(b)
        balloon = b

        b.run(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.14),
            SKAction.scale(to: 1.0,  duration: 0.07),
            SKAction.wait(forDuration: duration),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.28),
                SKAction.moveBy(x: 0, y: 6, duration: 0.28)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
