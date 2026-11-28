import AppTrackingTransparency
import GoogleMobileAds
import StoreKit
import UIKit

enum AdvertisingRegionPolicy {
    private static let disabledRegions: Set<String> = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DE", "DK", "EE", "ES", "FI",
        "FR", "GR", "HU", "IE", "IS", "IT", "LI", "LT", "LU", "LV", "MT",
        "NL", "NO", "PL", "PT", "RO", "SE", "SI", "SK", "GB", "CH"
    ]

    static func allowsAdvertising(countryCode: String?) -> Bool {
        guard let countryCode, countryCode.count == 2 else { return false }
        return !disabledRegions.contains(countryCode.uppercased())
    }
}

@MainActor
final class AdvertisingStartup {
    static let shared = AdvertisingStartup()

    private var startTask: Task<Void, Never>?
    private var didStartServices = false

    private init() {}

    func start() {
        guard startTask == nil, !didStartServices else { return }
        startTask = Task { [weak self] in
            guard let self else { return }
            await resolveTrackingAuthorizationWhenActive()

            guard ATTrackingManager.trackingAuthorizationStatus != .notDetermined,
                  AdvertisingRegionPolicy.allowsAdvertising(
                    countryCode: await storefrontCountryCode()
                  ) else {
                startTask = nil
                return
            }

            didStartServices = true
            AnalyticsManager.shared.configure()
            MobileAds.shared.start { _ in
                NotificationCenter.default.post(name: .adMobReady, object: nil)
            }
            startTask = nil
        }
    }

    private func storefrontCountryCode() async -> String? {
#if DEBUG
        if let override = ProcessInfo.processInfo.environment["CLICKGIRL_AD_REGION"],
           override.count == 2 {
            return override.uppercased()
        }
#endif
        return await Storefront.current?.countryCode.uppercased()
    }

    private func resolveTrackingAuthorizationWhenActive() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        while UIApplication.shared.applicationState != .active {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        try? await Task.sleep(nanoseconds: 600_000_000)

        for attempt in 0..<3 {
            while UIApplication.shared.applicationState != .active {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            let status = await requestTrackingAuthorization()
            if status != .notDetermined { return }
            if attempt < 2 {
                try? await Task.sleep(nanoseconds: 800_000_000)
            }
        }
    }

    private func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
