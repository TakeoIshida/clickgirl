# 将棋ガールズ

10人の新キャラクターと対戦するiPhone／iPad向け将棋ゲーム。SpriteKitの盤面とUIKitの画面を分離し、将棋ルール・AI・保存処理はFoundationだけでテストできる構成です。

## 起動

`ShogiGirls.xcodeproj` をXcodeで開き、`ShogiGirls` スキームを選択します。iOS 16以降に対応。初回はSwift Package Managerが公式のGoogle Mobile Ads SDK 12.14.0とUMP 3.1.0を取得します。App Store Connectへのアップロードには、現在のApple要件に従いXcode 26／iOS 26 SDK以降が必要です。

シミュレータのDebug版では対局力を消費しません。Release版は1局20消費します。実機の署名設定は既存作と同じチームを初期設定しています。新作のBundle IDは `com.takeo.ShogiGirls` です。

## 実装済みのゲーム機能

- 10人のCPU、キャラ別の強さと序盤の狙い、台詞、基本画像。対戦相手は前の相手への1勝で順番に解放。
- 平手と10種類の駒落ち、双方の持ち駒、成り／不成、強制成り、二歩・行き所のない駒・王手放置・打ち歩詰めの禁止。
- 詰み、投了、四回同一局面の千日手、連続王手の千日手、条件を満たす入玉宣言、500手打ち切り。
- 非同期の反復深化αβ探索、静止探索、置換表、思考時間上限、キャンセル。棋力は相対的なゲーム設定で、段級位認定ではありません。
- 戦績、勝率、1・3・5・10・20勝の50画像解放枠、ギャラリー、結果画面の新規解放演出。
- 毎手の中断保存、起動後の再開、結果の重複計上防止、バックアップ復旧。
- 対局力100上限／20消費／180秒ごとに1回復。再開は無料。無料ヒント1日3回、広告ヒント、広告で1対局1回の待った、広告で対局力20回復。
- 全画面広告は結果画面のみ、3局ごと・180秒以上の間隔・セッション最大3回。広告失敗時に報酬や無料回数を消費しません。
- 効果音、触覚、合法手ガイドの設定、盤のVoiceOver操作用アクセシビリティ要素。

## ルールの明確化

駒落ちではAIの駒を減らし、上手のAIが最初に指します。先手側／後手側の選択は盤面の向きも切り替えます。香落ちは角のある側の香、右香落ちは反対側の香を除きます。駒落ちの勝ちも報酬に数えます。

千日手はこのゲームでは引き分けとして記録します。入玉は無条件の点数比較ではなく宣言制です。手番、敵陣の玉、王手なし、玉以外の敵陣の駒10枚以上、敵陣と持ち駒の点数（飛・角5点、その他1点）が先手28／後手27点以上で成立します。駒落ちの上手には落とした駒の点数を加算します。500手で引き分けとするカジュアル対局規定です。

参照：[日本将棋連盟 対局規則](https://www.shogi.or.jp/match/taikyoku_rules/)、[駒落ちなどのFAQ](https://www.shogi.or.jp/faq/rules/)。

## 広告とリリース前設定

DebugはGoogle公式テスト広告を使用します。Releaseは `ShogiAdsProductionReady` がtrueのため、新作専用の本番広告を使用します。2026年9月13日にAdMobアプリ「将棋ガールズ」と広告ユニット `ShogiGirls_Rewarded`・`ShogiGirls_Interstitial` を作成し、3つの本番IDを `App/Info.plist` に設定済みです。2026年9月21日に「将棋ガールズ 欧州同意」を公開し、本番広告を有効化しました。既存ゲームの広告IDは流用していません。

UMPの同意情報更新・必要なフォーム表示・広告リクエスト可否・設定からのプライバシー選択に対応しています。App Store Connectへ「将棋ガールズ」を登録済みです。審査提出前に、広告SDKを含めたデータ収集申告、年齢区分、ストア説明、スクリーンショットを設定してください。

2026年9月23日にバージョン1.0.0（ビルド1）の本番広告有効版をアーカイブし、App Store配布署名付きIPAを書き出しました。アップロード検証では、作成に使ったXcode 16.4／iOS 18.5 SDKがAppleの受付要件を満たさないため却下されました。Xcode 26以降へ更新後、同じバージョンを再アーカイブしてアップロードしてください。

参照：[Googleの初期設定](https://developers.google.com/admob/ios/quick-start)、[UMP](https://developers.google.com/admob/ios/privacy)、[リワード広告](https://developers.google.com/admob/ios/rewarded)。

## 検証

```sh
swift test -c release
xcodebuild -project ShogiGirls.xcodeproj -scheme ShogiGirls \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

UIテストは専用のUserDefaults領域を使い、本来のセーブを変更しません。`--ui-testing`・`--mate-fixture`・`--all-unlocked`などの検証用起動引数はDebugだけで有効です。Releaseで報酬の偽装や全解放はできません。

## ファイル構成と画像追加

- `Sources/ShogiCore`：将棋ルール、キャラ／AI設定、探索、セーブ。
- `App`：画面、SpriteKit盤、広告、素材。`Tests`／`UITests`：ロジックと画面テスト。
- `scripts/create_project.rb`：新規ファイル追加後のXcodeプロジェクト再生成（Rubyのxcodeprojが必要）。既存pbxprojへ手動設定を追加した場合は、先にこのスクリプトへ反映してください。

画像の命名は `<キャラID>_base.png`、表情差分の `_happy.png`・`_worry.png`、報酬の `_reward_1.png`〜`_reward_5.png`。基本10枚・表情20枚・報酬50枚の全80枚を収録済みです。素材は内蔵画像生成で制作し、ユーザーが承認した千夏の画風を参照しています。元画像は上書きせず保持しています。将来画像が欠けた場合も基本画像と「イラスト準備中」にフォールバックし、勝数は保持します。

全50枚の制作状況と未完了点は `STATUS.md` に記録します。
