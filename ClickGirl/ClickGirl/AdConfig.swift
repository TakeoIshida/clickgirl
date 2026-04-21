import Foundation

extension Notification.Name {
    static let adMobReady = Notification.Name("adMobReady")
}

enum AdConfig {
    #if DEBUG
    // テスト用ID（Google公式テストID）
    static let appID          = "ca-app-pub-3940256099942544~1458002511"
    static let rewardedAdUnit = "ca-app-pub-3940256099942544/1712485313"
    #else
    // 本番ID（AdMobコンソールで取得してここに入れること）
    static let appID          = "YOUR_ADMOB_APP_ID"
    static let rewardedAdUnit = "YOUR_REWARDED_AD_UNIT_ID"
    #endif
}
