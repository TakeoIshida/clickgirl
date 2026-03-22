import Foundation

class GameManager {
    static let shared = GameManager()

    // MARK: - State
    var money: Double = 0
    var totalEarned: Double = 0
    var employees: [Employee] = Employee.allEmployees
    var pendingOfflineIncome: Double = 0
    // 図鑑: キャラごとに選択した画像インデックス [charId: imageIndex]
    var selectedImageIndex: [Int: Int] = [:]
    // ショップ: 購入済み永続アップグレード
    var purchasedUpgrades: Set<String> = []
    // ショップ: 時限ブースト [id: 有効期限Date]
    var activeBoosts: [String: Date] = [:]
    // オフィス: アップグレードレベル [id: level]
    var officeUpgrades: [String: Int] = [:]
    // オフィス: フロア数
    var officeFloors: Int = 1
    // ガチャ: 天井カウンター
    var gachaPityCount: Int = 0
    // ガチャ: 所持カード枚数 ["charId_imageIndex": count]
    var gachaCardCounts: [String: Int] = [:]
    // 都市: 建設済み建物 [プロット番号: CityBuilding]
    var cityBuildings: [Int: CityBuilding] = [:]

    private var lastSaveDate: Date = Date()

    private init() {
        loadGame()
        calculateOfflineIncome()
    }

    // MARK: - Computed

    var tapMultiplier: Double {
        var m = 1.0
        if purchasedUpgrades.contains("tap_lv1") { m += 0.5 }
        if purchasedUpgrades.contains("tap_lv2") { m += 1.0 }
        if purchasedUpgrades.contains("tap_lv3") { m += 1.5 }   // ガチャSR限定
        if isBoostActive("boost_tap2")  { m *= 2.0 }
        if isBoostActive("boost_all3")  { m *= 3.0 }
        return m
    }

    var incomeMultiplier: Double {
        var m = 1.0
        if purchasedUpgrades.contains("income_lv1") { m += 0.3 }
        if purchasedUpgrades.contains("income_lv2") { m += 0.7 }
        if purchasedUpgrades.contains("income_lv3") { m += 2.0 }  // ガチャSSR限定
        if isBoostActive("boost_income2") { m *= 2.0 }
        if isBoostActive("boost_income5") { m *= 5.0 }
        if isBoostActive("boost_all3")    { m *= 3.0 }
        return m
    }

    var officeIncomeMultiplier: Double {
        var bonus = 0.0
        for item in OfficeItem.all {
            let level = officeUpgrades[item.id] ?? 0
            bonus += Double(level) * item.incomeBoostPerLevel
        }
        return 1.0 + bonus
    }

    var floorIncomeMultiplier: Double {
        1.0 + Double(officeFloors - 1) * 0.3   // フロアごとに +30%
    }

    var cityIncomePerSec: Double {
        cityBuildings.values.reduce(0.0) { total, bld in
            guard let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }) else { return total }
            return total + t.incomePerSec(level: bld.level)
        }
    }

    var totalIncomePerSec: Double {
        let empIncome = employees.filter { $0.isHired }.reduce(0.0) { total, emp in
            total + emp.currentIncomePerSec * cardIncomeMultiplier(for: emp.id)
        }
        return (empIncome * incomeMultiplier * officeIncomeMultiplier * floorIncomeMultiplier)
            + cityIncomePerSec
    }

    // MARK: - ガチャカード管理

    func cardCount(charId: Int, imageIndex: Int) -> Int {
        gachaCardCounts["\(charId)_\(imageIndex)"] ?? 0
    }

    func addCard(_ card: GachaCard) {
        let key = card.cardKey
        gachaCardCounts[key] = (gachaCardCounts[key] ?? 0) + 1
    }

    /// キャラのカード合計から収益倍率を計算
    func cardIncomeMultiplier(for charId: Int) -> Double {
        var bonus = 0.0
        for card in GachaCatalog.pool where card.charId == charId {
            let count = cardCount(charId: charId, imageIndex: card.imageIndex)
            bonus += card.rarity.incomeBonus * Double(count)
        }
        return 1.0 + bonus
    }

    var tapValue: Double {
        let base = 1.0
        let bonus = employees.filter { $0.isHired }.reduce(0.0) { $0 + $1.currentIncomePerSec * 0.1 }
        return (base + bonus) * tapMultiplier
    }

    var allHired: Bool {
        employees.filter { $0.id < 6 }.allSatisfy { $0.isHired }
    }

    // MARK: - Shop helpers

    func hasUpgrade(_ id: String) -> Bool { purchasedUpgrades.contains(id) }

    func isBoostActive(_ id: String) -> Bool {
        guard let exp = activeBoosts[id] else { return false }
        return exp > Date()
    }

    func boostTimeRemaining(_ id: String) -> Double {
        guard let exp = activeBoosts[id] else { return 0 }
        return max(0, exp.timeIntervalSinceNow)
    }

    /// ショップでアイテムを購入。成功時 true
    func buyShopItem(_ item: ShopItem) -> Bool {
        guard money >= item.cost else { return false }
        // 永続アップグレードは一度のみ（前提条件チェック）
        if item.boostDuration == 0 {
            guard !purchasedUpgrades.contains(item.id) else { return false }
            if let req = item.requiresId, !purchasedUpgrades.contains(req) { return false }
        }
        money -= item.cost
        if item.boostDuration > 0 {
            // 時限ブースト: 既存の残り時間に加算
            let base = max(Date(), activeBoosts[item.id] ?? Date())
            activeBoosts[item.id] = base.addingTimeInterval(item.boostDuration)
        } else {
            purchasedUpgrades.insert(item.id)
        }
        saveGame()
        return true
    }

    // MARK: - Actions

    @discardableResult
    func tap() -> Double {
        let earned = max(1.0, tapValue)
        money += earned
        totalEarned += earned
        return earned
    }

    func hire(id: Int) -> Bool {
        guard let index = employees.firstIndex(where: { $0.id == id }),
              !employees[index].isHired,
              money >= employees[index].hireCost else { return false }
        money -= employees[index].hireCost
        employees[index].isHired = true
        employees[index].level = 1
        return true
    }

    func upgrade(id: Int) -> Bool {
        guard let index = employees.firstIndex(where: { $0.id == id }),
              employees[index].isHired,
              money >= employees[index].upgradeCost else { return false }
        money -= employees[index].upgradeCost
        employees[index].level += 1
        return true
    }

    // MARK: - 図鑑: 選択画像

    func selectedNobgImageName(for charId: Int) -> String {
        guard let emp = employees.first(where: { $0.id == charId }) else { return "" }
        let idx = selectedImageIndex[charId] ?? 0
        return emp.nobgImageName(at: idx)
    }

    func setSelectedImage(charId: Int, index: Int) {
        selectedImageIndex[charId] = index
        saveGame()
    }

    // MARK: - Offline Income

    private func calculateOfflineIncome() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSaveDate)
        guard elapsed > 60 else { return }

        let maxHours: Double = purchasedUpgrades.contains("offline_ext") ? 16 : 8
        let effectiveTime = min(elapsed, maxHours * 3600)
        let earned = totalIncomePerSec * effectiveTime
        guard earned > 0 else { return }

        money += earned
        totalEarned += earned
        pendingOfflineIncome = earned
    }

    // MARK: - Office Floors

    func floorCost(_ floors: Int) -> Double { 80_000 * pow(5.0, Double(floors - 1)) }

    @discardableResult
    func addOfficeFloor() -> Bool {
        let cost = floorCost(officeFloors)
        guard money >= cost else { return false }
        money -= cost
        officeFloors += 1
        saveGame()
        return true
    }

    // MARK: - City Buildings

    @discardableResult
    func placeBuilding(plot: Int, typeId: String) -> Bool {
        guard cityBuildings[plot] == nil,
              let t = CityBuildingType.all.first(where: { $0.id == typeId }),
              money >= t.placeCost else { return false }
        money -= t.placeCost
        cityBuildings[plot] = CityBuilding(typeId: typeId, level: 1)
        saveGame()
        return true
    }

    @discardableResult
    func upgradeBuilding(plot: Int) -> Bool {
        guard var bld = cityBuildings[plot],
              let t = CityBuildingType.all.first(where: { $0.id == bld.typeId }),
              bld.level < t.maxLevel else { return false }
        let cost = t.upgradeCost(level: bld.level)
        guard money >= cost else { return false }
        money -= cost
        bld.level += 1
        cityBuildings[plot] = bld
        saveGame()
        return true
    }

    // MARK: - Office Upgrades

    @discardableResult
    func upgradeOffice(id: String) -> Bool {
        guard let item = OfficeItem.all.first(where: { $0.id == id }) else { return false }
        let current = officeUpgrades[id] ?? 0
        guard current < item.maxLevel else { return false }
        let cost = item.costForNextLevel(current)
        guard money >= cost else { return false }
        money -= cost
        officeUpgrades[id] = current + 1
        saveGame()
        return true
    }

    // MARK: - Save / Load

    func saveGame() {
        let d = UserDefaults.standard
        d.set(money, forKey: "cg_money")
        d.set(totalEarned, forKey: "cg_totalEarned")
        d.set(Date(), forKey: "cg_lastSave")

        let empData = employees.map { e -> [String: Any] in
            ["id": e.id, "level": e.level, "isHired": e.isHired]
        }
        d.set(empData, forKey: "cg_employees")
        d.set(selectedImageIndex.map { ["id": $0.key, "idx": $0.value] }, forKey: "cg_selImg")

        // ショップ
        d.set(Array(purchasedUpgrades), forKey: "cg_upgrades")
        let boostData = activeBoosts.map { ["id": $0.key, "exp": $0.value.timeIntervalSince1970] }
        d.set(boostData, forKey: "cg_boosts")

        // オフィス
        let officeData = officeUpgrades.map { ["id": $0.key, "lv": $0.value] }
        d.set(officeData, forKey: "cg_office")
        d.set(officeFloors, forKey: "cg_floors")

        // ガチャ
        d.set(gachaPityCount, forKey: "cg_gachaPity")
        let cardData = gachaCardCounts.map { ["k": $0.key, "v": $0.value] }
        d.set(cardData, forKey: "cg_gachaCards")

        // 都市
        let cityData = cityBuildings.map { ["plot": $0.key, "type": $0.value.typeId, "lv": $0.value.level] }
        d.set(cityData, forKey: "cg_city")

        lastSaveDate = Date()
    }

    func loadGame() {
        let d = UserDefaults.standard
        money = d.double(forKey: "cg_money")
        totalEarned = d.double(forKey: "cg_totalEarned")
        lastSaveDate = d.object(forKey: "cg_lastSave") as? Date ?? Date()

        if let empData = d.array(forKey: "cg_employees") as? [[String: Any]] {
            for data in empData {
                guard let id = data["id"] as? Int,
                      let level = data["level"] as? Int,
                      let isHired = data["isHired"] as? Bool,
                      let index = employees.firstIndex(where: { $0.id == id }) else { continue }
                employees[index].level = level
                employees[index].isHired = isHired
            }
        }
        if let selData = d.array(forKey: "cg_selImg") as? [[String: Int]] {
            for item in selData {
                if let id = item["id"], let idx = item["idx"] {
                    selectedImageIndex[id] = idx
                }
            }
        }

        // ショップ
        if let upgrades = d.array(forKey: "cg_upgrades") as? [String] {
            purchasedUpgrades = Set(upgrades)
        }
        if let boostData = d.array(forKey: "cg_boosts") as? [[String: Any]] {
            for item in boostData {
                if let id = item["id"] as? String, let ts = item["exp"] as? Double {
                    let exp = Date(timeIntervalSince1970: ts)
                    if exp > Date() { activeBoosts[id] = exp }
                }
            }
        }

        // オフィス
        if let officeData = d.array(forKey: "cg_office") as? [[String: Any]] {
            for item in officeData {
                if let id = item["id"] as? String, let lv = item["lv"] as? Int {
                    officeUpgrades[id] = lv
                }
            }
        }
        officeFloors    = max(1, d.integer(forKey: "cg_floors"))
        gachaPityCount  = d.integer(forKey: "cg_gachaPity")
        if let cardData = d.array(forKey: "cg_gachaCards") as? [[String: Any]] {
            for item in cardData {
                if let k = item["k"] as? String, let v = item["v"] as? Int {
                    gachaCardCounts[k] = v
                }
            }
        }

        // 都市
        if let cityData = d.array(forKey: "cg_city") as? [[String: Any]] {
            for item in cityData {
                if let plot = item["plot"] as? Int,
                   let typeId = item["type"] as? String,
                   let lv = item["lv"] as? Int {
                    cityBuildings[plot] = CityBuilding(typeId: typeId, level: lv)
                }
            }
        }
    }
}
