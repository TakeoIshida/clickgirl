import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // AdMob を即時初期化（検証タイミングより前に start() を済ませる）
        MobileAds.shared.start { _ in
            NotificationCenter.default.post(name: .adMobReady, object: nil)
        }

        // ATTracking はパーソナライズ広告のためだけなので非同期で別途リクエスト
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { _ in }
            }
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameManager.shared.saveGame()
    }
}
