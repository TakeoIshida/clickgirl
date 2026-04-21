import GoogleMobileAds

class AdManager: NSObject {
    static let shared = AdManager()

    private var rewardedAd: RewardedAd?
    private var isLoading = false

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
            if let error { print("[AdManager] リワード広告ロード失敗: \(error)"); return }
            self?.rewardedAd = ad
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
                      onRewarded: @escaping () -> Void,
                      onNotReady: (() -> Void)? = nil) {
        guard let ad = rewardedAd else {
            print("[AdManager] 広告未準備")
            onNotReady?()
            loadRewarded()
            return
        }
        ad.present(from: rootVC) { [weak self] in
            onRewarded()
            self?.rewardedAd = nil
            self?.loadRewarded()
        }
    }
}
