import Foundation

public enum Side: Int, Codable, CaseIterable, Sendable {
    case black, white
    public var opponent: Side { self == .black ? .white : .black }
    public var forward: Int { self == .black ? -1 : 1 }
    public var title: String { self == .black ? "先手" : "後手" }
    public func inCamp(_ row: Int) -> Bool { self == .black ? row < 3 : row > 5 }
    public func relativeRow(_ row: Int) -> Int { self == .black ? row : 8 - row }
}

public enum PieceKind: Int, Codable, CaseIterable, Sendable {
    case pawn, lance, knight, silver, gold, bishop, rook, king
    public var text: String { ["歩", "香", "桂", "銀", "金", "角", "飛", "玉"][rawValue] }
    public var promotedText: String { ["と", "杏", "圭", "全", "金", "馬", "龍", "玉"][rawValue] }
    public var canPromote: Bool { self != .gold && self != .king }
    public var value: Int { [100, 300, 320, 450, 550, 800, 1000, 0][rawValue] }
    public var points: Int { self == .king ? 0 : (self == .bishop || self == .rook ? 5 : 1) }
    public static var handKinds: [PieceKind] { [.rook, .bishop, .gold, .silver, .knight, .lance, .pawn] }
}

public struct Piece: Codable, Equatable, Sendable {
    public var kind: PieceKind
    public var side: Side
    public var promoted: Bool
    public init(_ kind: PieceKind, _ side: Side, promoted: Bool = false) { self.kind = kind; self.side = side; self.promoted = promoted }
    public var text: String { promoted ? kind.promotedText : kind.text }
    public var value: Int { promoted ? (kind == .rook ? 1400 : kind == .bishop ? 1200 : 550) : kind.value }
}

public struct ShogiMove: Codable, Hashable, Sendable {
    public let from: Int?
    public let to: Int
    public let drop: PieceKind?
    public let promote: Bool
    public init(from: Int? = nil, to: Int, drop: PieceKind? = nil, promote: Bool = false) { self.from = from; self.to = to; self.drop = drop; self.promote = promote }
    public func notation(in position: ShogiPosition) -> String {
        let name = drop?.text ?? from.flatMap { position.board[$0]?.text } ?? ""
        return "\(position.turn == .black ? "▲" : "△")\(9 - to % 9)\(["一","二","三","四","五","六","七","八","九"][to / 9])\(name)\(drop != nil ? "打" : promote ? "成" : "")"
    }
}

public enum Handicap: String, Codable, CaseIterable, Sendable {
    case even, lance, rightLance, bishop, rook, rookLance, two, four, six, eight, ten
    public var title: String {
        switch self {
        case .even: return "平手"; case .lance: return "香落ち"; case .rightLance: return "右香落ち"
        case .bishop: return "角落ち"; case .rook: return "飛車落ち"; case .rookLance: return "飛香落ち"
        case .two: return "二枚落ち"; case .four: return "四枚落ち"; case .six: return "六枚落ち"
        case .eight: return "八枚落ち"; case .ten: return "十枚落ち"
        }
    }
    // Coordinates from the white/upper player's initial position.
    public var removed: [Int] {
        switch self {
        case .even: return []; case .lance: return [8]; case .rightLance: return [0]
        case .bishop: return [16]; case .rook: return [10]; case .rookLance: return [10, 8]
        case .two: return [10, 16]; case .four: return [10, 16, 0, 8]
        case .six: return [10, 16, 0, 8, 1, 7]; case .eight: return [10, 16, 0, 8, 1, 7, 2, 6]
        case .ten: return [10, 16, 0, 8, 1, 7, 2, 6, 3, 5]
        }
    }
}

public struct ShogiPosition: Codable, Equatable, Sendable {
    public var board: [Piece?]
    public var hands: [[Int]]
    public var turn: Side
    public var ply: Int
    public init(board: [Piece?] = Array(repeating: nil, count: 81), hands: [[Int]] = Array(repeating: Array(repeating: 0, count: 8), count: 2), turn: Side = .black, ply: Int = 0) {
        self.board = board; self.hands = hands; self.turn = turn; self.ply = ply
    }
    public static func initial(handicap: Handicap = .even, player: Side = .black) -> ShogiPosition {
        var p = ShogiPosition()
        let back: [PieceKind] = [.lance, .knight, .silver, .gold, .king, .gold, .silver, .knight, .lance]
        for c in 0..<9 { p.board[c] = Piece(back[c], .white); p.board[72 + c] = Piece(back[c], .black); p.board[18 + c] = Piece(.pawn, .white); p.board[54 + c] = Piece(.pawn, .black) }
        p.board[10] = Piece(.rook, .white); p.board[16] = Piece(.bishop, .white)
        p.board[64] = Piece(.bishop, .black); p.board[70] = Piece(.rook, .black)
        for i in handicap.removed { p.board[player == .black ? i : 80 - i] = nil }
        // In handicap games the upper player (AI) starts, regardless of board orientation.
        if handicap != .even { p.turn = player.opponent }
        return p
    }
    public var isStructurallyValid: Bool {
        board.count == 81 && hands.count == 2 && hands.allSatisfy { $0.count == 8 && $0.allSatisfy { (0...18).contains($0) } && $0[7] == 0 } && Side.allCases.allSatisfy { s in board.compactMap { $0 }.filter { $0.kind == .king && $0.side == s }.count == 1 } && ply >= 0 && board.compactMap { $0 }.allSatisfy { !$0.promoted || $0.kind.canPromote }
    }
    public func king(_ side: Side) -> Int? { board.firstIndex { $0?.side == side && $0?.kind == .king } }
    public var key: String {
        board.map { p in p.map { String($0.kind.rawValue + 1 + $0.side.rawValue * 8 + ($0.promoted ? 16 : 0), radix: 36) } ?? "." }.joined() + ":\(turn.rawValue):" + hands.flatMap { $0 }.map(String.init).joined(separator: ",")
    }
    public func attacked(_ square: Int, by side: Side) -> Bool {
        for i in board.indices { if let p = board[i], p.side == side, destinations(from: i, piece: p).contains(square) { return true } }
        return false
    }
    public func inCheck(_ side: Side) -> Bool { guard let k = king(side) else { return true }; return attacked(k, by: side.opponent) }
    public func destinations(from: Int, piece: Piece) -> [Int] {
        let gold = [(0,-1),(-1,-1),(1,-1),(-1,0),(1,0),(0,1)]
        let ortho = [(0,-1),(0,1),(-1,0),(1,0)], diag = [(-1,-1),(1,-1),(-1,1),(1,1)]
        var steps: [(Int,Int)] = [], rays: [(Int,Int)] = []
        if piece.promoted && [.pawn,.lance,.knight,.silver].contains(piece.kind) { steps = gold }
        else {
            switch piece.kind {
            case .pawn: steps = [(0,-1)]
            case .lance: rays = [(0,-1)]
            case .knight: steps = [(-1,-2),(1,-2)]
            case .silver: steps = [(0,-1)] + diag
            case .gold: steps = gold
            case .king: steps = ortho + diag
            case .bishop: rays = diag; if piece.promoted { steps = ortho }
            case .rook: rays = ortho; if piece.promoted { steps = diag }
            }
        }
        let sign = piece.side == .black ? 1 : -1
        var result: [Int] = []
        for (dx,dy) in steps {
            let x = from % 9 + dx * sign, y = from / 9 + dy * sign
            if (0..<9).contains(x) && (0..<9).contains(y) { result.append(y * 9 + x) }
        }
        for (dx,dy) in rays {
            var x = from % 9 + dx * sign, y = from / 9 + dy * sign
            while (0..<9).contains(x) && (0..<9).contains(y) {
                let j = y * 9 + x; result.append(j)
                if board[j] != nil { break }
                x += dx * sign; y += dy * sign
            }
        }
        return result
    }
    public func legalMoves(validatePawnMate: Bool = true) -> [ShogiMove] {
        var moves: [ShogiMove] = []
        for i in board.indices {
            guard let piece = board[i], piece.side == turn else { continue }
            for to in destinations(from: i, piece: piece) {
                if board[to]?.side == turn || board[to]?.kind == .king { continue }
                let r = turn.relativeRow(to / 9)
                let forced = !piece.promoted && (([PieceKind.pawn,.lance].contains(piece.kind) && r == 0) || (piece.kind == .knight && r <= 1))
                if !forced { moves.append(ShogiMove(from: i, to: to)) }
                if !piece.promoted && piece.kind.canPromote && (turn.inCamp(i / 9) || turn.inCamp(to / 9)) { moves.append(ShogiMove(from: i, to: to, promote: true)) }
            }
        }
        for kind in PieceKind.handKinds where hands[turn.rawValue][kind.rawValue] > 0 {
            for to in board.indices where board[to] == nil {
                let r = turn.relativeRow(to / 9)
                if ([PieceKind.pawn,.lance].contains(kind) && r == 0) || (kind == .knight && r <= 1) { continue }
                if kind == .pawn && (0..<9).contains(where: { row in board[row * 9 + to % 9] == Piece(.pawn, turn) }) { continue }
                moves.append(ShogiMove(to: to, drop: kind))
            }
        }
        return moves.filter { m in
            let next = applyingUnchecked(m)
            if next.inCheck(turn) { return false }
            if validatePawnMate && m.drop == .pawn && next.inCheck(next.turn) && next.legalMoves(validatePawnMate: false).isEmpty { return false }
            return true
        }
    }
    public func applying(_ move: ShogiMove) -> ShogiPosition? { legalMoves().contains(move) ? applyingUnchecked(move) : nil }
    // Call only for engine-generated legal/pseudo-legal moves.
    public func applyingUnchecked(_ move: ShogiMove) -> ShogiPosition {
        var next = self
        if let kind = move.drop {
            next.hands[turn.rawValue][kind.rawValue] -= 1; next.board[move.to] = Piece(kind, turn)
        } else if let from = move.from, var p = board[from] {
            if let captured = board[move.to] { next.hands[turn.rawValue][captured.kind.rawValue] += 1 }
            p.promoted = p.promoted || move.promote; next.board[from] = nil; next.board[move.to] = p
        }
        next.turn = turn.opponent; next.ply += 1
        return next
    }
    public func canDeclareWin(_ side: Side, handicap: Handicap = .even, player: Side = .black) -> Bool {
        guard turn == side, let k = king(side), side.inCamp(k / 9), !inCheck(side) else { return false }
        let camp = board.indices.filter { i in board[i]?.side == side && board[i]?.kind != .king && side.inCamp(i / 9) }
        let points = camp.reduce(0) { $0 + board[$1]!.kind.points } + PieceKind.handKinds.reduce(0) { $0 + hands[side.rawValue][$1.rawValue] * $1.points }
        let removedPoints = handicap.removed.reduce(0) { $0 + (ShogiPosition.initial().board[$1]?.kind.points ?? 0) }
        return camp.count >= 10 && points + (side != player ? removedPoints : 0) >= (side == .black ? 28 : 27)
    }
}

public enum EndReason: String, Codable, Sendable {
    case mate, resignation, repetition, perpetualCheck, declaration, moveLimit
    public var title: String {
        switch self { case .mate: return "詰み"; case .resignation: return "投了"; case .repetition: return "千日手"; case .perpetualCheck: return "連続王手の千日手"; case .declaration: return "入玉宣言"; case .moveLimit: return "500手・引き分け" }
    }
}
public struct GameResult: Codable, Equatable, Sendable {
    public var winner: Side?
    public var reason: EndReason
    public init(winner: Side?, reason: EndReason) { self.winner = winner; self.reason = reason }
}
public struct Match: Codable, Sendable {
    public let id: UUID
    public let characterID: String
    public let player: Side
    public let handicap: Handicap
    public var positions: [ShogiPosition]
    public var moves: [ShogiMove] = []
    public var result: GameResult?
    public var undoUsed = false
    public var position: ShogiPosition { positions.last! }
    public init(characterID: String, player: Side, handicap: Handicap, initial: ShogiPosition? = nil) {
        id = UUID(); self.characterID = characterID; self.player = player; self.handicap = handicap
        positions = [initial ?? .initial(handicap: handicap, player: player)]
    }
    @discardableResult public mutating func play(_ move: ShogiMove) -> Bool {
        guard result == nil, let next = position.applying(move) else { return false }
        moves.append(move); positions.append(next); result = adjudicate(); return true
    }
    public func adjudicate() -> GameResult? {
        let p = position
        let repetitions = positions.indices.filter { positions[$0].key == p.key }
        if repetitions.count >= 4 {
            let first = repetitions[repetitions.count - 4]
            for side in Side.allCases {
                let indices = ((first + 1)..<positions.count).filter { positions[$0].turn == side.opponent }
                if !indices.isEmpty && indices.allSatisfy({ positions[$0].inCheck(side.opponent) }) { return GameResult(winner: side.opponent, reason: .perpetualCheck) }
            }
            return GameResult(winner: nil, reason: .repetition)
        }
        if p.legalMoves().isEmpty { return GameResult(winner: p.turn.opponent, reason: .mate) }
        if moves.count >= 500 { return GameResult(winner: nil, reason: .moveLimit) }
        return nil
    }
    public mutating func resign(_ side: Side) { guard result == nil else { return }; result = GameResult(winner: side.opponent, reason: .resignation) }
    @discardableResult public mutating func declareWin() -> Bool {
        guard result == nil, position.canDeclareWin(position.turn, handicap: handicap, player: player) else { return false }
        result = GameResult(winner: position.turn, reason: .declaration); return true
    }
    public var canUndo: Bool { result == nil && !undoUsed && positions.dropLast().contains { $0.turn == player } }
    @discardableResult public mutating func undo() -> Bool {
        guard canUndo, let i = positions.dropLast().lastIndex(where: { $0.turn == player }) else { return false }
        positions = Array(positions.prefix(i + 1)); moves = Array(moves.prefix(i)); undoUsed = true; return true
    }
}
