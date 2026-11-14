import UIKit
import GoogleMobileAds
import StoreKit
import AppTrackingTransparency

@MainActor final class Ads: NSObject, FullScreenContentDelegate {
    private enum Availability: Equatable {
        case checking
        case enabled
        case disabled
    }

    // GoogleのEEA向け同意要件の対象地域に英国・スイスを加える。
    // Storefrontを取得できない場合も広告を開始しない（安全側）。
    private static let advertisingDisabledRegions: Set<String> = [
        "AT", "BE", "BG", "HR", "CY", "CZ", "DE", "DK", "EE", "ES", "FI",
        "FR", "GR", "HU", "IE", "IS", "IT", "LI", "LT", "LU", "LV", "MT",
        "NL", "NO", "PL", "PT", "RO", "SE", "SI", "SK", "GB", "CH"
    ]

    private var rewarded: RewardedAd?
    private var interstitial: InterstitialAd?
    private var started = false
    private var startRequested = false
    private var loading = false
    private var rewardEarned = false
    private var completion: ((Bool) -> Void)?
    private var interstitialCount = 0
    private var completedGames = 0
    private var lastInterstitial = Date.distantPast
    private var seenResults: Set<UUID> = []
    private var availability: Availability = .checking
    var testing = false
    var forceUnavailable = false
    private var productionReady: Bool { Bundle.main.object(forInfoDictionaryKey:"ShogiAdsProductionReady") as? Bool == true }
    private var enabled: Bool {
        #if DEBUG
        return !testing
        #else
        return productionReady
        #endif
    }
    private var rewardID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/1712485313"
        #else
        return Bundle.main.object(forInfoDictionaryKey:"ShogiRewardedAdUnitID") as? String ?? ""
        #endif
    }
    private var interstitialID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910"
        #else
        return Bundle.main.object(forInfoDictionaryKey:"ShogiInterstitialAdUnitID") as? String ?? ""
        #endif
    }
    func start(from _: UIViewController) {
        guard enabled, !started, !startRequested else { return }
        startRequested = true
        Task { [weak self] in
            guard let self else { return }
            // App Store privacy declares tracking. Resolve ATT before any ad SDK
            // initialization or region-dependent advertising decision so the
            // first-launch review path is deterministic.
            await self.requestTrackingAuthorizationIfNeeded()

            guard let countryCode = await self.storefrontCountryCode(),
                  !Self.advertisingDisabledRegions.contains(countryCode) else {
                self.availability = .disabled
                self.startRequested = false
                return
            }

            guard !self.started else { return }
            self.availability = .enabled
            self.started = true
            _ = await MobileAds.shared.start()
            self.load()
        }
    }
    private func storefrontCountryCode() async -> String? {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["SHOGI_AD_REGION"],
           override.count == 2 {
            return override.uppercased()
        }
        #endif
        return await Storefront.current?.countryCode.uppercased()
    }
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ATTrackingManager.requestTrackingAuthorization { _ in continuation.resume() }
        }
    }
    private func load() {
        guard started, availability == .enabled, !loading else { return }
        loading = true
        RewardedAd.load(with:rewardID,request:Request()) { [weak self] ad, _ in
            self?.rewarded = ad; ad?.fullScreenContentDelegate = self; self?.loading = false
        }
        InterstitialAd.load(with:interstitialID,request:Request()) { [weak self] ad, _ in self?.interstitial = ad; ad?.fullScreenContentDelegate = self }
    }
    func reward(from controller: UIViewController, completion: @escaping (Bool) -> Void) {
        guard !forceUnavailable else { completion(false); return }
        #if DEBUG
        if testing { completion(true); return }
        #endif
        guard let ad = rewarded, self.completion == nil else { load(); completion(false); return }
        self.completion = completion; rewardEarned = false; rewarded = nil
        ad.present(from:controller) { [weak self] in self?.rewardEarned = true }
    }
    func resultShown(id: UUID, from controller: UIViewController) {
        guard !seenResults.contains(id) else { return }; seenResults.insert(id); completedGames += 1
        guard enabled, completedGames % 3 == 0, interstitialCount < 3, Date().timeIntervalSince(lastInterstitial) >= 180, let ad = interstitial, controller.presentedViewController == nil else { return }
        interstitialCount += 1; lastInterstitial = Date(); interstitial = nil; ad.present(from:controller)
    }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { completeReward(); load() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { rewardEarned = false; completeReward(); load() }
    private func completeReward() { let callback = completion; completion = nil; callback?(rewardEarned); rewardEarned = false }
}
