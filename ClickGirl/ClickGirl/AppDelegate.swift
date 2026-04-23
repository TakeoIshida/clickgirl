import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import UserMessagingPlatform

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var adMobStarted = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // SDK v13: UMP consent flow を先に済ませてから MobileAds.start() を呼ぶ
        let params = RequestParameters()
        params.isTaggedForUnderAgeOfConsent = false

        ConsentInformation.shared.requestConsentInfoUpdate(with: params) { [weak self] _ in
            DispatchQueue.main.async {
                self?.startMobileAdsIfReady()
            }
        }

        // 前回セッションで同意済みの場合はすぐに起動
        startMobileAdsIfReady()

        return true
    }

    private func startMobileAdsIfReady() {
        guard !adMobStarted,
              UMPConsentInformation.sharedInstance.canRequestAds else { return }
        adMobStarted = true

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
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameManager.shared.saveGame()
    }
}
