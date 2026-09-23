import Foundation

public struct MatchRecord: Codable, Equatable, Sendable {
    public var wins = 0
    public var losses = 0
    public var draws = 0
    public var played: Int { wins + losses + draws }
    public var winRate: Int { played == 0 ? 0 : Int(Double(wins) / Double(played) * 100) }
    public init() {}
}
public struct Settings: Codable, Sendable {
    public var sound = true
    public var legalGuides = true
    public var haptics = true
    public var player: Side = .black
    public var handicap: Handicap = .even
    public init() {}
}
public struct SaveState: Codable, Sendable {
    public var version = 1
    public var records: [String: MatchRecord] = [:]
    public var processedMatches: Set<UUID> = []
    public var activeMatch: Match?
    public var settings = Settings()
    public var energy = 100
    public var energyDate = Date()
    public var hintDay = ""
    public var hintCount = 0
    public var lastCharacter = "koharu"
    public init() {}
}
public final class SaveStore {
    public static let key = "shogiGirls.save.v1"
    public private(set) var state: SaveState
    public private(set) var recoveryMessage: String?
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key), let decoded = try? JSONDecoder().decode(SaveState.self, from: data), Self.valid(decoded) { state = decoded }
        else if let data = defaults.data(forKey: Self.key + ".backup"), let backup = try? JSONDecoder().decode(SaveState.self, from: data), Self.valid(backup) {
            state = backup; recoveryMessage = "保存データをバックアップから復元したよ。"
        } else {
            state = SaveState()
            if let data = defaults.data(forKey: Self.key) { defaults.set(data, forKey: Self.key + ".damaged"); recoveryMessage = "保存データを読み込めなかったため、新しく始めるね。元データは保管済みだよ。" }
        }
    }
    private static func valid(_ s: SaveState) -> Bool {
        guard s.version == 1, (0...100).contains(s.energy), s.hintCount >= 0, s.records.values.allSatisfy({ $0.wins >= 0 && $0.losses >= 0 && $0.draws >= 0 }) else { return false }
        if let m = s.activeMatch {
            return Characters.all.contains { $0.id == m.characterID } && !m.positions.isEmpty && m.positions.count == m.moves.count + 1 && m.positions.count <= 501 && m.positions.allSatisfy { $0.isStructurallyValid } && m.moves.allSatisfy { (0..<81).contains($0.to) && ($0.from == nil || (0..<81).contains($0.from!)) && (($0.from != nil) != ($0.drop != nil)) }
        }
        return true
    }
    public func update(_ body: (inout SaveState) -> Void) {
        var next = state; body(&next)
        guard let data = try? JSONEncoder().encode(next) else { return }
        if let old = defaults.data(forKey: Self.key), let decoded = try? JSONDecoder().decode(SaveState.self, from: old), Self.valid(decoded) { defaults.set(old, forKey: Self.key + ".backup") }
        defaults.set(data, forKey: Self.key); state = next
    }
    public func record(_ id: String) -> MatchRecord { state.records[id] ?? MatchRecord() }
    public func unlocked(_ id: String) -> Bool {
        guard let i = Characters.all.firstIndex(where: { $0.id == id }) else { return false }
        return i == 0 || record(Characters.all[i - 1].id).wins > 0
    }
    public func unlocked(_ reward: GalleryReward) -> Bool { record(reward.characterID).wins >= reward.requiredWins }
    public func energy(at now: Date = Date()) -> Int { min(100, state.energy + max(0, Int(now.timeIntervalSince(state.energyDate) / 180))) }
    public func recoverySeconds(at now: Date = Date()) -> Int { energy(at: now) == 100 ? 0 : max(1, 180 - max(0, Int(now.timeIntervalSince(state.energyDate))) % 180) }
    @discardableResult public func begin(_ match: Match, now: Date = Date(), free: Bool = false) -> Bool {
        guard state.activeMatch == nil, unlocked(match.characterID), free || energy(at: now) >= 20 else { return false }
        update { s in
            let current = energy(at: now)
            if !free {
                let elapsedSteps = max(0, Int(now.timeIntervalSince(s.energyDate) / 180))
                s.energyDate = current == 100 ? now : s.energyDate.addingTimeInterval(Double(elapsedSteps * 180))
                s.energy = current - 20
            }
            s.activeMatch = match; s.lastCharacter = match.characterID
        }; return true
    }
    public func rewardEnergy(now: Date = Date()) {
        update { s in
            let current = energy(at: now)
            let rewarded = min(100, current + 20)
            if rewarded == 100 {
                s.energyDate = now
            } else {
                let elapsedSteps = max(0, Int(now.timeIntervalSince(s.energyDate) / 180))
                s.energyDate = s.energyDate.addingTimeInterval(Double(elapsedSteps * 180))
            }
            s.energy = rewarded
        }
    }
    public func saveMatch(_ match: Match) { update { $0.activeMatch = match } }
    @discardableResult public func finish(_ match: Match) -> [GalleryReward] {
        guard let result = match.result, !state.processedMatches.contains(match.id) else { return [] }
        let before = record(match.characterID).wins
        update { s in
            var r = s.records[match.characterID] ?? MatchRecord()
            if result.winner == nil { r.draws += 1 } else if result.winner == match.player { r.wins += 1 } else { r.losses += 1 }
            s.records[match.characterID] = r; s.processedMatches.insert(match.id); s.activeMatch = match
        }
        return GalleryReward.all(for: match.characterID).filter { before < $0.requiredWins && record(match.characterID).wins >= $0.requiredWins }
    }
    public func dismissResult() { update { $0.activeMatch = nil } }
    private func day(_ now: Date) -> String { let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.dateFormat = "yyyy-MM-dd"; return f.string(from: now) }
    public func freeHints(at now: Date = Date()) -> Int { state.hintDay == day(now) ? max(0, 3 - state.hintCount) : 3 }
    @discardableResult public func useFreeHint(at now: Date = Date()) -> Bool {
        guard freeHints(at: now) > 0 else { return false }
        update { s in if s.hintDay != day(now) { s.hintDay = day(now); s.hintCount = 0 }; s.hintCount += 1 }; return true
    }
}
