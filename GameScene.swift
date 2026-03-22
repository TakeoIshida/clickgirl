import SpriteKit
import AVFoundation

class GameScene: SKScene {

    // MARK: - Nodes
    private var backgroundNode: SKSpriteNode!
    private var mainCharNode: SKSpriteNode!
    private var hudNode: HUDNode!
    private var employeePanel: EmployeePanelNode!
    private var tapHintLabel: SKLabelNode!
    private var offlinePopup: SKNode?
    private var bgmPlayer: AVAudioPlayer?

    // MARK: - State
    private let gm = GameManager.shared
    private var lastUpdateTime: TimeInterval = 0
    private var saveAccum: TimeInterval = 0
    private let saveInterval: TimeInterval = 30

    // タッチ判別
    private var touchBegan: CGPoint = .zero
    private var touchBeganTime: TimeInterval = 0
    private let tapThreshold: CGFloat = 10
    private let tapTimeThreshold: TimeInterval = 0.3

    // MARK: - Setup

    override func didMove(to view: SKView) {
        setupBackground()
        setupMainCharacter()
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

    private func setupBackground() {
        // 夜景背景
        backgroundNode = SKSpriteNode(imageNamed: "bg_city")
        backgroundNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode.size = frame.size
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
        // メインタップキャラ（さくら）
        mainCharNode = SKSpriteNode(imageNamed: "char_sakura")
        let charH: CGFloat = min(frame.height * 0.48, 420)
        let charW: CGFloat = charH * 0.72
        mainCharNode.size = CGSize(width: charW, height: charH)
        mainCharNode.position = CGPoint(x: frame.midX, y: frame.midY + 25)
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
        tapHintLabel.position = CGPoint(x: frame.midX, y: frame.midY - charH / 2 - 10)
        tapHintLabel.zPosition = 3
        addChild(tapHintLabel)

        let fadeSeq = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.25, duration: 1.2),
            SKAction.fadeAlpha(to: 0.85, duration: 1.2)
        ])
        tapHintLabel.run(SKAction.repeatForever(fadeSeq))

        // グロウリング
        let glow = SKShapeNode(circleOfRadius: charW * 0.48)
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
        hudNode.position = CGPoint(x: 0, y: frame.height - 100)
        hudNode.zPosition = 10
        addChild(hudNode)
        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)
    }

    private func setupEmployeePanel() {
        let panelH: CGFloat = 210
        employeePanel = EmployeePanelNode(width: frame.width)
        employeePanel.position = CGPoint(x: 0, y: 0)
        employeePanel.zPosition = 10
        addChild(employeePanel)
        employeePanel.onEmployeeTap = { [weak self] id in
            self?.handleEmployeeTap(id: id)
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

        // パネル内タップ → 社員採用/UP
        let panelLoc = touch.location(in: employeePanel)
        if panelLoc.y >= 0 && panelLoc.y <= 210 {
            if let id = employeePanel.tapCard(at: panelLoc) {
                handleEmployeeTap(id: id)
            }
            return
        }

        // メインキャラタップ
        handleMainTap(at: loc)
    }

    // MARK: - Game Actions

    private func handleMainTap(at loc: CGPoint) {
        let earned = gm.tap()
        animateMainCharTap()
        showFloatingMoney(earned, at: loc)
        spawnCoins(at: loc, count: 4)
        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)
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

    private func handleEmployeeTap(id: Int) {
        let emp = gm.employees.first(where: { $0.id == id })!
        let success: Bool
        if emp.isHired {
            success = gm.upgrade(id: id)
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

        let charNode = SKSpriteNode(imageNamed: "char_sakura")
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

        hudNode.update(money: gm.money, incomePerSec: gm.totalIncomePerSec)

        employeePanel.applyInertia()

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
