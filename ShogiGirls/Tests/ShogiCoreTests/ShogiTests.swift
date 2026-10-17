import XCTest
@testable import ShogiCore

final class ShogiTests: XCTestCase {
    func empty() -> ShogiPosition { var p = ShogiPosition(); p.board[76] = Piece(.king,.black); p.board[4] = Piece(.king,.white); return p }
    func testInitialAndAllHandicaps() {
        let p = ShogiPosition.initial()
        XCTAssertEqual(p.board.compactMap { $0 }.count, 40)
        XCTAssertEqual(p.legalMoves().count, 30)
        XCTAssertNil(ShogiPosition.initial(handicap:.lance).board[8])
        XCTAssertNotNil(ShogiPosition.initial(handicap:.lance).board[0])
        XCTAssertNil(ShogiPosition.initial(handicap:.rightLance).board[0])
        for h in Handicap.allCases { for side in Side.allCases {
            let q = ShogiPosition.initial(handicap: h, player: side)
            XCTAssertEqual(q.board.compactMap { $0 }.count, 40 - h.removed.count)
            XCTAssertEqual(q.turn, h == .even ? .black : side.opponent)
            XCTAssertTrue(q.isStructurallyValid)
            XCTAssertFalse(q.legalMoves().isEmpty)
        } }
    }
    func testPieceDirectionsAndPromotion() {
        let expected: [PieceKind:Int] = [.pawn:1,.lance:4,.knight:2,.silver:5,.gold:6,.bishop:16,.rook:16,.king:8]
        for side in Side.allCases { for kind in PieceKind.allCases {
            let p = ShogiPosition()
            XCTAssertEqual(p.destinations(from:40, piece:Piece(kind,side)).count, expected[kind])
            if kind.canPromote { XCTAssertEqual(p.destinations(from:40,piece:Piece(kind,side,promoted:true)).count, kind == .bishop || kind == .rook ? 20 : 6) }
        } }
        var p = empty(); p.board[18] = Piece(.pawn,.black)
        XCTAssertTrue(p.legalMoves().contains(.init(from:18,to:9)))
        XCTAssertTrue(p.legalMoves().contains(.init(from:18,to:9,promote:true)))
        p.board[18] = nil; p.board[9] = Piece(.pawn,.black)
        XCTAssertFalse(p.legalMoves().contains(.init(from:9,to:0)))
        XCTAssertTrue(p.legalMoves().contains(.init(from:9,to:0,promote:true)))
        p.board[9] = Piece(.knight,.black)
        XCTAssertFalse(p.legalMoves().contains { $0.from == 9 })
    }
    func testCaptureDemotesAndDropRules() {
        var p = empty(); p.board[40] = Piece(.rook,.black); p.board[31] = Piece(.silver,.white,promoted:true)
        let q = p.applying(.init(from:40,to:31))!
        XCTAssertEqual(q.hands[0][PieceKind.silver.rawValue],1)
        p.hands[0][0] = 1; p.hands[0][2] = 1; p.hands[0][1] = 1; p.board[54] = Piece(.pawn,.black)
        let drops = p.legalMoves().filter { $0.drop != nil }
        XCTAssertFalse(drops.contains { $0.drop == .pawn && $0.to % 9 == 0 })
        XCTAssertFalse(drops.contains { ($0.drop == .pawn || $0.drop == .lance) && $0.to < 9 })
        XCTAssertFalse(drops.contains { $0.drop == .knight && $0.to < 18 })
        XCTAssertTrue(drops.contains { $0.drop == .pawn && $0.to == 41 })
    }
    func testCheckPinAndKingCaptureProhibited() {
        var p = empty(); p.board[13] = Piece(.rook,.white); p.board[67] = Piece(.gold,.black)
        XCTAssertFalse(p.inCheck(.black))
        XCTAssertFalse(p.legalMoves().contains(.init(from:67,to:66)))
        p.board[67] = nil
        XCTAssertTrue(p.inCheck(.black))
        XCTAssertTrue(p.legalMoves().allSatisfy { !p.applyingUnchecked($0).inCheck(.black) })
        p.board[13] = Piece(.rook,.black)
        XCTAssertFalse(p.legalMoves().contains { $0.to == 4 })
    }
    func testPawnDropMateForbiddenButPawnMoveMateAllowed() {
        var p = empty(); p.board[3] = Piece(.lance,.white); p.board[5] = Piece(.lance,.white)
        p.board[12] = Piece(.pawn,.white); p.board[14] = Piece(.pawn,.white)
        p.board[22] = Piece(.gold,.black); p.hands[0][0] = 1
        XCTAssertFalse(p.legalMoves().contains(.init(to:13,drop:.pawn)))
        p.board[22] = Piece(.pawn,.black); p.board[21] = Piece(.gold,.black)
        XCTAssertTrue(p.legalMoves().contains(.init(from:22,to:13)))
        let next = p.applying(.init(from:22,to:13))!
        XCTAssertTrue(next.inCheck(.white)); XCTAssertTrue(next.legalMoves().isEmpty)
    }
    func testRepetitionAndPerpetualCheck() {
        let p = empty()
        var m = Match(characterID:"koharu",player:.black,handicap:.even,initial:p)
        let cycle: [ShogiMove] = [.init(from:76,to:75),.init(from:4,to:3),.init(from:75,to:76),.init(from:3,to:4)]
        for _ in 0..<3 { for move in cycle { XCTAssertTrue(m.play(move)) } }
        XCTAssertEqual(m.result, GameResult(winner:nil,reason:.repetition))
        var c = ShogiPosition(); c.board[80] = Piece(.king,.black); c.board[3] = Piece(.king,.white); c.board[13] = Piece(.rook,.black)
        var check = Match(characterID:"koharu",player:.black,handicap:.even,initial:c)
        let checking: [ShogiMove] = [.init(from:13,to:12),.init(from:3,to:4),.init(from:12,to:13),.init(from:4,to:3)]
        for _ in 0..<3 { for move in checking { XCTAssertTrue(check.play(move)) } }
        XCTAssertEqual(check.result,GameResult(winner:.white,reason:.perpetualCheck))
    }
    func testUndoAndCodableRoundTrip() throws {
        var m = Match(characterID:"koharu",player:.black,handicap:.even)
        XCTAssertTrue(m.play(.init(from:54,to:45)))
        XCTAssertTrue(m.play(.init(from:18,to:27)))
        XCTAssertTrue(m.undo()); XCTAssertEqual(m.position,.initial()); XCTAssertFalse(m.undo())
        let decoded = try JSONDecoder().decode(Match.self,from:JSONEncoder().encode(m))
        XCTAssertEqual(decoded.position,m.position); XCTAssertTrue(decoded.undoUsed)
    }
    func testDeclaration() {
        var p = ShogiPosition(); p.board[0] = Piece(.king,.black); p.board[80] = Piece(.king,.white)
        for i in 1...10 { p.board[i] = Piece(.pawn,.black) }; p.hands[0][6] = 2; p.hands[0][5] = 2
        XCTAssertTrue(p.canDeclareWin(.black))
        p.hands[0][6] = 0; XCTAssertFalse(p.canDeclareWin(.black))
        p.board[10] = nil; p.hands[0][6] = 2; XCTAssertFalse(p.canDeclareWin(.black))
    }
    func testAIAllProfilesReturnLegalAndRespectBudget() {
        for c in Characters.all {
            let p = ShogiPosition.initial()
            let start = Date(); let r = ShogiAI(profile:c.ai,seed:42).search(p,timeLimit:0.08)
            XCTAssertNotNil(r.move); XCTAssertTrue(p.legalMoves().contains(r.move!)); XCTAssertLessThan(Date().timeIntervalSince(start),1.0)
        }
    }
    func testAISeesOneMoveMate() {
        var p = empty(); p.board[3] = Piece(.lance,.white); p.board[5] = Piece(.lance,.white); p.board[12] = Piece(.pawn,.white); p.board[14] = Piece(.pawn,.white); p.board[22] = Piece(.pawn,.black); p.board[21] = Piece(.gold,.black)
        let r = ShogiAI(profile:.init(level:10,style:.balanced),seed:1).search(p,timeLimit:1)
        XCTAssertNotNil(r.move)
        XCTAssertTrue(p.applying(r.move!)!.legalMoves().isEmpty)
    }
    func testRandomLegalPlayoutAndConservation() {
        var p = ShogiPosition.initial(); var rng: UInt64 = 11
        for _ in 0..<180 {
            let moves = p.legalMoves(); if moves.isEmpty { break }
            rng = rng &* 6364136223846793005 &+ 1
            let move = moves[Int(rng % UInt64(moves.count))]; let side = p.turn
            p = p.applyingUnchecked(move)
            XCTAssertFalse(p.inCheck(side)); XCTAssertTrue(p.isStructurallyValid)
            XCTAssertEqual(p.board.compactMap{$0}.count + p.hands.flatMap{$0}.reduce(0,+),40)
        }
    }
    func testSaveIdempotencyRewardsEnergyAndBackup() throws {
        let suite = "shogi-test-\(UUID())"; let defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let store = SaveStore(defaults:defaults), now = Date()
        store.update { $0.energy = 100; $0.energyDate = now }
        for n in 1...20 {
            var m = Match(characterID:"koharu",player:.black,handicap:.ten)
            XCTAssertTrue(store.begin(m,now:now,free:true)); m.resign(.white)
            let rewards = store.finish(m); XCTAssertEqual(rewards.count,[1,3,5,10,20].contains(n) ? 1 : 0)
            XCTAssertTrue(store.finish(m).isEmpty); store.dismissResult()
        }
        XCTAssertEqual(store.record("koharu").wins,20); XCTAssertTrue(store.unlocked("hinata")); XCTAssertFalse(store.unlocked("chinatsu"))
        XCTAssertEqual(SaveStore(defaults:defaults).record("koharu").wins,20)
        let match = Match(characterID:"koharu",player:.black,handicap:.even)
        XCTAssertTrue(store.begin(match,now:now)); XCTAssertEqual(store.energy(at:now),80)
        XCTAssertFalse(store.begin(match,now:now))
        XCTAssertEqual(store.energy(at:now.addingTimeInterval(360)),82)
        XCTAssertEqual(store.energy(at:now.addingTimeInterval(-999)),80)
        store.update { $0.energy = 40; $0.energyDate = now }
        store.rewardEnergy(now:now.addingTimeInterval(179))
        XCTAssertEqual(store.energy(at:now.addingTimeInterval(179)),60)
        XCTAssertEqual(store.recoverySeconds(at:now.addingTimeInterval(179)),1)
        XCTAssertEqual(store.energy(at:now.addingTimeInterval(180)),61)
        for _ in 0..<3 { XCTAssertTrue(store.useFreeHint(at:now)) }; XCTAssertFalse(store.useFreeHint(at:now))
        XCTAssertEqual(store.freeHints(at:now.addingTimeInterval(86400)),3)
        defaults.set(Data([0,1]),forKey:SaveStore.key)
        let recovered = SaveStore(defaults:defaults); XCTAssertNotNil(recovered.recoveryMessage); XCTAssertEqual(recovered.record("koharu").wins,20)
    }
}
