import Foundation

public struct SearchResult: Sendable {
    public let move: ShogiMove?
    public let score: Int
    public let depth: Int
    public let nodes: Int
}
public final class SearchCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    public init() {}
    public func cancel() { lock.lock(); value = true; lock.unlock() }
    public var cancelled: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

/// One instance per search, used on a background queue. No shared mutable search state.
public final class ShogiAI {
    private let profile: AIProfile
    private var deadline = 0.0
    private var nodes = 0
    private var aborted = false
    private var rng: UInt64
    private var cancellation = SearchCancellation()
    private var rootSide: Side = .black
    private struct Entry { let depth: Int; let score: Int; let move: ShogiMove?; let flag: Int }
    private var table: [String: Entry] = [:]
    public init(profile: AIProfile, seed: UInt64 = UInt64.random(in: 1...UInt64.max)) { self.profile = profile; self.rng = seed == 0 ? 1 : seed }
    private func random(_ limit: Int) -> Int { rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17; return limit > 0 ? Int(rng % UInt64(limit)) : 0 }
    private var shouldStop: Bool {
        if cancellation.cancelled || ProcessInfo.processInfo.systemUptime >= deadline { aborted = true }
        return aborted
    }
    public func search(_ p: ShogiPosition, timeLimit: Double? = nil, cancellation: SearchCancellation = SearchCancellation()) -> SearchResult {
        self.cancellation = cancellation; deadline = ProcessInfo.processInfo.systemUptime + (timeLimit ?? profile.seconds)
        nodes = 0; aborted = false; rootSide = p.turn; table.removeAll(keepingCapacity: true)
        let moves = ordered(p.legalMoves(), in: p, preferred: nil)
        guard !moves.isEmpty else { return .init(move: nil, score: -100000, depth: 0, nodes: 0) }
        var best = moves[0], score = -100001, completed = 0
        let noises = Dictionary(uniqueKeysWithValues: moves.map { ($0, random(profile.noise * 2 + 1) - profile.noise) })
        let opening = openingMove(in: p, legal: moves)
        for depth in 1...profile.depth {
            var candidate = best, candidateScore = -100001
            for move in ordered(moves, in: p, preferred: best) {
                if shouldStop { break }
                let next = p.applyingUnchecked(move)
                let adjustment = (noises[move] ?? 0) + (move == opening ? 85 : 0)
                // Share the best root bound between moves, adjusted for character
                // preferences, so stronger levels can finish deeper iterations.
                let bound = min(100001, -candidateScore + adjustment)
                let searched = -negamax(next, depth: depth - 1, alpha: -100001, beta: bound, ply: 1, path: [p.key])
                let value = searched + (abs(searched) < 90000 ? adjustment : 0)
                if aborted { break }
                if value > candidateScore { candidateScore = value; candidate = move }
            }
            if aborted { break }
            best = candidate; score = candidateScore; completed = depth
            if score > 90000 { break }
        }
        if completed == 0 { score = evaluate(p, for: p.turn) }
        return .init(move: best, score: score, depth: completed, nodes: nodes)
    }
    // Short original development plans. These are preferences, never forced moves:
    // tactical search can reject them when a capture or king danger takes priority.
    private func openingMove(in p: ShogiPosition, legal: [ShogiMove]) -> ShogiMove? {
        guard p.ply < 32, !p.inCheck(p.turn) else { return nil }
        let plan: [(Int,Int)]
        switch profile.style {
        case .fourthFile: plan = [(56,47),(70,66),(57,48),(76,68),(68,69),(69,70),(78,69)]
        case .thirdFile: plan = [(56,47),(70,65),(56,47),(76,68),(68,69),(69,70)]
        case .climbingSilver: plan = [(61,52),(78,69),(69,60),(60,51),(52,43)]
        case .fortress: plan = [(56,47),(59,50),(74,66),(75,67),(76,75),(75,66)]
        case .anaguma: plan = [(56,47),(64,56),(76,66),(66,65),(72,63),(65,64),(64,72)]
        case .bishopExchange: plan = [(56,47),(61,52),(78,69)]
        case .attack: plan = [(61,52),(52,43),(56,47),(78,69)]
        case .beginner,.adaptive,.balanced: return nil
        }
        for (from,to) in plan {
            let a = p.turn == .black ? from : 80-from, b = p.turn == .black ? to : 80-to
            let move = ShogiMove(from:a,to:b)
            if p.board[a]?.side == p.turn && legal.contains(move) { return move }
        }
        return nil
    }
    private func negamax(_ p: ShogiPosition, depth: Int, alpha: Int, beta: Int, ply: Int, path: Set<String>) -> Int {
        nodes += 1
        if shouldStop { return 0 }
        if path.contains(p.key) { return 0 }
        let originalAlpha = alpha
        var a = alpha, b = beta
        let entry = table[p.key]
        if let e = entry, e.depth >= depth, abs(e.score) < 90000 {
            if e.flag == 0 { return e.score }
            if e.flag == 1 { a = max(a, e.score) } else { b = min(b, e.score) }
            if a >= b { return e.score }
        }
        let moves = p.legalMoves()
        if moves.isEmpty { return -100000 + ply }
        if depth <= 0 { return quiescence(p, moves: moves, alpha: a, beta: b, remaining: 2, ply: ply) }
        var bestScore = -100001, bestMove: ShogiMove?
        var nextPath = path; nextPath.insert(p.key)
        for move in ordered(moves, in: p, preferred: entry?.move) {
            let value = -negamax(p.applyingUnchecked(move), depth: depth - 1, alpha: -b, beta: -a, ply: ply + 1, path: nextPath)
            if aborted { return 0 }
            if value > bestScore { bestScore = value; bestMove = move }
            a = max(a, value); if a >= b { break }
        }
        if table.count < 30000 { table[p.key] = Entry(depth: depth, score: bestScore, move: bestMove, flag: bestScore <= originalAlpha ? 2 : bestScore >= beta ? 1 : 0) }
        return bestScore
    }
    private func quiescence(_ p: ShogiPosition, moves: [ShogiMove], alpha: Int, beta: Int, remaining: Int, ply: Int) -> Int {
        if shouldStop { return 0 }
        let checked = p.inCheck(p.turn)
        let stand = evaluate(p, for: p.turn)
        if remaining == 0 { return stand }
        var a = checked ? alpha : max(alpha, stand)
        if !checked && a >= beta { return a }
        let tactical = checked ? moves : moves.filter { p.board[$0.to] != nil || $0.promote }
        for move in ordered(tactical, in: p, preferred: nil) {
            let next = p.applyingUnchecked(move), replies = next.legalMoves()
            let score = replies.isEmpty ? 100000 - ply : -quiescence(next, moves: replies, alpha: -beta, beta: -a, remaining: remaining - 1, ply: ply + 1)
            if aborted { return 0 }
            a = max(a, score); if a >= beta { break }
        }
        return a
    }
    private func ordered(_ moves: [ShogiMove], in p: ShogiPosition, preferred: ShogiMove?) -> [ShogiMove] {
        moves.sorted { orderScore($0, p, preferred) > orderScore($1, p, preferred) }
    }
    private func orderScore(_ m: ShogiMove, _ p: ShogiPosition, _ preferred: ShogiMove?) -> Int {
        if m == preferred { return 1000000 }
        let capture = p.board[m.to].map { $0.value * 10 } ?? 0
        return capture + (m.promote ? 700 : 0) - (m.from.flatMap { p.board[$0]?.value } ?? 0) / 10
    }
    public func evaluate(_ p: ShogiPosition, for side: Side) -> Int {
        var total = 0
        for s in Side.allCases {
            var value = 0
            let king = p.king(s) ?? 40
            let ownProfile = s == rootSide ? profile.style : .balanced
            for i in p.board.indices {
                guard let piece = p.board[i], piece.side == s else { continue }
                let row = s.relativeRow(i / 9), col = s == .black ? i % 9 : 8 - i % 9
                value += piece.value
                if piece.kind != .king {
                    let advancement = 8 - row
                    value += advancement * (ownProfile == .attack ? 12 : 4)
                    value += p.destinations(from: i, piece: piece).filter { p.board[$0]?.side != s }.count * (ownProfile == .thirdFile ? 5 : 2)
                    if [.gold,.silver].contains(piece.kind) {
                        let distance = abs(i % 9 - king % 9) + abs(i / 9 - king / 9)
                        value += max(0, 4 - distance) * ([PlayingStyle.fortress,.anaguma].contains(ownProfile) ? 22 : 8)
                    }
                    if piece.kind == .rook && p.ply < 42 {
                        let target = ownProfile == .fourthFile ? 3 : ownProfile == .thirdFile ? 2 : 7
                        value += (8 - abs(col - target)) * ([PlayingStyle.fourthFile,.thirdFile].contains(ownProfile) ? 28 : 4)
                    }
                    if piece.kind == .silver && ownProfile == .climbingSilver { value += col >= 6 ? advancement * 25 : 0 }
                    if piece.kind == .bishop && ownProfile == .bishopExchange { value += p.destinations(from: i, piece: piece).count * 7 }
                    if ownProfile == .adaptive {
                        let enemyKing = p.king(s.opponent) ?? 40
                        value += max(0, 8 - abs(i % 9 - enemyKing % 9) - abs(i / 9 - enemyKing / 9)) * 5
                    }
                } else if p.ply < 60 {
                    if ownProfile == .anaguma { value += (col == 0 && row == 8) ? 190 : -abs(col) * 10 }
                    if [.thirdFile,.fourthFile].contains(ownProfile) { value += max(0, 3 - abs(col - 7)) * 25 }
                    if ownProfile == .fortress { value += max(0, 4 - abs(col - 2) - abs(row - 7)) * 25 }
                }
            }
            for kind in PieceKind.handKinds { value += p.hands[s.rawValue][kind.rawValue] * (kind.value + 15) }
            if p.inCheck(s) { value -= 40 }
            total += s == side ? value : -value
        }
        return total
    }
}
