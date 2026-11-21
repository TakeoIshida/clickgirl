import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private enum Key {
        static let bgmEnabled = "cg_setting_bgm_enabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.bgmEnabled: true])
    }

    var isBGMEnabled: Bool {
        get { defaults.bool(forKey: Key.bgmEnabled) }
        set { defaults.set(newValue, forKey: Key.bgmEnabled) }
    }
}
