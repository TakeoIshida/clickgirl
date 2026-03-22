import SpriteKit

// MARK: - Data

struct OfficeItem {
    let id: String
    let name: String
    let icon: String
    let maxLevel: Int
    let baseCost: Double
    let costMult: Double
    let incomeBoostPerLevel: Double   // additive: 0.05 = +5% per level
    let levelNames: [String]

    func costForNextLevel(_ current: Int) -> Double {
        baseCost * pow(costMult, Double(current))
    }

    static let all: [OfficeItem] = [
        OfficeItem(id: "size",     name: "オフィス拡張",  icon: "📐", maxLevel: 3,
                   baseCost: 5000,  costMult: 20, incomeBoostPerLevel: 0.20,
                   levelNames: ["スモール", "ミドル", "ラージ"]),
        OfficeItem(id: "floor",    name: "フローリング",  icon: "🪵", maxLevel: 3,
                   baseCost: 300,   costMult: 8,  incomeBoostPerLevel: 0.05,
                   levelNames: ["木材フロア", "オーク材", "大理石"]),
        OfficeItem(id: "window",   name: "窓",            icon: "🪟", maxLevel: 3,
                   baseCost: 1000,  costMult: 8,  incomeBoostPerLevel: 0.08,
                   levelNames: ["小窓 ×1", "大窓 ×2", "全面ガラス"]),
        OfficeItem(id: "desk",     name: "デスク",        icon: "🖥️", maxLevel: 4,
                   baseCost: 500,   costMult: 6,  incomeBoostPerLevel: 0.06,
                   levelNames: ["折りたたみ机", "木製デスク", "ハイエンド", "社長室"]),
        OfficeItem(id: "chair",    name: "チェア",        icon: "🪑", maxLevel: 3,
                   baseCost: 400,   costMult: 6,  incomeBoostPerLevel: 0.04,
                   levelNames: ["パイプ椅子", "オフィスチェア", "高級レザー"]),
        OfficeItem(id: "lighting", name: "照明",          icon: "💡", maxLevel: 3,
                   baseCost: 2000,  costMult: 10, incomeBoostPerLevel: 0.08,
                   levelNames: ["蛍光灯", "LEDパネル", "シャンデリア"]),
        OfficeItem(id: "plant",    name: "観葉植物",      icon: "🌿", maxLevel: 3,
                   baseCost: 800,   costMult: 6,  incomeBoostPerLevel: 0.04,
                   levelNames: ["サボテン", "観葉植物", "植物コーナー"]),
        OfficeItem(id: "meeting",  name: "会議室",        icon: "🤝", maxLevel: 2,
                   baseCost: 12000, costMult: 15, incomeBoostPerLevel: 0.15,
                   levelNames: ["打ち合わせ席", "プレミアム会議室"]),
    ]
}

// MARK: - OfficeScene

class OfficeScene: SKScene {

    private let gm = GameManager.shared

    // Layout constants
    private let topBarH:   CGFloat = 56
    private let roomAreaH: CGFloat = 235
    private let boostBarH: CGFloat = 38
    private let cardH:     CGFloat = 152
    private let colGap:    CGFloat = 10
    private let rowGap:    CGFloat = 10
    private let sideMargin: CGFloat = 12
    private let cardW: CGFloat

    // Nodes
    private var roomNode:   SKNode!
    private var boostLabel: SKLabelNode!
    private var moneyLabel: SKLabelNode!

    // Scroll
    private var scrollContainer = SKNode()
    private var cropNode: SKCropNode!
    private var isDragging   = false
    private var dragStartY:  CGFloat = 0
    private var scrollStartY: CGFloat = 0
    private var velocity:    CGFloat = 0
    private var lastDragY:   CGFloat = 0
    private var lastDragTime: TimeInterval = 0
    private var maxScrollUp: CGFloat = 0

    // MARK: - Init

    override init(size: CGSize) {
        cardW = (size.width - 2 * 12 - 10) / 2
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0)
        setupTopBar()
        setupRoomArea()
        setupBoostBar()
        setupScrollList()
    }

    // MARK: - Top Bar

    private func setupTopBar() {
        let bar = SKShapeNode(rectOf: CGSize(width: frame.width, height: topBarH))
        bar.fillColor = UIColor(red: 0.06, green: 0.06, blue: 0.18, alpha: 1.0)
        bar.strokeColor = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 0.4)
        bar.lineWidth = 1
        bar.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        bar.zPosition = 10
        addChild(bar)

        let back = SKLabelNode(text: "◀ 戻る")
        back.fontName = "HiraginoSans-W5"
        back.fontSize = 15
        back.fontColor = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)
        back.horizontalAlignmentMode = .left
        back.verticalAlignmentMode   = .center
        back.position = CGPoint(x: 14, y: frame.height - topBarH / 2)
        back.zPosition = 11
        back.name = "backBtn"
        addChild(back)

        let title = SKLabelNode(text: "🏢 オフィス拡張")
        title.fontName = "HiraginoSans-W6"
        title.fontSize = 17
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        title.zPosition = 11
        addChild(title)

        moneyLabel = SKLabelNode()
        moneyLabel.fontName = "HiraginoSans-W7"
        moneyLabel.fontSize = 14
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .right
        moneyLabel.verticalAlignmentMode   = .center
        moneyLabel.position = CGPoint(x: frame.width - 12, y: frame.height - topBarH / 2)
        moneyLabel.zPosition = 11
        moneyLabel.text = "¥\(formatMoney(gm.money))"
        addChild(moneyLabel)
    }

    // MARK: - Room Area

    private func setupRoomArea() {
        let roomY = frame.height - topBarH - roomAreaH / 2 - 8
        roomNode = SKNode()
        roomNode.position = CGPoint(x: frame.midX, y: roomY)
        roomNode.zPosition = 5
        addChild(roomNode)
        drawRoom()

        // Opaque cover so scrolled cards hide behind it
        let cover = SKSpriteNode(color: UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0),
                                  size: CGSize(width: frame.width, height: topBarH + roomAreaH + 16))
        cover.anchorPoint = CGPoint(x: 0, y: 0)
        cover.position = CGPoint(x: 0, y: frame.height - topBarH - roomAreaH - 16)
        cover.zPosition = 4
        addChild(cover)
    }

    private func drawRoom() {
        roomNode.removeAllChildren()

        let w = frame.width - 24
        let h = roomAreaH
        let lv        = gm.officeUpgrades
        let sizeLv    = lv["size"]     ?? 0
        let floorLv   = lv["floor"]    ?? 0
        let windowLv  = lv["window"]   ?? 0
        let deskLv    = lv["desk"]     ?? 0
        let chairLv   = lv["chair"]    ?? 0
        let lightLv   = lv["lighting"] ?? 0
        let plantLv   = lv["plant"]    ?? 0
        let meetingLv = lv["meeting"]  ?? 0

        let floorH: CGFloat = h * 0.28
        let ceilH:  CGFloat = 22
        let wallH:  CGFloat = h - floorH - ceilH - 4
        let floorY  = -h/2 + floorH/2 + 2
        let wallY   = floorY + floorH/2 + wallH/2
        let ceilY   = h/2 - ceilH/2 - 2
        let floorSurface = floorY + floorH/2

        // --- Room border ---
        let border = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        border.fillColor = .clear
        border.strokeColor = UIColor(red: 0.3, green: 0.45, blue: 0.85, alpha: 0.7)
        border.lineWidth = 2
        roomNode.addChild(border)

        // --- Ceiling ---
        let ceilBg = SKShapeNode(rectOf: CGSize(width: w - 4, height: ceilH), cornerRadius: 2)
        ceilBg.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.2, alpha: 1.0)
        ceilBg.strokeColor = .clear
        ceilBg.position = CGPoint(x: 0, y: ceilY)
        roomNode.addChild(ceilBg)

        // Lighting
        switch lightLv {
        case 0:
            let strip = SKShapeNode(rectOf: CGSize(width: 40, height: 5), cornerRadius: 2)
            strip.fillColor = UIColor(white: 0.4, alpha: 0.5)
            strip.strokeColor = .clear
            strip.position = CGPoint(x: 0, y: ceilY)
            roomNode.addChild(strip)
        case 1:
            for xOff: CGFloat in [-w * 0.22, w * 0.22] {
                let strip = SKShapeNode(rectOf: CGSize(width: 70, height: 6), cornerRadius: 3)
                strip.fillColor = UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 0.85)
                strip.strokeColor = UIColor(white: 1.0, alpha: 0.3)
                strip.lineWidth = 1
                strip.position = CGPoint(x: xOff, y: ceilY)
                roomNode.addChild(strip)
            }
        case 2:
            let panel = SKShapeNode(rectOf: CGSize(width: w * 0.65, height: 8), cornerRadius: 4)
            panel.fillColor = UIColor(red: 0.85, green: 0.93, blue: 1.0, alpha: 0.92)
            panel.strokeColor = UIColor(white: 1.0, alpha: 0.35)
            panel.lineWidth = 1
            panel.position = CGPoint(x: 0, y: ceilY)
            roomNode.addChild(panel)
        default:
            let base = SKShapeNode(circleOfRadius: 11)
            base.fillColor = UIColor(red: 1.0, green: 0.92, blue: 0.6, alpha: 1.0)
            base.strokeColor = UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.8)
            base.lineWidth = 2
            base.position = CGPoint(x: 0, y: ceilY - 7)
            roomNode.addChild(base)
            let glow = SKShapeNode(circleOfRadius: 30)
            glow.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.1)
            glow.strokeColor = .clear
            glow.position = base.position
            roomNode.addChild(glow)
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.05, duration: 1.5),
                SKAction.fadeAlpha(to: 0.15, duration: 1.5)
            ])
            glow.run(SKAction.repeatForever(pulse))
        }

        // --- Back Wall ---
        let wallBg = SKShapeNode(rectOf: CGSize(width: w - 4, height: wallH))
        wallBg.fillColor = UIColor(red: 0.1, green: 0.12, blue: 0.25, alpha: 1.0)
        wallBg.strokeColor = .clear
        wallBg.position = CGPoint(x: 0, y: wallY)
        roomNode.addChild(wallBg)

        // Window(s)
        let winH: CGFloat = 58
        let winMidY = wallY + wallH * 0.1
        switch windowLv {
        case 1:
            drawWindow(at: CGPoint(x: 0, y: winMidY), size: CGSize(width: 72, height: winH), level: 1)
        case 2:
            drawWindow(at: CGPoint(x: -w * 0.22, y: winMidY), size: CGSize(width: 72, height: winH), level: 2)
            drawWindow(at: CGPoint(x:  w * 0.22, y: winMidY), size: CGSize(width: 72, height: winH), level: 2)
        case let wl where wl >= 3:
            drawWindow(at: CGPoint(x: meetingLv > 0 ? -w * 0.1 : 0, y: wallY + 4),
                       size: CGSize(width: w * (meetingLv > 0 ? 0.58 : 0.76), height: wallH - 18), level: 3)
        default:
            break
        }

        // Meeting room partition
        if meetingLv > 0 {
            let partW: CGFloat = w * 0.3
            let partH: CGFloat = wallH + floorH + 4
            let partX: CGFloat = w / 2 - partW / 2 - 2
            let partY: CGFloat = floorY - floorH/2 + partH/2 + 2

            let partition = SKShapeNode(rectOf: CGSize(width: partW, height: partH), cornerRadius: 4)
            partition.fillColor = UIColor(red: 0.07, green: 0.1, blue: 0.22, alpha: 1.0)
            partition.strokeColor = UIColor(red: 0.4, green: 0.55, blue: 0.95, alpha: 0.65)
            partition.lineWidth = 1.5
            partition.position = CGPoint(x: partX, y: partY)
            roomNode.addChild(partition)

            let meetIcon = SKLabelNode(text: meetingLv >= 2 ? "🤝✨" : "🤝")
            meetIcon.fontSize = 20
            meetIcon.position = CGPoint(x: partX, y: partY + 14)
            roomNode.addChild(meetIcon)

            let meetText = SKLabelNode(text: "会議室")
            meetText.fontName = "HiraginoSans-W4"
            meetText.fontSize = 10
            meetText.fontColor = UIColor(white: 0.55, alpha: 1.0)
            meetText.position = CGPoint(x: partX, y: partY - 14)
            roomNode.addChild(meetText)
        }

        // --- Floor ---
        let floorColors: [UIColor] = [
            UIColor(red: 0.18, green: 0.14, blue: 0.1,  alpha: 1.0),
            UIColor(red: 0.5,  green: 0.36, blue: 0.2,  alpha: 1.0),
            UIColor(red: 0.62, green: 0.48, blue: 0.28, alpha: 1.0),
            UIColor(red: 0.88, green: 0.86, blue: 0.83, alpha: 1.0),
        ]
        let floorBg = SKShapeNode(rectOf: CGSize(width: w - 4, height: floorH))
        floorBg.fillColor = floorColors[min(floorLv, 3)]
        floorBg.strokeColor = .clear
        floorBg.position = CGPoint(x: 0, y: floorY)
        roomNode.addChild(floorBg)

        if floorLv == 1 || floorLv == 2 {
            for i in 0..<4 {
                let plank = SKShapeNode()
                let path = CGMutablePath()
                let px = -w/2 + 20 + CGFloat(i) * ((w - 40) / 3)
                path.move(to: CGPoint(x: px, y: floorY - floorH/2))
                path.addLine(to: CGPoint(x: px, y: floorY + floorH/2))
                plank.path = path
                plank.strokeColor = UIColor(red: 0.28, green: 0.18, blue: 0.08, alpha: 0.4)
                plank.lineWidth = 1
                roomNode.addChild(plank)
            }
        }
        if floorLv >= 3 {
            let shine = SKShapeNode(rectOf: CGSize(width: w * 0.35, height: 3), cornerRadius: 1)
            shine.fillColor = UIColor(white: 1.0, alpha: 0.18)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -w * 0.08, y: floorY + floorH * 0.22)
            roomNode.addChild(shine)
        }

        // --- Furniture ---
        let furY = floorSurface + 4

        // Desks
        if deskLv > 0 {
            let twoDesks = deskLv >= 3
            let meetOffset: CGFloat = meetingLv > 0 ? -w * 0.08 : 0
            let deskXList: [CGFloat] = twoDesks
                ? [-w * 0.28 + meetOffset, w * 0.05 + meetOffset]
                : [-w * 0.12 + meetOffset]
            for dx in deskXList {
                drawDesk(at: CGPoint(x: dx, y: furY), level: deskLv)
            }
            if chairLv > 0 {
                for dx in deskXList {
                    drawChair(at: CGPoint(x: dx, y: furY), level: chairLv)
                }
            }
        }

        // Plants
        if plantLv > 0 {
            let pX: CGFloat = meetingLv > 0 ? -w * 0.38 : w * 0.34
            drawPlant(at: CGPoint(x: pX, y: furY), level: plantLv)
            if plantLv >= 3 {
                drawPlant(at: CGPoint(x: -w * 0.38, y: furY), level: plantLv)
            }
        }

        // Size label
        let sizeNames = ["スモール", "ミドル", "ラージ", "タワー"]
        let sizeLbl = SKLabelNode(text: "🏢 \(sizeNames[min(sizeLv, 3)])オフィス")
        sizeLbl.fontName = "HiraginoSans-W4"
        sizeLbl.fontSize = 10
        sizeLbl.fontColor = UIColor(white: 0.45, alpha: 0.9)
        sizeLbl.horizontalAlignmentMode = .right
        sizeLbl.position = CGPoint(x: w/2 - 8, y: -h/2 + 5)
        roomNode.addChild(sizeLbl)
    }

    // MARK: - Room Drawing Helpers

    private func drawWindow(at pos: CGPoint, size sz: CGSize, level: Int) {
        let winNode = SKShapeNode(rectOf: sz, cornerRadius: 5)
        winNode.fillColor = UIColor(red: 0.4, green: 0.58, blue: 0.82, alpha: level >= 3 ? 0.5 : 0.62)
        winNode.strokeColor = UIColor(red: 0.55, green: 0.72, blue: 1.0, alpha: 0.8)
        winNode.lineWidth = 2
        winNode.position = pos
        roomNode.addChild(winNode)

        let buildCount = level >= 3 ? 7 : 3
        for i in 0..<buildCount {
            let bh = CGFloat.random(in: sz.height * 0.28 ... sz.height * 0.62)
            let bw: CGFloat = level >= 3 ? 16 : 11
            let bx = pos.x - sz.width/2 + 10 + CGFloat(i) * ((sz.width - 16) / CGFloat(max(buildCount - 1, 1)))
            let building = SKShapeNode(rectOf: CGSize(width: bw, height: bh))
            building.fillColor = UIColor(red: 0.12, green: 0.16, blue: 0.35, alpha: 0.75)
            building.strokeColor = .clear
            building.position = CGPoint(x: bx, y: pos.y - sz.height/2 + bh/2)
            roomNode.addChild(building)
        }
        let shine = SKShapeNode(rectOf: CGSize(width: sz.width * 0.1, height: sz.height * 0.65), cornerRadius: 2)
        shine.fillColor = UIColor(white: 1.0, alpha: 0.2)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: pos.x + sz.width * 0.32, y: pos.y)
        roomNode.addChild(shine)
    }

    private func drawDesk(at pos: CGPoint, level: Int) {
        let dw: CGFloat = level >= 3 ? 82 : 64
        let dh: CGFloat = level >= 4 ? 26 : 20
        let deskColors: [UIColor] = [
            UIColor(red: 0.48, green: 0.48, blue: 0.52, alpha: 1.0),
            UIColor(red: 0.48, green: 0.34, blue: 0.18, alpha: 1.0),
            UIColor(red: 0.9,  green: 0.88, blue: 0.82, alpha: 1.0),
            UIColor(red: 0.5,  green: 0.72, blue: 0.9,  alpha: 0.85),
        ]
        let desk = SKShapeNode(rectOf: CGSize(width: dw, height: dh), cornerRadius: 3)
        desk.fillColor = deskColors[min(level - 1, 3)]
        desk.strokeColor = UIColor(white: 0.5, alpha: 0.45)
        desk.lineWidth = 1
        desk.position = CGPoint(x: pos.x, y: pos.y + dh / 2)
        roomNode.addChild(desk)

        if level >= 2 {
            let mw: CGFloat = level >= 4 ? 22 : 16
            let mon = SKShapeNode(rectOf: CGSize(width: mw, height: 14), cornerRadius: 2)
            mon.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1.0)
            mon.strokeColor = UIColor(white: 0.4, alpha: 0.45)
            mon.lineWidth = 1
            mon.position = CGPoint(x: pos.x, y: pos.y + dh + 9)
            roomNode.addChild(mon)
            let screen = SKShapeNode(rectOf: CGSize(width: mw - 4, height: 10), cornerRadius: 1)
            screen.fillColor = UIColor(red: 0.18, green: 0.48, blue: 0.9, alpha: 0.7)
            screen.strokeColor = .clear
            screen.position = mon.position
            roomNode.addChild(screen)
        }
        if level >= 4 {
            let mon2 = SKShapeNode(rectOf: CGSize(width: 20, height: 14), cornerRadius: 2)
            mon2.fillColor = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1.0)
            mon2.strokeColor = UIColor(white: 0.4, alpha: 0.45)
            mon2.lineWidth = 1
            mon2.position = CGPoint(x: pos.x + 26, y: pos.y + dh + 9)
            roomNode.addChild(mon2)
            let s2 = SKShapeNode(rectOf: CGSize(width: 16, height: 10), cornerRadius: 1)
            s2.fillColor = UIColor(red: 0.18, green: 0.48, blue: 0.9, alpha: 0.7)
            s2.strokeColor = .clear
            s2.position = mon2.position
            roomNode.addChild(s2)
        }
    }

    private func drawChair(at pos: CGPoint, level: Int) {
        let cw: CGFloat = level >= 3 ? 30 : 22
        let chairColors: [UIColor] = [
            UIColor(red: 0.48, green: 0.48, blue: 0.52, alpha: 1.0),
            UIColor(red: 0.12, green: 0.14, blue: 0.28, alpha: 1.0),
            UIColor(red: 0.22, green: 0.07, blue: 0.05, alpha: 1.0),
        ]
        let seat = SKShapeNode(rectOf: CGSize(width: cw, height: 12), cornerRadius: 3)
        seat.fillColor = chairColors[min(level - 1, 2)]
        seat.strokeColor = UIColor(white: 0.4, alpha: 0.4)
        seat.lineWidth = 1
        seat.position = CGPoint(x: pos.x, y: pos.y - 16)
        roomNode.addChild(seat)
    }

    private func drawPlant(at pos: CGPoint, level: Int) {
        let pot = SKShapeNode(rectOf: CGSize(width: 16, height: 14), cornerRadius: 2)
        pot.fillColor = UIColor(red: 0.48, green: 0.28, blue: 0.12, alpha: 1.0)
        pot.strokeColor = .clear
        pot.position = pos
        roomNode.addChild(pot)

        let lh: CGFloat = level == 1 ? 20 : (level == 2 ? 35 : 55)
        let lw: CGFloat = level == 1 ? 18 : (level == 2 ? 26 : 45)
        let leafColors: [UIColor] = [
            UIColor(red: 0.2,  green: 0.5,  blue: 0.2,  alpha: 1.0),
            UIColor(red: 0.15, green: 0.65, blue: 0.25, alpha: 1.0),
            UIColor(red: 0.1,  green: 0.72, blue: 0.3,  alpha: 1.0),
        ]
        let leaf = SKShapeNode(ellipseOf: CGSize(width: lw, height: lh))
        leaf.fillColor = leafColors[min(level - 1, 2)]
        leaf.strokeColor = .clear
        leaf.position = CGPoint(x: pos.x, y: pos.y + lh / 2 + 6)
        roomNode.addChild(leaf)
    }

    // MARK: - Boost Bar

    private func setupBoostBar() {
        let boostY = frame.height - topBarH - roomAreaH - boostBarH / 2 - 12

        let barBg = SKShapeNode(rectOf: CGSize(width: frame.width - 20, height: boostBarH), cornerRadius: 8)
        barBg.fillColor = UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.95)
        barBg.strokeColor = UIColor(red: 0.25, green: 0.48, blue: 0.8, alpha: 0.5)
        barBg.lineWidth = 1
        barBg.position = CGPoint(x: frame.midX, y: boostY)
        barBg.zPosition = 5
        addChild(barBg)

        boostLabel = SKLabelNode()
        boostLabel.fontName = "HiraginoSans-W5"
        boostLabel.fontSize = 13
        boostLabel.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.55, alpha: 0.95)
        boostLabel.verticalAlignmentMode = .center
        boostLabel.position = CGPoint(x: frame.midX, y: boostY)
        boostLabel.zPosition = 6
        updateBoostLabel()
        addChild(boostLabel)

        // Boost bar cover so scrolled cards hide behind it
        let boostCover = SKSpriteNode(color: UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0),
                                       size: CGSize(width: frame.width, height: boostBarH + 24))
        boostCover.anchorPoint = CGPoint(x: 0, y: 0)
        boostCover.position = CGPoint(x: 0, y: boostY - (boostBarH + 24) / 2)
        boostCover.zPosition = 4
        addChild(boostCover)
    }

    private func updateBoostLabel() {
        let officePct = Int((gm.officeIncomeMultiplier - 1.0) * 100)
        let floorPct  = Int((gm.floorIncomeMultiplier  - 1.0) * 100)
        let total = officePct + floorPct
        boostLabel.text = "🏢 オフィスボーナス: +\(total)%  (\(gm.officeFloors)F)"
    }

    // MARK: - Scroll List

    private var cardListTopY: CGFloat {
        frame.height - topBarH - roomAreaH - boostBarH - 26
    }

    private func setupScrollList() {
        // Crop node clips cards to the scrollable area
        cropNode = SKCropNode()
        cropNode.position = .zero
        cropNode.zPosition = 2

        let maskH = cardListTopY
        let mask = SKSpriteNode(color: .white, size: CGSize(width: frame.width, height: maskH))
        mask.anchorPoint = CGPoint(x: 0.5, y: 0)
        mask.position = CGPoint(x: frame.midX, y: 0)
        cropNode.maskNode = mask

        addChild(cropNode)
        cropNode.addChild(scrollContainer)
        buildCards()
    }

    private func buildCards() {
        scrollContainer.removeAllChildren()

        var currentY = cardListTopY - rowGap

        // --- 都市開発ボタン (全幅) ---
        let cityBtnH: CGFloat = 44
        let cityBtn = makeCityNavButton()
        cityBtn.position = CGPoint(x: frame.midX, y: currentY - cityBtnH / 2)
        scrollContainer.addChild(cityBtn)
        currentY -= cityBtnH + rowGap

        // --- フロア追加カード (全幅) ---
        let floorCardH: CGFloat = 72
        let floorCard = makeFloorCard(height: floorCardH)
        floorCard.position = CGPoint(x: frame.midX, y: currentY - floorCardH / 2)
        scrollContainer.addChild(floorCard)
        currentY -= floorCardH + rowGap * 2

        // --- 内装アップグレードカード (2列) ---
        let items = OfficeItem.all
        let firstCardCenterY = currentY - cardH / 2
        for (i, item) in items.enumerated() {
            let col = i % 2
            let row = i / 2
            let x = sideMargin + cardW / 2 + CGFloat(col) * (cardW + colGap)
            let y = firstCardCenterY - CGFloat(row) * (cardH + rowGap)
            let card = makeCard(item: item)
            card.position = CGPoint(x: x, y: y)
            scrollContainer.addChild(card)
        }

        let itemRows = (items.count + 1) / 2
        let fixedSectionH = cityBtnH + rowGap + floorCardH + rowGap * 2
        let totalH = fixedSectionH + CGFloat(itemRows) * (cardH + rowGap) + rowGap
        maxScrollUp = max(0, totalH - cardListTopY + 20)
    }

    private func makeCityNavButton() -> SKNode {
        let container = SKNode()
        container.name = "cityNavBtn"
        let w = frame.width - sideMargin * 2
        let h: CGFloat = 44
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        bg.fillColor = UIColor(red: 0.1, green: 0.18, blue: 0.38, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.7)
        bg.lineWidth = 1.5
        bg.name = "cityNavBtn"
        container.addChild(bg)
        let lbl = SKLabelNode(text: "🌆 都市開発へ  ▶")
        lbl.fontName = "HiraginoSans-W6"
        lbl.fontSize = 15
        lbl.fontColor = UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0)
        lbl.verticalAlignmentMode = .center
        lbl.name = "cityNavBtn"
        container.addChild(lbl)
        return container
    }

    private func makeFloorCard(height h: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = "floorCard"
        let w = frame.width - sideMargin * 2
        let floors = gm.officeFloors
        let cost = gm.floorCost(floors)
        let canAfford = gm.money >= cost

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        bg.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.22, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.6)
        bg.lineWidth = 1.5
        bg.name = "floorCard"
        container.addChild(bg)

        let iconLbl = SKLabelNode(text: "🏗️")
        iconLbl.fontSize = 24
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position = CGPoint(x: -w/2 + 30, y: 0)
        container.addChild(iconLbl)

        let titleLbl = SKLabelNode(text: "フロア追加  現在 \(floors)F")
        titleLbl.fontName = "HiraginoSans-W6"
        titleLbl.fontSize = 13
        titleLbl.fontColor = .white
        titleLbl.horizontalAlignmentMode = .left
        titleLbl.verticalAlignmentMode   = .center
        titleLbl.position = CGPoint(x: -w/2 + 58, y: 10)
        container.addChild(titleLbl)

        let boostLbl = SKLabelNode(text: "追加ごとに収益 +30%")
        boostLbl.fontName = "HiraginoSans-W4"
        boostLbl.fontSize = 11
        boostLbl.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.55, alpha: 0.85)
        boostLbl.horizontalAlignmentMode = .left
        boostLbl.verticalAlignmentMode   = .center
        boostLbl.position = CGPoint(x: -w/2 + 58, y: -8)
        container.addChild(boostLbl)

        let btnW: CGFloat = 130
        let btnBg = SKShapeNode(rectOf: CGSize(width: btnW, height: 30), cornerRadius: 10)
        btnBg.name = "addFloorBtn"
        btnBg.zPosition = 2
        btnBg.fillColor = canAfford
            ? UIColor(red: 0.22, green: 0.48, blue: 1.0, alpha: 0.9)
            : UIColor(red: 0.16, green: 0.16, blue: 0.28, alpha: 0.85)
        btnBg.strokeColor = canAfford
            ? UIColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 0.6)
            : UIColor(red: 0.28, green: 0.28, blue: 0.48, alpha: 0.5)
        btnBg.lineWidth = 1
        btnBg.position = CGPoint(x: w/2 - btnW/2 - 8, y: 0)
        container.addChild(btnBg)

        let btnLbl = SKLabelNode(text: "¥\(formatMoney(cost))")
        btnLbl.fontName = "HiraginoSans-W6"
        btnLbl.fontSize = 12
        btnLbl.fontColor = canAfford ? .white : UIColor(white: 0.38, alpha: 1.0)
        btnLbl.verticalAlignmentMode = .center
        btnLbl.position = btnBg.position
        btnLbl.zPosition = 3
        btnLbl.name = "addFloorBtn"
        container.addChild(btnLbl)

        return container
    }

    private func makeCard(item: OfficeItem) -> SKNode {
        let current   = gm.officeUpgrades[item.id] ?? 0
        let maxed     = current >= item.maxLevel
        let cost      = item.costForNextLevel(current)
        let canAfford = gm.money >= cost

        let container = SKNode()
        container.name = "card_\(item.id)"

        let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
        bg.fillColor = maxed
            ? UIColor(red: 0.06, green: 0.15, blue: 0.09, alpha: 0.95)
            : UIColor(red: 0.07, green: 0.07, blue: 0.20, alpha: 0.95)
        bg.strokeColor = maxed
            ? UIColor(red: 0.3,  green: 0.85, blue: 0.4, alpha: 0.7)
            : UIColor(red: 0.35, green: 0.5,  blue: 0.9, alpha: 0.6)
        bg.lineWidth = 1.5
        bg.name = "card_\(item.id)"
        container.addChild(bg)

        let icon = SKLabelNode(text: item.icon)
        icon.fontSize = 30
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: cardH/2 - 28)
        container.addChild(icon)

        let nameLbl = SKLabelNode(text: item.name)
        nameLbl.fontName = "HiraginoSans-W7"
        nameLbl.fontSize = 13
        nameLbl.fontColor = maxed ? UIColor(red: 0.5, green: 1.0, blue: 0.6, alpha: 1.0) : .white
        nameLbl.verticalAlignmentMode = .center
        nameLbl.position = CGPoint(x: 0, y: cardH/2 - 52)
        container.addChild(nameLbl)

        // Level dots
        let dotSpacing: CGFloat = 13
        let totalDotsW = CGFloat(item.maxLevel) * dotSpacing
        let dotY: CGFloat = cardH/2 - 68
        for d in 0..<item.maxLevel {
            let dot = SKShapeNode(circleOfRadius: 4.5)
            dot.fillColor = d < current
                ? UIColor(red: 0.3, green: 0.9, blue: 0.45, alpha: 1.0)
                : UIColor(white: 0.2, alpha: 1.0)
            dot.strokeColor = UIColor(white: 0.35, alpha: 0.5)
            dot.lineWidth = 1
            dot.position = CGPoint(x: -totalDotsW/2 + 6.5 + CGFloat(d) * dotSpacing, y: dotY)
            container.addChild(dot)
        }

        // Description
        let descText: String
        if maxed {
            descText = "✅ " + item.levelNames[item.maxLevel - 1]
        } else if current == 0 {
            descText = "→ " + item.levelNames[0]
        } else {
            descText = item.levelNames[current - 1] + " → " + item.levelNames[current]
        }
        let descLbl = SKLabelNode(text: descText)
        descLbl.fontName = "HiraginoSans-W3"
        descLbl.fontSize = descText.count > 14 ? 9 : 11
        descLbl.fontColor = UIColor(white: 0.62, alpha: 1.0)
        descLbl.verticalAlignmentMode = .center
        descLbl.position = CGPoint(x: 0, y: cardH/2 - 85)
        container.addChild(descLbl)

        // Income boost per level
        let boostLbl = SKLabelNode(text: "+\(Int(item.incomeBoostPerLevel * 100))% 収益/Lv")
        boostLbl.fontName = "HiraginoSans-W5"
        boostLbl.fontSize = 11
        boostLbl.fontColor = UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.9)
        boostLbl.verticalAlignmentMode = .center
        boostLbl.position = CGPoint(x: 0, y: cardH/2 - 100)
        container.addChild(boostLbl)

        // Button or MAX badge
        let btnY: CGFloat = -(cardH/2 - 22)
        if maxed {
            let badge = SKLabelNode(text: "✅ MAX")
            badge.fontName = "HiraginoSans-W6"
            badge.fontSize = 13
            badge.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.55, alpha: 1.0)
            badge.verticalAlignmentMode = .center
            badge.position = CGPoint(x: 0, y: btnY)
            container.addChild(badge)
        } else {
            let btnBg = SKShapeNode(rectOf: CGSize(width: cardW - 18, height: 30), cornerRadius: 10)
            btnBg.name = "upgradeBtn_\(item.id)"
            btnBg.zPosition = 2
            btnBg.fillColor = canAfford
                ? UIColor(red: 0.22, green: 0.48, blue: 1.0, alpha: 0.9)
                : UIColor(red: 0.16, green: 0.16, blue: 0.28, alpha: 0.85)
            btnBg.strokeColor = canAfford
                ? UIColor(red: 0.5, green: 0.75, blue: 1.0, alpha: 0.6)
                : UIColor(red: 0.28, green: 0.28, blue: 0.48, alpha: 0.5)
            btnBg.lineWidth = 1
            btnBg.position = CGPoint(x: 0, y: btnY)
            container.addChild(btnBg)

            let btnLbl = SKLabelNode(text: "¥\(formatMoney(cost))")
            btnLbl.fontName = "HiraginoSans-W6"
            btnLbl.fontSize = 12
            btnLbl.fontColor = canAfford ? .white : UIColor(white: 0.38, alpha: 1.0)
            btnLbl.verticalAlignmentMode = .center
            btnLbl.position = CGPoint(x: 0, y: btnY)
            btnLbl.zPosition = 3
            btnLbl.name = "upgradeBtn_\(item.id)"
            container.addChild(btnLbl)
        }

        return container
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        isDragging = false
        dragStartY = loc.y
        scrollStartY = scrollContainer.position.y
        velocity = 0
        lastDragY = loc.y
        lastDragTime = t.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        if abs(loc.y - dragStartY) > 5 { isDragging = true }
        guard isDragging else { return }
        let dt = t.timestamp - lastDragTime
        if dt > 0 { velocity = (loc.y - lastDragY) / CGFloat(dt) }
        lastDragY = loc.y
        lastDragTime = t.timestamp
        scrollContainer.position.y = clampScroll(scrollStartY + (loc.y - dragStartY))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        if !isDragging { handleTap(at: t.location(in: self)) }
        isDragging = false
    }

    private func clampScroll(_ y: CGFloat) -> CGFloat {
        max(min(0, y), -maxScrollUp)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if !isDragging {
            if abs(velocity) > 1 {
                scrollContainer.position.y = clampScroll(scrollContainer.position.y + velocity * 0.016)
                velocity *= 0.92
            } else {
                velocity = 0
            }
        }
        moneyLabel.text = "¥\(formatMoney(gm.money))"
    }

    // MARK: - Tap

    private func handleTap(at loc: CGPoint) {
        for node in nodes(at: loc) {
            guard let name = node.name else { continue }
            if name == "backBtn"    { goBack();       return }
            if name == "cityNavBtn" { openCity();     return }
            if name == "addFloorBtn" || name == "floorCard" {
                attemptAddFloor()
                return
            }
            if name.hasPrefix("upgradeBtn_") {
                attemptUpgrade(id: String(name.dropFirst("upgradeBtn_".count)))
                return
            }
            if name.hasPrefix("card_") {
                attemptUpgrade(id: String(name.dropFirst("card_".count)))
                return
            }
        }
    }

    private func attemptAddFloor() {
        let cost = gm.floorCost(gm.officeFloors)
        guard gm.money >= cost else {
            showToast("💸 お金が足りません (¥\(formatMoney(cost)) 必要)")
            return
        }
        if gm.addOfficeFloor() {
            buildCards()
            updateBoostLabel()
            drawRoom()
            showUpgradeEffect(name: "\(gm.officeFloors)F に拡張", newLevel: gm.officeFloors)
            moneyLabel.text = "¥\(formatMoney(gm.money))"
        }
    }

    private func openCity() {
        gm.saveGame()
        let scene = CityScene(size: frame.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.push(with: .left, duration: 0.3))
    }

    private func attemptUpgrade(id: String) {
        guard let item = OfficeItem.all.first(where: { $0.id == id }) else { return }
        let current = gm.officeUpgrades[id] ?? 0
        guard current < item.maxLevel else { return }
        let cost = item.costForNextLevel(current)
        guard gm.money >= cost else {
            showToast("💸 お金が足りません (¥\(formatMoney(cost)) 必要)")
            return
        }
        if gm.upgradeOffice(id: id) {
            buildCards()
            updateBoostLabel()
            drawRoom()
            showUpgradeEffect(name: item.name, newLevel: current + 1)
            moneyLabel.text = "¥\(formatMoney(gm.money))"
        }
    }

    // MARK: - Effects

    private func showUpgradeEffect(name: String, newLevel: Int) {
        let label = SKLabelNode(text: "✨ \(name) Lv.\(newLevel)！")
        label.fontName = "HiraginoSans-W7"
        label.fontSize = 20
        label.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: frame.midX,
                                  y: frame.height - topBarH - roomAreaH / 2)
        label.zPosition = 50
        label.setScale(0.6)
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.05, duration: 0.18), SKAction.fadeIn(withDuration: 0.18)]),
            SKAction.scale(to: 1.0, duration: 0.08),
            SKAction.wait(forDuration: 1.2),
            SKAction.group([SKAction.fadeOut(withDuration: 0.4), SKAction.moveBy(x: 0, y: 28, duration: 0.4)]),
            SKAction.removeFromParent()
        ]))

        let flash = SKSpriteNode(color: UIColor(white: 1.0, alpha: 0.07), size: frame.size)
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.zPosition = 49
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))

        // Sparkle particles in room area
        let roomCenterY = frame.height - topBarH - roomAreaH / 2 - 8
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            spark.fillColor = UIColor(
                red: CGFloat.random(in: 0.9...1.0),
                green: CGFloat.random(in: 0.7...0.95),
                blue: 0, alpha: 1.0
            )
            spark.strokeColor = .clear
            spark.position = CGPoint(x: CGFloat.random(in: 60...frame.width - 60), y: roomCenterY)
            spark.zPosition = 20
            addChild(spark)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let spd = CGFloat.random(in: 60...160)
            let move = SKAction.moveBy(x: cos(angle) * spd, y: sin(angle) * spd, duration: 0.55)
            move.timingMode = .easeOut
            let fade = SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.35)])
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }

    private func showToast(_ message: String) {
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width - 40, height: 40), cornerRadius: 10)
        bg.fillColor = UIColor(red: 0.12, green: 0.05, blue: 0.22, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 0.7)
        bg.lineWidth = 1
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
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
        bg.run(seq)
        lbl.run(seq)
    }

    // MARK: - Back

    private func goBack() {
        gm.saveGame()
        let scene = GameScene(size: frame.size)
        scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.push(with: .right, duration: 0.3))
    }

    // MARK: - Format

    private func formatMoney(_ v: Double) -> String {
        if v >= 1_000_000_000_000 { return String(format: "%.2f兆", v / 1_000_000_000_000) }
        if v >= 100_000_000      { return String(format: "%.2f億", v / 100_000_000) }
        if v >= 10_000           { return String(format: "%.1f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
