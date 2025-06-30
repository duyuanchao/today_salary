import Foundation
import UserNotifications

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var userProfile = UserProfile()
    @Published var todayEarnings = DailyEarnings()
    @Published var achievements: [Achievement] = []
    @Published var challenges: [Challenge] = []
    @Published var currentProgress: Double = 0.0
    
    private let userProfileKey = "UserProfile"
    private let earningsKey = "DailyEarnings"
    private let achievementsKey = "Achievements"
    private let challengesKey = "Challenges"
    private let lastCalculationMonthKey = "LastCalculationMonth"
    
    // 定时器用于自动更新收入
    private var earningsUpdateTimer: Timer?
    
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
    }
    
    // MARK: - 自动收入更新
    private func startAutoEarningsUpdate() {
        // 每分钟更新一次基于时间的收入
        earningsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeBasedEarnings()
        }
        
        // 立即执行一次更新
        updateTimeBasedEarnings()
    }
    
    private func stopAutoEarningsUpdate() {
        earningsUpdateTimer?.invalidate()
        earningsUpdateTimer = nil
    }
    
    private func updateTimeBasedEarnings() {
        guard userProfile.isSetup && userProfile.workingHours.isAutoCalculateEnabled else { return }
        
        let timeBasedEarnings = userProfile.calculateTimeBasedEarnings()
        
        // 只有当自动计算的收入大于当前记录的收入时才更新
        if timeBasedEarnings > todayEarnings.amount {
            todayEarnings.updateAmount(timeBasedEarnings, target: userProfile.dailyTarget)
            updateProgress()
            checkAchievements()
            checkChallenges()
            saveData()
        }
    }
    
    // MARK: - 月份检查和重新计算
    private func checkAndUpdateMonthlyCalculation() {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let currentMonthKey = "\(currentYear)-\(currentMonth)"
        
        let lastCalculationMonth = UserDefaults.standard.string(forKey: lastCalculationMonthKey)
        
        if lastCalculationMonth != currentMonthKey {
            // 月份已变化，重新计算每日目标
            userProfile.recalculateDailyTarget()
            UserDefaults.standard.set(currentMonthKey, forKey: lastCalculationMonthKey)
            saveData()
            
            // 清除上个月的挑战，生成新的挑战
            removeOldChallenges()
            generateDailyChallenge()
        }
    }
    
    private func removeOldChallenges() {
        let calendar = Calendar.current
        let today = Date()
        challenges.removeAll { challenge in
            !calendar.isDate(challenge.date, inSameDayAs: today)
        }
    }
    
    // MARK: - 数据加载与保存
    func loadData() {
        // 加载用户配置
        if let data = UserDefaults.standard.data(forKey: userProfileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
        
        // 加载今日收入
        loadTodayEarnings()
        
        // 加载成就
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let achievements = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = achievements
        }
        
        // 加载挑战
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let challenges = try? JSONDecoder().decode([Challenge].self, from: data) {
            self.challenges = challenges
        }
        
        updateProgress()
    }
    
    func saveData() {
        // 保存用户配置
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: userProfileKey)
        }
        
        // 保存今日收入
        saveTodayEarnings()
        
        // 保存成就
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
        
        // 保存挑战
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: challengesKey)
        }
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
        todayEarnings.updateAmount(amount, target: userProfile.dailyTarget)
        updateProgress()
        checkAchievements()
        checkChallenges()
        saveData()
        
        if todayEarnings.isGoalReached {
            scheduleSuccessNotification()
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
        
        saveData()
        generateDailyChallenge()
        
        // 启动自动更新
        startAutoEarningsUpdate()
    }
    
    func updateWorkingHours(_ workingHours: WorkingHours) {
        userProfile.workingHours = workingHours
        saveData()
        
        // 如果启用了自动计算，立即更新收入
        if workingHours.isAutoCalculateEnabled {
            updateTimeBasedEarnings()
        }
    }
    
    func updatePaydaySettings(_ paydaySettings: PaydaySettings) {
        userProfile.paydaySettings = paydaySettings
        saveData()
    }
    
    private func updateProgress() {
        if userProfile.dailyTarget > 0 {
            currentProgress = min(todayEarnings.amount / userProfile.dailyTarget, 1.0)
        } else {
            currentProgress = 0.0
        }
    }
    
    // MARK: - 月份信息获取
    func getCurrentMonthInfo() -> MonthInfo {
        return userProfile.getCurrentMonthInfo()
    }
    
    func getDetailedProgressInfo() -> DetailedProgressInfo {
        let monthInfo = getCurrentMonthInfo()
        let totalEarnings = todayEarnings.amount
        let targetForToday = userProfile.dailyTarget
        let remainingTarget = max(0, userProfile.monthlyIncome - getTotalMonthEarnings())
        let avgNeededPerDay = remainingTarget / Double(max(1, monthInfo.relevantRemainingDays))
        
        return DetailedProgressInfo(
            monthInfo: monthInfo,
            todayEarnings: totalEarnings,
            todayTarget: targetForToday,
            monthlyTarget: userProfile.monthlyIncome,
            totalMonthEarnings: getTotalMonthEarnings(),
            remainingTarget: remainingTarget,
            averageNeededPerRemainingDay: avgNeededPerDay,
            isOnTrack: avgNeededPerDay <= targetForToday * 1.1 // 10%容错
        )
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
        saveData()
    }
    
    private func checkChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        for i in challenges.indices {
            if Calendar.current.isDate(challenges[i].date, inSameDayAs: today) &&
               !challenges[i].isCompleted &&
               todayEarnings.amount >= challenges[i].targetAmount {
                challenges[i].isCompleted = true
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