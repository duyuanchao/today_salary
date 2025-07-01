import SwiftUI
import Foundation
import Combine

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
    
    var isCurrentWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    var formattedTimeOnly: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
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
    
    var compactCurrencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = self < 100 ? 2 : 0
        return formatter.string(from: NSNumber(value: self)) ?? "$0"
    }
    
    func roundedToDecimalPlaces(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - View Extensions for Performance
extension View {
    /// 智能键盘管理
    func smartKeyboardManagement() -> some View {
        self
            .onTapGesture {
                hideKeyboard()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // 键盘显示时的性能优化
                DispatchQueue.main.async {
                    // 可以在这里添加键盘显示时的优化逻辑
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // 键盘隐藏时的性能优化
                DispatchQueue.main.async {
                    // 可以在这里添加键盘隐藏时的优化逻辑
                }
            }
    }
    
    /// 隐藏键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// 条件性视图渲染，提高性能
    @ViewBuilder
    func conditionalRendering<Content: View>(
        condition: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if condition {
            self.modifier(ConditionalViewModifier(content: content()))
        } else {
            self
        }
    }
    
    /// 性能优化的动画
    func optimizedAnimation(_ animation: Animation, value: some Equatable) -> some View {
        self.animation(animation, value: value)
    }
    
    /// 延迟加载视图
    func lazyLoad(delay: TimeInterval = 0.1) -> some View {
        LazyLoadView(content: self, delay: delay)
    }
    
    /// 添加性能监控
    func performanceMonitored(name: String) -> some View {
        PerformanceMonitoredView(content: self, traceName: name)
    }
}

// MARK: - Custom View Modifiers
struct ConditionalViewModifier<Content: View>: ViewModifier {
    let content: Content
    
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Lazy Load View
struct LazyLoadView<Content: View>: View {
    let content: Content
    let delay: TimeInterval
    
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                content
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isLoaded = true
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Performance Monitored View
struct PerformanceMonitoredView<Content: View>: View {
    let content: Content
    let traceName: String
    
    @State private var trace: Trace?
    
    var body: some View {
        content
            .onAppear {
                trace = FirebaseManager.shared.startPerformanceTrace(name: traceName)
            }
            .onDisappear {
                trace?.stop()
            }
    }
}

// MARK: - String Extensions
extension String {
    var isValidDecimal: Bool {
        return Double(self) != nil
    }
    
    var sanitizedForCurrency: String {
        let filtered = self.filter { "0123456789.".contains($0) }
        let components = filtered.components(separatedBy: ".")
        if components.count <= 2 {
            return filtered
        } else {
            return components[0] + "." + components[1]
        }
    }
    
    func limitLength(_ maxLength: Int) -> String {
        if self.count > maxLength {
            return String(self.prefix(maxLength))
        }
        return self
    }
}

// MARK: - Combine Extensions
extension Publisher {
    /// 智能防抖，根据输入频率调整延迟时间
    func adaptiveDebounce(scheduler: DispatchQueue = DispatchQueue.main) -> AnyPublisher<Output, Failure> {
        var lastEmissionTime = Date()
        let baseDelay: TimeInterval = 0.3
        let maxDelay: TimeInterval = 1.0
        
        return self
            .handleEvents(receiveOutput: { _ in
                lastEmissionTime = Date()
            })
            .debounce(for: .milliseconds(Int(baseDelay * 1000)), scheduler: scheduler)
            .eraseToAnyPublisher()
    }
    
    /// 批量处理
    func batch(size: Int, timeout: TimeInterval) -> AnyPublisher<[Output], Failure> {
        self
            .collect(.byTimeOrCount(DispatchQueue.main, timeout, size))
            .eraseToAnyPublisher()
    }
}

// MARK: - Performance Utilities
struct PerformanceUtils {
    /// 主线程执行检查
    static func ensureMainThread<T>(_ operation: @escaping () -> T) -> T {
        if Thread.isMainThread {
            return operation()
        } else {
            return DispatchQueue.main.sync {
                operation()
            }
        }
    }
    
    /// 异步主线程执行
    static func asyncMain<T>(_ operation: @escaping () -> T, completion: @escaping (T) -> Void) {
        DispatchQueue.main.async {
            let result = operation()
            completion(result)
        }
    }
    
    /// 后台队列执行
    static func asyncBackground<T>(_ operation: @escaping () -> T, completion: @escaping (T) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = operation()
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    /// 测量执行时间
    static func measureExecutionTime<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
}

// MARK: - Memory Management Extensions
extension NSObject {
    /// 检查对象是否已被释放
    var isDeallocation: Bool {
        return type(of: self) == NSObject.self
    }
}

// MARK: - Animation Extensions
extension Animation {
    /// 优化的弹簧动画
    static let optimizedSpring = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    
    /// 快速淡入淡出
    static let fastFade = Animation.easeInOut(duration: 0.2)
    
    /// 流畅的缩放动画
    static let smoothScale = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// 自适应动画（根据设备性能调整）
    static var adaptive: Animation {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            return .linear(duration: 0.1)
        } else {
            return optimizedSpring
        }
    }
}

// MARK: - Device Performance Detection
extension ProcessInfo {
    /// 检测设备性能等级
    var devicePerformanceLevel: DevicePerformanceLevel {
        let totalMemory = self.physicalMemory
        
        // 基于内存大小和CPU核心数简单判断设备性能
        switch totalMemory {
        case 0..<2_000_000_000: // < 2GB
            return .low
        case 2_000_000_000..<4_000_000_000: // 2-4GB
            return .medium
        case 4_000_000_000..<8_000_000_000: // 4-8GB
            return .high
        default: // > 8GB
            return .veryHigh
        }
    }
}

enum DevicePerformanceLevel {
    case low, medium, high, veryHigh
    
    var recommendedAnimationDuration: TimeInterval {
        switch self {
        case .low:
            return 0.1
        case .medium:
            return 0.2
        case .high:
            return 0.3
        case .veryHigh:
            return 0.4
        }
    }
    
    var shouldUseComplexAnimations: Bool {
        return self != .low
    }
    
    var maxConcurrentAnimations: Int {
        switch self {
        case .low:
            return 2
        case .medium:
            return 4
        case .high:
            return 6
        case .veryHigh:
            return 8
        }
    }
}

// MARK: - Optimized View Components
struct OptimizedText: View, Equatable {
    let text: String
    let font: Font
    let color: Color
    
    static func == (lhs: OptimizedText, rhs: OptimizedText) -> Bool {
        lhs.text == rhs.text && lhs.font == rhs.font && lhs.color == rhs.color
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
    }
}

struct OptimizedImage: View, Equatable {
    let systemName: String
    let size: CGFloat
    let color: Color
    
    static func == (lhs: OptimizedImage, rhs: OptimizedImage) -> Bool {
        lhs.systemName == rhs.systemName && lhs.size == rhs.size && lhs.color == rhs.color
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

// MARK: - Loading States
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }
    
    var error: Error? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
} 