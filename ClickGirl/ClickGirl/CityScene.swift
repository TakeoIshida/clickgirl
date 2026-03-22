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

    // MARK: - Top-Down City View

    private func drawCityView() {
        cityNode.removeAllChildren()

        let vw = frame.width - 16
        let vh = cityViewH

        // --- 外枠背景 ---
        let outerBg = SKShapeNode(rectOf: CGSize(width: vw, height: vh), cornerRadius: 10)
        outerBg.fillColor = UIColor(red: 0.07, green: 0.08, blue: 0.16, alpha: 1.0)
        outerBg.strokeColor = UIColor(red: 0.28, green: 0.38, blue: 0.7, alpha: 0.5)
        outerBg.lineWidth = 1.5
        cityNode.addChild(outerBg)

        // --- グリッドレイアウト計算 ---
        let cols = 3, rows = 2
        let roadW:   CGFloat = 15
        let margin:  CGFloat = 8
        let labelH:  CGFloat = 20
        let gridW = vw - 2 * margin
        let gridH = vh - 2 * margin - labelH
        let plotW = (gridW - CGFloat(cols - 1) * roadW) / CGFloat(cols)
        let plotH = (gridH - CGFloat(rows - 1) * roadW) / CGFloat(rows)

        // グリッド左上 (cityNode ローカル座標)
        let gLeft = -gridW / 2
        let gTop  =  gridH / 2 - labelH / 2 + 2

        // --- 道路面 (全体を舗装色で塗る) ---
        let asphalt = SKShapeNode(rectOf: CGSize(width: gridW, height: gridH), cornerRadius: 4)
        asphalt.fillColor = UIColor(red: 0.11, green: 0.12, blue: 0.21, alpha: 1.0)
        asphalt.strokeColor = .clear
        asphalt.position = CGPoint(x: 0, y: gTop - gridH / 2)
        cityNode.addChild(asphalt)

        // --- 縦道路センターライン ---
        for c in 0..<(cols - 1) {
            let rx = gLeft + CGFloat(c + 1) * (plotW + roadW) - roadW / 2
            addDashedLine(x: rx, y0: gTop, y1: gTop - gridH, vertical: true)
        }
        // --- 横道路センターライン ---
        for r in 0..<(rows - 1) {
            let ry = gTop - CGFloat(r + 1) * (plotH + roadW) + roadW / 2
            addDashedLine(x: gLeft, y0: ry, y1: gLeft + gridW, vertical: false)
        }

        // --- 交差点の街灯 ---
        let ix = gLeft + (plotW + roadW)
        let iy = gTop  - (plotH + roadW)
        addStreetLight(at: CGPoint(x: ix,        y: iy))
        addStreetLight(at: CGPoint(x: ix + plotW + roadW, y: iy))

        // --- 縁石（各プロット外周） ---
        for i in 0..<plotCount {
            let c = i % cols, r = i / cols
            let px = gLeft + CGFloat(c) * (plotW + roadW)
            let py = gTop  - CGFloat(r) * (plotH + roadW)
            let center = CGPoint(x: px + plotW / 2, y: py - plotH / 2)
            let pSize  = CGSize(width: plotW, height: plotH)

            if let bld = gm.cityBuildings[i],
               let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }) {
                drawTopDownBuilding(type: t, level: bld.level, center: center, size: pSize)
            } else {
                drawEmptyPlot(center: center, size: pSize)
            }
        }

        // --- 街路樹 (空きスペースに点在) ---
        let treeSpots: [CGPoint] = [
            CGPoint(x: gLeft + gridW - 10, y: gTop  - 10),
            CGPoint(x: gLeft + 10,         y: gTop  - 10),
            CGPoint(x: gLeft + gridW - 10, y: gTop  - gridH + 10),
            CGPoint(x: gLeft + 10,         y: gTop  - gridH + 10),
        ]
        for sp in treeSpots { addTree(at: sp) }

        // --- 都市収益ラベル ---
        let cityInc = gm.cityIncomePerSec
        let incLbl = SKLabelNode(
            text: cityInc > 0 ? "都市収益  +¥\(formatMoney(cityInc))/s" : "建物を建てて都市を発展させよう"
        )
        incLbl.fontName = "HiraginoSans-W4"
        incLbl.fontSize = 11
        incLbl.fontColor = UIColor(red: 0.42, green: 1.0, blue: 0.58, alpha: 0.88)
        incLbl.position = CGPoint(x: 0, y: -vh / 2 + 8)
        cityNode.addChild(incLbl)
    }

    // MARK: - Top-Down Building

    private func drawTopDownBuilding(type t: CityBuildingType, level: Int,
                                      center: CGPoint, size plotSz: CGSize) {
        // 建物フットプリントサイズ
        let pad: CGFloat
        switch t.id {
        case "tower": pad = 16
        case "hotel": pad = 10
        case "mall":  pad = 7
        default:      pad = 12
        }
        let bldW = plotSz.width  - pad * 2
        let bldH = plotSz.height - pad * 2

        // 壁の高さ（レベルで増加）
        let wallH: CGFloat
        switch t.id {
        case "tower":      wallH = 10 + CGFloat(level) * 13
        case "hotel":      wallH = 7  + CGFloat(level) * 9
        case "mall":       wallH = 6  + CGFloat(level) * 7
        case "restaurant": wallH = 5  + CGFloat(level) * 5
        default:           wallH = 4  + CGFloat(level) * 4  // cafe
        }
        let wallSide = wallH * 0.38  // 東面の幅

        // 屋上の色
        let br: CGFloat = min(0.65 + CGFloat(level - 1) * 0.06, 1.0)
        let roofR = min(t.cr * br + 0.04, 1.0)
        let roofG = min(t.cg * br + 0.04, 1.0)
        let roofB = min(t.cb * br + 0.08, 1.0)

        let rLeft  = center.x - bldW / 2
        let rRight = center.x + bldW / 2
        let rTop   = center.y + bldH / 2
        let rBot   = center.y - bldH / 2

        // ---- 地盤・歩道 ----
        let ground = SKShapeNode(rectOf: plotSz, cornerRadius: 3)
        ground.fillColor = UIColor(red: 0.14, green: 0.15, blue: 0.24, alpha: 1.0)
        ground.strokeColor = UIColor(white: 0.3, alpha: 0.2)
        ground.lineWidth = 0.5
        ground.position = center
        ground.zPosition = 0
        cityNode.addChild(ground)

        let sidewalk = SKShapeNode(rectOf: CGSize(width: plotSz.width - 6, height: plotSz.height - 6), cornerRadius: 2)
        sidewalk.fillColor = UIColor(red: 0.19, green: 0.20, blue: 0.32, alpha: 1.0)
        sidewalk.strokeColor = .clear
        sidewalk.zPosition = 1
        sidewalk.position = center
        cityNode.addChild(sidewalk)

        // ---- 南面（下側の壁）— オブリーク投影 ----
        let southPath = CGMutablePath()
        southPath.move(to: CGPoint(x: rLeft,          y: rBot))
        southPath.addLine(to: CGPoint(x: rRight,         y: rBot))
        southPath.addLine(to: CGPoint(x: rRight + wallSide, y: rBot - wallH))
        southPath.addLine(to: CGPoint(x: rLeft  + wallSide, y: rBot - wallH))
        southPath.closeSubpath()
        let southFace = SKShapeNode(path: southPath)
        southFace.fillColor = UIColor(red: roofR * 0.58, green: roofG * 0.58, blue: roofB * 0.62, alpha: 1.0)
        southFace.strokeColor = UIColor(white: 0.0, alpha: 0.25)
        southFace.lineWidth = 0.5
        southFace.zPosition = 2
        cityNode.addChild(southFace)

        // ---- 東面（右側の壁）----
        let eastPath = CGMutablePath()
        eastPath.move(to: CGPoint(x: rRight,          y: rTop))
        eastPath.addLine(to: CGPoint(x: rRight,          y: rBot))
        eastPath.addLine(to: CGPoint(x: rRight + wallSide, y: rBot - wallH))
        eastPath.addLine(to: CGPoint(x: rRight + wallSide, y: rTop - wallH))
        eastPath.closeSubpath()
        let eastFace = SKShapeNode(path: eastPath)
        eastFace.fillColor = UIColor(red: roofR * 0.38, green: roofG * 0.38, blue: roofB * 0.44, alpha: 1.0)
        eastFace.strokeColor = UIColor(white: 0.0, alpha: 0.25)
        eastFace.lineWidth = 0.5
        eastFace.zPosition = 2
        cityNode.addChild(eastFace)

        // 南面の窓
        if wallH > 12 {
            let wCols = max(2, Int(bldW / 16))
            let wRows = max(1, Int(wallH / 14))
            for wr in 0..<wRows {
                let tp = CGFloat(wr + 1) / CGFloat(wRows + 1)
                let baseY = rBot - wallH * tp
                let lx = rLeft + wallSide * tp
                let rx = rRight + wallSide * tp
                let step = (rx - lx) / CGFloat(wCols + 1)
                for wc in 0..<wCols {
                    guard Bool.random() || Bool.random() else { continue }
                    let win = SKShapeNode(rectOf: CGSize(width: 3.5, height: 3.0), cornerRadius: 0.3)
                    win.fillColor = UIColor(red: 1.0,
                                            green: CGFloat.random(in: 0.85...0.98),
                                            blue: CGFloat.random(in: 0.4...0.65),
                                            alpha: CGFloat.random(in: 0.6...0.95))
                    win.strokeColor = .clear
                    win.position = CGPoint(x: lx + step * CGFloat(wc + 1), y: baseY)
                    win.zPosition = 3
                    cityNode.addChild(win)
                }
            }
        }

        // ---- 屋上（ルーフ面）----
        let roof = SKShapeNode(rectOf: CGSize(width: bldW, height: bldH), cornerRadius: 3)
        roof.fillColor = UIColor(red: roofR, green: roofG, blue: roofB, alpha: 1.0)
        roof.strokeColor = UIColor(red: min(t.cr + 0.3, 1), green: min(t.cg + 0.3, 1), blue: min(t.cb + 0.3, 1), alpha: 0.55)
        roof.lineWidth = 1.0
        roof.position = center
        roof.zPosition = 4
        cityNode.addChild(roof)

        // 屋上テクスチャ
        drawRooftopDetails(type: t, level: level, center: center, bldSize: CGSize(width: bldW, height: bldH))

        // アイコン
        let iconLbl = SKLabelNode(text: t.icon)
        iconLbl.fontSize = min(bldW, bldH) * 0.44
        iconLbl.alpha = 0.58
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position = center
        iconLbl.zPosition = 5
        cityNode.addChild(iconLbl)

        // レベルバッジ（左上）
        if level > 1 {
            let badge = SKShapeNode(rectOf: CGSize(width: 22, height: 13), cornerRadius: 4)
            badge.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 0.92)
            badge.strokeColor = .clear
            badge.position = CGPoint(x: center.x - bldW / 2 + 11, y: center.y + bldH / 2 - 7)
            badge.zPosition = 6
            cityNode.addChild(badge)
            let lvLbl = SKLabelNode(text: "L\(level)")
            lvLbl.fontName = "HiraginoSans-W8"
            lvLbl.fontSize = 9
            lvLbl.fontColor = UIColor(red: 0.12, green: 0.08, blue: 0.0, alpha: 1.0)
            lvLbl.verticalAlignmentMode = .center
            lvLbl.position = badge.position
            lvLbl.zPosition = 7
            cityNode.addChild(lvLbl)
        }
    }

    private func drawRooftopDetails(type t: CityBuildingType, level: Int,
                                     center: CGPoint, bldSize sz: CGSize) {
        switch t.id {
        case "tower":
            // アンテナ塔
            let antenna = SKShapeNode(rectOf: CGSize(width: 3, height: sz.height * 0.35), cornerRadius: 1)
            antenna.fillColor = UIColor(white: 0.7, alpha: 0.9)
            antenna.strokeColor = .clear
            antenna.position = CGPoint(x: center.x, y: center.y + sz.height * 0.5 - sz.height * 0.175 - 2)
            cityNode.addChild(antenna)
            // 頂点の赤ランプ
            let lamp = SKShapeNode(circleOfRadius: 3)
            lamp.fillColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
            lamp.strokeColor = .clear
            lamp.position = CGPoint(x: center.x, y: center.y + sz.height * 0.5 + sz.height * 0.35 / 2 - 2)
            cityNode.addChild(lamp)
            let blink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.8),
                SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            ])
            lamp.run(SKAction.repeatForever(blink))

        case "hotel":
            // プール（水色の四角）
            let pool = SKShapeNode(rectOf: CGSize(width: sz.width * 0.35, height: sz.height * 0.28), cornerRadius: 3)
            pool.fillColor = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.85)
            pool.strokeColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.5)
            pool.lineWidth = 1
            pool.position = CGPoint(x: center.x + sz.width * 0.18, y: center.y - sz.height * 0.1)
            cityNode.addChild(pool)

        case "mall":
            // ガラス天窓（ストライプ）
            for i in 0..<3 {
                let stripe = SKShapeNode(rectOf: CGSize(width: sz.width * 0.55, height: 4), cornerRadius: 1)
                stripe.fillColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.25)
                stripe.strokeColor = .clear
                stripe.position = CGPoint(x: center.x, y: center.y - sz.height * 0.15 + CGFloat(i) * 8)
                cityNode.addChild(stripe)
            }

        case "restaurant":
            // テラス席（小さな四角が並ぶ）
            for i in 0..<(level >= 3 ? 4 : 2) {
                let table = SKShapeNode(circleOfRadius: 3)
                table.fillColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 0.8)
                table.strokeColor = .clear
                table.position = CGPoint(x: center.x - sz.width * 0.2 + CGFloat(i) * 12,
                                          y: center.y + sz.height * 0.22)
                cityNode.addChild(table)
            }

        default: // cafe
            // 看板（色帯）
            let sign = SKShapeNode(rectOf: CGSize(width: sz.width * 0.6, height: 5), cornerRadius: 2)
            sign.fillColor = UIColor(red: min(t.cr + 0.3, 1),
                                      green: min(t.cg + 0.3, 1),
                                      blue:  min(t.cb + 0.3, 1), alpha: 0.9)
            sign.strokeColor = .clear
            sign.position = CGPoint(x: center.x, y: center.y - sz.height * 0.3)
            cityNode.addChild(sign)
        }
    }

    // MARK: - Empty Plot

    private func drawEmptyPlot(center: CGPoint, size: CGSize) {
        // 地盤
        let ground = SKShapeNode(rectOf: size, cornerRadius: 3)
        ground.fillColor = UIColor(red: 0.11, green: 0.12, blue: 0.2, alpha: 1.0)
        ground.strokeColor = UIColor(white: 0.28, alpha: 0.3)
        ground.lineWidth = 0.5
        ground.position = center
        cityNode.addChild(ground)

        // 点線の区画枠（手動でダッシュ描画）
        let bw = size.width - 8, bh = size.height - 8
        let dashLen: CGFloat = 6, gapLen: CGFloat = 5
        let dashColor = UIColor(white: 0.32, alpha: 0.45)
        // 上辺
        var x = center.x - bw/2; let topY = center.y + bh/2
        while x < center.x + bw/2 {
            let w = min(dashLen, center.x + bw/2 - x)
            let d = SKShapeNode(rectOf: CGSize(width: w, height: 1)); d.fillColor = dashColor; d.strokeColor = .clear
            d.position = CGPoint(x: x + w/2, y: topY); cityNode.addChild(d); x += dashLen + gapLen
        }
        // 下辺
        x = center.x - bw/2; let botY = center.y - bh/2
        while x < center.x + bw/2 {
            let w = min(dashLen, center.x + bw/2 - x)
            let d = SKShapeNode(rectOf: CGSize(width: w, height: 1)); d.fillColor = dashColor; d.strokeColor = .clear
            d.position = CGPoint(x: x + w/2, y: botY); cityNode.addChild(d); x += dashLen + gapLen
        }
        // 左辺
        var y = center.y - bh/2; let leftX = center.x - bw/2
        while y < center.y + bh/2 {
            let h = min(dashLen, center.y + bh/2 - y)
            let d = SKShapeNode(rectOf: CGSize(width: 1, height: h)); d.fillColor = dashColor; d.strokeColor = .clear
            d.position = CGPoint(x: leftX, y: y + h/2); cityNode.addChild(d); y += dashLen + gapLen
        }
        // 右辺
        y = center.y - bh/2; let rightX = center.x + bw/2
        while y < center.y + bh/2 {
            let h = min(dashLen, center.y + bh/2 - y)
            let d = SKShapeNode(rectOf: CGSize(width: 1, height: h)); d.fillColor = dashColor; d.strokeColor = .clear
            d.position = CGPoint(x: rightX, y: y + h/2); cityNode.addChild(d); y += dashLen + gapLen
        }

        // 十字マーク
        for (w, h): (CGFloat, CGFloat) in [(20, 2), (2, 20)] {
            let arm = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 1)
            arm.fillColor = UIColor(white: 0.35, alpha: 0.5)
            arm.strokeColor = .clear
            arm.position = center
            cityNode.addChild(arm)
        }
    }

    // MARK: - Road Helpers

    private func addDashedLine(x xOrY: CGFloat, y0: CGFloat, y1: CGFloat, vertical: Bool) {
        let dashLen: CGFloat = 8, gapLen: CGFloat = 7
        let total = abs(y1 - y0)
        let count = Int(total / (dashLen + gapLen))
        for i in 0..<count {
            let offset = CGFloat(i) * (dashLen + gapLen) + dashLen / 2
            let pos: CGPoint = vertical
                ? CGPoint(x: xOrY, y: y0 - offset)
                : CGPoint(x: y0 + offset, y: xOrY)
            let dash = SKShapeNode(rectOf: vertical
                ? CGSize(width: 1.5, height: dashLen)
                : CGSize(width: dashLen, height: 1.5), cornerRadius: 0.5)
            dash.fillColor = UIColor(white: 0.42, alpha: 0.55)
            dash.strokeColor = .clear
            dash.position = pos
            cityNode.addChild(dash)
        }
    }

    private func addStreetLight(at pos: CGPoint) {
        let glow = SKShapeNode(circleOfRadius: 10)
        glow.fillColor = UIColor(red: 1.0, green: 0.94, blue: 0.5, alpha: 0.1)
        glow.strokeColor = .clear
        glow.position = pos
        cityNode.addChild(glow)
        let dot = SKShapeNode(circleOfRadius: 2.5)
        dot.fillColor = UIColor(red: 1.0, green: 0.94, blue: 0.6, alpha: 0.92)
        dot.strokeColor = .clear
        dot.position = pos
        cityNode.addChild(dot)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.8),
            SKAction.fadeAlpha(to: 0.92, duration: 1.8)
        ])
        dot.run(SKAction.repeatForever(pulse))
    }

    private func addTree(at pos: CGPoint) {
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 11, height: 6))
        shadow.fillColor = UIColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: pos.x + 3, y: pos.y - 3)
        cityNode.addChild(shadow)
        let tree = SKShapeNode(circleOfRadius: 6)
        tree.fillColor = UIColor(red: 0.14, green: 0.55, blue: 0.2, alpha: 0.92)
        tree.strokeColor = UIColor(red: 0.08, green: 0.32, blue: 0.1, alpha: 0.5)
        tree.lineWidth = 1
        tree.position = pos
        cityNode.addChild(tree)
    }

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

            let incLbl = SKLabelNode(text: "+¥\(formatMoney(bld.incomePerSec))/s")
            incLbl.fontName = "HiraginoSans-W5"
            incLbl.fontSize = 12
            incLbl.fontColor = UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.9)
            incLbl.verticalAlignmentMode = .center
            incLbl.position = CGPoint(x: 0, y: cardH/2 - 84)
            container.addChild(incLbl)

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
                btnBg.name = "upgradeBtn_\(plot)"
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

                let btnLbl = SKLabelNode(text: "UP ¥\(formatMoney(upgCost))")
                btnLbl.fontName = "HiraginoSans-W6"
                btnLbl.fontSize = 12
                btnLbl.fontColor = canAfford ? .white : UIColor(white: 0.38, alpha: 1.0)
                btnLbl.verticalAlignmentMode = .center
                btnLbl.position = CGPoint(x: 0, y: btnY)
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
        let panelH: CGFloat = CGFloat(CityBuildingType.all.count) * 68 + 70
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 18)
        panel.fillColor = UIColor(red: 0.06, green: 0.07, blue: 0.18, alpha: 0.98)
        panel.strokeColor = UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 0.7)
        panel.lineWidth = 1.5
        panel.position = CGPoint(x: frame.midX, y: frame.midY)
        overlay.addChild(panel)

        let titleLbl = SKLabelNode(text: "建物を選ぶ")
        titleLbl.fontName = "HiraginoSans-W6"
        titleLbl.fontSize = 16
        titleLbl.fontColor = .white
        titleLbl.verticalAlignmentMode = .center
        titleLbl.position = CGPoint(x: frame.midX, y: frame.midY + panelH/2 - 26)
        overlay.addChild(titleLbl)

        for (i, t) in CityBuildingType.all.enumerated() {
            let rowY = frame.midY + panelH/2 - 60 - CGFloat(i) * 68
            let canAfford = gm.money >= t.placeCost

            let rowBg = SKShapeNode(rectOf: CGSize(width: panelW - 20, height: 58), cornerRadius: 10)
            rowBg.fillColor = canAfford
                ? UIColor(red: t.cr * 0.2 + 0.05, green: t.cg * 0.2 + 0.05, blue: t.cb * 0.2 + 0.1, alpha: 0.9)
                : UIColor(white: 0.06, alpha: 0.8)
            rowBg.strokeColor = canAfford
                ? UIColor(red: t.cr * 0.5 + 0.2, green: t.cg * 0.5 + 0.2, blue: t.cb * 0.5 + 0.2, alpha: 0.6)
                : UIColor(white: 0.2, alpha: 0.3)
            rowBg.lineWidth = 1
            rowBg.position = CGPoint(x: frame.midX, y: rowY)
            rowBg.name = "selectBuilding_\(plot)_\(t.id)"
            overlay.addChild(rowBg)

            let iconLbl = SKLabelNode(text: t.icon)
            iconLbl.fontSize = 26
            iconLbl.verticalAlignmentMode = .center
            iconLbl.position = CGPoint(x: frame.midX - panelW/2 + 30, y: rowY)
            overlay.addChild(iconLbl)

            let nameLbl = SKLabelNode(text: t.name)
            nameLbl.fontName = "HiraginoSans-W6"
            nameLbl.fontSize = 13
            nameLbl.fontColor = canAfford ? .white : UIColor(white: 0.35, alpha: 1.0)
            nameLbl.horizontalAlignmentMode = .left
            nameLbl.verticalAlignmentMode   = .center
            nameLbl.position = CGPoint(x: frame.midX - panelW/2 + 56, y: rowY + 9)
            overlay.addChild(nameLbl)

            let costLbl = SKLabelNode(text: "¥\(formatMoney(t.placeCost)) / +¥\(formatMoney(t.baseIncome))/s")
            costLbl.fontName = "HiraginoSans-W4"
            costLbl.fontSize = 11
            costLbl.fontColor = canAfford
                ? UIColor(red: 0.38, green: 0.98, blue: 0.52, alpha: 0.85)
                : UIColor(white: 0.28, alpha: 1.0)
            costLbl.horizontalAlignmentMode = .left
            costLbl.verticalAlignmentMode   = .center
            costLbl.position = CGPoint(x: frame.midX - panelW/2 + 56, y: rowY - 10)
            overlay.addChild(costLbl)
        }

        // Cancel button
        let cancelBtn = SKShapeNode(rectOf: CGSize(width: panelW - 20, height: 36), cornerRadius: 10)
        cancelBtn.fillColor = UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 0.8)
        cancelBtn.strokeColor = UIColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 0.6)
        cancelBtn.lineWidth = 1
        cancelBtn.position = CGPoint(x: frame.midX, y: frame.midY - panelH/2 + 26)
        cancelBtn.name = "cancelOverlay"
        overlay.addChild(cancelBtn)

        let cancelLbl = SKLabelNode(text: "キャンセル")
        cancelLbl.fontName = "HiraginoSans-W5"
        cancelLbl.fontSize = 14
        cancelLbl.fontColor = UIColor(red: 0.9, green: 0.5, blue: 0.5, alpha: 1.0)
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
        moneyLabel.text  = "¥\(formatMoney(gm.money))"
        let cityInc = gm.cityIncomePerSec
        incomeLabel.text = cityInc > 0 ? "都市: +¥\(formatMoney(cityInc))/s" : ""
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
            showToast("💸 お金が足りません (¥\(formatMoney(t.placeCost)) 必要)")
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
            showToast("💸 お金が足りません (¥\(formatMoney(cost)) 必要)")
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
        let label = SKLabelNode(text: "🏗️ \(name) 完成！")
        label.fontName = "HiraginoSans-W7"
        label.fontSize = 20
        label.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        label.position = CGPoint(x: frame.midX, y: frame.height - topBarH - cityViewH / 2)
        label.zPosition = 30
        label.setScale(0.6)
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1.05, duration: 0.18), SKAction.fadeIn(withDuration: 0.18)]),
            SKAction.scale(to: 1.0, duration: 0.08),
            SKAction.wait(forDuration: 1.3),
            SKAction.group([SKAction.fadeOut(withDuration: 0.4), SKAction.moveBy(x: 0, y: 30, duration: 0.4)]),
            SKAction.removeFromParent()
        ]))
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
        let seq = SKAction.sequence([SKAction.wait(forDuration: 2.2), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()])
        bg.run(seq); lbl.run(seq)
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
