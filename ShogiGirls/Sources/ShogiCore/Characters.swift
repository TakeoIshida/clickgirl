import Foundation

public enum PlayingStyle: String, Codable, Sendable { case beginner, climbingSilver, fourthFile, fortress, bishopExchange, thirdFile, anaguma, attack, adaptive, balanced }
public struct AIProfile: Codable, Sendable {
    public let level: Int
    public let style: PlayingStyle
    public var depth: Int { [1,1,2,2,3,3,4,4,5,6][max(0,min(9,level - 1))] }
    public var seconds: Double { [0.25,0.35,0.5,0.65,0.8,1.0,1.2,1.5,1.8,2.2][max(0,min(9,level - 1))] }
    public var noise: Int { [230,130,85,55,35,20,12,8,3,0][max(0,min(9,level - 1))] }
    public init(level: Int, style: PlayingStyle) { self.level = level; self.style = style }
}
public struct CharacterProfile: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let age: Int
    public let subtitle: String
    public let colorHex: UInt32
    public let ai: AIProfile
    public let greeting: String
    public let winLine: String
    public let loseLine: String
    public let look: String
    public var imageName: String { "\(id)_base" }
    public var difficulty: String { ["入門", "初級", "初級＋", "中級", "中級＋", "上級", "上級＋", "強豪", "熟練", "最強"][ai.level - 1] }
    public func line(for event: String) -> String {
        switch event {
        case "start": return greeting
        case "win": return winLine
        case "lose": return loseLine
        case "check": return ["あっ、王手？ よく見ないと…", "ここからが勝負ね。", "その一手、読んでいたわ。"][(ai.level - 1) % 3]
        case "promote": return "成り駒ができたね。ここからどう攻めよう？"
        case "capture": return "その駒、大事に使わせてもらうね。"
        case "lead": return "この形、私の得意な展開だよ。"
        case "behind": return "少し苦しいけど、まだ諦めないよ。"
        case "draw": return "引き分けだね。また一局、付き合って？"
        default: return "一手ずつ、ゆっくり考えてね。"
        }
    }
}
public enum Characters {
    public static let all: [CharacterProfile] = [
        .init(id: "koharu", name: "小春", age: 20, subtitle: "はじめの一歩", colorHex: 0xE9A4A6, ai: .init(level: 1, style: .beginner), greeting: "まだ勉強中だけど、一緒に指そう？", winLine: "私の勝ち？ えへへ、うれしいな。", loseLine: "すごい！ 次はもっと頑張るね。", look: "peach pink cardigan, white blouse, short honey brown bob, daisy hair clip"),
        .init(id: "hinata", name: "ひなた", age: 21, subtitle: "まっすぐ棒銀", colorHex: 0xF5AE65, ai: .init(level: 2, style: .climbingSilver), greeting: "銀を前へ！ 今日も元気に勝負だよ！", winLine: "よしっ！ 攻め切った！", loseLine: "あちゃー！ 次は負けないからね！", look: "orange casual sporty jacket, cream top, auburn ponytail"),
        .init(id: "chinatsu", name: "千夏", age: 22, subtitle: "そよ風の四間飛車", colorHex: 0xA5BE88, ai: .init(level: 3, style: .fourthFile), greeting: "お茶の用意もできたし、一局いかが？", winLine: "ふふ、いい勝負だったね。", loseLine: "参りました。もう一局、お願いしてもいい？", look: "pale leaf green kimono, cream obi, chestnut shoulder length hair, red camellia hair ornament, closed fan"),
        .init(id: "mio", name: "澪", age: 24, subtitle: "静かな矢倉", colorHex: 0x87ADCF, ai: .init(level: 4, style: .fortress), greeting: "焦らず、足元を固めていきましょう。", winLine: "守りが実を結びましたね。", loseLine: "見事な攻めでした。覚えておきます。", look: "navy elegant blouse, long slate skirt, straight black long hair, small blue ribbon"),
        .init(id: "kotone", name: "琴音", age: 23, subtitle: "角筋のメロディ", colorHex: 0xC1A2D2, ai: .init(level: 5, style: .bishopExchange), greeting: "斜めのラインに、気をつけてね。", winLine: "きれいに決まったね、私の角。", loseLine: "そんな手があったの？ 素敵だね。", look: "lavender dress, ivory shawl, plum brown wavy hair, music note brooch"),
        .init(id: "rin", name: "凛", age: 25, subtitle: "軽やかな三間飛車", colorHex: 0x75BDBA, ai: .init(level: 6, style: .thirdFile), greeting: "駒は自由に。さあ、始めよう。", winLine: "いいさばきだったでしょ？", loseLine: "一本取られたね。面白かったよ。", look: "teal tailored jacket, black trousers, short dark teal hair, silver earrings"),
        .init(id: "cecilia", name: "セシリア", age: 24, subtitle: "優雅な穴熊", colorHex: 0xD8BD76, ai: .init(level: 7, style: .anaguma), greeting: "長い一局も、あなたとなら楽しめそう。", winLine: "この城は、そう簡単には崩れませんわ。", loseLine: "お見事。私の城を破るなんて。", look: "ivory elegant high collar dress, gold ribbon, long blonde hair"),
        .init(id: "akane", name: "朱音", age: 26, subtitle: "烈火の急戦", colorHex: 0xD57C82, ai: .init(level: 8, style: .attack), greeting: "最初から全力。受け止めてみせて。", winLine: "この勢い、止められなかったでしょ。", loseLine: "参った。あなた、なかなかやるわね。", look: "crimson fitted jacket, black blouse and long skirt, red brown swept long hair"),
        .init(id: "shion", name: "紫苑", age: 27, subtitle: "千変の読み", colorHex: 0xA391BF, ai: .init(level: 9, style: .adaptive), greeting: "あなたは、どんな将棋を見せてくれるの？", winLine: "あなたの一手、よく分かったわ。", loseLine: "私の読みを越えたのね。忘れないわ。", look: "deep violet kimono, pale silver obi, long dark purple hair, subtle butterfly pin"),
        .init(id: "tsukika", name: "月華", age: 28, subtitle: "月下の終盤", colorHex: 0xB8C9E1, ai: .init(level: 10, style: .balanced), greeting: "盤上で、あなたのすべてを見せて。", winLine: "またここまで、会いに来てね。", loseLine: "参りました。今夜の一局、宝物にするわ。", look: "midnight blue kimono with silver crescent motifs, white silver long hair, moon hairpin")
    ]
    public static func find(_ id: String) -> CharacterProfile { all.first { $0.id == id } ?? all[0] }
}
public struct GalleryReward: Identifiable, Sendable {
    public let characterID: String
    public let index: Int
    public var id: String { "\(characterID)_reward_\(index + 1)" }
    public var requiredWins: Int { [1,3,5,10,20][index] }
    public var title: String { ["はじめての一勝", "休日の装い", "夏の約束", "特別な晴れ姿", "あなたと、もう一局"][index] }
    public static func all(for id: String) -> [GalleryReward] { (0..<5).map { .init(characterID: id, index: $0) } }
}
