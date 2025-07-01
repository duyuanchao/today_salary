import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import FirebasePerformance
import Combine

// MARK: - Firebase Event Model
struct FirebaseEvent {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
    let priority: EventPriority
    
    enum EventPriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: EventPriority, rhs: EventPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    // 事件队列和批处理
    private var eventQueue: [FirebaseEvent] = []
    private var batchTimer: Timer?
    private let maxBatchSize = 5
    private let batchTimeInterval: TimeInterval = 3.0 // 3秒批处理
    private let eventQueueLock = NSLock()
    
    // 性能监控
    private var sessionStartTime: Date?
    private var screenViewTimes: [String: Date] = [:]
    
    // 事件缓存避免重复发送
    private var recentEvents: [String: Date] = [:]
    private let eventCacheExpiryInterval: TimeInterval = 60 // 1分钟内不重复发送相同事件
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSessionTracking()
        setupBatchProcessing()
    }
    
    deinit {
        batchTimer?.invalidate()
    }
    
    // MARK: - Setup
    private func setupSessionTracking() {
        sessionStartTime = Date()
        
        // 监听应用生命周期
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecomeActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppEnterBackground()
            }
            .store(in: &cancellables)
    }
    
    private func setupBatchProcessing() {
        // 定期处理事件队列
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchTimeInterval, repeats: true) { [weak self] _ in
            self?.processBatchEvents()
        }
    }
    
    // MARK: - Firebase初始化
    func configure() {
        FirebaseApp.configure()
        
        // 设置默认用户属性
        Analytics.setDefaultEventParameters([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "iOS"
        ])
        
        // 记录应用启动事件
        trackAppLaunch()
    }
    
    // MARK: - 批量事件处理
    private func queueEvent(_ event: FirebaseEvent) {
        eventQueueLock.lock()
        defer { eventQueueLock.unlock() }
        
        // 检查是否为重复事件
        let eventKey = "\(event.name)_\(event.parameters.description)"
        if let lastTime = recentEvents[eventKey],
           Date().timeIntervalSince(lastTime) < eventCacheExpiryInterval {
            return // 跳过重复事件
        }
        
        recentEvents[eventKey] = Date()
        eventQueue.append(event)
        
        // 如果是高优先级事件或队列已满，立即发送
        if event.priority >= .high || eventQueue.count >= maxBatchSize {
            processBatchEvents()
        }
    }
    
    private func processBatchEvents() {
        eventQueueLock.lock()
        let eventsToProcess = Array(eventQueue)
        eventQueue.removeAll()
        eventQueueLock.unlock()
        
        guard !eventsToProcess.isEmpty else { return }
        
        // 按优先级排序处理
        let sortedEvents = eventsToProcess.sorted { $0.priority > $1.priority }
        
        // 批量发送事件
        DispatchQueue.global(qos: .utility).async {
            for event in sortedEvents {
                Analytics.logEvent(event.name, parameters: event.parameters)
            }
        }
    }
    
    // MARK: - 优化的事件追踪方法
    
    // 用户设置相关事件
    func trackUserSetup(monthlyIncome: Double, calculationMethod: String) {
        let event = FirebaseEvent(
            name: "user_setup_completed",
            parameters: [
                "monthly_income_range": getIncomeRange(monthlyIncome),
                "calculation_method": calculationMethod,
                "setup_timestamp": Date().timeIntervalSince1970
            ],
            timestamp: Date(),
            priority: .high
        )
        queueEvent(event)
    }
    
    func trackWorkingHoursSet(startHour: Int, endHour: Int, autoCalculateEnabled: Bool) {
        let event = FirebaseEvent(
            name: "working_hours_configured",
            parameters: [
                "start_hour": startHour,
                "end_hour": endHour,
                "work_hours_duration": endHour - startHour,
                "auto_calculate_enabled": autoCalculateEnabled
            ],
            timestamp: Date(),
            priority: .normal
        )
        queueEvent(event)
    }
    
    func trackPaydaySettingsUpdate(paydayType: String, dayOfMonth: Int?) {
        var params: [String: Any] = [
            "payday_type": paydayType
        ]
        if let day = dayOfMonth {
            params["day_of_month"] = day
        }
        
        let event = FirebaseEvent(
            name: "payday_settings_updated",
            parameters: params,
            timestamp: Date(),
            priority: .normal
        )
        queueEvent(event)
    }
    
    // 收入追踪事件 - 降低频率
    func trackEarningsUpdate(amount: Double, isGoalReached: Bool, progressPercentage: Double, inputMethod: String = "manual") {
        // 只在重要里程碑时追踪，减少事件噪音
        let shouldTrack = isGoalReached || 
                         progressPercentage >= 0.25 && progressPercentage.truncatingRemainder(dividingBy: 0.25) < 0.01 ||
                         amount.truncatingRemainder(dividingBy: 50) == 0
        
        guard shouldTrack else { return }
        
        let event = FirebaseEvent(
            name: "earnings_updated",
            parameters: [
                "amount_range": getAmountRange(amount),
                "goal_reached": isGoalReached,
                "progress_percentage": Int(progressPercentage * 100),
                "input_method": inputMethod,
                "day_of_week": getDayOfWeek(),
                "hour_of_day": Calendar.current.component(.hour, from: Date())
            ],
            timestamp: Date(),
            priority: isGoalReached ? .high : .normal
        )
        queueEvent(event)
    }
    
    func trackAutoEarningsCalculation(calculatedAmount: Double, hoursWorked: Double) {
        // 降低自动计算事件的频率
        let shouldTrack = calculatedAmount.truncatingRemainder(dividingBy: 10) == 0 ||
                         hoursWorked.truncatingRemainder(dividingBy: 1.0) == 0
        
        guard shouldTrack else { return }
        
        let event = FirebaseEvent(
            name: "auto_earnings_calculated",
            parameters: [
                "calculated_amount_range": getAmountRange(calculatedAmount),
                "hours_worked": Int(hoursWorked * 10) / 10,
                "calculation_timestamp": Date().timeIntervalSince1970
            ],
            timestamp: Date(),
            priority: .low
        )
        queueEvent(event)
    }
    
    func trackGoalAchievement(targetAmount: Double, actualAmount: Double, achievementTime: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: achievementTime)
        
        let event = FirebaseEvent(
            name: "daily_goal_achieved",
            parameters: [
                "target_amount_range": getAmountRange(targetAmount),
                "actual_amount_range": getAmountRange(actualAmount),
                "overachievement_percentage": Int((actualAmount / targetAmount - 1) * 100),
                "achievement_hour": hour,
                "day_of_week": getDayOfWeek(for: achievementTime)
            ],
            timestamp: Date(),
            priority: .critical
        )
        queueEvent(event)
    }
    
    // 成就系统事件
    func trackAchievementUnlocked(achievementTitle: String, achievementIndex: Int) {
        let event = FirebaseEvent(
            name: "achievement_unlocked",
            parameters: [
                "achievement_name": achievementTitle,
                "achievement_index": achievementIndex,
                "unlock_timestamp": Date().timeIntervalSince1970
            ],
            timestamp: Date(),
            priority: .high
        )
        queueEvent(event)
    }
    
    func trackChallengeCompleted(challengeTitle: String, targetAmount: Double, timeToComplete: TimeInterval) {
        let event = FirebaseEvent(
            name: "challenge_completed",
            parameters: [
                "challenge_name": challengeTitle,
                "target_amount_range": getAmountRange(targetAmount),
                "completion_time_minutes": Int(timeToComplete / 60),
                "day_of_week": getDayOfWeek()
            ],
            timestamp: Date(),
            priority: .high
        )
        queueEvent(event)
    }
    
    // 用户行为事件 - 优化屏幕访问追踪
    func trackScreenView(screenName: String) {
        // 记录屏幕访问时间用于后续分析
        screenViewTimes[screenName] = Date()
        
        let event = FirebaseEvent(
            name: AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName,
                AnalyticsParameterScreenClass: screenName
            ],
            timestamp: Date(),
            priority: .normal
        )
        queueEvent(event)
    }
    
    func trackScreenExit(screenName: String) {
        guard let startTime = screenViewTimes[screenName] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let event = FirebaseEvent(
            name: "screen_exit",
            parameters: [
                "screen_name": screenName,
                "duration_seconds": Int(duration)
            ],
            timestamp: Date(),
            priority: .low
        )
        queueEvent(event)
        
        screenViewTimes.removeValue(forKey: screenName)
    }
    
    func trackButtonTap(buttonName: String, screenName: String) {
        let event = FirebaseEvent(
            name: "button_tapped",
            parameters: [
                "button_name": buttonName,
                "screen_name": screenName
            ],
            timestamp: Date(),
            priority: .low
        )
        queueEvent(event)
    }
    
    func trackSettingsChanged(settingName: String, oldValue: String?, newValue: String) {
        var params: [String: Any] = [
            "setting_name": settingName,
            "new_value": newValue
        ]
        if let old = oldValue {
            params["old_value"] = old
        }
        
        let event = FirebaseEvent(
            name: "settings_changed",
            parameters: params,
            timestamp: Date(),
            priority: .normal
        )
        queueEvent(event)
    }
    
    // MARK: - 应用生命周期事件
    private func trackAppLaunch() {
        let event = FirebaseEvent(
            name: "app_launched",
            parameters: [
                "launch_timestamp": Date().timeIntervalSince1970,
                "day_of_week": getDayOfWeek(),
                "hour_of_day": Calendar.current.component(.hour, from: Date())
            ],
            timestamp: Date(),
            priority: .high
        )
        queueEvent(event)
    }
    
    private func handleAppBecomeActive() {
        sessionStartTime = Date()
        trackDailyActiveUser()
    }
    
    private func handleAppEnterBackground() {
        let event = FirebaseEvent(
            name: "app_backgrounded",
            parameters: [
                "session_duration": getSessionDuration(),
                "background_timestamp": Date().timeIntervalSince1970
            ],
            timestamp: Date(),
            priority: .normal
        )
        queueEvent(event)
        
        // 立即发送剩余事件
        processBatchEvents()
    }
    
    private func trackDailyActiveUser() {
        let today = DateFormatter().string(from: Date())
        let lastActiveDate = UserDefaults.standard.string(forKey: "last_active_date")
        
        // 只在新的一天时记录DAU
        guard lastActiveDate != today else { return }
        
        UserDefaults.standard.set(today, forKey: "last_active_date")
        
        let event = FirebaseEvent(
            name: "daily_active_user",
            parameters: [
                "date": today,
                "user_type": "active"
            ],
            timestamp: Date(),
            priority: .high
        )
        queueEvent(event)
    }
    
    // MARK: - 用户属性设置
    func setUserProperties(monthlyIncome: Double, calculationMethod: String, hasWorkingHours: Bool) {
        DispatchQueue.global(qos: .utility).async {
            Analytics.setUserProperty(self.getIncomeRange(monthlyIncome), forName: "income_range")
            Analytics.setUserProperty(calculationMethod, forName: "calculation_method")
            Analytics.setUserProperty(hasWorkingHours ? "yes" : "no", forName: "uses_working_hours")
            Analytics.setUserProperty(self.getAppUsageDays(), forName: "app_usage_days")
        }
    }
    
    // MARK: - 错误追踪
    func trackError(error: Error, context: String) {
        Crashlytics.crashlytics().record(error: error)
        
        let event = FirebaseEvent(
            name: "app_error",
            parameters: [
                "error_type": String(describing: type(of: error)),
                "context": context,
                "error_description": error.localizedDescription
            ],
            timestamp: Date(),
            priority: .critical
        )
        queueEvent(event)
    }
    
    func trackCustomEvent(eventName: String, parameters: [String: Any] = [:], priority: FirebaseEvent.EventPriority = .normal) {
        let event = FirebaseEvent(
            name: eventName,
            parameters: parameters,
            timestamp: Date(),
            priority: priority
        )
        queueEvent(event)
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
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    private func getAppUsageDays() -> String {
        let firstLaunchKey = "first_launch_date"
        let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchKey) as? Date ?? {
            let now = Date()
            UserDefaults.standard.set(now, forKey: firstLaunchKey)
            return now
        }()
        
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
    
    // MARK: - 强制发送队列中的事件
    func flushEvents() {
        processBatchEvents()
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