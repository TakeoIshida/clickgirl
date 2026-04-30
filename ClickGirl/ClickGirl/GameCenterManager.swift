import GameKit

class GameCenterManager: NSObject {
    static let shared = GameCenterManager()
    static let leaderboardID = "com.tko.ClickGirl.totalearned"

    private(set) var isAuthenticated = false
    weak var presentingViewController: UIViewController?

    private override init() {}

    func authenticate() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] vc, _ in
            guard let self = self else { return }
            if let vc = vc {
                self.presentingViewController?.present(vc, animated: true)
            } else if player.isAuthenticated {
                self.isAuthenticated = true
                self.submitScore(GameManager.shared.totalEarned)
            } else {
                self.isAuthenticated = false
            }
        }
    }

    func submitScore(_ score: Double) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let intScore = Int(min(score, Double(Int64.max)))
        GKLeaderboard.submitScore(
            intScore, context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [GameCenterManager.leaderboardID]
        ) { _ in }
    }

    func loadTopEntries(completion: @escaping (_ entries: [GKLeaderboard.Entry], _ myEntry: GKLeaderboard.Entry?) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else {
            DispatchQueue.main.async { completion([], nil) }
            return
        }
        GKLeaderboard.loadLeaderboards(IDs: [GameCenterManager.leaderboardID]) { leaderboards, _ in
            guard let lb = leaderboards?.first else {
                DispatchQueue.main.async { completion([], nil) }
                return
            }
            lb.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 10)
            ) { myEntry, entries, _, _ in
                DispatchQueue.main.async {
                    completion(entries ?? [], myEntry)
                }
            }
        }
    }
}
