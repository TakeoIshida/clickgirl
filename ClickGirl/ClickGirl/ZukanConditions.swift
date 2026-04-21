import Foundation

// MARK: - 解放条件

enum UnlockCondition {
    case hired                                             // 採用するだけ（デフォルト）
    case gachaCard(charId: Int, imageIndex: Int, count: Int) // 同じカードをX枚集める

    func isUnlocked(gm: GameManager) -> Bool {
        switch self {
        case .hired:
            return true
        case .gachaCard(let cid, let idx, let count):
            return gm.cardCount(charId: cid, imageIndex: idx) >= count
        }
    }

    var description: String {
        switch self {
        case .hired:
            return "採用時に解放"
        case .gachaCard(_, _, let count):
            return "同じカードを\(count)枚集める"
        }
    }
}

// MARK: - 各キャラ・各画像の解放条件

struct ZukanConditions {

    // [charId: [imageIndex: UnlockCondition]]
    // ・N/Rカード : 1枚で解放
    // ・SRカード  : 2枚で解放
    // ・SSRカード : 3枚で解放
    static let conditions: [Int: [UnlockCondition]] = [

        // アイリ (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        0: [
            .gachaCard(charId: 0, imageIndex: 0, count: 1),   // N
            .gachaCard(charId: 0, imageIndex: 1, count: 1),   // N
            .gachaCard(charId: 0, imageIndex: 2, count: 1),   // R
            .gachaCard(charId: 0, imageIndex: 3, count: 2),   // SR × 2枚
            .gachaCard(charId: 0, imageIndex: 4, count: 3),   // SSR × 3枚
        ],

        // ハナ (7枚: 0-2=N, 3-4=R, 5=SR, 6=SSR)
        1: [
            .gachaCard(charId: 1, imageIndex: 0, count: 1),   // N
            .gachaCard(charId: 1, imageIndex: 1, count: 1),   // N
            .gachaCard(charId: 1, imageIndex: 2, count: 1),   // N
            .gachaCard(charId: 1, imageIndex: 3, count: 1),   // R
            .gachaCard(charId: 1, imageIndex: 4, count: 1),   // R
            .gachaCard(charId: 1, imageIndex: 5, count: 2),   // SR × 2枚
            .gachaCard(charId: 1, imageIndex: 6, count: 3),   // SSR × 3枚
        ],

        // ミク (5枚: 0-1=N, 2=R, 3=SR, 4=SSR)
        2: [
            .gachaCard(charId: 2, imageIndex: 0, count: 1),   // N
            .gachaCard(charId: 2, imageIndex: 1, count: 1),   // N
            .gachaCard(charId: 2, imageIndex: 2, count: 1),   // R
            .gachaCard(charId: 2, imageIndex: 3, count: 2),   // SR × 2枚
            .gachaCard(charId: 2, imageIndex: 4, count: 3),   // SSR × 3枚
        ],

        // りお (3枚: 0-2=N / 画像追加次第拡張予定)
        3: [
            .gachaCard(charId: 3, imageIndex: 0, count: 1),
            .gachaCard(charId: 3, imageIndex: 1, count: 1),
            .gachaCard(charId: 3, imageIndex: 2, count: 1),
        ],

        // さき (8枚: 0-1=N, 2=R, 3=SR, 4-5=SR secret, 6-7=SSR secret)
        4: [
            .gachaCard(charId: 4, imageIndex: 0, count: 1),   // N
            .gachaCard(charId: 4, imageIndex: 1, count: 1),   // N
            .gachaCard(charId: 4, imageIndex: 2, count: 1),   // R
            .gachaCard(charId: 4, imageIndex: 3, count: 2),   // SR × 2枚
            .gachaCard(charId: 4, imageIndex: 4, count: 5),   // SR secret × 5枚
            .gachaCard(charId: 4, imageIndex: 5, count: 5),   // SR secret × 5枚
            .gachaCard(charId: 4, imageIndex: 6, count: 5),   // SSR secret × 5枚
            .gachaCard(charId: 4, imageIndex: 7, count: 5),   // SSR secret × 5枚
        ],
    ]

    static func isImageUnlocked(charId: Int, imageIndex: Int, gm: GameManager) -> Bool {
        guard let conds = conditions[charId], imageIndex < conds.count else { return false }
        return conds[imageIndex].isUnlocked(gm: gm)
    }

    static func conditionText(charId: Int, imageIndex: Int) -> String {
        guard let conds = conditions[charId], imageIndex < conds.count else { return "?" }
        return conds[imageIndex].description
    }

    static func fmt(_ v: Double) -> String {
        if v >= 100_000_000 { return String(format: "%.0f億", v / 100_000_000) }
        if v >= 10_000      { return String(format: "%.0f万", v / 10_000) }
        return String(format: "%.0f", v)
    }
}
