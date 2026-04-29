import SpriteKit

// MARK: - City Data

struct CityBuildingType {
    let id: String
    let name: String
    let icon: String
    let placeCost: Double
    let upgradeMult: Double
    let baseIncome: Double
    let incomeMult: Double
    let maxLevel: Int
    let cr: CGFloat; let cg: CGFloat; let cb: CGFloat

    func upgradeCost(level: Int) -> Double { placeCost * pow(upgradeMult, Double(level)) }
    func incomePerSec(level: Int) -> Double { baseIncome * pow(incomeMult, Double(level - 1)) }

    /// 建物の描画高さ (px)
    func buildingHeight(level: Int) -> CGFloat {
        baseHeight + CGFloat(level - 1) * heightPerLevel
    }
    private var baseHeight: CGFloat {
        switch id {
        case "cafe":       return 38
        case "restaurant": return 55
        case "hotel":      return 85
        case "mall":       return 72
        case "tower":      return 130
        default:           return 40
        }
    }
    private var heightPerLevel: CGFloat {
        switch id {
        case "cafe":       return 12
        case "restaurant": return 18
        case "hotel":      return 28
        case "mall":       return 22
        case "tower":      return 40
        default:           return 15
        }
    }

    static let all: [CityBuildingType] = [
        CityBuildingType(id: "cafe",       name: "カフェ",           icon: "☕",
                         placeCost: 50_000,     upgradeMult: 3.5, baseIncome: 50,
                         incomeMult: 1.6, maxLevel: 5, cr: 0.85, cg: 0.5,  cb: 0.22),
        CityBuildingType(id: "restaurant", name: "レストラン",        icon: "🍜",
                         placeCost: 300_000,    upgradeMult: 3.5, baseIncome: 300,
                         incomeMult: 1.7, maxLevel: 4, cr: 0.78, cg: 0.22, cb: 0.22),
        CityBuildingType(id: "hotel",      name: "ホテル",            icon: "🏨",
                         placeCost: 2_000_000,  upgradeMult: 4.0, baseIncome: 2_000,
                         incomeMult: 1.8, maxLevel: 4, cr: 0.22, cg: 0.42, cb: 0.82),
        CityBuildingType(id: "mall",       name: "ショッピングモール", icon: "🏬",
                         placeCost: 10_000_000, upgradeMult: 4.0, baseIncome: 10_000,
                         incomeMult: 1.9, maxLevel: 3, cr: 0.58, cg: 0.18, cb: 0.80),
        CityBuildingType(id: "tower",      name: "タワー",            icon: "🗼",
                         placeCost: 80_000_000, upgradeMult: 5.0, baseIncome: 80_000,
                         incomeMult: 2.0, maxLevel: 3, cr: 0.18, cg: 0.72, cb: 0.72),
    ]
}

struct CityBuilding {
    var typeId: String
    var level: Int
    var incomePerSec: Double {
        CityBuildingType.all.first(where: { $0.id == typeId })?.incomePerSec(level: level) ?? 0
    }
}

// MARK: - CityScene

class CityScene: SKScene {

    private let gm = GameManager.shared
    private let topBarH:   CGFloat = 56
    private let cityViewH: CGFloat = 215
    private let plotCount  = 6
    private let cardH:     CGFloat = 148
    private let colGap:    CGFloat = 10
    private let rowGap:    CGFloat = 10
    private let sideMargin: CGFloat = 12
    private let cardW: CGFloat

    private var moneyLabel:  SKLabelNode!
    private var incomeLabel: SKLabelNode!
    private var cityNode:    SKNode!
    private var scrollContainer = SKNode()
    private var cropNode: SKCropNode!
    private var selectionOverlay: SKNode?

    // Scroll
    private var isDragging = false
    private var dragStartY:  CGFloat = 0
    private var scrollStartY: CGFloat = 0
    private var velocity:    CGFloat = 0
    private var lastDragY:   CGFloat = 0
    private var lastDragTime: TimeInterval = 0
    private var maxScrollUp: CGFloat = 0

    override init(size: CGSize) {
        cardW = (size.width - 2 * 12 - 10) / 2
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0)
        setupTopBar()
        setupCityView()
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

        // Gold accent line at bottom of top bar
        let accent = SKShapeNode(rectOf: CGSize(width: frame.width, height: 1.5))
        accent.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.45)
        accent.strokeColor = .clear
        accent.position = CGPoint(x: frame.midX, y: frame.height - topBarH)
        accent.zPosition = 12
        addChild(accent)

        // Subtle glow under accent
        let accentGlow = SKShapeNode(rectOf: CGSize(width: frame.width, height: 8))
        accentGlow.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.07)
        accentGlow.strokeColor = .clear
        accentGlow.position = CGPoint(x: frame.midX, y: frame.height - topBarH - 2)
        accentGlow.zPosition = 3
        addChild(accentGlow)

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

        let title = SKLabelNode(text: "🌆 都市開発")
        title.fontName = "HiraginoSans-W6"
        title.fontSize = 17
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: frame.midX, y: frame.height - topBarH / 2)
        title.zPosition = 11
        addChild(title)

        moneyLabel = SKLabelNode()
        moneyLabel.fontName = "HiraginoSans-W7"
        moneyLabel.fontSize = 13
        moneyLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.2, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .right
        moneyLabel.verticalAlignmentMode   = .center
        moneyLabel.position = CGPoint(x: frame.width - 12, y: frame.height - topBarH / 2 + 8)
        moneyLabel.zPosition = 11
        addChild(moneyLabel)

        incomeLabel = SKLabelNode()
        incomeLabel.fontName = "HiraginoSans-W4"
        incomeLabel.fontSize = 11
        incomeLabel.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.55, alpha: 0.9)
        incomeLabel.horizontalAlignmentMode = .right
        incomeLabel.verticalAlignmentMode   = .center
        incomeLabel.position = CGPoint(x: frame.width - 12, y: frame.height - topBarH / 2 - 8)
        incomeLabel.zPosition = 11
        addChild(incomeLabel)

        updateLabels()
    }

    // MARK: - City View

    private func setupCityView() {
        let viewY = frame.height - topBarH - cityViewH / 2 - 6
        cityNode = SKNode()
        cityNode.position = CGPoint(x: frame.midX, y: viewY)
        cityNode.zPosition = 5
        addChild(cityNode)

        // Cover so scrolled cards go behind it
        let cover = SKSpriteNode(color: UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 1.0),
                                  size: CGSize(width: frame.width, height: topBarH + cityViewH + 14))
        cover.anchorPoint = CGPoint(x: 0, y: 0)
        cover.position = CGPoint(x: 0, y: frame.height - topBarH - cityViewH - 14)
        cover.zPosition = 4
        addChild(cover)

        drawCityView()
    }

    // MARK: - Isometric City View

    // Tile constants
    private let tW: CGFloat = 76
    private let tH: CGFloat = 38
    private let gox: CGFloat = -19   // center the 3-col iso grid
    private let goy: CGFloat = -22   // push grid into lower half

    /// (col,row) → cityNode local coordinate of tile center
    private func isoCenter(col: Int, row: Int) -> CGPoint {
        CGPoint(x: CGFloat(col - row) * tW / 2 + gox,
                y: -CGFloat(col + row) * tH / 2 + goy)
    }

    private func drawCityView() {
        cityNode.removeAllChildren()

        let vw = frame.width - 16
        let vh = cityViewH

        // ===== Layer 1: Sky background =====
        let skyBase = SKShapeNode(rectOf: CGSize(width: vw, height: vh), cornerRadius: 12)
        skyBase.fillColor   = UIColor(red: 0.50, green: 0.76, blue: 0.93, alpha: 1.0)
        skyBase.strokeColor = UIColor(red: 0.30, green: 0.50, blue: 0.82, alpha: 0.55)
        skyBase.lineWidth   = 1.5
        skyBase.zPosition   = 1
        cityNode.addChild(skyBase)

        // Lighter top sky
        let skyTop = SKShapeNode(rectOf: CGSize(width: vw - 4, height: vh * 0.45))
        skyTop.fillColor   = UIColor(red: 0.65, green: 0.88, blue: 0.98, alpha: 1.0)
        skyTop.strokeColor = .clear
        skyTop.position    = CGPoint(x: 0, y: vh * 0.275)
        skyTop.zPosition   = 2
        cityNode.addChild(skyTop)

        // ===== Layer 2: Distant city silhouette =====
        let horizonY: CGFloat = vh * 0.18
        let bgBldgs: [(x: CGFloat, w: CGFloat, h: CGFloat)] = [
            (-vw*0.40, 20, 50), (-vw*0.24, 16, 66), (-vw*0.10, 26, 40),
            ( vw*0.04, 22, 58), ( vw*0.18, 30, 72), ( vw*0.33, 22, 48),
            (-vw*0.44, 14, 32), ( vw*0.42, 16, 36)
        ]
        for b in bgBldgs {
            let s = SKShapeNode(rectOf: CGSize(width: b.w, height: b.h))
            s.fillColor   = UIColor(red: 0.20, green: 0.30, blue: 0.55, alpha: 0.60)
            s.strokeColor = .clear
            s.position    = CGPoint(x: b.x, y: horizonY + b.h/2)
            s.zPosition   = 3
            cityNode.addChild(s)
            // Window lights
            for wr in 0..<Int(b.h / 16) {
                guard Bool.random() else { continue }
                let win = SKShapeNode(rectOf: CGSize(width: 3, height: 2))
                win.fillColor   = UIColor(red: 1.0, green: 0.95, blue: 0.55, alpha: CGFloat.random(in: 0.4...0.8))
                win.strokeColor = .clear
                win.position    = CGPoint(x: b.x + CGFloat.random(in: -b.w*0.3...b.w*0.3),
                                          y: horizonY + CGFloat(wr+1) * b.h / (CGFloat(Int(b.h/16))+1))
                win.zPosition   = 4
                cityNode.addChild(win)
            }
        }

        // ===== Layer 3: Water strip =====
        let waterMidY: CGFloat = vh * 0.11
        let waterH:    CGFloat = 28
        let waterPath = CGMutablePath()
        waterPath.move(to:    CGPoint(x: -vw/2, y: waterMidY + waterH * 0.58))
        waterPath.addLine(to: CGPoint(x:  vw/2, y: waterMidY + waterH * 0.42))
        waterPath.addLine(to: CGPoint(x:  vw/2, y: waterMidY - waterH * 0.42))
        waterPath.addLine(to: CGPoint(x: -vw/2, y: waterMidY - waterH * 0.58))
        waterPath.closeSubpath()
        let water = SKShapeNode(path: waterPath)
        water.fillColor   = UIColor(red: 0.16, green: 0.52, blue: 0.88, alpha: 1.0)
        water.strokeColor = .clear
        water.zPosition   = 5
        cityNode.addChild(water)
        // Shimmer
        for i in 0..<5 {
            let sw = CGFloat.random(in: 30...75)
            let sh = SKShapeNode(rectOf: CGSize(width: sw, height: 1.5), cornerRadius: 0.5)
            sh.fillColor   = UIColor(white: 1.0, alpha: 0.28)
            sh.strokeColor = .clear
            sh.position    = CGPoint(x: -vw/2 + CGFloat(i) * vw/4 + CGFloat.random(in: -8...8),
                                     y: waterMidY + CGFloat(i % 3 - 1) * 5)
            sh.zPosition   = 6
            cityNode.addChild(sh)
            sh.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.05, duration: Double.random(in: 1.1...2.6)),
                SKAction.fadeAlpha(to: 0.35, duration: Double.random(in: 1.1...2.6))
            ])))
        }

        // ===== Layer 4: Ground base =====
        let groundTopY: CGFloat = waterMidY - waterH * 0.5
        let groundH = groundTopY + vh/2
        let groundNode = SKShapeNode(rectOf: CGSize(width: vw - 4, height: groundH))
        groundNode.fillColor   = UIColor(red: 0.24, green: 0.40, blue: 0.18, alpha: 1.0)
        groundNode.strokeColor = .clear
        groundNode.position    = CGPoint(x: 0, y: groundTopY - groundH/2)
        groundNode.zPosition   = 6
        cityNode.addChild(groundNode)

        // Road base
        let roadBase = SKShapeNode(rectOf: CGSize(width: vw - 4, height: groundH * 0.68))
        roadBase.fillColor   = UIColor(red: 0.27, green: 0.27, blue: 0.29, alpha: 0.72)
        roadBase.strokeColor = .clear
        roadBase.position    = CGPoint(x: 0, y: groundTopY - groundH * 0.34 - 6)
        roadBase.zPosition   = 7
        cityNode.addChild(roadBase)

        // ===== Layer 5: Isometric plots (depth-sorted) =====
        let plotOrder: [(col: Int, row: Int, plot: Int)] = [
            (0,0,0),(1,0,1),(2,0,2),(0,1,3),(1,1,4),(2,1,5)
        ].sorted { ($0.col + $0.row) < ($1.col + $1.row) }

        for p in plotOrder {
            let center = isoCenter(col: p.col, row: p.row)
            let baseZ  = CGFloat(p.col + p.row) * 14 + 20

            // Road diamond
            drawIsoTile(center: center, w: tW + 10, h: tH + 5,
                        fill: UIColor(red: 0.30, green: 0.30, blue: 0.32, alpha: 1.0), z: baseZ)
            // Sidewalk diamond
            drawIsoTile(center: center, w: tW - 2, h: tH - 1,
                        fill: UIColor(red: 0.58, green: 0.56, blue: 0.52, alpha: 1.0), z: baseZ + 1)

            if let bld = gm.cityBuildings[p.plot],
               let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }) {
                drawIsoBuilding(center: center, type: t, level: bld.level, baseZ: baseZ + 2)
            } else {
                drawIsoEmptyPlot(center: center, baseZ: baseZ + 2)
            }
        }

        // ===== Layer 6: Trees =====
        let treeSpots: [CGPoint] = [
            CGPoint(x: gox - tW - 8,         y: goy + 10),
            CGPoint(x: gox + tW * 1.5 + 14,  y: goy - tH + 6),
            CGPoint(x: gox - tW * 0.5 - 18,  y: goy - tH * 1.5 - 4),
            CGPoint(x: gox + tW + 10,         y: goy + tH * 0.5 + 6),
            CGPoint(x: -vw/2 + 18,            y: goy + 12),
            CGPoint(x:  vw/2 - 18,            y: goy - 16),
        ]
        for sp in treeSpots { addIsoTree(at: sp) }

        // Street lights at road intersections
        let lightPositions: [CGPoint] = [
            CGPoint(x: isoCenter(col:1,row:0).x + tW/2, y: isoCenter(col:1,row:0).y),
            CGPoint(x: isoCenter(col:1,row:1).x - tW/2, y: isoCenter(col:1,row:1).y),
        ]
        for lp in lightPositions { addIsoStreetLight(at: lp) }

        // ===== Income label =====
        let cityInc = gm.cityIncomePerSec
        let incLbl = SKLabelNode(
            text: cityInc > 0 ? "都市収益  +✦\(formatMoney(cityInc))/s" : "建物を建てて都市を発展させよう"
        )
        incLbl.fontName = "HiraginoSans-W4"
        incLbl.fontSize = 11
        incLbl.fontColor = UIColor(red: 0.42, green: 1.0, blue: 0.58, alpha: 0.88)
        incLbl.position  = CGPoint(x: 0, y: -vh / 2 + 8)
        incLbl.zPosition = 90
        cityNode.addChild(incLbl)
    }

    // MARK: - Iso Helpers

    private func drawIsoTile(center: CGPoint, w: CGFloat, h: CGFloat, fill: UIColor, z: CGFloat) {
        let p = CGMutablePath()
        p.move(to:    CGPoint(x: center.x,     y: center.y + h/2))
        p.addLine(to: CGPoint(x: center.x+w/2, y: center.y))
        p.addLine(to: CGPoint(x: center.x,     y: center.y - h/2))
        p.addLine(to: CGPoint(x: center.x-w/2, y: center.y))
        p.closeSubpath()
        let tile = SKShapeNode(path: p)
        tile.fillColor   = fill
        tile.strokeColor = UIColor(white: 0, alpha: 0.12)
        tile.lineWidth   = 0.5
        tile.zPosition   = z
        cityNode.addChild(tile)
    }

    private func drawIsoBuilding(center: CGPoint, type t: CityBuildingType, level: Int, baseZ: CGFloat) {
        let bh = t.buildingHeight(level: level) * 0.48
        let fw = tW * 0.70
        let fd = tH * 0.70

        let br = min(0.55 + CGFloat(level-1) * 0.09, 1.0)
        let rr = min(t.cr * br + 0.12, 1.0)
        let rg = min(t.cg * br + 0.12, 1.0)
        let rb = min(t.cb * br + 0.14, 1.0)

        // Front-left face
        let fl = CGMutablePath()
        fl.move(to:    CGPoint(x: center.x,      y: center.y - fd/2))
        fl.addLine(to: CGPoint(x: center.x-fw/2, y: center.y))
        fl.addLine(to: CGPoint(x: center.x-fw/2, y: center.y + bh))
        fl.addLine(to: CGPoint(x: center.x,      y: center.y - fd/2 + bh))
        fl.closeSubpath()
        let leftFace = SKShapeNode(path: fl)
        leftFace.fillColor   = UIColor(red: rr*0.62, green: rg*0.62, blue: rb*0.65, alpha: 1.0)
        leftFace.strokeColor = UIColor(white: 0, alpha: 0.14)
        leftFace.lineWidth   = 0.5
        leftFace.zPosition   = baseZ
        cityNode.addChild(leftFace)

        // Front-right face
        let fr = CGMutablePath()
        fr.move(to:    CGPoint(x: center.x,      y: center.y - fd/2))
        fr.addLine(to: CGPoint(x: center.x+fw/2, y: center.y))
        fr.addLine(to: CGPoint(x: center.x+fw/2, y: center.y + bh))
        fr.addLine(to: CGPoint(x: center.x,      y: center.y - fd/2 + bh))
        fr.closeSubpath()
        let rightFace = SKShapeNode(path: fr)
        rightFace.fillColor   = UIColor(red: rr*0.44, green: rg*0.44, blue: rb*0.47, alpha: 1.0)
        rightFace.strokeColor = UIColor(white: 0, alpha: 0.14)
        rightFace.lineWidth   = 0.5
        rightFace.zPosition   = baseZ
        cityNode.addChild(rightFace)

        // Roof face
        let rf = CGMutablePath()
        rf.move(to:    CGPoint(x: center.x,      y: center.y + fd/2 + bh))
        rf.addLine(to: CGPoint(x: center.x+fw/2, y: center.y + bh))
        rf.addLine(to: CGPoint(x: center.x,      y: center.y - fd/2 + bh))
        rf.addLine(to: CGPoint(x: center.x-fw/2, y: center.y + bh))
        rf.closeSubpath()
        let roofFace = SKShapeNode(path: rf)
        roofFace.fillColor   = UIColor(red: rr, green: rg, blue: rb, alpha: 1.0)
        roofFace.strokeColor = UIColor(white: 1.0, alpha: 0.10)
        roofFace.lineWidth   = 0.5
        roofFace.zPosition   = baseZ + 1
        cityNode.addChild(roofFace)

        // Windows on front-left face (parallelogram interpolation)
        if bh > 20 {
            let wRows = max(1, Int(bh / 15))
            let wCols = 3
            for wr in 0..<wRows {
                for wc in 0..<wCols {
                    guard Bool.random() || Bool.random() else { continue }
                    let u = CGFloat(wc+1) / CGFloat(wCols+1)
                    let v = CGFloat(wr+1) / CGFloat(wRows+1)
                    let wx = center.x - u * fw/2
                    let wy = center.y - fd/2 + u * fd/2 + v * bh
                    let win = SKShapeNode(rectOf: CGSize(width: 3.0, height: 2.5), cornerRadius: 0.3)
                    win.fillColor   = UIColor(red: 1.0, green: CGFloat.random(in: 0.85...0.98),
                                              blue: CGFloat.random(in: 0.4...0.65),
                                              alpha: CGFloat.random(in: 0.5...0.92))
                    win.strokeColor = .clear
                    win.position    = CGPoint(x: wx, y: wy)
                    win.zPosition   = baseZ + 2
                    cityNode.addChild(win)
                }
            }
        }

        // Roof details per type
        let roofCenter = CGPoint(x: center.x, y: center.y + bh)
        switch t.id {
        case "tower":
            let ant = SKShapeNode(rectOf: CGSize(width: 2.5, height: bh * 0.32), cornerRadius: 1)
            ant.fillColor   = UIColor(white: 0.78, alpha: 0.92)
            ant.strokeColor = .clear
            ant.position    = CGPoint(x: center.x, y: center.y + bh + bh * 0.16)
            ant.zPosition   = baseZ + 5
            cityNode.addChild(ant)
            let lamp = SKShapeNode(circleOfRadius: 2.5)
            lamp.fillColor   = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
            lamp.strokeColor = .clear
            lamp.position    = CGPoint(x: center.x, y: center.y + bh + bh * 0.32)
            lamp.zPosition   = baseZ + 6
            cityNode.addChild(lamp)
            lamp.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.7),
                SKAction.fadeAlpha(to: 1.0, duration: 0.7)
            ])))
        case "hotel":
            let pool = SKShapeNode(ellipseOf: CGSize(width: fw * 0.30, height: fd * 0.25))
            pool.fillColor   = UIColor(red: 0.2, green: 0.62, blue: 0.92, alpha: 0.85)
            pool.strokeColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.5)
            pool.lineWidth   = 1
            pool.position    = CGPoint(x: roofCenter.x + fw * 0.10, y: roofCenter.y + fd * 0.05)
            pool.zPosition   = baseZ + 3
            cityNode.addChild(pool)
        case "mall":
            for i in 0..<3 {
                let stripe = SKShapeNode(rectOf: CGSize(width: fw * 0.48, height: 2.5), cornerRadius: 1)
                stripe.fillColor   = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.20)
                stripe.strokeColor = .clear
                stripe.position    = CGPoint(x: roofCenter.x, y: roofCenter.y + CGFloat(i-1) * 6)
                stripe.zPosition   = baseZ + 3
                cityNode.addChild(stripe)
            }
        default: break
        }

        // Icon on roof
        let icon = SKLabelNode(text: t.icon)
        icon.fontSize  = min(fw, fd) * 0.46
        icon.alpha     = 0.62
        icon.verticalAlignmentMode = .center
        icon.position  = CGPoint(x: center.x, y: center.y + bh + 2)
        icon.zPosition = baseZ + 3
        cityNode.addChild(icon)

        // Ambient glow
        let glowPath = CGMutablePath()
        glowPath.move(to:    CGPoint(x: center.x,         y: center.y + (fd/2 + 4) + bh))
        glowPath.addLine(to: CGPoint(x: center.x+(fw/2+4), y: center.y + bh))
        glowPath.addLine(to: CGPoint(x: center.x,         y: center.y - (fd/2 + 4) + bh))
        glowPath.addLine(to: CGPoint(x: center.x-(fw/2+4), y: center.y + bh))
        glowPath.closeSubpath()
        let glowNode = SKShapeNode(path: glowPath)
        glowNode.fillColor   = UIColor(red: t.cr*0.4, green: t.cg*0.4, blue: t.cb*0.4, alpha: 0.0)
        glowNode.strokeColor = UIColor(red: t.cr*0.6+0.1, green: t.cg*0.6+0.1, blue: t.cb*0.6+0.1, alpha: 0.32)
        glowNode.lineWidth   = 2
        glowNode.zPosition   = baseZ - 1
        cityNode.addChild(glowNode)
        glowNode.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.05, duration: Double.random(in: 1.6...3.0)),
            SKAction.fadeAlpha(to: 0.32, duration: Double.random(in: 1.6...3.0))
        ])))

        // Level badge
        if level > 1 {
            let badge = SKShapeNode(rectOf: CGSize(width: 20, height: 12), cornerRadius: 3)
            badge.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 0.92)
            badge.strokeColor = .clear
            badge.position    = CGPoint(x: center.x + fw/2 - 8, y: center.y + bh + fd/2 - 4)
            badge.zPosition   = baseZ + 7
            cityNode.addChild(badge)
            let lvLbl = SKLabelNode(text: "L\(level)")
            lvLbl.fontName = "HiraginoSans-W8"
            lvLbl.fontSize = 8
            lvLbl.fontColor = UIColor(red: 0.08, green: 0.05, blue: 0.0, alpha: 1.0)
            lvLbl.verticalAlignmentMode = .center
            lvLbl.position  = badge.position
            lvLbl.zPosition = baseZ + 8
            cityNode.addChild(lvLbl)
        }
    }

    private func drawIsoEmptyPlot(center: CGPoint, baseZ: CGFloat) {
        drawIsoTile(center: center, w: tW - 4, h: tH - 2,
                    fill: UIColor(red: 0.18, green: 0.34, blue: 0.14, alpha: 1.0), z: baseZ)
        for (w, h): (CGFloat, CGFloat) in [(12, 1.5), (1.5, 12)] {
            let arm = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 0.5)
            arm.fillColor   = UIColor(white: 0.40, alpha: 0.48)
            arm.strokeColor = .clear
            arm.position    = center
            arm.zPosition   = baseZ + 1
            cityNode.addChild(arm)
        }
    }

    private func addIsoTree(at pos: CGPoint) {
        let trunk = SKShapeNode(rectOf: CGSize(width: 3.5, height: 7), cornerRadius: 1)
        trunk.fillColor   = UIColor(red: 0.40, green: 0.26, blue: 0.10, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position    = pos
        trunk.zPosition   = 70
        cityNode.addChild(trunk)
        let sizes: [(CGFloat, CGFloat)] = [(9, 9), (7, 17), (5, 23)]
        for (r, yo) in sizes {
            let leaf = SKShapeNode(circleOfRadius: r)
            leaf.fillColor   = UIColor(red: CGFloat.random(in: 0.12...0.20),
                                        green: CGFloat.random(in: 0.52...0.68),
                                        blue: CGFloat.random(in: 0.10...0.20), alpha: 0.95)
            leaf.strokeColor = .clear
            leaf.position    = CGPoint(x: pos.x + CGFloat.random(in: -1.5...1.5), y: pos.y + yo)
            leaf.zPosition   = 71
            cityNode.addChild(leaf)
        }
    }

    private func addIsoStreetLight(at pos: CGPoint) {
        let dot = SKShapeNode(circleOfRadius: 2.5)
        dot.fillColor   = UIColor(red: 1.0, green: 0.94, blue: 0.6, alpha: 0.88)
        dot.strokeColor = .clear
        dot.position    = pos
        dot.zPosition   = 72
        cityNode.addChild(dot)
        let halo = SKShapeNode(circleOfRadius: 8)
        halo.fillColor   = UIColor(red: 1.0, green: 0.92, blue: 0.5, alpha: 0.08)
        halo.strokeColor = .clear
        halo.position    = pos
        halo.zPosition   = 71
        cityNode.addChild(halo)
        dot.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 2.0),
            SKAction.fadeAlpha(to: 0.92, duration: 2.0)
        ])))
    }

    // placeholders so legacy call-sites compile (no longer called)
    private func addTree(at pos: CGPoint) {}

    // MARK: - Scroll List (plot cards)

    private var cardListTopY: CGFloat {
        frame.height - topBarH - cityViewH - 12
    }

    private func setupScrollList() {
        cropNode = SKCropNode()
        cropNode.position = .zero
        cropNode.zPosition = 2
        let mask = SKSpriteNode(color: .white, size: CGSize(width: frame.width, height: cardListTopY))
        mask.anchorPoint = CGPoint(x: 0.5, y: 0)
        mask.position = CGPoint(x: frame.midX, y: 0)
        cropNode.maskNode = mask
        addChild(cropNode)
        cropNode.addChild(scrollContainer)
        buildCards()
    }

    private func buildCards() {
        scrollContainer.removeAllChildren()

        let firstY = cardListTopY - rowGap - cardH / 2
        for i in 0..<plotCount {
            let col = i % 2
            let row = i / 2
            let x = sideMargin + cardW / 2 + CGFloat(col) * (cardW + colGap)
            let y = firstY - CGFloat(row) * (cardH + rowGap)
            let card = makePlotCard(plot: i)
            card.position = CGPoint(x: x, y: y)
            scrollContainer.addChild(card)
        }

        let rows = (plotCount + 1) / 2
        let totalH = CGFloat(rows) * (cardH + rowGap) + rowGap
        maxScrollUp = max(0, totalH - cardListTopY + 20)
    }

    private func makePlotCard(plot: Int) -> SKNode {
        let container = SKNode()
        container.name = "plot_\(plot)"

        if let bld = gm.cityBuildings[plot],
           let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }) {
            // Occupied card
            let maxed = bld.level >= t.maxLevel
            let upgCost = t.upgradeCost(level: bld.level)
            let canAfford = gm.money >= upgCost

            let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
            bg.fillColor = UIColor(red: t.cr * 0.15, green: t.cg * 0.15 + 0.05, blue: t.cb * 0.15 + 0.12, alpha: 0.95)
            bg.strokeColor = UIColor(red: t.cr * 0.6 + 0.2, green: t.cg * 0.6 + 0.2, blue: t.cb * 0.6 + 0.2, alpha: 0.7)
            bg.lineWidth = 1.5
            bg.name = "plot_\(plot)"
            container.addChild(bg)

            let iconLbl = SKLabelNode(text: t.icon)
            iconLbl.fontSize = 28
            iconLbl.verticalAlignmentMode = .center
            iconLbl.position = CGPoint(x: 0, y: cardH/2 - 26)
            container.addChild(iconLbl)

            let nameLbl = SKLabelNode(text: t.name)
            nameLbl.fontName = "HiraginoSans-W7"
            nameLbl.fontSize = 12
            nameLbl.fontColor = .white
            nameLbl.verticalAlignmentMode = .center
            nameLbl.position = CGPoint(x: 0, y: cardH/2 - 50)
            container.addChild(nameLbl)

            // Level dots
            let dotSpacing: CGFloat = 12
            let totalW = CGFloat(t.maxLevel) * dotSpacing
            for d in 0..<t.maxLevel {
                let dot = SKShapeNode(circleOfRadius: 4)
                dot.fillColor = d < bld.level
                    ? UIColor(red: 0.3, green: 0.9, blue: 0.45, alpha: 1.0)
                    : UIColor(white: 0.2, alpha: 1.0)
                dot.strokeColor = UIColor(white: 0.35, alpha: 0.5)
                dot.lineWidth = 1
                dot.position = CGPoint(x: -totalW/2 + 6 + CGFloat(d) * dotSpacing, y: cardH/2 - 66)
                container.addChild(dot)
            }

            // Income pill badge
            let incomePill = SKShapeNode(rectOf: CGSize(width: 100, height: 18), cornerRadius: 9)
            incomePill.fillColor = UIColor(red: 0.08, green: 0.32, blue: 0.12, alpha: 0.85)
            incomePill.strokeColor = UIColor(red: 0.28, green: 0.88, blue: 0.42, alpha: 0.5)
            incomePill.lineWidth = 1
            incomePill.position = CGPoint(x: 0, y: cardH/2 - 84)
            container.addChild(incomePill)

            let incLbl = SKLabelNode(text: "+✦\(formatMoney(bld.incomePerSec))/s")
            incLbl.fontName = "HiraginoSans-W5"
            incLbl.fontSize = 11
            incLbl.fontColor = UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.95)
            incLbl.verticalAlignmentMode = .center
            incLbl.position = CGPoint(x: 0, y: cardH/2 - 84)
            container.addChild(incLbl)

            let btnY: CGFloat = -(cardH/2 - 22)
            if maxed {
                let maxPill = SKShapeNode(rectOf: CGSize(width: cardW - 18, height: 30), cornerRadius: 10)
                maxPill.fillColor = UIColor(red: 0.1, green: 0.32, blue: 0.15, alpha: 0.7)
                maxPill.strokeColor = UIColor(red: 0.3, green: 0.9, blue: 0.42, alpha: 0.5)
                maxPill.lineWidth = 1
                maxPill.position = CGPoint(x: 0, y: btnY)
                container.addChild(maxPill)
                let badge = SKLabelNode(text: "✅ MAX")
                badge.fontName = "HiraginoSans-W6"
                badge.fontSize = 13
                badge.fontColor = UIColor(red: 0.4, green: 1.0, blue: 0.55, alpha: 1.0)
                badge.verticalAlignmentMode = .center
                badge.position = CGPoint(x: 0, y: btnY)
                badge.zPosition = 1
                container.addChild(badge)
            } else {
                // Glow ring when affordable (pulsing)
                if canAfford {
                    let glow = SKShapeNode(rectOf: CGSize(width: cardW - 12, height: 36), cornerRadius: 12)
                    glow.fillColor = .clear
                    glow.strokeColor = UIColor(red: 0.4, green: 0.72, blue: 1.0, alpha: 0.7)
                    glow.lineWidth = 2.5
                    glow.position = CGPoint(x: 0, y: btnY)
                    glow.zPosition = 1
                    let pulse = SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.15, duration: 0.75),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.75)
                    ])
                    glow.run(SKAction.repeatForever(pulse))
                    container.addChild(glow)
                }

                let btnBg = SKShapeNode(rectOf: CGSize(width: cardW - 18, height: 30), cornerRadius: 10)
                btnBg.name = "upgradeBtn_\(plot)"
                btnBg.zPosition = 2
                btnBg.fillColor = canAfford
                    ? UIColor(red: 0.18, green: 0.42, blue: 0.92, alpha: 0.92)
                    : UIColor(red: 0.14, green: 0.14, blue: 0.26, alpha: 0.85)
                btnBg.strokeColor = canAfford
                    ? UIColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 0.55)
                    : UIColor(red: 0.26, green: 0.26, blue: 0.46, alpha: 0.45)
                btnBg.lineWidth = 1
                btnBg.position = CGPoint(x: 0, y: btnY)
                container.addChild(btnBg)

                // Arrow icon prefix for upgrade
                let arrowIcon = SKLabelNode(text: canAfford ? "⬆" : "🔒")
                arrowIcon.fontSize = 10
                arrowIcon.verticalAlignmentMode = .center
                arrowIcon.position = CGPoint(x: -(cardW - 18) / 2 + 14, y: btnY)
                arrowIcon.zPosition = 3
                container.addChild(arrowIcon)

                let btnLbl = SKLabelNode(text: "UP ✦\(formatMoney(upgCost))")
                btnLbl.fontName = "HiraginoSans-W6"
                btnLbl.fontSize = 12
                btnLbl.fontColor = canAfford ? .white : UIColor(white: 0.36, alpha: 1.0)
                btnLbl.verticalAlignmentMode = .center
                btnLbl.position = CGPoint(x: 6, y: btnY)
                btnLbl.zPosition = 3
                btnLbl.name = "upgradeBtn_\(plot)"
                container.addChild(btnLbl)
            }

        } else {
            // Empty plot card
            let bg = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 14)
            bg.fillColor = UIColor(red: 0.06, green: 0.07, blue: 0.18, alpha: 0.9)
            bg.strokeColor = UIColor(red: 0.3, green: 0.35, blue: 0.6, alpha: 0.5)
            bg.lineWidth = 1.5
            bg.name = "plot_\(plot)"
            container.addChild(bg)

            let emptyIcon = SKLabelNode(text: "🏗️")
            emptyIcon.fontSize = 30
            emptyIcon.verticalAlignmentMode = .center
            emptyIcon.position = CGPoint(x: 0, y: 20)
            container.addChild(emptyIcon)

            let emptyLbl = SKLabelNode(text: "空き地 #\(plot + 1)")
            emptyLbl.fontName = "HiraginoSans-W5"
            emptyLbl.fontSize = 13
            emptyLbl.fontColor = UIColor(white: 0.55, alpha: 1.0)
            emptyLbl.verticalAlignmentMode = .center
            emptyLbl.position = CGPoint(x: 0, y: -8)
            container.addChild(emptyLbl)

            let buildBtn = SKShapeNode(rectOf: CGSize(width: cardW - 18, height: 32), cornerRadius: 10)
            buildBtn.name = "buildBtn_\(plot)"
            buildBtn.zPosition = 2
            buildBtn.fillColor = UIColor(red: 0.3, green: 0.25, blue: 0.55, alpha: 0.9)
            buildBtn.strokeColor = UIColor(red: 0.55, green: 0.45, blue: 0.9, alpha: 0.7)
            buildBtn.lineWidth = 1
            buildBtn.position = CGPoint(x: 0, y: -(cardH/2 - 22))
            container.addChild(buildBtn)

            let buildLbl = SKLabelNode(text: "＋ 建設する")
            buildLbl.fontName = "HiraginoSans-W6"
            buildLbl.fontSize = 13
            buildLbl.fontColor = .white
            buildLbl.verticalAlignmentMode = .center
            buildLbl.position = buildBtn.position
            buildLbl.zPosition = 3
            buildLbl.name = "buildBtn_\(plot)"
            container.addChild(buildLbl)
        }

        return container
    }

    // MARK: - Building Selection Overlay

    private func showBuildingSelection(plot: Int) {
        selectionOverlay?.removeFromParent()

        let overlay = SKNode()
        overlay.zPosition = 50

        // Dimming background
        let dim = SKSpriteNode(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.72), size: frame.size)
        dim.position = CGPoint(x: frame.midX, y: frame.midY)
        dim.name = "dismissOverlay"
        overlay.addChild(dim)

        // Panel
        let panelW: CGFloat = frame.width - 30
        let panelH: CGFloat = CGFloat(CityBuildingType.all.count) * 68 + 80
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 20)
        panel.fillColor = UIColor(red: 0.05, green: 0.06, blue: 0.16, alpha: 0.98)
        panel.strokeColor = UIColor(red: 0.38, green: 0.5, blue: 0.92, alpha: 0.65)
        panel.lineWidth = 1.5
        panel.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.addChild(panel)

        // Panel header decoration — gold line
        let headerLine = SKShapeNode(rectOf: CGSize(width: panelW - 30, height: 1.5))
        headerLine.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.5)
        headerLine.strokeColor = .clear
        headerLine.position = CGPoint(x: frame.midX, y: frame.midY + panelH/2 - 44)
        overlay.addChild(headerLine)

        // Corner decoration dots
        for xSign: CGFloat in [-1, 1] {
            let corner = SKShapeNode(circleOfRadius: 3.5)
            corner.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.7)
            corner.strokeColor = .clear
            corner.position = CGPoint(x: frame.midX + xSign * (panelW/2 - 14), y: frame.midY + panelH/2 - 22)
            overlay.addChild(corner)
        }

        let titleLbl = SKLabelNode(text: "🏗️ 建物を選ぶ")
        titleLbl.fontName = "HiraginoSans-W7"
        titleLbl.fontSize = 16
        titleLbl.fontColor = .white
        titleLbl.verticalAlignmentMode = .center
        titleLbl.position = CGPoint(x: frame.midX, y: frame.midY + panelH/2 - 25)
        overlay.addChild(titleLbl)

        for (i, t) in CityBuildingType.all.enumerated() {
            let rowY = frame.midY + panelH/2 - 66 - CGFloat(i) * 68
            let canAfford = gm.money >= t.placeCost

            let rowBg = SKShapeNode(rectOf: CGSize(width: panelW - 20, height: 58), cornerRadius: 12)
            rowBg.fillColor = canAfford
                ? UIColor(red: t.cr * 0.22 + 0.04, green: t.cg * 0.22 + 0.04, blue: t.cb * 0.22 + 0.1, alpha: 0.92)
                : UIColor(white: 0.055, alpha: 0.85)
            rowBg.strokeColor = canAfford
                ? UIColor(red: t.cr * 0.55 + 0.18, green: t.cg * 0.55 + 0.18, blue: t.cb * 0.55 + 0.22, alpha: 0.65)
                : UIColor(white: 0.18, alpha: 0.3)
            rowBg.lineWidth = 1.2
            rowBg.position = CGPoint(x: frame.midX, y: rowY)
            rowBg.name = "selectBuilding_\(plot)_\(t.id)"
            // Slide-in entrance animation
            rowBg.alpha = 0
            rowBg.position.x += 24
            rowBg.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.16),
                    SKAction.moveBy(x: -24, y: 0, duration: 0.16)
                ])
            ]))
            overlay.addChild(rowBg)

            let iconLbl = SKLabelNode(text: t.icon)
            iconLbl.fontSize = 26
            iconLbl.verticalAlignmentMode = .center
            iconLbl.position = CGPoint(x: frame.midX - panelW/2 + 32, y: rowY)
            iconLbl.alpha = 0
            iconLbl.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06 + 0.1),
                SKAction.fadeIn(withDuration: 0.14)
            ]))
            overlay.addChild(iconLbl)

            let nameLbl = SKLabelNode(text: t.name)
            nameLbl.fontName = "HiraginoSans-W6"
            nameLbl.fontSize = 13
            nameLbl.fontColor = canAfford ? .white : UIColor(white: 0.35, alpha: 1.0)
            nameLbl.horizontalAlignmentMode = .left
            nameLbl.verticalAlignmentMode   = .center
            nameLbl.position = CGPoint(x: frame.midX - panelW/2 + 58, y: rowY + 9)
            nameLbl.alpha = 0
            nameLbl.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06 + 0.1),
                SKAction.fadeIn(withDuration: 0.14)
            ]))
            overlay.addChild(nameLbl)

            let costLbl = SKLabelNode(text: "✦\(formatMoney(t.placeCost))  /  +✦\(formatMoney(t.baseIncome))/s")
            costLbl.fontName = "HiraginoSans-W4"
            costLbl.fontSize = 11
            costLbl.fontColor = canAfford
                ? UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.85)
                : UIColor(white: 0.28, alpha: 1.0)
            costLbl.horizontalAlignmentMode = .left
            costLbl.verticalAlignmentMode   = .center
            costLbl.position = CGPoint(x: frame.midX - panelW/2 + 58, y: rowY - 11)
            costLbl.alpha = 0
            costLbl.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06 + 0.1),
                SKAction.fadeIn(withDuration: 0.14)
            ]))
            overlay.addChild(costLbl)

            // Max level badge on right
            let maxLvlTxt = "MAX Lv.\(t.maxLevel)"
            let maxBadge = SKLabelNode(text: maxLvlTxt)
            maxBadge.fontName = "HiraginoSans-W4"
            maxBadge.fontSize = 10
            maxBadge.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: canAfford ? 0.75 : 0.3)
            maxBadge.horizontalAlignmentMode = .right
            maxBadge.verticalAlignmentMode   = .center
            maxBadge.position = CGPoint(x: frame.midX + panelW/2 - 16, y: rowY)
            maxBadge.alpha = 0
            maxBadge.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.06 + 0.12),
                SKAction.fadeIn(withDuration: 0.14)
            ]))
            overlay.addChild(maxBadge)
        }

        // Cancel button
        let cancelBtn = SKShapeNode(rectOf: CGSize(width: panelW - 20, height: 38), cornerRadius: 12)
        cancelBtn.fillColor = UIColor(red: 0.18, green: 0.08, blue: 0.1, alpha: 0.85)
        cancelBtn.strokeColor = UIColor(red: 0.55, green: 0.22, blue: 0.22, alpha: 0.55)
        cancelBtn.lineWidth = 1.2
        cancelBtn.position = CGPoint(x: frame.midX, y: frame.midY - panelH/2 + 28)
        cancelBtn.name = "cancelOverlay"
        overlay.addChild(cancelBtn)

        let cancelLbl = SKLabelNode(text: "キャンセル")
        cancelLbl.fontName = "HiraginoSans-W5"
        cancelLbl.fontSize = 14
        cancelLbl.fontColor = UIColor(red: 0.9, green: 0.48, blue: 0.48, alpha: 1.0)
        cancelLbl.verticalAlignmentMode = .center
        cancelLbl.position = cancelBtn.position
        cancelLbl.name = "cancelOverlay"
        overlay.addChild(cancelLbl)

        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.18))
        addChild(overlay)
        selectionOverlay = overlay
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        isDragging = false
        dragStartY = t.location(in: self).y
        scrollStartY = scrollContainer.position.y
        velocity = 0
        lastDragY = t.location(in: self).y
        lastDragTime = t.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, selectionOverlay == nil else { return }
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

    private func clampScroll(_ y: CGFloat) -> CGFloat { max(min(0, y), -maxScrollUp) }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if !isDragging {
            if abs(velocity) > 1 {
                scrollContainer.position.y = clampScroll(scrollContainer.position.y + velocity * 0.016)
                velocity *= 0.92
            } else { velocity = 0 }
        }
        updateLabels()
    }

    private func updateLabels() {
        moneyLabel.text  = "✦\(formatMoney(gm.money))"
        let cityInc = gm.cityIncomePerSec
        incomeLabel.text = cityInc > 0 ? "都市: +✦\(formatMoney(cityInc))/s" : ""
    }

    // MARK: - Tap Handling

    private func handleTap(at loc: CGPoint) {
        // Overlay taps
        if selectionOverlay != nil {
            for node in nodes(at: loc) {
                guard let name = node.name else { continue }
                if name == "cancelOverlay" || name == "dismissOverlay" {
                    dismissOverlay()
                    return
                }
                if name.hasPrefix("selectBuilding_") {
                    let parts = name.split(separator: "_")
                    if parts.count >= 3,
                       let plot = Int(parts[1]) {
                        let typeId = String(parts[2])
                        attemptPlace(plot: plot, typeId: typeId)
                    }
                    return
                }
            }
            return
        }

        for node in nodes(at: loc) {
            guard let name = node.name else { continue }
            if name == "backBtn"             { goBack(); return }
            if name.hasPrefix("buildBtn_"),
               let plot = Int(name.dropFirst("buildBtn_".count)) {
                showBuildingSelection(plot: plot)
                return
            }
            if name.hasPrefix("upgradeBtn_"),
               let plot = Int(name.dropFirst("upgradeBtn_".count)) {
                attemptUpgrade(plot: plot)
                return
            }
            if name.hasPrefix("plot_"),
               let plot = Int(name.dropFirst("plot_".count)) {
                if gm.cityBuildings[plot] != nil {
                    attemptUpgrade(plot: plot)
                } else {
                    showBuildingSelection(plot: plot)
                }
                return
            }
        }
    }

    private func dismissOverlay() {
        selectionOverlay?.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
        selectionOverlay = nil
    }

    private func attemptPlace(plot: Int, typeId: String) {
        dismissOverlay()
        guard let t = CityBuildingType.all.first(where: { $0.id == typeId }) else { return }
        guard gm.money >= t.placeCost else {
            showToast("💸 お金が足りません (✦\(formatMoney(t.placeCost)) 必要)")
            return
        }
        if gm.placeBuilding(plot: plot, typeId: typeId) {
            buildCards()
            drawCityView()
            showBuildEffect(name: t.name)
        }
    }

    private func attemptUpgrade(plot: Int) {
        guard let bld = gm.cityBuildings[plot],
              let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }) else { return }
        guard bld.level < t.maxLevel else { return }
        let cost = t.upgradeCost(level: bld.level)
        guard gm.money >= cost else {
            showToast("💸 お金が足りません (✦\(formatMoney(cost)) 必要)")
            return
        }
        if gm.upgradeBuilding(plot: plot) {
            buildCards()
            drawCityView()
            showBuildEffect(name: "\(t.name) Lv.\(bld.level + 1)")
        }
    }

    // MARK: - Effects

    private func showBuildEffect(name: String) {
        // Gold burst particles
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.0))
            particle.fillColor = UIColor(red: 1.0, green: CGFloat.random(in: 0.7...0.95), blue: 0.1, alpha: 0.9)
            particle.strokeColor = .clear
            particle.position = CGPoint(x: frame.midX + CGFloat.random(in: -20...20),
                                        y: frame.height - topBarH - cityViewH / 2)
            particle.zPosition = 29
            addChild(particle)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist  = CGFloat.random(in: 30...70)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.55),
                    SKAction.fadeOut(withDuration: 0.55),
                    SKAction.scale(to: 0.1, duration: 0.55)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Banner
        let banner = SKNode()
        banner.zPosition = 30
        banner.position = CGPoint(x: frame.midX, y: frame.height - topBarH - cityViewH / 2)
        addChild(banner)

        let bannerBg = SKShapeNode(rectOf: CGSize(width: 220, height: 38), cornerRadius: 12)
        bannerBg.fillColor = UIColor(red: 0.10, green: 0.08, blue: 0.02, alpha: 0.95)
        bannerBg.strokeColor = UIColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 0.8)
        bannerBg.lineWidth = 1.5
        banner.addChild(bannerBg)

        let label = SKLabelNode(text: "🏗️ \(name) 完成！")
        label.fontName = "HiraginoSans-W7"
        label.fontSize = 16
        label.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.3, alpha: 1.0)
        label.verticalAlignmentMode = .center
        banner.addChild(label)

        banner.setScale(0.55)
        banner.alpha = 0
        banner.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.05, duration: 0.2), SKAction.fadeIn(withDuration: 0.2)]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.4),
            SKAction.group([SKAction.fadeOut(withDuration: 0.38), SKAction.moveBy(x: 0, y: 28, duration: 0.38)]),
            SKAction.removeFromParent()
        ]))
    }

    private func showToast(_ message: String) {
        let toastY: CGFloat = 72
        let bg = SKShapeNode(rectOf: CGSize(width: frame.width - 36, height: 42), cornerRadius: 12)
        bg.fillColor = UIColor(red: 0.10, green: 0.04, blue: 0.20, alpha: 0.97)
        bg.strokeColor = UIColor(red: 0.62, green: 0.30, blue: 0.90, alpha: 0.68)
        bg.lineWidth = 1.2
        bg.position = CGPoint(x: frame.midX, y: toastY - 20)
        bg.zPosition = 60
        bg.alpha = 0
        addChild(bg)

        let lbl = SKLabelNode(text: message)
        lbl.fontName = "HiraginoSans-W5"
        lbl.fontSize = 12
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        lbl.position = bg.position
        lbl.zPosition = 61
        lbl.alpha = 0
        addChild(lbl)

        let slideIn = SKAction.group([
            SKAction.moveBy(x: 0, y: 20, duration: 0.22),
            SKAction.fadeIn(withDuration: 0.22)
        ])
        let slideOut = SKAction.group([
            SKAction.moveBy(x: 0, y: 10, duration: 0.32),
            SKAction.fadeOut(withDuration: 0.32)
        ])
        let seq = SKAction.sequence([slideIn, SKAction.wait(forDuration: 2.0), slideOut, SKAction.removeFromParent()])
        bg.run(seq)
        lbl.run(seq)
    }

    // MARK: - Navigation

    private func goBack() {
        gm.saveGame()
        let scene = OfficeScene(size: frame.size)
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
