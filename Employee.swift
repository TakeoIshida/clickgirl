import Foundation

struct Employee {
    let id: Int
    let name: String
    let role: String
    let imageName: String
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

    // 次のレベルでの収益
    var nextLevelIncome: Double {
        baseIncomePerSec * Double(level + 1)
    }

    static let allEmployees: [Employee] = [
        Employee(
            id: 0, name: "あかり", role: "営業部長",
            imageName: "char_akari",
            description: "元気いっぱい！営業成績No.1",
            baseCost: 50, baseIncomePerSec: 0.5
        ),
        Employee(
            id: 1, name: "みさき", role: "開発部長",
            imageName: "char_misaki",
            description: "クールな天才エンジニア",
            baseCost: 300, baseIncomePerSec: 3.0
        ),
        Employee(
            id: 2, name: "はな", role: "マーケ部長",
            imageName: "char_hana",
            description: "SNS1000万フォロワーの広報",
            baseCost: 1500, baseIncomePerSec: 15.0
        ),
        Employee(
            id: 3, name: "ゆき", role: "管理部長",
            imageName: "char_yuki",
            description: "会社全体の効率を最適化",
            baseCost: 8000, baseIncomePerSec: 80.0
        ),
        Employee(
            id: 4, name: "かれん", role: "受付・広報",
            imageName: "char_karen",
            description: "会社の顔。来客対応のプロ",
            baseCost: 40000, baseIncomePerSec: 400.0
        ),
        Employee(
            id: 5, name: "かりん", role: "企画部長",
            imageName: "char_karin",
            description: "トレンドを読む次世代プランナー",
            baseCost: 200000, baseIncomePerSec: 2000.0
        ),
        Employee(
            id: 6, name: "さくら", role: "副社長",
            imageName: "char_sakura",
            description: "謎多き副社長。全員雇用で解禁",
            baseCost: 1000000, baseIncomePerSec: 10000.0
        ),
    ]
}
