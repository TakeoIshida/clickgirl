import Foundation

struct Employee {
    let id: Int
    let name: String
    let role: String
    let charPrefix: String   // "karen" / "misaki" / "yuki"
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
            id: 0, name: "カレン", role: "営業部長",
            charPrefix: "karen", imageCount: 10,
            description: "クールだけど仕事は誰より熱い",
            baseCost: 100, baseIncomePerSec: 1.0
        ),
        Employee(
            id: 1, name: "みさき", role: "開発部長",
            charPrefix: "misaki", imageCount: 8,
            description: "笑顔で難題を解決する天才エンジニア",
            baseCost: 1500, baseIncomePerSec: 15.0
        ),
        Employee(
            id: 2, name: "ゆき", role: "管理部長",
            charPrefix: "yuki", imageCount: 10,
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
            id: 4, name: "あかり", role: "社長秘書",
            charPrefix: "akari", imageCount: 8,
            description: "完璧な段取りで社長を全力サポート",
            baseCost: 5_000_000, baseIncomePerSec: 50_000.0
        ),
    ]
}
