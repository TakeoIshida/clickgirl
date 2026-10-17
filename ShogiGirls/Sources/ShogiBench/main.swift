import Foundation
import ShogiCore

let exhaustive = CommandLine.arguments.contains("--all-handicaps")
var failures = 0
if exhaustive {
    // Completion smoke test for every character/handicap combination. Seeded legal
    // playouts test the lifecycle; actual AI legality/tactics are covered separately.
    var finished = 0, maximum = 0
    for (index,c) in Characters.all.enumerated() {
        for (hIndex,h) in Handicap.allCases.enumerated() {
            let player: Side = hIndex % 2 == 0 ? .black : .white
            var m = Match(characterID:c.id,player:player,handicap:h)
            var seed = UInt64(1000 + index*100 + hIndex)
            while m.result == nil && m.moves.count <= 500 {
                let legal = m.position.legalMoves()
                if legal.isEmpty { m.result = m.adjudicate(); break }
                seed = seed &* 6364136223846793005 &+ 1
                // Prefer captures half the time to exercise hands and promotions.
                let captures = legal.filter { m.position.board[$0.to] != nil }
                let choices = seed % 2 == 0 && !captures.isEmpty ? captures : legal
                let move = choices[Int(seed % UInt64(choices.count))]
                guard m.play(move) else { failures += 1; break }
            }
            if m.result == nil { failures += 1 } else { finished += 1 }
            maximum = max(maximum,m.moves.count)
        }
        print("\(c.name): 11 handicap games checked")
        fflush(stdout)
    }
    print("Completed \(finished)/110 games; max ply \(maximum); failures \(failures)")
} else {
    for c in Characters.all {
        let p = ShogiPosition.initial(); let start = Date()
        let result = ShogiAI(profile:c.ai,seed:42).search(p)
        if result.move == nil || !p.legalMoves().contains(result.move!) { failures += 1 }
        print("\(c.name) level=\(c.ai.level) move=\(result.move?.notation(in:p) ?? "none") depth=\(result.depth) nodes=\(result.nodes) seconds=\(String(format:"%.3f",Date().timeIntervalSince(start)))")
    }
}
exit(failures == 0 ? 0 : 1)
