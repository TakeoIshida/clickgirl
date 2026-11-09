import Foundation
import OSLog

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// 広告導線の計測窓口。
/// Firebase 設定がないビルドでも安全に動作し、端末内カウンターとログは残す。
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ClickGirl", category: "Analytics")
    private let defaults = UserDefaults.standard
    private let counterPrefix = "cg_analytics_count_"
    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true

#if canImport(FirebaseCore)
        if FirebaseApp.app() == nil,
           Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
            logger.info("Firebase Analytics enabled")
        } else if FirebaseApp.app() == nil {
            logger.notice("Firebase configuration is not bundled; using local analytics only")
        }
#else
        logger.notice("Firebase Analytics SDK is not linked; using local analytics only")
#endif

        log("app_session_start")
    }

    func logRewardedOpportunity(placement: String) {
        log("rewarded_opportunity", parameters: ["placement": placement])
    }

    func logRewardedRequest(placement: String) {
        log("rewarded_request", parameters: ["placement": placement])
    }

    func logRewardedPresented(placement: String) {
        log("rewarded_presented", parameters: ["placement": placement])
    }

    func logRewardedCompleted(placement: String) {
        log("rewarded_complete", parameters: ["placement": placement])
    }

    func logRewardedDismissed(placement: String, earnedReward: Bool) {
        log("rewarded_dismissed", parameters: [
            "placement": placement,
            "earned_reward": earnedReward ? 1 : 0
        ])
    }

    func logRewardedNotReady(placement: String) {
        log("rewarded_not_ready", parameters: ["placement": placement])
    }

    func logRewardedLoadFailed(errorCode: Int) {
        log("rewarded_load_failed", parameters: ["error_code": errorCode])
    }

    func logRewardedPresentFailed(placement: String, errorCode: Int) {
        log("rewarded_present_failed", parameters: [
            "placement": placement,
            "error_code": errorCode
        ])
    }

    func logAdRevenue(value: NSDecimalNumber,
                      currencyCode: String,
                      precision: String,
                      placement: String) {
        log("ad_revenue", parameters: [
            "value": value.doubleValue,
            "currency": currencyCode,
            "precision": precision,
            "placement": placement,
            "ad_platform": "admob",
            "ad_format": "rewarded"
        ])
    }

    func logDailyMissionCompleted(missionID: String,
                                  moneyReward: Double,
                                  ticketReward: Int) {
        log("daily_mission_complete", parameters: [
            "mission_id": missionID,
            "money_reward": moneyReward,
            "ticket_reward": ticketReward
        ])
    }

    func logDailyMissionStreak(streak: Int, receivedSevenDayBonus: Bool) {
        log("daily_mission_streak", parameters: [
            "streak_days": streak,
            "seven_day_bonus": receivedSevenDayBonus
        ])
    }

    func logWeeklyMissionCompleted(completedDays: Int,
                                   moneyReward: Double,
                                   ticketReward: Int) {
        log("weekly_mission_complete", parameters: [
            "completed_days": completedDays,
            "money_reward": moneyReward,
            "ticket_reward": ticketReward
        ])
    }

    func logComebackBonus(awayDays: Int,
                          moneyReward: Double,
                          ticketReward: Int) {
        log("comeback_bonus", parameters: [
            "away_days": awayDays,
            "money_reward": moneyReward,
            "ticket_reward": ticketReward
        ])
    }

    private func log(_ name: String, parameters: [String: Any] = [:]) {
        incrementLocalCounter(event: name, placement: parameters["placement"] as? String)
        logger.info("event=\(name, privacy: .public) parameters=\(String(describing: parameters), privacy: .private)")

#if canImport(FirebaseAnalytics) && canImport(FirebaseCore)
        if FirebaseApp.app() != nil {
            Analytics.logEvent(name, parameters: parameters)
        }
#endif
    }

    private func incrementLocalCounter(event: String, placement: String?) {
        let suffix = placement.map { "\(event)_\($0)" } ?? event
        let key = counterPrefix + suffix
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }
}
