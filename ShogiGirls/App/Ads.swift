import UIKit
import GoogleMobileAds
import UserMessagingPlatform

@MainActor final class Ads: NSObject, FullScreenContentDelegate {
    private var rewarded: RewardedAd?
    private var interstitial: InterstitialAd?
    private var started = false
    private var loading = false
    private var rewardEarned = false
    private var completion: ((Bool) -> Void)?
    private var interstitialCount = 0
    private var completedGames = 0
    private var lastInterstitial = Date.distantPast
    private var seenResults: Set<UUID> = []
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
    var privacyRequired: Bool { ConsentInformation.shared.privacyOptionsRequirementStatus == .required }
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
    func start(from controller: UIViewController) {
        guard enabled, !started else { return }
        #if DEBUG
        // The official sample app ID has no publisher-configured UMP form.
        // This branch requests only Google's official test ad units.
        if !productionReady {
            started = true
            MobileAds.shared.start { _ in Task { @MainActor in self.load() } }
            return
        }
        #endif
        ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self, weak controller] _ in
            Task { @MainActor in
                if let controller { try? await ConsentForm.loadAndPresentIfRequired(from: controller) }
                guard let self, ConsentInformation.shared.canRequestAds, !self.started else { return }
                self.started = true
                MobileAds.shared.start { _ in Task { @MainActor in self.load() } }
            }
        }
    }
    func privacy(from controller: UIViewController, completion: @escaping () -> Void) {
        Task { @MainActor in
            try? await ConsentForm.presentPrivacyOptionsForm(from:controller)
            if !ConsentInformation.shared.canRequestAds { rewarded = nil; interstitial = nil }
            else { load() }
            completion()
        }
    }
    private func load() {
        #if DEBUG
        let consentAllowed = !productionReady || ConsentInformation.shared.canRequestAds
        #else
        let consentAllowed = ConsentInformation.shared.canRequestAds
        #endif
        guard started, !loading, consentAllowed else { return }
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
