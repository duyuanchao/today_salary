import Foundation
import UserNotifications

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var userProfile = UserProfile()
    @Published var todayEarnings = DailyEarnings()
    @Published var achievements: [Achievement] = []
    @Published var challenges: [Challenge] = []
    @Published var currentProgress: Double = 0.0
    
    // Firebase管理器
    private let firebaseManager = FirebaseManager.shared
    
    private let userProfileKey = "UserProfile"
    private let earningsKey = "DailyEarnings"
    private let achievementsKey = "Achievements"
    private let challengesKey = "Challenges"
    private let lastCalculationMonthKey = "LastCalculationMonth"
    
    // 定时器用于自动更新收入 - 优化：降低频率
    private var earningsUpdateTimer: Timer?
    
    // 性能优化：添加数据保存队列和节流
    private let saveQueue = DispatchQueue(label: "DataManagerSave", qos: .utility)
    private var saveWorkItem: DispatchWorkItem?
    private let saveDelay: TimeInterval = 0.5 // 延迟保存，避免频繁IO
    
    // 性能优化：缓存计算结果
    private var cachedMonthInfo: MonthInfo?
    private var cachedDetailedProgressInfo: DetailedProgressInfo?
    private var lastCacheUpdate = Date()
    private let cacheTimeout: TimeInterval = 30 // 30秒缓存超时
    
    private init() {
        loadData()
        setupDefaultAchievements()
        generateDailyChallenge()
        requestNotificationPermission()
        checkAndUpdateMonthlyCalculation()
        startAutoEarningsUpdate()
    }
    
    deinit {
        stopAutoEarningsUpdate()
        saveWorkItem?.cancel()
    }
    
    // MARK: - 性能优化：节流保存
    private func scheduleSave() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        
        if let workItem = saveWorkItem {
            saveQueue.asyncAfter(deadline: .now() + saveDelay, execute: workItem)
        }
    }
    
    private func performSave() {
        let profileData = try? JSONEncoder().encode(userProfile)
        let achievementsData = try? JSONEncoder().encode(achievements)
        let challengesData = try? JSONEncoder().encode(challenges)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let profileData = profileData {
                UserDefaults.standard.set(profileData, forKey: self.userProfileKey)
            }
            if let achievementsData = achievementsData {
                UserDefaults.standard.set(achievementsData, forKey: self.achievementsKey)
            }
            if let challengesData = challengesData {
                UserDefaults.standard.set(challengesData, forKey: self.challengesKey)
            }
            
            self.saveTodayEarnings()
        }
    }
    
    // MARK: - 自动收入更新 - 优化：降低频率
    private func startAutoEarningsUpdate() {
        // 优化：从每分钟改为每3分钟更新一次
        earningsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            self?.updateTimeBasedEarningsAsync()
        }
        
        // 立即执行一次更新
        updateTimeBasedEarningsAsync()
    }
    
    private func stopAutoEarningsUpdate() {
        earningsUpdateTimer?.invalidate()
        earningsUpdateTimer = nil
    }
    
    // 性能优化：异步执行耗时计算
    private func updateTimeBasedEarningsAsync() {
        guard userProfile.isSetup && userProfile.workingHours.isAutoCalculateEnabled else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let timeBasedEarnings = self.userProfile.calculateTimeBasedEarnings()
            let hoursWorked = self.userProfile.workingHours.getWorkedHoursToday()
            
            DispatchQueue.main.async {
                // 只有当自动计算的收入大于当前记录的收入时才更新
                if timeBasedEarnings > self.todayEarnings.amount {
                    self.todayEarnings.updateAmount(timeBasedEarnings, target: self.userProfile.dailyTarget)
                    self.updateProgress()
                    self.checkAchievements()
                    self.checkChallenges()
                    self.scheduleSave() // 使用节流保存
                    
                    // Firebase分析：异步执行
                    DispatchQueue.global(qos: .utility).async {
                        self.firebaseManager.trackAutoEarningsCalculation(
                            calculatedAmount: timeBasedEarnings,
                            hoursWorked: hoursWorked
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 月份检查和重新计算
    private func checkAndUpdateMonthlyCalculation() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: Date())
            let currentYear = calendar.component(.year, from: Date())
            let currentMonthKey = "\(currentYear)-\(currentMonth)"
            
            let lastCalculationMonth = UserDefaults.standard.string(forKey: self.lastCalculationMonthKey)
            
            if lastCalculationMonth != currentMonthKey {
                DispatchQueue.main.async {
                    // 月份已变化，重新计算每日目标
                    self.userProfile.recalculateDailyTarget()
                    UserDefaults.standard.set(currentMonthKey, forKey: self.lastCalculationMonthKey)
                    self.scheduleSave()
                    
                    // 清除上个月的挑战，生成新的挑战
                    self.removeOldChallenges()
                    self.generateDailyChallenge()
                    
                    // 清除缓存
                    self.clearCache()
                }
            }
        }
    }
    
    private func removeOldChallenges() {
        let calendar = Calendar.current
        let today = Date()
        challenges.removeAll { challenge in
            !calendar.isDate(challenge.date, inSameDayAs: today)
        }
    }
    
    // MARK: - 性能优化：缓存管理
    private func clearCache() {
        cachedMonthInfo = nil
        cachedDetailedProgressInfo = nil
        lastCacheUpdate = Date()
    }
    
    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(lastCacheUpdate) < cacheTimeout
    }
    
    // MARK: - 数据加载与保存
    func loadData() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 加载用户配置
            var loadedProfile = UserProfile()
            if let data = UserDefaults.standard.data(forKey: self.userProfileKey),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                loadedProfile = profile
            }
            
            // 加载成就
            var loadedAchievements: [Achievement] = []
            if let data = UserDefaults.standard.data(forKey: self.achievementsKey),
               let achievements = try? JSONDecoder().decode([Achievement].self, from: data) {
                loadedAchievements = achievements
            }
            
            // 加载挑战
            var loadedChallenges: [Challenge] = []
            if let data = UserDefaults.standard.data(forKey: self.challengesKey),
               let challenges = try? JSONDecoder().decode([Challenge].self, from: data) {
                loadedChallenges = challenges
            }
            
            DispatchQueue.main.async {
                self.userProfile = loadedProfile
                self.achievements = loadedAchievements
                self.challenges = loadedChallenges
                
                // 加载今日收入
                self.loadTodayEarnings()
                self.updateProgress()
            }
        }
    }
    
    func saveData() {
        scheduleSave() // 使用节流保存
    }
    
    private func loadTodayEarnings() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = "\(earningsKey)_\(today.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.data(forKey: todayKey),
           let earnings = try? JSONDecoder().decode(DailyEarnings.self, from: data) {
            todayEarnings = earnings
        } else {
            todayEarnings = DailyEarnings()
        }
    }
    
    private func saveTodayEarnings() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayKey = "\(earningsKey)_\(today.timeIntervalSince1970)"
        
        if let data = try? JSONEncoder().encode(todayEarnings) {
            UserDefaults.standard.set(data, forKey: todayKey)
        }
    }
    
    // MARK: - 收入管理
    func updateTodayEarnings(_ amount: Double) {
        let wasGoalReached = todayEarnings.isGoalReached
        todayEarnings.updateAmount(amount, target: userProfile.dailyTarget)
        updateProgress()
        checkAchievements()
        checkChallenges()
        clearCache() // 清除缓存
        scheduleSave() // 使用节流保存
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.firebaseManager.trackEarningsUpdate(
                amount: amount,
                isGoalReached: self.todayEarnings.isGoalReached,
                progressPercentage: self.currentProgress,
                inputMethod: "manual"
            )
            
            // 如果刚刚达到目标，记录目标达成事件
            if self.todayEarnings.isGoalReached && !wasGoalReached {
                self.firebaseManager.trackGoalAchievement(
                    targetAmount: self.userProfile.dailyTarget,
                    actualAmount: amount,
                    achievementTime: Date()
                )
                
                DispatchQueue.main.async {
                    self.scheduleSuccessNotification()
                }
            }
        }
    }
    
    func setupUserProfile(monthlyIncome: Double, userName: String? = nil, calculationMethod: CalculationMethod = .naturalDays) {
        userProfile.setupProfile(monthlyIncome: monthlyIncome, userName: userName, calculationMethod: calculationMethod)
        
        // 设置当前月份标记
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let currentMonthKey = "\(currentYear)-\(currentMonth)"
        UserDefaults.standard.set(currentMonthKey, forKey: lastCalculationMonthKey)
        
        clearCache() // 清除缓存
        scheduleSave()
        generateDailyChallenge()
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.firebaseManager.trackUserSetup(
                monthlyIncome: monthlyIncome,
                calculationMethod: calculationMethod.rawValue
            )
            
            // 设置Firebase用户属性
            self.firebaseManager.setUserProperties(
                monthlyIncome: monthlyIncome,
                calculationMethod: calculationMethod.rawValue,
                hasWorkingHours: self.userProfile.workingHours.isAutoCalculateEnabled
            )
        }
        
        // 启动自动更新
        startAutoEarningsUpdate()
    }
    
    func updateWorkingHours(_ workingHours: WorkingHours) {
        userProfile.workingHours = workingHours
        clearCache() // 清除缓存
        scheduleSave()
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: workingHours.startTime)
            let endHour = calendar.component(.hour, from: workingHours.endTime)
            
            self.firebaseManager.trackWorkingHoursSet(
                startHour: startHour,
                endHour: endHour,
                autoCalculateEnabled: workingHours.isAutoCalculateEnabled
            )
        }
        
        // 如果启用了自动计算，立即更新收入
        if workingHours.isAutoCalculateEnabled {
            updateTimeBasedEarningsAsync()
        }
    }
    
    func updatePaydaySettings(_ paydaySettings: PaydaySettings) {
        userProfile.paydaySettings = paydaySettings
        clearCache() // 清除缓存
        scheduleSave()
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.firebaseManager.trackPaydaySettingsUpdate(
                paydayType: paydaySettings.isLastDayOfMonth ? "month_end" : "specific_date",
                dayOfMonth: paydaySettings.isLastDayOfMonth ? nil : paydaySettings.paydayOfMonth
            )
        }
    }
    
    private func updateProgress() {
        if userProfile.dailyTarget > 0 {
            currentProgress = min(todayEarnings.amount / userProfile.dailyTarget, 1.0)
        } else {
            currentProgress = 0.0
        }
    }
    
    // MARK: - 月份信息获取 - 性能优化：添加缓存
    func getCurrentMonthInfo() -> MonthInfo {
        if let cached = cachedMonthInfo, isCacheValid() {
            return cached
        }
        
        let monthInfo = userProfile.getCurrentMonthInfo()
        cachedMonthInfo = monthInfo
        lastCacheUpdate = Date()
        return monthInfo
    }
    
    func getDetailedProgressInfo() -> DetailedProgressInfo {
        if let cached = cachedDetailedProgressInfo, isCacheValid() {
            return cached
        }
        
        let monthInfo = getCurrentMonthInfo()
        let totalEarnings = todayEarnings.amount
        let targetForToday = userProfile.dailyTarget
        let remainingTarget = max(0, userProfile.monthlyIncome - getTotalMonthEarnings())
        let avgNeededPerDay = remainingTarget / Double(max(1, monthInfo.relevantRemainingDays))
        
        let progressInfo = DetailedProgressInfo(
            monthInfo: monthInfo,
            todayEarnings: totalEarnings,
            todayTarget: targetForToday,
            monthlyTarget: userProfile.monthlyIncome,
            totalMonthEarnings: getTotalMonthEarnings(),
            remainingTarget: remainingTarget,
            averageNeededPerRemainingDay: avgNeededPerDay,
            isOnTrack: avgNeededPerDay <= targetForToday * 1.1 // 10%容错
        )
        
        cachedDetailedProgressInfo = progressInfo
        lastCacheUpdate = Date()
        return progressInfo
    }
    
    func getWorkingTimeInfo() -> WorkingTimeInfo {
        let workingHours = userProfile.workingHours
        let workedHours = workingHours.getWorkedHoursToday()
        let totalHours = workingHours.workingHoursPerDay
        let hourlyRate = userProfile.dailyTarget / totalHours
        let isWorkingTime = workingHours.isCurrentlyWorkingTime()
        let timeBasedEarnings = userProfile.calculateTimeBasedEarnings()
        
        return WorkingTimeInfo(
            startTime: workingHours.formattedStartTime,
            endTime: workingHours.formattedEndTime,
            workedHours: workedHours,
            totalWorkingHours: totalHours,
            hourlyRate: hourlyRate,
            isCurrentlyWorkingTime: isWorkingTime,
            timeBasedEarnings: timeBasedEarnings,
            isAutoCalculateEnabled: workingHours.isAutoCalculateEnabled
        )
    }
    
    func getPaydayInfo() -> PaydayInfo {
        let payday = userProfile.paydaySettings
        let daysUntilPayday = payday.getDaysUntilNextPayday()
        let nextPayday = payday.getPaydayForCurrentMonth()
        
        return PaydayInfo(
            paydaySettings: payday,
            daysUntilNextPayday: daysUntilPayday,
            nextPaydayDate: nextPayday
        )
    }
    
    private func getTotalMonthEarnings() -> Double {
        // 这里应该加载当月所有的收入记录并求和
        // 为了简化，暂时只返回今日收入
        // 在实际应用中，你可能需要存储和加载整个月的数据
        return todayEarnings.amount
    }
    
    // MARK: - 激励消息
    func getMotivationalMessage() -> MotivationalMessage {
        let progress = currentProgress
        
        switch progress {
        case 1.0...:
            return .excellent
        case 0.7..<1.0:
            return .good
        case 0.4..<0.7:
            return .average
        case 0.1..<0.4:
            return .needsWork
        default:
            return .justStarted
        }
    }
    
    // MARK: - 成就系统
    private func setupDefaultAchievements() {
        if achievements.isEmpty {
            achievements = [
                Achievement(title: "First Dollar", description: "Earn your first dollar today!", icon: "dollarsign.circle"),
                Achievement(title: "Half Way There", description: "Reach 50% of daily goal", icon: "chart.pie"),
                Achievement(title: "Goal Crusher", description: "Reach 100% of daily goal", icon: "target"),
                Achievement(title: "Overachiever", description: "Exceed daily goal by 50%", icon: "crown"),
                Achievement(title: "Weekly Warrior", description: "Meet daily goal 7 days in a row", icon: "calendar"),
                Achievement(title: "Coffee Money", description: "Earn enough for a Starbucks!", icon: "cup.and.saucer")
            ]
        }
    }
    
    private func checkAchievements() {
        let progress = currentProgress
        let amount = todayEarnings.amount
        
        // First Dollar
        if amount > 0 && !achievements[0].isUnlocked {
            unlockAchievement(at: 0)
        }
        
        // Half Way There
        if progress >= 0.5 && !achievements[1].isUnlocked {
            unlockAchievement(at: 1)
        }
        
        // Goal Crusher
        if progress >= 1.0 && !achievements[2].isUnlocked {
            unlockAchievement(at: 2)
        }
        
        // Overachiever
        if progress >= 1.5 && !achievements[3].isUnlocked {
            unlockAchievement(at: 3)
        }
        
        // Coffee Money (假设星巴克咖啡$5)
        if amount >= 5 && !achievements[5].isUnlocked {
            unlockAchievement(at: 5)
        }
    }
    
    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            self.firebaseManager.trackAchievementUnlocked(
                achievementTitle: self.achievements[index].title,
                achievementIndex: index
            )
        }
        
        scheduleAchievementNotification(achievements[index])
    }
    
    // MARK: - 挑战系统
    private func generateDailyChallenge() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查是否已有今日挑战
        if challenges.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return
        }
        
        let dailyTarget = userProfile.dailyTarget
        let challengeAmount = dailyTarget * 0.3 // 30% of daily target
        
        let challengeOptions = [
            Challenge(title: "Coffee Run", description: "Earn enough for your morning coffee", targetAmount: 5, reward: "☕ Coffee break!"),
            Challenge(title: "Lunch Money", description: "Earn enough for a nice lunch", targetAmount: 15, reward: "🍔 Tasty lunch!"),
            Challenge(title: "Movie Night", description: "Earn enough for a movie ticket", targetAmount: 12, reward: "🎬 Movie time!"),
            Challenge(title: "Quick Start", description: "Earn 30% of your daily goal", targetAmount: challengeAmount, reward: "🚀 Great start!")
        ]
        
        let randomChallenge = challengeOptions.randomElement()!
        challenges.append(randomChallenge)
        scheduleSave()
    }
    
    private func checkChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        for i in challenges.indices {
            if Calendar.current.isDate(challenges[i].date, inSameDayAs: today) &&
               !challenges[i].isCompleted &&
               todayEarnings.amount >= challenges[i].targetAmount {
                
                let challenge = challenges[i]
                let timeToComplete = Date().timeIntervalSince(challenge.date)
                
                challenges[i].isCompleted = true
                
                // Firebase分析：异步执行
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    guard let self = self else { return }
                    
                    self.firebaseManager.trackChallengeCompleted(
                        challengeTitle: challenge.title,
                        targetAmount: challenge.targetAmount,
                        timeToComplete: timeToComplete
                    )
                }
                
                scheduleChallengeNotification(challenges[i])
            }
        }
    }
    
    // MARK: - 通知系统
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    private func scheduleSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"
        content.body = "Congratulations! You've reached your daily earning goal!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goalAchieved", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleAchievementNotification(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Achievement Unlocked!"
        content.body = achievement.title
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "achievement_\(achievement.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleChallengeNotification(_ challenge: Challenge) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Challenge Complete!"
        content.body = "\(challenge.title) - \(challenge.reward)"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "challenge_\(challenge.id)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "💰 Check Your Progress"
        content.body = "How much have you earned today?"
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 18 // 6 PM reminder
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 详细进度信息
struct DetailedProgressInfo {
    let monthInfo: MonthInfo
    let todayEarnings: Double
    let todayTarget: Double
    let monthlyTarget: Double
    let totalMonthEarnings: Double
    let remainingTarget: Double
    let averageNeededPerRemainingDay: Double
    let isOnTrack: Bool
}

// MARK: - 工作时间信息
struct WorkingTimeInfo {
    let startTime: String
    let endTime: String
    let workedHours: Double
    let totalWorkingHours: Double
    let hourlyRate: Double
    let isCurrentlyWorkingTime: Bool
    let timeBasedEarnings: Double
    let isAutoCalculateEnabled: Bool
}

// MARK: - 发薪日信息
struct PaydayInfo {
    let paydaySettings: PaydaySettings
    let daysUntilNextPayday: Int
    let nextPaydayDate: Date?
} 