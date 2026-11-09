import GoogleMobileAds

class AdManager: NSObject {
    static let shared = AdManager()

    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var activePlacement: String?
    private var didEarnActiveReward = false

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAdMobReady),
            name: .adMobReady,
            object: nil
        )
    }

    @objc private func onAdMobReady() {
        loadRewarded()
    }

    // MARK: - Load

    func loadRewarded() {
        guard !isLoading else { return }
        isLoading = true
        let req = Request()
        RewardedAd.load(with: AdConfig.rewardedAdUnit, request: req) { [weak self] ad, error in
            self?.isLoading = false
            if let error {
                print("[AdManager] リワード広告ロード失敗: \(error)")
                AnalyticsManager.shared.logRewardedLoadFailed(errorCode: (error as NSError).code)
                return
            }
            self?.rewardedAd = ad
            ad?.fullScreenContentDelegate = self
            print("[AdManager] リワード広告ロード完了")
        }
    }

    var isRewardedReady: Bool { rewardedAd != nil }

    // MARK: - Show

    /// リワード広告を表示する
    /// - Parameters:
    ///   - rootVC: 広告を表示する UIViewController
    ///   - onRewarded: 動画完視聴後に呼ばれるコールバック
    ///   - onNotReady: 広告が未ロードの場合に呼ばれるコールバック
    func showRewarded(from rootVC: UIViewController,
                      placement: String,
                      onRewarded: @escaping () -> Void,
                      onNotReady: (() -> Void)? = nil) {
        AnalyticsManager.shared.logRewardedRequest(placement: placement)
        guard let ad = rewardedAd else {
            print("[AdManager] 広告未準備")
            AnalyticsManager.shared.logRewardedNotReady(placement: placement)
            onNotReady?()
            loadRewarded()
            return
        }

        activePlacement = placement
        didEarnActiveReward = false
        ad.paidEventHandler = { adValue in
            AnalyticsManager.shared.logAdRevenue(
                value: adValue.value,
                currencyCode: adValue.currencyCode,
                precision: String(describing: adValue.precision),
                placement: placement
            )
        }
        ad.present(from: rootVC) { [weak self] in
            self?.didEarnActiveReward = true
            onRewarded()
        }
    }
}

extension AdManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let placement = activePlacement else { return }
        AnalyticsManager.shared.logRewardedPresented(placement: placement)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if let placement = activePlacement {
            AnalyticsManager.shared.logRewardedDismissed(
                placement: placement,
                earnedReward: didEarnActiveReward
            )
        }
        clearPresentedAdAndReload()
    }

    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        if let placement = activePlacement {
            AnalyticsManager.shared.logRewardedPresentFailed(
                placement: placement,
                errorCode: (error as NSError).code
            )
        }
        clearPresentedAdAndReload()
    }

    private func clearPresentedAdAndReload() {
        rewardedAd = nil
        activePlacement = nil
        didEarnActiveReward = false
        loadRewarded()
    }
}
