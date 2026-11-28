import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            return true
        }

        AdvertisingStartup.shared.start()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameManager.shared.saveGame()
    }
}
