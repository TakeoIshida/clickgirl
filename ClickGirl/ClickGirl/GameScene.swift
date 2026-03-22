import SpriteKit
import AVFoundation

class GameScene: SKScene {

    // MARK: - Nodes
    private var backgroundNode: SKSpriteNode!
    private var mainCharNode: SKSpriteNode!
    private var hudNode: HUDNode!
    private var employeePanel: EmployeePanelNode!
    private var officeChibiLayer: OfficeChibiLayer!
    private var tapHintLabel: SKLabelNode!
    private var offlinePopup: SKNode?
    private var bgmPlayer: AVAudioPlayer?

    // MARK: - State
    private let gm = GameManager.shared
    private var lastUpdateTime: TimeInterval = 0
    private var saveAccum: TimeInterval = 0
    private let saveInterval: TimeInterval = 30
    private var autoTapAccum: TimeInterval = 0
    private var mainCharImageName: String {
        gm.selectedNobgImageName(for: 0)
            .isEmpty ? "karen_4_nobg" : gm.selectedNobgImageName(for: 0)
    }

    // タッチ判別
    private var touchBegan: CGPoint = .zero
    private var touchBeganTime: TimeInterval = 0
    private let tapThreshold: CGFloat = 10
    private let tapTimeThreshold: TimeInterval = 0.3

    // コンボ
    private var comboCount: Int = 0
    private var comboAccum: TimeInterval = 0
    private let comboResetTime: TimeInterval = 0.85
    private var comboLabelNode: SKLabelNode?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.1, alpha: 1.0)
        setupBackground()
        setupMainCharacter()
        setupOfficeChiibis()
        setupHUD()
        setupEmployeePanel()
        setupNotifications()
        playBGM()

        if gm.pendingOfflineIncome > 0 {
            run(SKAction.wait(forDuration: 0.5)) { [weak self] in
                self?.showOfflinePopup(amount: self!.gm.pendingOfflineIncome)
                self?.gm.pendingOfflineIncome = 0
            }
        }
    }

    // 画像のアスペクト比を保ちながら指定サイズにアスペクトフィルするサイズを返す
    private func aspectFillSize(imageSize: CGSize, targetSize: CGSize) -> CGSize {
        let scaleX = targetSize.width  / imageSize.width
        let scaleY = targetSize.height / imageSize.height
        let scale  = max(scaleX, scaleY)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    // 画像のアスペクト比を保ちながら幅に合わせた高さを返す
    // UIImage を優先して使用（SKTexture はシーン遷移直後にサイズが未取得のことがある）
    private func heightForWidth(_ w: CGFloat, imageName: String) -> CGFloat {
        if let img = UIImage(named: imageName), img.size.width > 0 {
            return w * (img.size.height / img.size.width)
        }
        let s = SKTexture(imageNamed: imageName).size()
        guard s.width > 0 else { return w * 1.4 }   // fallback: 縦長比率
        return w * (s.height / s.width)
    }

    // 後方互換（bg_city など imageName を直接持たない場合）
    private func heightForWidth(_ w: CGFloat, texture: SKTexture) -> CGFloat {
        let s = texture.size()
        guard s.width > 0 else { return w * 1.4 }
        return w * (s.height / s.width)
    }

    private func setupBackground() {
        // 夜景背景（アスペクトフィルで画面全体を覆う）
        let bgTexture = SKTexture(imageNamed: "bg_city")
        backgroundNode = SKSpriteNode(texture: bgTexture)
        backgroundNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode.size = aspectFillSize(imageSize: bgTexture.size(), targetSize: frame.size)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)

        // 暗めオーバーレイ
        let overlay = SKSpriteNode(color: UIColor(red: 0.0, green: 0.0, blue: 0.08, alpha: 0.55),
                                   size: frame.size)
        overlay.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.zPosition = -9
        addChild(overlay)

        // 降り注ぐ星パーティクル
        addStarParticles()
    }

    private func addStarParticles() {
        for _ in 0..<30 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            star.fillColor = UIColor(white: 1.0, alpha: CGFloat.random(in: 0.4...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: 220...frame.height)
            )
            star.zPosition = -8
            addChild(star)

            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.1...0.3), duration: CGFloat.random(in: 0.8...2.5)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: CGFloat.random(in: 0.8...2.5))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    private func setupMainCharacter() {
        // メインタップキャラ - UIImage でアスペクト比を確実に取得
        let charTexture = SKTexture(imageNamed: mainCharImageName)

        // HUD(100pt) と 社員パネル(210pt) の間の中央に配置
        let availableTop: CGFloat    = frame.height - 120
        let availableBottom: CGFloat = 210
        let maxH = (availableTop - availableBottom) * 0.95

        var charW: CGFloat = frame.width * 0.85
        var charH: CGFloat = heightForWidth(charW, imageName: mainCharImageName)
        if charH > maxH {
            let ratio = charH / charW
            charH = maxH
            charW = charH / ratio
        }

        mainCharNode = SKSpriteNode(texture: charTexture)
        mainCharNode.size = CGSize(width: charW, height: charH)

        let centerY = availableBottom + (availableTop - availableBottom) / 2
        mainCharNode.position = CGPoint(x: frame.midX, y: centerY)
        mainCharNode.zPosition = 2
        mainCharNode.name = "mainChar"
        addChild(mainCharNode)

        // ふわふわアイドルアニメ
        let bobUp   = SKAction.moveBy(x: 0, y: 7, duration: 1.6)
        let bobDown = bobUp.reversed()
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        mainCharNode.run(SKAction.repeatForever(SKAction.sequence([bobUp, bobDown])))

        // タップヒント
        tapHintLabel = SKLabelNode(text: "👆 タップして売上を稼ごう！")
        tapHintLabel.fontName = "HiraginoSans-W5"
        tapHintLabel.fontSize = 15
        tapHintLabel.fontColor = UIColor(white: 0.9, alpha: 0.85)
        tapHintLabel.position = CGPoint(x: frame.midX, y: centerY - charH / 2 - 14)
        tapHintLabel.zPosition = 3
        addChild(tapHintLabel)

        let fadeSeq = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.25, duration: 1.2),
            SKAction.fadeAlpha(to: 0.85, duration: 1.2)
        ])
        tapHintLabel.run(SKAction.repeatForever(fadeSeq))

        // グロウリング
        let glow = SKShapeNode(circleOfRadius: charW * 0.36)
        glow.fillColor = .clear
        glow.strokeColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.18)
        glow.lineWidth = 18
        glow.position = CGPoint(x: frame.midX, y: mainCharNode.position.y - charH * 0.1)
        glow.zPosition = 1
        addChild(glow)
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.05, duration: 1.8),
            SKAction.fadeAlpha(to: 0.25, duration: 1.8)
        ])
        glow.run(SKAction.repeatForever(glowPulse))
    }

    private func setupHUD() {
        hudNode = HUDNode(width: frame.width)
        hudNode.position = CGPoint(x: 0, y: frame.height - 120)
        hudNode.zPosition = 10
        addChild(hudNode)
        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)
    }

    private func setupOfficeChiibis() {
        officeChibiLayer = OfficeChibiLayer(sceneWidth: frame.width)
        // 社員パネル(210pt) 直上に layerH 分の領域を確保
        let layerH = officeChibiLayer.layerH
        officeChibiLayer.position = CGPoint(x: 0, y: 210)
        officeChibiLayer.zPosition = 1
        addChild(officeChibiLayer)
        officeChibiLayer.refresh(employees: gm.employees)
        _ = layerH
    }

    private func setupEmployeePanel() {
        let panelH: CGFloat = 210
        employeePanel = EmployeePanelNode(width: frame.width)
        employeePanel.position = CGPoint(x: 0, y: 0)
        employeePanel.zPosition = 10
        addChild(employeePanel)
        employeePanel.onEmployeeTap = { [weak self] id, area in
            self?.handleEmployeeTap(id: id, area: area)
        }
        _ = panelH
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc private func appResignActive() {
        gm.saveGame()
    }

    private func playBGM() {
        guard let url = Bundle.main.url(forResource: "雨の曲", withExtension: "mp3") else { return }
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.volume = 0.4
        bgmPlayer?.play()
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchBegan = touch.location(in: self)
        touchBeganTime = touch.timestamp
        employeePanel.handleTouchBegan(
            touch.location(in: employeePanel),
            at: touch.timestamp
        )
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        employeePanel.handleTouchMoved(
            touch.location(in: employeePanel),
            at: touch.timestamp
        )
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let dt = touch.timestamp - touchBeganTime
        let dist = hypot(loc.x - touchBegan.x, loc.y - touchBegan.y)

        employeePanel.handleTouchEnded(touch.location(in: employeePanel), at: touch.timestamp)

        guard dist < tapThreshold && dt < tapTimeThreshold else { return }

        // オフラインポップアップを閉じる
        if let popup = offlinePopup {
            popup.run(SKAction.sequence([
                SKAction.scale(to: 0, duration: 0.2),
                SKAction.removeFromParent()
            ]))
            offlinePopup = nil
            return
        }

        // HUD ボタン
        for node in nodes(at: loc) {
            if node.name == "zukanBtn"  { openZukan();  return }
            if node.name == "shopBtn"   { openShop();   return }
            if node.name == "officeBtn" { openOffice(); return }
            if node.name == "gachaBtn"  { openGacha();  return }
        }

        // パネル内タップ → キャラ切替 or 採用/UP
        let panelLoc = touch.location(in: employeePanel)
        if panelLoc.y >= 0 && panelLoc.y <= 210 {
            if let result = employeePanel.tapCard(at: panelLoc) {
                handleEmployeeTap(id: result.id, area: result.area)
            }
            return
        }

        // メインキャラタップ
        handleMainTap(at: loc)
    }

    private func openShop() {
        gm.saveGame()
        let scene = ShopScene(size: frame.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func openOffice() {
        gm.saveGame()
        let scene = OfficeScene(size: frame.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func openZukan() {
        gm.saveGame()
        let scene = ZukanScene(size: frame.size)
        scene.scaleMode      = .resizeFill
        scene.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0)
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func openGacha() {
        gm.saveGame()
        let scene = GachaScene(size: frame.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    // MARK: - Game Actions

    private func handleMainTap(at loc: CGPoint) {
        comboCount += 1
        comboAccum = 0

        let baseTap = gm.tap()

        // コンボボーナス: +10% × (combo-1)、最大+100%
        let comboBonus: Double
        if comboCount > 1 {
            let ratio = min(Double(comboCount - 1) * 0.1, 1.0)
            comboBonus = baseTap * ratio
            gm.money += comboBonus
            gm.totalEarned += comboBonus
        } else {
            comboBonus = 0
        }

        animateMainCharTap()
        showFloatingMoney(baseTap + comboBonus, at: loc)
        spawnCoins(at: loc, count: min(3 + comboCount, 12))
        updateComboDisplay()
        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)
    }

    private func updateComboDisplay() {
        comboLabelNode?.removeFromParent()

        guard comboCount >= 2 else {
            comboLabelNode = nil
            return
        }

        let multiplier = 1.0 + min(Double(comboCount - 1) * 0.1, 1.0)
        let label = SKLabelNode(text: "COMBO ×\(comboCount)  ×\(String(format: "%.1f", multiplier))")
        label.fontName = "HiraginoSans-W8"
        label.fontSize = comboCount >= 10 ? 24 : 18
        label.fontColor = comboCount >= 10
            ? UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            : comboCount >= 5
            ? UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: frame.height * 0.705)
        label.zPosition = 22

        // 影
        let shadow = SKLabelNode(text: label.text!)
        shadow.fontName = label.fontName
        shadow.fontSize = label.fontSize
        shadow.fontColor = UIColor(red: 0.3, green: 0.2, blue: 0.0, alpha: 0.5)
        shadow.position = CGPoint(x: 2, y: -2)
        label.addChild(shadow)

        label.setScale(1.35)
        label.run(SKAction.scale(to: 1.0, duration: 0.1))
        addChild(label)
        comboLabelNode = label
    }

    private func animateMainCharTap() {
        mainCharNode.removeAction(forKey: "tapAnim")
        let seq = SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.06),
            SKAction.scale(to: 0.97, duration: 0.08),
            SKAction.scale(to: 1.00, duration: 0.08)
        ])
        mainCharNode.run(seq, withKey: "tapAnim")
    }

    private func handleEmployeeTap(id: Int, area: CardTapArea) {
        let emp = gm.employees.first(where: { $0.id == id })!

        if emp.isHired && area == .character {
            // キャラ画像エリアタップ → メインキャラ切替
            let nobgName = emp.imageNameNobg
            let safeName = UIImage(named: nobgName) != nil ? nobgName : emp.imageName
            switchMainChar(to: safeName, name: emp.name)
            return
        }

        // ボタンエリアタップ → 採用 / レベルアップ
        let success: Bool
        if emp.isHired {
            success = gm.upgrade(id: id)
            if success {
                let newLevel = gm.employees.first(where: { $0.id == id })!.level
                showLevelUpEffect(newLevel: newLevel)
            }
        } else {
            success = gm.hire(id: id)
            if success { showHireEffect(name: gm.employees.first(where: { $0.id == id })!.name) }
        }
        if success {
            employeePanel.refresh()
            hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)
        } else {
            showNotEnoughMoneyEffect()
        }
    }

    private func switchMainChar(to imageName: String, name: String) {

        // フェードアウト → テクスチャ差替 → フェードイン
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let swap = SKAction.run { [weak self] in
            guard let self = self else { return }
            let newTex = SKTexture(imageNamed: imageName)
            self.mainCharNode.texture = newTex
            // UIImage でアスペクト比を確実に取得
            let w = self.mainCharNode.size.width
            let h = self.heightForWidth(w, imageName: imageName)
            self.mainCharNode.size = CGSize(width: w, height: h)
        }
        let fadeIn  = SKAction.fadeAlpha(to: 1, duration: 0.25)
        mainCharNode.run(SKAction.sequence([fadeOut, swap, fadeIn]))

        // 「〇〇に切り替えました」通知
        showSwitchLabel(name: name)
    }

    private func showSwitchLabel(name: String) {
        let label = SKLabelNode(text: "✨ \(name) に切り替えました")
        label.fontName = "HiraginoSans-W6"
        label.fontSize = 16
        label.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: frame.height - 130)
        label.zPosition = 25
        label.setScale(0.8)
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.fadeIn(withDuration: 0.15)
            ]),
            SKAction.wait(forDuration: 1.2),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.moveBy(x: 0, y: 20, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Animations

    private func showFloatingMoney(_ amount: Double, at pos: CGPoint) {
        let text = "+¥\(formatMoney(amount))"
        let label = SKLabelNode(text: text)
        label.fontName = "HiraginoSans-W8"
        label.fontSize = 26
        label.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.15, alpha: 1.0)
        label.position = pos
        label.zPosition = 20

        // 影
        let shadow = SKLabelNode(text: text)
        shadow.fontName = label.fontName
        shadow.fontSize = label.fontSize
        shadow.fontColor = UIColor(red: 0.4, green: 0.35, blue: 0.0, alpha: 0.6)
        shadow.position = CGPoint(x: 2, y: -2)
        label.addChild(shadow)
        addChild(label)

        let drift = CGFloat.random(in: -25...25)
        let move = SKAction.moveBy(x: drift, y: 110, duration: 1.1)
        move.timingMode = .easeOut
        let fadeOut = SKAction.sequence([SKAction.wait(forDuration: 0.45), SKAction.fadeOut(withDuration: 0.65)])
        let scaleDown = SKAction.sequence([SKAction.wait(forDuration: 0.5), SKAction.scale(to: 0.8, duration: 0.6)])
        label.run(SKAction.sequence([SKAction.group([move, fadeOut, scaleDown]), SKAction.removeFromParent()]))
    }

    private func spawnCoins(at pos: CGPoint, count: Int) {
        for _ in 0..<count {
            let coin = SKShapeNode(circleOfRadius: 7)
            coin.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
            coin.strokeColor = UIColor(red: 0.7, green: 0.55, blue: 0.0, alpha: 1.0)
            coin.lineWidth = 1.5
            coin.position = pos
            coin.zPosition = 15
            addChild(coin)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let spd = CGFloat.random(in: 70...160)
            let move = SKAction.moveBy(x: cos(angle) * spd, y: sin(angle) * spd, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.3)])
            let shrink = SKAction.scale(to: 0.2, duration: 0.5)
            coin.run(SKAction.sequence([
                SKAction.group([move, fade, shrink]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showLevelUpEffect(newLevel: Int) {
        let centerX = frame.midX
        let originY: CGFloat = 150  // 社員パネル付近

        // 光の柱
        let pillarH: CGFloat = frame.height * 0.55
        let pillar = SKSpriteNode(
            color: UIColor(red: 1.0, green: 0.88, blue: 0.25, alpha: 0.5),
            size: CGSize(width: 10, height: pillarH)
        )
        pillar.position = CGPoint(x: centerX, y: originY + pillarH / 2)
        pillar.zPosition = 18
        addChild(pillar)
        pillar.run(SKAction.sequence([
            SKAction.group([
                SKAction.scaleX(to: 8, duration: 0.55),
                SKAction.fadeOut(withDuration: 0.55)
            ]),
            SKAction.removeFromParent()
        ]))

        // 拡散リング
        for i in 0..<4 {
            let ring = SKShapeNode(circleOfRadius: 18)
            ring.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.75)
            ring.lineWidth = 2.5
            ring.fillColor = .clear
            ring.position = CGPoint(x: centerX, y: originY)
            ring.zPosition = 17
            addChild(ring)
            ring.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.08),
                SKAction.group([
                    SKAction.scale(to: 5.5 + CGFloat(i) * 0.8, duration: 0.48),
                    SKAction.fadeOut(withDuration: 0.48)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Lv.N↑ ラベル
        let lvLabel = SKLabelNode(text: "Lv.\(newLevel) UP！")
        lvLabel.fontName = "HiraginoSans-W8"
        lvLabel.fontSize = 26
        lvLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        lvLabel.position = CGPoint(x: centerX, y: 250)
        lvLabel.zPosition = 25
        lvLabel.setScale(0.4)
        addChild(lvLabel)
        lvLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.15, duration: 0.18),
                SKAction.fadeIn(withDuration: 0.18)
            ]),
            SKAction.scale(to: 1.0, duration: 0.08),
            SKAction.wait(forDuration: 1.0),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.45),
                SKAction.moveBy(x: 0, y: 35, duration: 0.45)
            ]),
            SKAction.removeFromParent()
        ]))

        // ゴールドのキラ粒子
        for _ in 0..<16 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            spark.fillColor = UIColor(
                red: CGFloat.random(in: 0.9...1.0),
                green: CGFloat.random(in: 0.7...0.95),
                blue: 0,
                alpha: 1.0
            )
            spark.strokeColor = .clear
            spark.position = CGPoint(x: centerX, y: originY)
            spark.zPosition = 19
            addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...200)
            let move = SKAction.moveBy(x: cos(angle) * speed, y: sin(angle) * speed, duration: 0.55)
            move.timingMode = .easeOut
            let fade = SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.35)])
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    private func showHireEffect(name: String) {
        let label = SKLabelNode(text: "🎉 \(name) が入社しました！")
        label.fontName = "HiraginoSans-W6"
        label.fontSize = 20
        label.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: frame.midY + 80)
        label.zPosition = 25
        label.setScale(0)
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.5),
            SKAction.group([SKAction.fadeOut(withDuration: 0.5), SKAction.moveBy(x: 0, y: 30, duration: 0.5)]),
            SKAction.removeFromParent()
        ]))

        // 紙吹雪
        for _ in 0..<20 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 2)
            let colors: [UIColor] = [.systemPink, .systemYellow, .systemCyan, .systemGreen, .white]
            confetti.fillColor = colors.randomElement()!
            confetti.strokeColor = .clear
            confetti.position = CGPoint(x: CGFloat.random(in: 60...frame.width - 60),
                                        y: frame.height - 120)
            confetti.zPosition = 24
            confetti.zRotation = CGFloat.random(in: 0...(.pi * 2))
            addChild(confetti)

            let fall = SKAction.moveBy(x: CGFloat.random(in: -60...60), y: -frame.height * 0.6, duration: CGFloat.random(in: 1.5...3.0))
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: 3...10), duration: 2.0)
            let fade = SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.fadeOut(withDuration: 1.5)])
            confetti.run(SKAction.sequence([
                SKAction.group([fall, spin, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showNotEnoughMoneyEffect() {
        let label = SKLabelNode(text: "💸 お金が足りません")
        label.fontName = "HiraginoSans-W5"
        label.fontSize = 16
        label.fontColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: 230)
        label.zPosition = 25
        addChild(label)

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
        ])
        label.run(SKAction.sequence([
            shake,
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }

    private func showOfflinePopup(amount: Double) {
        let popup = SKNode()
        popup.zPosition = 50
        popup.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(popup)

        let bg = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 22)
        bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.18, alpha: 0.97)
        bg.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.9)
        bg.lineWidth = 2
        popup.addChild(bg)

        let charNode = SKSpriteNode(imageNamed: mainCharImageName)
        charNode.size = CGSize(width: 90, height: 110)
        charNode.position = CGPoint(x: 95, y: 35)
        popup.addChild(charNode)

        let title = SKLabelNode(text: "おかえりなさい！")
        title.fontName = "HiraginoSans-W6"
        title.fontSize = 18
        title.fontColor = .white
        title.position = CGPoint(x: -20, y: 70)
        popup.addChild(title)

        let amtLabel = SKLabelNode(text: "¥\(formatMoney(amount)) 獲得！")
        amtLabel.fontName = "HiraginoSans-W8"
        amtLabel.fontSize = 22
        amtLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        amtLabel.position = CGPoint(x: -20, y: 35)
        popup.addChild(amtLabel)

        let sub = SKLabelNode(text: "放置中に社員が稼いでくれました")
        sub.fontName = "HiraginoSans-W3"
        sub.fontSize = 12
        sub.fontColor = .lightGray
        sub.position = CGPoint(x: -20, y: 5)
        popup.addChild(sub)

        let hint = SKLabelNode(text: "タップで閉じる")
        hint.fontName = "HiraginoSans-W3"
        hint.fontSize = 13
        hint.fontColor = UIColor(white: 0.5, alpha: 1.0)
        hint.position = CGPoint(x: 0, y: -75)
        popup.addChild(hint)
        let blinkHint = SKAction.sequence([SKAction.fadeAlpha(to: 0.2, duration: 0.8), SKAction.fadeAlpha(to: 1.0, duration: 0.8)])
        hint.run(SKAction.repeatForever(blinkHint))

        popup.setScale(0)
        popup.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
        offlinePopup = popup
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let delta = min(currentTime - lastUpdateTime, 0.05)
        lastUpdateTime = currentTime

        gm.money += gm.totalIncomePerSec * delta
        gm.totalEarned += gm.totalIncomePerSec * delta

        // 自動タップ (shop upgrade)
        if gm.hasUpgrade("auto_tap") {
            autoTapAccum += delta
            while autoTapAccum >= 1.0 {
                autoTapAccum -= 1.0
                gm.tap()
            }
        }

        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)

        officeChibiLayer.refresh(employees: gm.employees)
        employeePanel.applyInertia()
        employeePanel.updateProgressBars(money: gm.money)

        // コンボタイムアウト
        if comboCount > 0 {
            comboAccum += delta
            if comboAccum >= comboResetTime {
                comboCount = 0
                comboAccum = 0
                comboLabelNode?.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.25),
                    SKAction.removeFromParent()
                ]))
                comboLabelNode = nil
            }
        }

        saveAccum += delta
        if saveAccum >= saveInterval {
            saveAccum = 0
            gm.saveGame()
        }
    }

    // MARK: - Helpers

    private func formatMoney(_ v: Double) -> String {
        if v >= 1_000_000_000_000 { return String(format: "%.2f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000      { return String(format: "%.2f億", v / 100_000_000) }
        if v >= 10_000           { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
