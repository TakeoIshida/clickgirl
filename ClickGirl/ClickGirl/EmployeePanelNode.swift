import SpriteKit

// MARK: - CardTapArea

enum CardTapArea {
    case character  // 上半分（キャラ画像・名前）→ メインキャラ切替
    case button     // 下半分（採用/UPボタン）  → 採用・レベルアップ
}

// MARK: - Employee Card

class EmployeeCardNode: SKNode {
    private let employee: Employee
    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 190
    var onTap: ((Int) -> Void)?

    private var progressFill: SKSpriteNode?
    private let progressBarMaxWidth: CGFloat = 112
    private let targetCost: Double

    init(employee: Employee) {
        self.employee = employee
        self.targetCost = employee.isHired ? employee.upgradeCost : employee.hireCost
        super.init()
        setup()
        name = "empCard_\(employee.id)"
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateProgress(money: Double) {
        guard let fill = progressFill else { return }
        let progress = CGFloat(min(money / targetCost, 1.0))
        fill.xScale = max(progress, 0.005)
        if progress >= 1.0 {
            fill.color = UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
        } else if progress >= 0.7 {
            fill.color = UIColor(red: 1.0, green: 0.88, blue: 0.15, alpha: 1.0)
        } else {
            fill.color = UIColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
        }
    }

    private func setup() {
        // カード背景
        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 14)
        if employee.isHired {
            bg.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.2, alpha: 0.95)
            bg.strokeColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.8)
        } else {
            bg.fillColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.9)
            bg.strokeColor = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.5)
        }
        bg.lineWidth = 1.5
        bg.name = "empCard_\(employee.id)"
        addChild(bg)

        // キャラ画像（背景あり・アスペクト比を保持・最大高さ110pt）
        let charTexture = SKTexture(imageNamed: employee.imageName)
        let ratio: CGFloat
        if let img = UIImage(named: employee.imageName), img.size.width > 0 {
            ratio = img.size.height / img.size.width
        } else if charTexture.size().width > 0 {
            ratio = charTexture.size().height / charTexture.size().width
        } else {
            ratio = 0.56
        }
        let maxH: CGFloat = 110
        var imgW: CGFloat = 138
        var imgH: CGFloat = imgW * ratio
        if imgH > maxH {
            imgH = maxH
            imgW = imgH / ratio
        }
        let charNode = SKSpriteNode(texture: charTexture)
        charNode.size = CGSize(width: imgW, height: imgH)
        charNode.position = CGPoint(x: 0, y: imgH / 2 - 25)
        charNode.zPosition = 0
        charNode.name = "empCard_\(employee.id)"
        if !employee.isHired {
            charNode.alpha = 0.35
            charNode.color = .black
            charNode.colorBlendFactor = 0.5
        }
        addChild(charNode)

        // 名前
        let nameLabel = SKLabelNode(text: employee.name)
        nameLabel.fontName = "HiraginoSans-W6"
        nameLabel.fontSize = 14
        nameLabel.fontColor = employee.isHired ? .white : UIColor(white: 0.6, alpha: 1)
        nameLabel.position = CGPoint(x: 0, y: -42)
        nameLabel.zPosition = 2
        nameLabel.name = "empCard_\(employee.id)"
        addChild(nameLabel)

        // 役職
        let roleLabel = SKLabelNode(text: employee.role)
        roleLabel.fontName = "HiraginoSans-W3"
        roleLabel.fontSize = 10
        roleLabel.fontColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.8)
        roleLabel.position = CGPoint(x: 0, y: -54)
        roleLabel.zPosition = 2
        roleLabel.name = "empCard_\(employee.id)"
        addChild(roleLabel)

        if employee.isHired {
            // レベル表示
            let lvLabel = SKLabelNode(text: "Lv.\(employee.level)")
            lvLabel.fontName = "HiraginoSans-W8"
            lvLabel.fontSize = 12
            lvLabel.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
            lvLabel.position = CGPoint(x: -45, y: 83)
            lvLabel.name = "empCard_\(employee.id)"
            addChild(lvLabel)

            // 収益表示
            let incLabel = SKLabelNode(text: "+¥\(formatMoney(employee.currentIncomePerSec))/s")
            incLabel.fontName = "HiraginoSans-W3"
            incLabel.fontSize = 10
            incLabel.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.5, alpha: 0.9)
            incLabel.position = CGPoint(x: 0, y: -65)
            incLabel.zPosition = 2
            incLabel.name = "empCard_\(employee.id)"
            addChild(incLabel)

            // アップグレードボタン
            let upgBtn = SKShapeNode(rectOf: CGSize(width: 120, height: 26), cornerRadius: 8)
            upgBtn.fillColor = UIColor(red: 0.15, green: 0.35, blue: 0.7, alpha: 0.9)
            upgBtn.strokeColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.8)
            upgBtn.lineWidth = 1
            upgBtn.position = CGPoint(x: 0, y: -75)
            upgBtn.name = "empCard_\(employee.id)"
            addChild(upgBtn)

            let upgLabel = SKLabelNode(text: "UP ¥\(formatMoney(employee.upgradeCost))")
            upgLabel.fontName = "HiraginoSans-W6"
            upgLabel.fontSize = 11
            upgLabel.fontColor = .white
            upgLabel.verticalAlignmentMode = .center
            upgLabel.position = CGPoint(x: 0, y: -75)
            upgLabel.name = "empCard_\(employee.id)"
            addChild(upgLabel)

            addProgressBar(at: CGPoint(x: 0, y: -(cardHeight / 2 - 9)))

        } else {
            // 採用ボタン
            let hireBtn = SKShapeNode(rectOf: CGSize(width: 120, height: 30), cornerRadius: 10)
            hireBtn.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.6, alpha: 0.9)
            hireBtn.strokeColor = UIColor(red: 1.0, green: 0.5, blue: 0.9, alpha: 0.8)
            hireBtn.lineWidth = 1.5
            hireBtn.position = CGPoint(x: 0, y: -68)
            hireBtn.name = "empCard_\(employee.id)"
            addChild(hireBtn)

            let hireLabel = SKLabelNode(text: "採用 ¥\(formatMoney(employee.hireCost))")
            hireLabel.fontName = "HiraginoSans-W6"
            hireLabel.fontSize = 11
            hireLabel.fontColor = .white
            hireLabel.verticalAlignmentMode = .center
            hireLabel.position = CGPoint(x: 0, y: -68)
            hireLabel.name = "empCard_\(employee.id)"
            addChild(hireLabel)

            // ロックアイコン
            let lockLabel = SKLabelNode(text: "🔒")
            lockLabel.fontSize = 22
            lockLabel.position = CGPoint(x: 0, y: 35)
            lockLabel.name = "empCard_\(employee.id)"
            addChild(lockLabel)

            addProgressBar(at: CGPoint(x: 0, y: -(cardHeight / 2 - 9)))
        }
    }

    private func addProgressBar(at pos: CGPoint) {
        let barBg = SKSpriteNode(color: UIColor(white: 0.15, alpha: 1.0),
                                  size: CGSize(width: progressBarMaxWidth, height: 5))
        barBg.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        barBg.position = pos
        barBg.zPosition = 1
        addChild(barBg)

        let fill = SKSpriteNode(color: UIColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0),
                                 size: CGSize(width: progressBarMaxWidth, height: 5))
        fill.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.position = CGPoint(x: pos.x - progressBarMaxWidth / 2, y: pos.y)
        fill.xScale = 0.005
        fill.zPosition = 2
        addChild(fill)
        progressFill = fill
    }

    private func formatMoney(_ v: Double) -> String {
        if v >= 100_000_000 { return String(format: "%.1f億", v / 100_000_000) }
        if v >= 10_000      { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Employee Panel (横スクロール)

class EmployeePanelNode: SKNode {

    private let panelWidth: CGFloat
    private let panelHeight: CGFloat = 210
    private let cardSpacing: CGFloat = 150
    private var scrollContainer = SKNode()
    private var isDragging = false
    private var dragStartX: CGFloat = 0
    private var scrollStartX: CGFloat = 0
    private var velocity: CGFloat = 0
    private var lastDragX: CGFloat = 0
    private var lastDragTime: TimeInterval = 0

    var onEmployeeTap: ((Int, CardTapArea) -> Void)?

    init(width: CGFloat) {
        self.panelWidth = width
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        // パネル背景
        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 0)
        bg.fillColor = UIColor(red: 0.03, green: 0.03, blue: 0.12, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.4)
        bg.lineWidth = 1
        bg.position = CGPoint(x: panelWidth / 2, y: panelHeight / 2)
        addChild(bg)

        // 「社員」ラベル
        let titleLabel = SKLabelNode(text: "── 社員一覧 ──")
        titleLabel.fontName = "HiraginoSans-W3"
        titleLabel.fontSize = 12
        titleLabel.fontColor = UIColor(white: 0.6, alpha: 0.8)
        titleLabel.position = CGPoint(x: panelWidth / 2, y: panelHeight - 14)
        addChild(titleLabel)

        // スクロールコンテナ
        addChild(scrollContainer)
        scrollContainer.position = CGPoint(x: 10, y: 10)
        buildCards()
    }

    private func buildCards() {
        scrollContainer.removeAllChildren()
        let employees = GameManager.shared.employees
        for (i, emp) in employees.enumerated() {
            let card = EmployeeCardNode(employee: emp)
            card.position = CGPoint(x: CGFloat(i) * cardSpacing + 75, y: 95)
            scrollContainer.addChild(card)
        }
    }

    func refresh() {
        buildCards()
    }

    func updateProgressBars(money: Double) {
        for child in scrollContainer.children {
            guard let card = child as? EmployeeCardNode else { continue }
            card.updateProgress(money: money)
        }
    }

    // MARK: - Scroll & Touch

    private var maxScroll: CGFloat {
        let total = CGFloat(GameManager.shared.employees.count) * cardSpacing
        return max(0, total - panelWidth + 20)
    }

    func handleTouchBegan(_ location: CGPoint, at time: TimeInterval) {
        isDragging = true
        dragStartX = location.x
        scrollStartX = scrollContainer.position.x
        velocity = 0
        lastDragX = location.x
        lastDragTime = time
    }

    func handleTouchMoved(_ location: CGPoint, at time: TimeInterval) {
        guard isDragging else { return }
        let dx = location.x - dragStartX
        let dt = time - lastDragTime
        if dt > 0 { velocity = (location.x - lastDragX) / CGFloat(dt) }
        lastDragX = location.x
        lastDragTime = time
        scrollContainer.position.x = clampScroll(scrollStartX + dx)
    }

    func handleTouchEnded(_ location: CGPoint, at time: TimeInterval) {
        isDragging = false
    }

    func applyInertia() {
        guard !isDragging else { return }
        guard abs(velocity) > 1 else { velocity = 0; return }
        scrollContainer.position.x = clampScroll(scrollContainer.position.x + velocity * 0.016)
        velocity *= 0.92
    }

    private func clampScroll(_ x: CGFloat) -> CGFloat {
        let minX = 10 - maxScroll
        return max(min(10, x), minX)
    }

    func tapCard(at location: CGPoint) -> (id: Int, area: CardTapArea)? {
        let localX = location.x - scrollContainer.position.x
        let index = Int((localX - 5) / cardSpacing)
        let employees = GameManager.shared.employees
        guard index >= 0 && index < employees.count else { return nil }

        // カード内のY座標（カード中心が y=95）
        // 上半分（キャラ画像・名前）→ .character、下半分（ボタン）→ .button
        let cardCenterY: CGFloat = 95
        let localY = location.y - cardCenterY   // カード中心からの相対Y
        let area: CardTapArea = localY > -30 ? .character : .button

        return (id: employees[index].id, area: area)
    }
}
