import UIKit
import GoogleMobileAds
import AppTrackingTransparency

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    MobileAds.shared.start { _ in
                        NotificationCenter.default.post(name: .adMobReady, object: nil)
                    }
                }
            }
        } else {
            MobileAds.shared.start { _ in
                NotificationCenter.default.post(name: .adMobReady, object: nil)
            }
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameManager.shared.saveGame()
    }
}
