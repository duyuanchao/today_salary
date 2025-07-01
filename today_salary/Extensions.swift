import SwiftUI
import Foundation
import UIKit

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

// MARK: - HapticManager Extension (使用DesignSystem中的定义)
extension HapticManager {
    // 预加载触觉反馈生成器，减少延迟
    static func prepare() {
        // 预加载所有类型的反馈生成器
        impact(.light)
        impact(.medium)
        impact(.heavy)
        selection()
        notification(.success)
    }
}

// MARK: - 性能优化工具
struct PerformanceOptimizer {
    // 节流函数，防止过于频繁的调用
    static func throttle<T>(_ interval: TimeInterval, on queue: DispatchQueue = .main, action: @escaping (T) -> Void) -> (T) -> Void {
        var lastCallTime: Date?
        
        return { input in
            let now = Date()
            if let lastCall = lastCallTime,
               now.timeIntervalSince(lastCall) < interval {
                return
            }
            
            lastCallTime = now
            queue.async {
                action(input)
            }
        }
    }
    
    // 防抖函数，延迟执行直到停止调用
    static func debounce<T>(_ interval: TimeInterval, on queue: DispatchQueue = .main, action: @escaping (T) -> Void) -> (T) -> Void {
        var workItem: DispatchWorkItem?
        
        return { input in
            workItem?.cancel()
            workItem = DispatchWorkItem {
                action(input)
            }
            
            if let workItem = workItem {
                queue.asyncAfter(deadline: .now() + interval, execute: workItem)
            }
        }
    }
}

// MARK: - 键盘管理
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Extensions
extension View {
    // 性能优化：减少重绘
    func redacted(when condition: Bool) -> some View {
        self.redacted(reason: condition ? .placeholder : [])
    }
    
    // 键盘隐藏手势
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
    
    // 条件性应用修饰符
    @ViewBuilder func conditionalModifier<Content: View>(
        condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - 异步图片加载优化
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - 文本格式化优化
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

// MARK: - 安全的类型转换
extension String {
    var safeDoubleValue: Double? {
        let cleanedString = self.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedString)
    }
    
    var safeCurrencyValue: String {
        guard let value = safeDoubleValue else { return "$0.00" }
        return NumberFormatter.currency.string(from: NSNumber(value: value)) ?? "$0.00"
    }
} 