import SwiftUI
import Foundation

// MARK: - Preview Extensions
extension DataManager {
    static func mockDataManager() -> DataManager {
        let manager = DataManager.shared
        manager.userProfile = UserProfile()
        manager.userProfile.setupProfile(monthlyIncome: 3000, userName: "John")
        manager.todayEarnings = DailyEarnings(amount: 75.50)
        manager.currentProgress = 0.75
        return manager
    }
}

// MARK: - Date Extensions
extension Date {
    func timeUntilEndOfDay() -> TimeInterval {
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: self).addingTimeInterval(24 * 60 * 60)
        return endOfDay.timeIntervalSince(self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Double Extensions
extension Double {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
} 