import Foundation

class GameManager {
    static let shared = GameManager()

    // MARK: - State
    var money: Double = 0
    var totalEarned: Double = 0
    var employees: [Employee] = Employee.allEmployees
    var pendingOfflineIncome: Double = 0

    private var lastSaveDate: Date = Date()

    private init() {
        loadGame()
        calculateOfflineIncome()
    }

    // MARK: - Computed

    var totalIncomePerSec: Double {
        employees.filter { $0.isHired }.reduce(0) { $0 + $1.currentIncomePerSec }
    }

    var tapValue: Double {
        let base = 1.0
        let bonus = employees.filter { $0.isHired }.reduce(0.0) { $0 + $1.currentIncomePerSec * 0.1 }
        return base + bonus
    }

    var allHired: Bool {
        employees.filter { $0.id < 6 }.allSatisfy { $0.isHired }
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

    // MARK: - Offline Income

    private func calculateOfflineIncome() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastSaveDate)
        guard elapsed > 60 else { return }

        let maxOffline: TimeInterval = 8 * 3600
        let effectiveTime = min(elapsed, maxOffline)
        let earned = totalIncomePerSec * effectiveTime
        guard earned > 0 else { return }

        money += earned
        totalEarned += earned
        pendingOfflineIncome = earned
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
        lastSaveDate = Date()
    }

    func loadGame() {
        let d = UserDefaults.standard
        money = d.double(forKey: "cg_money")
        totalEarned = d.double(forKey: "cg_totalEarned")
        lastSaveDate = d.object(forKey: "cg_lastSave") as? Date ?? Date()

        guard let empData = d.array(forKey: "cg_employees") as? [[String: Any]] else { return }
        for data in empData {
            guard let id = data["id"] as? Int,
                  let level = data["level"] as? Int,
                  let isHired = data["isHired"] as? Bool,
                  let index = employees.firstIndex(where: { $0.id == id }) else { continue }
            employees[index].level = level
            employees[index].isHired = isHired
        }
    }
}
