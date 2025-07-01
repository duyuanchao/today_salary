//
//  PerformanceTests.swift
//  today_salary
//
//  性能测试和基准测试工具
//

import Foundation
import SwiftUI
import Darwin.Mach

#if DEBUG
struct PerformanceTests {
    
    // MARK: - 缓存性能测试
    static func testCachePerformance() {
        let dataManager = DataManager.shared
        
        print("🧪 开始缓存性能测试...")
        
        // 测试无缓存情况
        let startTime1 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            _ = dataManager.getDetailedProgressInfo()
        }
        let noCacheTime = CFAbsoluteTimeGetCurrent() - startTime1
        
        // 测试有缓存情况（第二次调用应该使用缓存）
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<100 {
            _ = dataManager.getDetailedProgressInfo()
        }
        let cachedTime = CFAbsoluteTimeGetCurrent() - startTime2
        
        print("📊 缓存性能测试结果:")
        print("   无缓存时间: \(String(format: "%.4f", noCacheTime))秒")
        print("   有缓存时间: \(String(format: "%.4f", cachedTime))秒")
        print("   性能提升: \(String(format: "%.1f", noCacheTime/cachedTime))倍")
    }
    
    // MARK: - 数据保存性能测试
    static func testSavePerformance() {
        let dataManager = DataManager.shared
        
        print("🧪 开始数据保存性能测试...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 模拟快速连续保存操作
        for i in 0..<50 {
            dataManager.updateTodayEarnings(Double(i))
        }
        
        let saveTime = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 数据保存性能测试结果:")
        print("   50次保存操作时间: \(String(format: "%.4f", saveTime))秒")
        print("   平均每次保存: \(String(format: "%.4f", saveTime/50))秒")
    }
    
    // MARK: - 内存使用测试
    static func testMemoryUsage() {
        print("🧪 开始内存使用测试...")
        
        let memoryBefore = getMemoryUsage()
        
        // 创建大量对象测试内存管理
        var objects: [DetailedProgressInfo] = []
        for _ in 0..<1000 {
            objects.append(DataManager.shared.getDetailedProgressInfo())
        }
        
        let memoryAfter = getMemoryUsage()
        
        // 清理对象
        objects.removeAll()
        
        let memoryAfterCleanup = getMemoryUsage()
        
        print("📊 内存使用测试结果:")
        print("   测试前内存: \(String(format: "%.2f", memoryBefore))MB")
        print("   测试后内存: \(String(format: "%.2f", memoryAfter))MB")
        print("   清理后内存: \(String(format: "%.2f", memoryAfterCleanup))MB")
        print("   内存增长: \(String(format: "%.2f", memoryAfter - memoryBefore))MB")
    }
    
    // MARK: - 触觉反馈性能测试
    static func testHapticPerformance() {
        print("🧪 开始触觉反馈性能测试...")
        
        // 预加载测试
        let startTime1 = CFAbsoluteTimeGetCurrent()
        HapticManager.prepare()
        let prepareTime = CFAbsoluteTimeGetCurrent() - startTime1
        
        // 触觉反馈响应时间测试
        let startTime2 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<10 {
            HapticManager.selection()
        }
        let hapticTime = CFAbsoluteTimeGetCurrent() - startTime2
        
        print("📊 触觉反馈性能测试结果:")
        print("   预加载时间: \(String(format: "%.4f", prepareTime))秒")
        print("   10次触觉反馈时间: \(String(format: "%.4f", hapticTime))秒")
        print("   平均响应时间: \(String(format: "%.4f", hapticTime/10))秒")
    }
    
    // MARK: - UI响应性能测试
    static func testUIPerformance() {
        print("🧪 开始UI响应性能测试...")
        
        let dataManager = DataManager.shared
        
        // 测试UI更新频率
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            DispatchQueue.main.async {
                dataManager.updateTodayEarnings(Double(i))
            }
        }
        
        let uiTime = CFAbsoluteTimeGetCurrent() - startTime
        
        print("📊 UI响应性能测试结果:")
        print("   100次UI更新时间: \(String(format: "%.4f", uiTime))秒")
        print("   平均每次更新: \(String(format: "%.4f", uiTime/100))秒")
    }
    
    // MARK: - 综合性能测试
    static func runAllTests() {
        print("🚀 开始综合性能测试...")
        print("=" * 50)
        
        testCachePerformance()
        print()
        
        testSavePerformance()
        print()
        
        testMemoryUsage()
        print()
        
        testHapticPerformance()
        print()
        
        testUIPerformance()
        print()
        
        print("=" * 50)
        print("✅ 所有性能测试完成")
    }
    
    // MARK: - 辅助方法
    static func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        } else {
            return 0
        }
    }
}

// MARK: - 性能监控器
class PerformanceMonitor: ObservableObject {
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMetrics() {
        metrics.memoryUsage = PerformanceTests.getMemoryUsage()
        metrics.timestamp = Date()
    }
}

struct PerformanceMetrics {
    var memoryUsage: Double = 0
    var timestamp: Date = Date()
    var cacheHitRate: Double = 0
    var averageResponseTime: Double = 0
}

// MARK: - 性能调试视图
struct PerformanceDebugView: View {
    @StateObject private var monitor = PerformanceMonitor()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("性能监控")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("内存使用: \(String(format: "%.2f", monitor.metrics.memoryUsage))MB")
                Text("更新时间: \(DateFormatter.localizedString(from: monitor.metrics.timestamp, dateStyle: .none, timeStyle: .medium))")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Button("运行性能测试") {
                PerformanceTests.runAllTests()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

// MARK: - String 重复操作符
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

#endif 