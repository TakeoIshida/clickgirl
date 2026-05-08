import Foundation

struct Employee {
    let id: Int
    let name: String
    let role: String
    let charPrefix: String   // "airi" / "hana" / "miku" / "rio" / "saki" / "nana" / "rena" / "shiori"
    let imageCount: Int      // 図鑑の画像枚数
    let description: String
    var level: Int = 0
    var isHired: Bool = false

    let baseCost: Double
    let baseIncomePerSec: Double

    var hireCost: Double { baseCost }

    var upgradeCost: Double {
        baseCost * pow(1.15, Double(level))
    }

    var currentIncomePerSec: Double {
        guard isHired else { return 0 }
        return baseIncomePerSec * Double(level)
    }

    // 図鑑用: 背景ありの画像名（index指定）
    func galleryImageName(at index: Int) -> String { "\(charPrefix)_\(index)" }

    // ゲーム表示用: 背景なし画像名（index指定）
    func nobgImageName(at index: Int) -> String { "\(charPrefix)_\(index)_nobg" }

    // 後方互換 / デフォルト
    var imageName: String     { galleryImageName(at: 0) }
    var imageNameNobg: String { nobgImageName(at: 0) }

    static let allEmployees: [Employee] = [
        Employee(
            id: 0, name: "アイリ", role: "営業部長",
            charPrefix: "airi", imageCount: 5,
            description: "明るい笑顔で誰より売上を叩き出す",
            baseCost: 50, baseIncomePerSec: 1.0
        ),
        Employee(
            id: 1, name: "ハナ", role: "開発部長",
            charPrefix: "hana", imageCount: 7,
            description: "笑顔で難題を解決する天才エンジニア",
            baseCost: 500, baseIncomePerSec: 15.0
        ),
        Employee(
            id: 2, name: "ミク", role: "管理部長",
            charPrefix: "miku", imageCount: 5,
            description: "ミステリアスな眼差しで会社を統括",
            baseCost: 3_000, baseIncomePerSec: 200.0
        ),
        Employee(
            id: 4, name: "さき", role: "広報部長",
            charPrefix: "saki", imageCount: 8,
            description: "鋭い眼差しで会社のブランドを牽引",
            baseCost: 25_000, baseIncomePerSec: 4_000.0
        ),
        Employee(
            id: 5, name: "ナナ", role: "財務部長",
            charPrefix: "nana", imageCount: 5,
            description: "数字に強く会社の資産を最大化する",
            baseCost: 250_000, baseIncomePerSec: 50_000.0
        ),
        Employee(
            id: 6, name: "レナ", role: "戦略部長",
            charPrefix: "rena", imageCount: 5,
            description: "大胆な戦略で会社を業界トップへ導く",
            baseCost: 2_500_000, baseIncomePerSec: 500_000.0
        ),
        Employee(
            id: 7, name: "シオリ", role: "CEO",
            charPrefix: "shiori", imageCount: 5,
            description: "カリスマ的リーダーシップで頂点を極める",
            baseCost: 25_000_000, baseIncomePerSec: 5_000_000.0
        ),
    ]
}
