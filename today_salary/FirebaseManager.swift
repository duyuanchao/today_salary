import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import FirebasePerformance

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private init() {}
    
    // MARK: - Firebase初始化
    func configure() {
        FirebaseApp.configure()
        
        // 设置默认用户属性
        Analytics.setDefaultEventParameters([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "iOS"
        ])
    }
    
    // MARK: - 用户设置相关事件
    func trackUserSetup(monthlyIncome: Double, calculationMethod: String) {
        Analytics.logEvent("user_setup_completed", parameters: [
            "monthly_income_range": getIncomeRange(monthlyIncome),
            "calculation_method": calculationMethod,
            "setup_timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackWorkingHoursSet(startHour: Int, endHour: Int, autoCalculateEnabled: Bool) {
        Analytics.logEvent("working_hours_configured", parameters: [
            "start_hour": startHour,
            "end_hour": endHour,
            "work_hours_duration": endHour - startHour,
            "auto_calculate_enabled": autoCalculateEnabled
        ])
    }
    
    func trackPaydaySettingsUpdate(paydayType: String, dayOfMonth: Int?) {
        var params: [String: Any] = [
            "payday_type": paydayType
        ]
        if let day = dayOfMonth {
            params["day_of_month"] = day
        }
        
        Analytics.logEvent("payday_settings_updated", parameters: params)
    }
    
    // MARK: - 收入追踪事件
    func trackEarningsUpdate(amount: Double, isGoalReached: Bool, progressPercentage: Double, inputMethod: String = "manual") {
        Analytics.logEvent("earnings_updated", parameters: [
            "amount_range": getAmountRange(amount),
            "goal_reached": isGoalReached,
            "progress_percentage": Int(progressPercentage * 100),
            "input_method": inputMethod,
            "day_of_week": getDayOfWeek(),
            "hour_of_day": Calendar.current.component(.hour, from: Date())
        ])
    }
    
    func trackAutoEarningsCalculation(calculatedAmount: Double, hoursWorked: Double) {
        Analytics.logEvent("auto_earnings_calculated", parameters: [
            "calculated_amount_range": getAmountRange(calculatedAmount),
            "hours_worked": Int(hoursWorked * 10) / 10, // 保留一位小数
            "calculation_timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackGoalAchievement(targetAmount: Double, actualAmount: Double, achievementTime: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: achievementTime)
        
        Analytics.logEvent("daily_goal_achieved", parameters: [
            "target_amount_range": getAmountRange(targetAmount),
            "actual_amount_range": getAmountRange(actualAmount),
            "overachievement_percentage": Int((actualAmount / targetAmount - 1) * 100),
            "achievement_hour": hour,
            "day_of_week": getDayOfWeek(for: achievementTime)
        ])
    }
    
    // MARK: - 成就系统事件
    func trackAchievementUnlocked(achievementTitle: String, achievementIndex: Int) {
        Analytics.logEvent("achievement_unlocked", parameters: [
            "achievement_name": achievementTitle,
            "achievement_index": achievementIndex,
            "unlock_timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackChallengeCompleted(challengeTitle: String, targetAmount: Double, timeToComplete: TimeInterval) {
        Analytics.logEvent("challenge_completed", parameters: [
            "challenge_name": challengeTitle,
            "target_amount_range": getAmountRange(targetAmount),
            "completion_time_minutes": Int(timeToComplete / 60),
            "day_of_week": getDayOfWeek()
        ])
    }
    
    // MARK: - 用户行为事件
    func trackScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName
        ])
    }
    
    func trackButtonTap(buttonName: String, screenName: String) {
        Analytics.logEvent("button_tapped", parameters: [
            "button_name": buttonName,
            "screen_name": screenName
        ])
    }
    
    func trackSettingsChanged(settingName: String, oldValue: String?, newValue: String) {
        var params: [String: Any] = [
            "setting_name": settingName,
            "new_value": newValue
        ]
        if let old = oldValue {
            params["old_value"] = old
        }
        
        Analytics.logEvent("settings_changed", parameters: params)
    }
    
    // MARK: - 应用生命周期事件
    func trackAppLaunch() {
        Analytics.logEvent("app_launched", parameters: [
            "launch_timestamp": Date().timeIntervalSince1970,
            "day_of_week": getDayOfWeek(),
            "hour_of_day": Calendar.current.component(.hour, from: Date())
        ])
    }
    
    func trackAppBackground() {
        Analytics.logEvent("app_backgrounded", parameters: [
            "session_duration": getSessionDuration(),
            "background_timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackDailyActiveUser() {
        Analytics.logEvent("daily_active_user", parameters: [
            "date": DateFormatter().string(from: Date()),
            "user_type": "active"
        ])
    }
    
    // MARK: - 用户属性设置
    func setUserProperties(monthlyIncome: Double, calculationMethod: String, hasWorkingHours: Bool) {
        Analytics.setUserProperty(getIncomeRange(monthlyIncome), forName: "income_range")
        Analytics.setUserProperty(calculationMethod, forName: "calculation_method")
        Analytics.setUserProperty(hasWorkingHours ? "yes" : "no", forName: "uses_working_hours")
        Analytics.setUserProperty(getAppUsageDays(), forName: "app_usage_days")
    }
    
    // MARK: - 错误追踪
    func trackError(error: Error, context: String) {
        Crashlytics.crashlytics().record(error: error)
        
        Analytics.logEvent("app_error", parameters: [
            "error_type": String(describing: type(of: error)),
            "context": context,
            "error_description": error.localizedDescription
        ])
    }
    
    func trackCustomEvent(eventName: String, parameters: [String: Any] = [:]) {
        Analytics.logEvent(eventName, parameters: parameters)
    }
    
    // MARK: - 辅助方法
    private func getIncomeRange(_ amount: Double) -> String {
        switch amount {
        case 0..<1000: return "0-1k"
        case 1000..<2000: return "1k-2k"
        case 2000..<3000: return "2k-3k"
        case 3000..<5000: return "3k-5k"
        case 5000..<10000: return "5k-10k"
        default: return "10k+"
        }
    }
    
    private func getAmountRange(_ amount: Double) -> String {
        switch amount {
        case 0..<5: return "0-5"
        case 5..<20: return "5-20"
        case 20..<50: return "20-50"
        case 50..<100: return "50-100"
        case 100..<200: return "100-200"
        default: return "200+"
        }
    }
    
    private func getDayOfWeek(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).lowercased()
    }
    
    private func getSessionDuration() -> TimeInterval {
        // 这里需要与应用的生命周期管理配合
        // 返回当前会话的持续时间
        return 0 // 占位符，需要实际实现
    }
    
    private func getAppUsageDays() -> String {
        // 计算用户使用应用的天数
        let firstLaunchDate = UserDefaults.standard.object(forKey: "first_launch_date") as? Date ?? Date()
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0
        
        switch daysSinceFirstLaunch {
        case 0: return "first_day"
        case 1...7: return "week_1"
        case 8...30: return "month_1"
        case 31...90: return "quarter_1"
        default: return "long_term"
        }
    }
    
    // MARK: - 性能监控
    func startPerformanceTrace(name: String) -> Trace? {
        return Performance.startTrace(name: name)
    }
}

// MARK: - Firebase事件名称常量
extension FirebaseManager {
    struct EventNames {
        static let userSetupCompleted = "user_setup_completed"
        static let earningsUpdated = "earnings_updated"
        static let goalAchieved = "daily_goal_achieved"
        static let achievementUnlocked = "achievement_unlocked"
        static let challengeCompleted = "challenge_completed"
        static let settingsChanged = "settings_changed"
        static let appLaunched = "app_launched"
        static let screenView = "screen_view"
        static let buttonTapped = "button_tapped"
    }
    
    struct UserPropertyNames {
        static let incomeRange = "income_range"
        static let calculationMethod = "calculation_method"
        static let usesWorkingHours = "uses_working_hours"
        static let appUsageDays = "app_usage_days"
    }
} 