import Foundation

// MARK: - レアリティ

enum GachaRarity: String {
    case n   = "N"
    case r   = "R"
    case sr  = "SR"
    case ssr = "SSR"

    var labelColor: (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .n:   return (0.75, 0.75, 0.75)
        case .r:   return (0.30, 0.60, 1.00)
        case .sr:  return (0.75, 0.25, 1.00)
        case .ssr: return (1.00, 0.72, 0.00)
        }
    }

    /// 重み (N:60% / R:30% / SR:8% / SSR:2%)
    var weight: Double {
        switch self {
        case .n:   return 60.0
        case .r:   return 30.0
        case .sr:  return 8.0
        case .ssr: return 2.0
        }
    }

    /// カード1枚あたりの収益ボーナス倍率
    var incomeBonus: Double {
        switch self {
        case .n:   return 0.02   // +2%
        case .r:   return 0.05   // +5%
        case .sr:  return 0.15   // +15%
        case .ssr: return 0.40   // +40%
        }
    }
}

// MARK: - ガチャカード（キャラ画像）

struct GachaCard {
    let charId:     Int
    let imageIndex: Int
    let rarity:     GachaRarity
    let charName:   String
    let charPrefix: String

    var cardKey: String { "\(charId)_\(imageIndex)" }

    /// ゲーム内で表示するキャラ画像名（背景あり）
    var galleryImageName: String { "\(charPrefix)_\(imageIndex)" }
}

// MARK: - ガチャカタログ & 抽選

enum GachaCatalog {

    static let singleCost: Double = 800
    static let tenCost:    Double = 7_200   // 10枚分まとめて = 1回分お得

    // アイリ(0) : 2N + 1R + 1SR + 1SSR =  5枚
    // ハナ(1)   : 3N + 2R + 1SR + 1SSR =  7枚
    // ミク(2)   : 2N + 1R + 1SR + 1SSR =  5枚
    // さき(4)   : 2N + 1R + 2SR + 2SSR =  8枚
    // ナナ(5)   : 2N + 1R + 1SR + 1SSR =  5枚
    // レナ(6)   : 2N + 1R + 1SR + 1SSR =  5枚
    // シオリ(7) : 2N + 1R + 1SR + 1SSR =  5枚
    static let pool: [GachaCard] = {
        var cards: [GachaCard] = []

        func add(_ charId: Int, _ charName: String, _ prefix: String,
                 _ rarity: GachaRarity, indices: ClosedRange<Int>) {
            for i in indices {
                cards.append(GachaCard(charId: charId, imageIndex: i,
                                       rarity: rarity, charName: charName,
                                       charPrefix: prefix))
            }
        }

        // アイリ (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        add(0, "アイリ", "airi", .n,   indices: 0...1)
        add(0, "アイリ", "airi", .r,   indices: 2...2)
        add(0, "アイリ", "airi", .sr,  indices: 3...3)
        add(0, "アイリ", "airi", .ssr, indices: 4...4)

        // ハナ (7枚: 0-2=N, 3-4=R, 5=SR, 6=SSR)
        add(1, "ハナ", "hana", .n,   indices: 0...2)
        add(1, "ハナ", "hana", .r,   indices: 3...4)
        add(1, "ハナ", "hana", .sr,  indices: 5...5)
        add(1, "ハナ", "hana", .ssr, indices: 6...6)

        // ミク (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        add(2, "ミク", "miku", .n,   indices: 0...1)
        add(2, "ミク", "miku", .r,   indices: 2...2)
        add(2, "ミク", "miku", .sr,  indices: 3...3)
        add(2, "ミク", "miku", .ssr, indices: 4...4)

        // さき (8枚: 0-1=N, 2=R, 3=SR, 4-5=SR secret, 6-7=SSR secret)
        add(4, "さき", "saki", .n,   indices: 0...1)
        add(4, "さき", "saki", .r,   indices: 2...2)
        add(4, "さき", "saki", .sr,  indices: 3...3)
        add(4, "さき", "saki", .sr,  indices: 4...5)   // シークレットSR
        add(4, "さき", "saki", .ssr, indices: 6...7)   // シークレットSSR

        // ナナ (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        add(5, "ナナ", "nana", .n,   indices: 0...1)
        add(5, "ナナ", "nana", .r,   indices: 2...2)
        add(5, "ナナ", "nana", .sr,  indices: 3...3)
        add(5, "ナナ", "nana", .ssr, indices: 4...4)

        // レナ (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        add(6, "レナ", "rena", .n,   indices: 0...1)
        add(6, "レナ", "rena", .r,   indices: 2...2)
        add(6, "レナ", "rena", .sr,  indices: 3...3)
        add(6, "レナ", "rena", .ssr, indices: 4...4)

        // シオリ (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        add(7, "シオリ", "shiori", .n,   indices: 0...1)
        add(7, "シオリ", "shiori", .r,   indices: 2...2)
        add(7, "シオリ", "shiori", .sr,  indices: 3...3)
        add(7, "シオリ", "shiori", .ssr, indices: 4...4)

        return cards
    }()

    // MARK: - 抽選

    /// count枚引く。天井: 10回ごとにR以上確定
    static func draw(count: Int, pityCount: Int) -> (cards: [GachaCard], newPity: Int) {
        var results: [GachaCard] = []
        var pity = pityCount
        for _ in 0..<count {
            pity += 1
            results.append(pickCard(forceROrAbove: pity % 10 == 0))
        }
        return (results, pity)
    }

    private static func pickCard(forceROrAbove: Bool) -> GachaCard {
        let weights: [(GachaRarity, Double)] = [
            (.n,   forceROrAbove ? 0.0 : 60.0),
            (.r,   30.0),
            (.sr,  8.0),
            (.ssr, 2.0),
        ]
        let total = weights.reduce(0.0) { $0 + $1.1 }
        var rand  = Double.random(in: 0..<total)
        var chosen = GachaRarity.r
        for (rarity, w) in weights {
            rand -= w
            if rand <= 0 { chosen = rarity; break }
        }
        let sub = pool.filter { $0.rarity == chosen }
        return sub.randomElement() ?? pool[0]
    }
}
