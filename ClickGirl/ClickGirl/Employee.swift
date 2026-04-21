import Foundation

struct Employee {
    let id: Int
    let name: String
    let role: String
    let charPrefix: String   // "airi" / "hana" / "miku" / "rio" / "saki"
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
            baseCost: 100, baseIncomePerSec: 1.0
        ),
        Employee(
            id: 1, name: "ハナ", role: "開発部長",
            charPrefix: "hana", imageCount: 7,
            description: "笑顔で難題を解決する天才エンジニア",
            baseCost: 1500, baseIncomePerSec: 15.0
        ),
        Employee(
            id: 2, name: "ミク", role: "管理部長",
            charPrefix: "miku", imageCount: 5,
            description: "ミステリアスな眼差しで会社を統括",
            baseCost: 20000, baseIncomePerSec: 200.0
        ),
        Employee(
            id: 3, name: "りお", role: "マーケティング部長",
            charPrefix: "rio", imageCount: 3,
            description: "SNS戦略で会社を一躍有名に",
            baseCost: 300_000, baseIncomePerSec: 3_000.0
        ),
        Employee(
            id: 4, name: "さき", role: "広報部長",
            charPrefix: "saki", imageCount: 8,
            description: "鋭い眼差しで会社のブランドを牽引",
            baseCost: 400_000, baseIncomePerSec: 4_000.0
        ),
    ]
}
