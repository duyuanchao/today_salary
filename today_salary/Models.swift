import Foundation

// MARK: - 计算方式枚举
enum CalculationMethod: String, CaseIterable, Codable {
    case naturalDays = "natural_days"
    case workingDays = "working_days"
    
    var displayName: String {
        switch self {
        case .naturalDays:
            return "Natural Days (All days)"
        case .workingDays:
            return "Working Days (Mon-Fri)"
        }
    }
    
    var description: String {
        switch self {
        case .naturalDays:
            return "Calculate based on all days in the month"
        case .workingDays:
            return "Calculate based on working days only (excludes weekends)"
        }
    }
}

// MARK: - 工作时间设置
struct WorkingHours: Codable {
    var startTime: Date
    var endTime: Date
    var isAutoCalculateEnabled: Bool
    
    init() {
        let calendar = Calendar.current
        // 默认9:00 AM - 5:00 PM
        self.startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        self.endTime = calendar.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
        self.isAutoCalculateEnabled = true
    }
    
    /// 获取工作时长（小时）
    var workingHoursPerDay: Double {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.hour, .minute], from: startTime)
        let end = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let endMinutes = (end.hour ?? 0) * 60 + (end.minute ?? 0)
        
        let totalMinutes = endMinutes > startMinutes ? endMinutes - startMinutes : (24 * 60 - startMinutes + endMinutes)
        return Double(totalMinutes) / 60.0
    }
    
    /// 格式化时间显示
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
    
    /// 检查当前是否在工作时间内
    func isCurrentlyWorkingTime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTimeComp = calendar.dateComponents([.hour, .minute], from: startTime)
        let endTimeComp = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        let startMinutes = (startTimeComp.hour ?? 0) * 60 + (startTimeComp.minute ?? 0)
        let endMinutes = (endTimeComp.hour ?? 0) * 60 + (endTimeComp.minute ?? 0)
        
        if endMinutes > startMinutes {
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // 跨夜班次
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
    
    /// 计算当前已工作的小时数
    func getWorkedHoursToday() -> Double {
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.dateComponents([.hour, .minute], from: now)
        let startTimeComp = calendar.dateComponents([.hour, .minute], from: startTime)
        
        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        let startMinutes = (startTimeComp.hour ?? 0) * 60 + (startTimeComp.minute ?? 0)
        
        // 如果当前时间在工作开始时间之前，返回0
        if currentMinutes < startMinutes {
            return 0
        }
        
        // 如果当前时间在工作时间内或之后
        let workedMinutes = min(currentMinutes - startMinutes, Int(workingHoursPerDay * 60))
        return max(0, Double(workedMinutes) / 60.0)
    }
}

// MARK: - 发薪日设置
struct PaydaySettings: Codable {
    var paydayOfMonth: Int // 每月的第几天发薪（1-31）
    var isLastDayOfMonth: Bool // 是否为月末发薪
    
    init() {
        self.paydayOfMonth = 1
        self.isLastDayOfMonth = false
    }
    
    /// 获取当前月份的发薪日期
    func getPaydayForCurrentMonth() -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        if isLastDayOfMonth {
            // 月末发薪
            let nextMonth = calendar.date(from: DateComponents(year: year, month: month + 1, day: 1))!
            return calendar.date(byAdding: .day, value: -1, to: nextMonth)
        } else {
            // 指定日期发薪
            let daysInMonth = DateCalculator.daysInMonth()
            let actualDay = min(paydayOfMonth, daysInMonth)
            return calendar.date(from: DateComponents(year: year, month: month, day: actualDay))
        }
    }
    
    /// 获取指定月份的发薪日期
    func getPaydayForMonth(_ date: Date) -> Date? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        if isLastDayOfMonth {
            let nextMonth = calendar.date(from: DateComponents(year: year, month: month + 1, day: 1))!
            return calendar.date(byAdding: .day, value: -1, to: nextMonth)
        } else {
            let daysInMonth = DateCalculator.daysInMonth(for: date)
            let actualDay = min(paydayOfMonth, daysInMonth)
            return calendar.date(from: DateComponents(year: year, month: month, day: actualDay))
        }
    }
    
    /// 获取距离下次发薪的天数
    func getDaysUntilNextPayday() -> Int {
        guard let payday = getPaydayForCurrentMonth() else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let paydayStart = calendar.startOfDay(for: payday)
        
        if paydayStart >= today {
            // 本月还未发薪
            return calendar.dateComponents([.day], from: today, to: paydayStart).day ?? 0
        } else {
            // 本月已发薪，计算下月发薪日
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!
            guard let nextPayday = getPaydayForMonth(nextMonth) else { return 0 }
            
            return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: nextPayday)).day ?? 0
        }
    }
    
    var displayText: String {
        if isLastDayOfMonth {
            return "Last day of month"
        } else {
            return "Day \(paydayOfMonth) of month"
        }
    }
}

// MARK: - 日期计算工具
struct DateCalculator {
    
    /// 获取指定月份的天数
    static func daysInMonth(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)
        return range?.count ?? 30
    }
    
    /// 获取指定月份的工作日数量（周一到周五）
    static func workingDaysInMonth(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return 22 // 默认工作日数
        }
        
        var workingDays = 0
        for day in monthRange {
            if let dayDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                let weekday = calendar.component(.weekday, from: dayDate)
                // 周一到周五 (weekday 2-6, 因为周日是1)
                if weekday >= 2 && weekday <= 6 {
                    workingDays += 1
                }
            }
        }
        
        return workingDays
    }
    
    /// 获取当前月份剩余的天数
    static func remainingDaysInMonth(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let today = calendar.component(.day, from: date)
        let totalDays = daysInMonth(for: date)
        return max(0, totalDays - today + 1)
    }
    
    /// 获取当前月份剩余的工作日数量
    static func remainingWorkingDaysInMonth(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let today = calendar.component(.day, from: date)
        
        guard let monthRange = calendar.range(of: .day, in: .month, for: date) else {
            return 0
        }
        
        var remainingWorkingDays = 0
        for day in today...monthRange.upperBound-1 {
            if let dayDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                let weekday = calendar.component(.weekday, from: dayDate)
                if weekday >= 2 && weekday <= 6 { // 周一到周五
                    remainingWorkingDays += 1
                }
            }
        }
        
        return remainingWorkingDays
    }
    
    /// 检查今天是否为工作日
    static func isTodayWorkingDay() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday >= 2 && weekday <= 6 // 周一到周五
    }
}

// MARK: - 用户配置模型
struct UserProfile: Codable {
    var monthlyIncome: Double
    var dailyTarget: Double
    var isSetup: Bool
    var userName: String?
    var calculationMethod: CalculationMethod
    var workingHours: WorkingHours
    var paydaySettings: PaydaySettings
    
    init() {
        self.monthlyIncome = 0
        self.dailyTarget = 0
        self.isSetup = false
        self.userName = nil
        self.calculationMethod = .naturalDays
        self.workingHours = WorkingHours()
        self.paydaySettings = PaydaySettings()
    }
    
    mutating func setupProfile(monthlyIncome: Double, userName: String? = nil, calculationMethod: CalculationMethod = .naturalDays) {
        self.monthlyIncome = monthlyIncome
        self.calculationMethod = calculationMethod
        self.dailyTarget = calculateDailyTarget()
        self.isSetup = true
        self.userName = userName
    }
    
    /// 计算每日目标收入
    private func calculateDailyTarget() -> Double {
        switch calculationMethod {
        case .naturalDays:
            let daysInMonth = DateCalculator.daysInMonth()
            return monthlyIncome / Double(daysInMonth)
        case .workingDays:
            let workingDays = DateCalculator.workingDaysInMonth()
            return monthlyIncome / Double(workingDays)
        }
    }
    
    /// 重新计算每日目标（当月份变化时调用）
    mutating func recalculateDailyTarget() {
        self.dailyTarget = calculateDailyTarget()
    }
    
    /// 获取当前月份信息
    func getCurrentMonthInfo() -> MonthInfo {
        let totalDays = DateCalculator.daysInMonth()
        let workingDays = DateCalculator.workingDaysInMonth()
        let remainingDays = DateCalculator.remainingDaysInMonth()
        let remainingWorkingDays = DateCalculator.remainingWorkingDaysInMonth()
        
        return MonthInfo(
            totalDays: totalDays,
            workingDays: workingDays,
            remainingDays: remainingDays,
            remainingWorkingDays: remainingWorkingDays,
            dailyTarget: dailyTarget,
            calculationMethod: calculationMethod
        )
    }
    
    /// 计算基于时间的当前收入
    func calculateTimeBasedEarnings() -> Double {
        // 如果未启用自动计算，返回0
        guard workingHours.isAutoCalculateEnabled else { return 0 }
        
        // 检查今天是否为工作日（如果使用工作日计算方式）
        if calculationMethod == .workingDays && !DateCalculator.isTodayWorkingDay() {
            return 0
        }
        
        // 获取今天已工作的小时数
        let workedHours = workingHours.getWorkedHoursToday()
        
        // 计算每小时收入
        let hourlyRate = dailyTarget / workingHours.workingHoursPerDay
        
        // 返回已赚取的收入
        return workedHours * hourlyRate
    }
}

// MARK: - 月份信息
struct MonthInfo {
    let totalDays: Int
    let workingDays: Int
    let remainingDays: Int
    let remainingWorkingDays: Int
    let dailyTarget: Double
    let calculationMethod: CalculationMethod
    
    var relevantDays: Int {
        switch calculationMethod {
        case .naturalDays:
            return totalDays
        case .workingDays:
            return workingDays
        }
    }
    
    var relevantRemainingDays: Int {
        switch calculationMethod {
        case .naturalDays:
            return remainingDays
        case .workingDays:
            return remainingWorkingDays
        }
    }
}

// MARK: - 每日收入记录
struct DailyEarnings: Codable, Identifiable {
    let id = UUID()
    let date: Date
    var amount: Double
    var isGoalReached: Bool
    
    init(date: Date = Date(), amount: Double = 0) {
        self.date = date
        self.amount = amount
        self.isGoalReached = false
    }
    
    mutating func updateAmount(_ newAmount: Double, target: Double) {
        self.amount = newAmount
        self.isGoalReached = newAmount >= target
    }
}

// MARK: - 成就系统
struct Achievement: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    let unlockDate: Date?
    
    init(title: String, description: String, icon: String) {
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = false
        self.unlockDate = nil
    }
}

// MARK: - 每日挑战
struct Challenge: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let targetAmount: Double
    let reward: String
    var isCompleted: Bool
    let date: Date
    
    init(title: String, description: String, targetAmount: Double, reward: String, date: Date = Date()) {
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.reward = reward
        self.isCompleted = false
        self.date = date
    }
}

// MARK: - 趣味提示类型
enum MotivationalMessage {
    case excellent
    case good
    case average
    case needsWork
    case justStarted
    
    var message: String {
        switch self {
        case .excellent:
            return "Amazing! You're crushing it today! 🚀"
        case .good:
            return "Great job! You're on track for success! ⭐"
        case .average:
            return "Nice progress! Keep pushing forward! 💪"
        case .needsWork:
            return "Every step counts! You've got this! 🌟"
        case .justStarted:
            return "Your journey to success starts now! 🎯"
        }
    }
    
    var localizedReward: String {
        switch self {
        case .excellent:
            return "Treat yourself to a fancy Starbucks! ☕"
        case .good:
            return "Time for a movie night! 🍿"
        case .average:
            return "Grab a delicious lunch! 🍔"
        case .needsWork:
            return "A small coffee to fuel up! ☕"
        case .justStarted:
            return "Start strong, finish stronger! ��"
        }
    }
} 