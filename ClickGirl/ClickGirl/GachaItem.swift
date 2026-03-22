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

    static let singleCost: Double = 50_000
    static let tenCost:    Double = 450_000   // 10枚分まとめて = 1回分お得

    // カレン(0) : 4N + 3R + 2SR + 1SSR = 10枚
    // みさき(1) : 3N + 3R + 1SR + 1SSR =  8枚
    // ゆき(2)   : 4N + 3R + 2SR + 1SSR = 10枚
    // りお(3)   : 3N + 3R + 1SR + 1SSR =  8枚
    // あかり(4) : 3N + 3R + 1SR + 1SSR =  8枚
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

        // カレン
        add(0, "カレン", "karen", .n,   indices: 0...3)
        add(0, "カレン", "karen", .r,   indices: 4...6)
        add(0, "カレン", "karen", .sr,  indices: 7...8)
        add(0, "カレン", "karen", .ssr, indices: 9...9)

        // みさき
        add(1, "みさき", "misaki", .n,   indices: 0...2)
        add(1, "みさき", "misaki", .r,   indices: 3...5)
        add(1, "みさき", "misaki", .sr,  indices: 6...6)
        add(1, "みさき", "misaki", .ssr, indices: 7...7)

        // ゆき
        add(2, "ゆき", "yuki", .n,   indices: 0...3)
        add(2, "ゆき", "yuki", .r,   indices: 4...6)
        add(2, "ゆき", "yuki", .sr,  indices: 7...8)
        add(2, "ゆき", "yuki", .ssr, indices: 9...9)

        // りお (3枚: 0-2=N / 画像追加次第拡張予定)
        add(3, "りお", "rio", .n,   indices: 0...2)

        // あかり
        add(4, "あかり", "akari", .n,   indices: 0...2)
        add(4, "あかり", "akari", .r,   indices: 3...5)
        add(4, "あかり", "akari", .sr,  indices: 6...6)
        add(4, "あかり", "akari", .ssr, indices: 7...7)

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
