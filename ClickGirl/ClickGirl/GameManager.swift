import Foundation

struct Mission {
    let id: String
    let title: String
    let detail: String
    let reward: Double
    let progress: (GameManager) -> Int
    let target: Int
}

struct DailyMission {
    let id: String
    let title: String
    let detail: String
    let baseReward: Double
    let incomeSeconds: Double
    let ticketReward: Int
    let progress: (GameManager) -> Int
    let target: Int

    func reward(for manager: GameManager) -> Double {
        max(baseReward, manager.totalIncomePerSec * incomeSeconds)
    }
}

struct DailyMissionReward {
    let mission: DailyMission
    let money: Double
    let tickets: Int
}

class GameManager {
    static let shared = GameManager()

    // MARK: - State
    var money: Double = 0
    var totalEarned: Double = 0
    var lifetimeTaps: Int = 0
    var gachaTickets: Int = 0
    var employees: [Employee] = Employee.allEmployees
    var pendingOfflineIncome: Double = 0
    var pendingComebackMoney: Double = 0
    var pendingComebackTickets: Int = 0
    var pendingComebackDays: Int = 0
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
    var didGrantStarterPack: Bool = false
    var completedMissionIDs: Set<String> = []
    var shopPurchaseCount: Int = 0
    var gachaPullCount: Int = 0
    var officeUpgradeCount: Int = 0
    var cityBuildCount: Int = 0
    var lastDailyGachaAdDate: Date?
    var dailyMissionDate: Date = Date()
    var completedDailyMissionIDs: Set<String> = []
    var dailyTapCount: Int = 0
    var dailyGrowthActionCount: Int = 0
    var dailyGachaPullCount: Int = 0
    var dailyMissionStreak: Int = 0
    var lastDailyMissionCompletionDate: Date?
    var weeklyMissionWeekStart: Date = Date()
    var weeklyCompletedDays: Int = 0
    var weeklyRewardClaimed: Bool = false

    private let calendar = Calendar.current

    private var lastSaveDate: Date = Date()

    private init() {
        loadGame()
        ensureDailyMissionsCurrent()
        ensureWeeklyMissionCurrent()
        calculateOfflineIncome()
    }

    // MARK: - Computed

    static let starterMoney: Double = 1_500
    static let starterTickets: Int = 1

    var missions: [Mission] {
        [
            Mission(id: "tap_10", title: "営業スタート", detail: "キャラを10回タップする",
                    reward: 300, progress: { min($0.lifetimeTaps, 10) }, target: 10),
            Mission(id: "hire_airi", title: "初めての採用", detail: "アイリを採用する",
                    reward: 500,
                    progress: { ($0.employees.first(where: { $0.id == 0 })?.isHired ?? false) ? 1 : 0 },
                    target: 1),
            Mission(id: "upgrade_airi", title: "社員育成", detail: "アイリをLv.3にする",
                    reward: 900,
                    progress: { min($0.employees.first(where: { $0.id == 0 })?.level ?? 0, 3) },
                    target: 3),
            Mission(id: "first_shop", title: "会社の仕組み化", detail: "ショップで強化を1つ購入する",
                    reward: 1_200, progress: { min($0.shopPurchaseCount, 1) }, target: 1),
            Mission(id: "first_gacha", title: "人材カード発掘", detail: "ガチャを1回引く",
                    reward: 1_500, progress: { min($0.gachaPullCount, 1) }, target: 1),
            Mission(id: "first_office", title: "働く場所づくり", detail: "オフィス設備を1つ強化する",
                    reward: 2_000, progress: { min($0.officeUpgradeCount, 1) }, target: 1),
            Mission(id: "first_city", title: "街へ進出", detail: "都市に建物を1つ建てる",
                    reward: 3_000, progress: { min($0.cityBuildCount, 1) }, target: 1),
        ]
    }

    var currentMission: Mission? {
        missions.first { !completedMissionIDs.contains($0.id) }
    }

    var dailyMissions: [DailyMission] {
        [
            DailyMission(id: "daily_tap_50", title: "朝の営業",
                         detail: "キャラを50回タップする", baseReward: 500,
                         incomeSeconds: 60, ticketReward: 0,
                         progress: { min($0.dailyTapCount, 50) }, target: 50),
            DailyMission(id: "daily_growth_2", title: "会社を成長",
                         detail: "採用・育成・設備強化を2回行う", baseReward: 1_500,
                         incomeSeconds: 180, ticketReward: 0,
                         progress: { min($0.dailyGrowthActionCount, 2) }, target: 2),
            DailyMission(id: "daily_gacha_1", title: "今日の人材発掘",
                         detail: "ガチャを1回引く", baseReward: 3_000,
                         incomeSeconds: 300, ticketReward: 1,
                         progress: { min($0.dailyGachaPullCount, 1) }, target: 1),
        ]
    }

    var currentDailyMission: DailyMission? {
        ensureDailyMissionsCurrent()
        guard currentMission == nil else { return nil }
        return dailyMissions.first { !completedDailyMissionIDs.contains($0.id) }
    }

    var dailyMissionStreakStep: Int {
        min((dailyMissionStreak % 7) + 1, 7)
    }

    var weeklyMissionProgress: Int {
        ensureWeeklyMissionCurrent()
        return min(weeklyCompletedDays, 5)
    }

    var canClaimDailyGachaAd: Bool {
        guard let last = lastDailyGachaAdDate else { return true }
        return !calendar.isDateInToday(last)
    }

    func claimDailyGachaAd() {
        lastDailyGachaAdDate = Date()
        saveGame()
    }

    func activateRewardedIncomeBoost(duration: TimeInterval = 300) {
        let base = max(Date(), activeBoosts["boost_income2"] ?? Date())
        activeBoosts["boost_income2"] = base.addingTimeInterval(duration)
        saveGame()
    }

    func recordRewardedOpportunity(_ placement: String) {
        let key = "cg_metric_rewarded_opportunity_\(placement)"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
        AnalyticsManager.shared.logRewardedOpportunity(placement: placement)
    }

    func recordRewardedCompletion(_ placement: String) {
        let key = "cg_metric_rewarded_completion_\(placement)"
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: key) + 1, forKey: key)
        AnalyticsManager.shared.logRewardedCompleted(placement: placement)
    }

    @discardableResult
    func grantStarterPackIfNeeded() -> Bool {
        guard !didGrantStarterPack else { return false }
        didGrantStarterPack = true
        money += Self.starterMoney
        totalEarned += Self.starterMoney
        gachaTickets += Self.starterTickets
        saveGame()
        return true
    }

    @discardableResult
    func claimCompletedMissions() -> [Mission] {
        let newlyCompleted = missions.filter {
            !completedMissionIDs.contains($0.id) && $0.progress(self) >= $0.target
        }
        guard !newlyCompleted.isEmpty else { return [] }

        let reward = newlyCompleted.reduce(0.0) { $0 + $1.reward }
        money += reward
        totalEarned += reward
        newlyCompleted.forEach { completedMissionIDs.insert($0.id) }
        saveGame()
        return newlyCompleted
    }

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
        shopPurchaseCount += 1
        recordDailyGrowthAction()
        saveGame()
        return true
    }

    func recordGachaPull(count: Int) {
        ensureDailyMissionsCurrent()
        gachaPullCount += count
        dailyGachaPullCount += count
    }

    // MARK: - Actions

    @discardableResult
    func tap() -> Double {
        ensureDailyMissionsCurrent()
        let earned = max(1.0, tapValue)
        lifetimeTaps += 1
        dailyTapCount += 1
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
        recordDailyGrowthAction()
        saveGame()
        return true
    }

    func upgrade(id: Int) -> Bool {
        guard let index = employees.firstIndex(where: { $0.id == id }),
              employees[index].isHired,
              money >= employees[index].upgradeCost else { return false }
        money -= employees[index].upgradeCost
        employees[index].level += 1
        recordDailyGrowthAction()
        saveGame()
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
        if earned > 0 {
            money += earned
            totalEarned += earned
            pendingOfflineIncome = earned
        }

        let awayDays = Int(elapsed / 86_400)
        if awayDays >= 3 {
            let comebackMoney = max(10_000, totalIncomePerSec * 1_800)
            let comebackTickets = min(3, max(1, awayDays / 3))
            money += comebackMoney
            totalEarned += comebackMoney
            gachaTickets += comebackTickets
            pendingComebackMoney = comebackMoney
            pendingComebackTickets = comebackTickets
            pendingComebackDays = awayDays
            AnalyticsManager.shared.logComebackBonus(
                awayDays: awayDays,
                moneyReward: comebackMoney,
                ticketReward: comebackTickets
            )
        }

        lastSaveDate = now
        UserDefaults.standard.set(now, forKey: "cg_lastSave")
    }

    // MARK: - Office Floors

    func floorCost(_ floors: Int) -> Double { 3_000 * pow(4.0, Double(floors - 1)) }

    @discardableResult
    func addOfficeFloor() -> Bool {
        let cost = floorCost(officeFloors)
        guard money >= cost else { return false }
        money -= cost
        officeFloors += 1
        officeUpgradeCount += 1
        recordDailyGrowthAction()
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
        cityBuildCount += 1
        recordDailyGrowthAction()
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
        recordDailyGrowthAction()
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
        officeUpgradeCount += 1
        recordDailyGrowthAction()
        saveGame()
        return true
    }

    // MARK: - Daily Missions

    @discardableResult
    func claimCompletedDailyMissions() -> [DailyMissionReward] {
        ensureDailyMissionsCurrent()
        guard currentMission == nil else { return [] }

        var claimed: [DailyMissionReward] = []
        while let mission = dailyMissions.first(where: { !completedDailyMissionIDs.contains($0.id) }),
              mission.progress(self) >= mission.target {
            var rewardMoney = mission.reward(for: self)
            var ticketReward = mission.ticketReward
            let completesDay = mission.id == dailyMissions.last?.id
            if completesDay {
                updateDailyMissionStreak()
                if dailyMissionStreak.isMultiple(of: 7) {
                    rewardMoney += max(10_000, totalIncomePerSec * 900)
                    ticketReward += 3
                }
                let weeklyBonus = recordWeeklyDailyCompletion()
                rewardMoney += weeklyBonus.money
                ticketReward += weeklyBonus.tickets
            }
            money += rewardMoney
            totalEarned += rewardMoney
            gachaTickets += ticketReward
            completedDailyMissionIDs.insert(mission.id)
            claimed.append(DailyMissionReward(mission: mission,
                                              money: rewardMoney,
                                              tickets: ticketReward))
            AnalyticsManager.shared.logDailyMissionCompleted(
                missionID: mission.id,
                moneyReward: rewardMoney,
                ticketReward: ticketReward
            )
            if completesDay {
                AnalyticsManager.shared.logDailyMissionStreak(
                    streak: dailyMissionStreak,
                    receivedSevenDayBonus: dailyMissionStreak.isMultiple(of: 7)
                )
            }
        }

        if !claimed.isEmpty { saveGame() }
        return claimed
    }

    private func recordDailyGrowthAction() {
        ensureDailyMissionsCurrent()
        dailyGrowthActionCount += 1
    }

    private func updateDailyMissionStreak() {
        let now = Date()
        if let last = lastDailyMissionCompletionDate {
            if calendar.isDate(last, inSameDayAs: now) { return }
            let previousDay = calendar.date(byAdding: .day, value: -1, to: now)
            dailyMissionStreak = previousDay.map { calendar.isDate(last, inSameDayAs: $0) } == true
                ? dailyMissionStreak + 1
                : 1
        } else {
            dailyMissionStreak = 1
        }
        lastDailyMissionCompletionDate = now
    }

    private func recordWeeklyDailyCompletion() -> (money: Double, tickets: Int) {
        ensureWeeklyMissionCurrent()
        weeklyCompletedDays = min(weeklyCompletedDays + 1, 5)
        guard weeklyCompletedDays >= 5, !weeklyRewardClaimed else { return (0, 0) }

        weeklyRewardClaimed = true
        let bonusMoney = max(50_000, totalIncomePerSec * 3_600)
        AnalyticsManager.shared.logWeeklyMissionCompleted(
            completedDays: weeklyCompletedDays,
            moneyReward: bonusMoney,
            ticketReward: 5
        )
        return (bonusMoney, 5)
    }

    private func ensureWeeklyMissionCurrent() {
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return }
        guard !calendar.isDate(weeklyMissionWeekStart, inSameDayAs: currentWeek) else { return }
        weeklyMissionWeekStart = currentWeek
        weeklyCompletedDays = 0
        weeklyRewardClaimed = false
    }

    private func ensureDailyMissionsCurrent() {
        guard !calendar.isDateInToday(dailyMissionDate) else { return }
        dailyMissionDate = Date()
        completedDailyMissionIDs = []
        dailyTapCount = 0
        dailyGrowthActionCount = 0
        dailyGachaPullCount = 0
    }

    // MARK: - Reset

    func resetAll() {
        let d = UserDefaults.standard
        let keys = ["cg_money","cg_totalEarned","cg_lastSave","cg_employees",
                    "cg_selImg","cg_upgrades","cg_boosts","cg_office",
                    "cg_floors","cg_gachaPity","cg_gachaCards","cg_city",
                    "cg_lifetimeTaps","cg_gachaTickets","cg_starterPack",
                    "cg_completedMissions","cg_shopPurchases","cg_gachaPulls",
                    "cg_officeUpgradeCount","cg_cityBuildCount","cg_dailyGachaAd",
                    "cg_dailyMissionDate","cg_completedDailyMissions","cg_dailyTaps",
                    "cg_dailyGrowthActions","cg_dailyGachaPulls","cg_dailyMissionStreak",
                    "cg_lastDailyMissionCompletion","cg_weeklyMissionWeekStart",
                    "cg_weeklyCompletedDays","cg_weeklyRewardClaimed"]
        keys.forEach { d.removeObject(forKey: $0) }
        money               = 0
        totalEarned         = 0
        lifetimeTaps        = 0
        gachaTickets        = 0
        employees           = Employee.allEmployees
        selectedImageIndex  = [:]
        purchasedUpgrades   = []
        activeBoosts        = [:]
        officeUpgrades      = [:]
        officeFloors        = 1
        gachaPityCount      = 0
        gachaCardCounts     = [:]
        cityBuildings       = [:]
        didGrantStarterPack = false
        completedMissionIDs = []
        shopPurchaseCount   = 0
        gachaPullCount      = 0
        officeUpgradeCount  = 0
        cityBuildCount      = 0
        lastDailyGachaAdDate = nil
        dailyMissionDate = Date()
        completedDailyMissionIDs = []
        dailyTapCount = 0
        dailyGrowthActionCount = 0
        dailyGachaPullCount = 0
        dailyMissionStreak = 0
        lastDailyMissionCompletionDate = nil
        weeklyMissionWeekStart = Date()
        weeklyCompletedDays = 0
        weeklyRewardClaimed = false
    }

    // MARK: - Save / Load

    func saveGame() {
        let d = UserDefaults.standard
        d.set(money, forKey: "cg_money")
        d.set(totalEarned, forKey: "cg_totalEarned")
        d.set(lifetimeTaps, forKey: "cg_lifetimeTaps")
        d.set(gachaTickets, forKey: "cg_gachaTickets")
        d.set(didGrantStarterPack, forKey: "cg_starterPack")
        d.set(Array(completedMissionIDs), forKey: "cg_completedMissions")
        d.set(shopPurchaseCount, forKey: "cg_shopPurchases")
        d.set(gachaPullCount, forKey: "cg_gachaPulls")
        d.set(officeUpgradeCount, forKey: "cg_officeUpgradeCount")
        d.set(cityBuildCount, forKey: "cg_cityBuildCount")
        d.set(lastDailyGachaAdDate, forKey: "cg_dailyGachaAd")
        d.set(dailyMissionDate, forKey: "cg_dailyMissionDate")
        d.set(Array(completedDailyMissionIDs), forKey: "cg_completedDailyMissions")
        d.set(dailyTapCount, forKey: "cg_dailyTaps")
        d.set(dailyGrowthActionCount, forKey: "cg_dailyGrowthActions")
        d.set(dailyGachaPullCount, forKey: "cg_dailyGachaPulls")
        d.set(dailyMissionStreak, forKey: "cg_dailyMissionStreak")
        d.set(lastDailyMissionCompletionDate, forKey: "cg_lastDailyMissionCompletion")
        d.set(weeklyMissionWeekStart, forKey: "cg_weeklyMissionWeekStart")
        d.set(weeklyCompletedDays, forKey: "cg_weeklyCompletedDays")
        d.set(weeklyRewardClaimed, forKey: "cg_weeklyRewardClaimed")
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
        GameCenterManager.shared.submitScore(totalEarned)
    }

    func loadGame() {
        let d = UserDefaults.standard
        money = d.double(forKey: "cg_money")
        totalEarned = d.double(forKey: "cg_totalEarned")
        lifetimeTaps = d.integer(forKey: "cg_lifetimeTaps")
        gachaTickets = d.integer(forKey: "cg_gachaTickets")
        didGrantStarterPack = d.bool(forKey: "cg_starterPack")
        if let ids = d.array(forKey: "cg_completedMissions") as? [String] {
            completedMissionIDs = Set(ids)
        }
        shopPurchaseCount = d.integer(forKey: "cg_shopPurchases")
        gachaPullCount = d.integer(forKey: "cg_gachaPulls")
        officeUpgradeCount = d.integer(forKey: "cg_officeUpgradeCount")
        cityBuildCount = d.integer(forKey: "cg_cityBuildCount")
        lastDailyGachaAdDate = d.object(forKey: "cg_dailyGachaAd") as? Date
        dailyMissionDate = d.object(forKey: "cg_dailyMissionDate") as? Date ?? Date()
        if let ids = d.array(forKey: "cg_completedDailyMissions") as? [String] {
            completedDailyMissionIDs = Set(ids)
        }
        dailyTapCount = d.integer(forKey: "cg_dailyTaps")
        dailyGrowthActionCount = d.integer(forKey: "cg_dailyGrowthActions")
        dailyGachaPullCount = d.integer(forKey: "cg_dailyGachaPulls")
        dailyMissionStreak = d.integer(forKey: "cg_dailyMissionStreak")
        lastDailyMissionCompletionDate = d.object(forKey: "cg_lastDailyMissionCompletion") as? Date
        weeklyMissionWeekStart = d.object(forKey: "cg_weeklyMissionWeekStart") as? Date ?? Date()
        weeklyCompletedDays = d.integer(forKey: "cg_weeklyCompletedDays")
        weeklyRewardClaimed = d.bool(forKey: "cg_weeklyRewardClaimed")
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
