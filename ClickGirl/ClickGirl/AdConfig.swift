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
    // 本番ID
    static let appID          = "ca-app-pub-8244563543256981~2074299497"
    static let rewardedAdUnit = "ca-app-pub-8244563543256981/7350157388"
    #endif
}
