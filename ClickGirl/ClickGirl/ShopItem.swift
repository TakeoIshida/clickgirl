import Foundation

// MARK: - ショップアイテム定義

struct ShopItem {
    let id: String
    let icon: String
    let name: String
    let description: String
    let cost: Double
    let boostDuration: Double   // 0 = 永続アップグレード、>0 = 秒数(時限ブースト)
    var requiresId: String? = nil

    var isPermanent: Bool { boostDuration == 0 }
}

// MARK: - カタログ

enum ShopCatalog {

    // 永続アップグレード
    static let permanentItems: [ShopItem] = [
        ShopItem(id: "tap_lv1",
                 icon: "👊",
                 name: "タップ強化 Lv.1",
                 description: "タップ収益 +50%",
                 cost: 30_000,
                 boostDuration: 0),

        ShopItem(id: "tap_lv2",
                 icon: "💥",
                 name: "タップ強化 Lv.2",
                 description: "タップ収益 さらに+100%",
                 cost: 200_000,
                 boostDuration: 0,
                 requiresId: "tap_lv1"),

        ShopItem(id: "income_lv1",
                 icon: "📈",
                 name: "収益強化 Lv.1",
                 description: "自動収益 +30%",
                 cost: 100_000,
                 boostDuration: 0),

        ShopItem(id: "income_lv2",
                 icon: "🚀",
                 name: "収益強化 Lv.2",
                 description: "自動収益 さらに+70%",
                 cost: 500_000,
                 boostDuration: 0,
                 requiresId: "income_lv1"),

        ShopItem(id: "auto_tap",
                 icon: "🤖",
                 name: "自動タップ",
                 description: "毎秒 自動で1タップ",
                 cost: 80_000,
                 boostDuration: 0),

        ShopItem(id: "offline_ext",
                 icon: "🌙",
                 name: "夜勤延長",
                 description: "放置上限 8h → 16h",
                 cost: 300_000,
                 boostDuration: 0),
    ]

    // 時限ブースト（何度でも購入可）
    static let boostItems: [ShopItem] = [
        ShopItem(id: "boost_tap2",
                 icon: "⚡",
                 name: "タップ 2倍",
                 description: "タップ収益が2倍に (30秒)",
                 cost: 10_000,
                 boostDuration: 30),

        ShopItem(id: "boost_income2",
                 icon: "💰",
                 name: "収益 2倍",
                 description: "自動収益が2倍に (60秒)",
                 cost: 50_000,
                 boostDuration: 60),

        ShopItem(id: "boost_income5",
                 icon: "💎",
                 name: "収益 5倍",
                 description: "自動収益が5倍に (30秒)",
                 cost: 300_000,
                 boostDuration: 30),

        ShopItem(id: "boost_all3",
                 icon: "🌟",
                 name: "全力 3倍",
                 description: "全収益が3倍に (60秒)",
                 cost: 200_000,
                 boostDuration: 60),
    ]
}
