import SwiftUI
import Combine

// MARK: - Input Debouncer
class InputDebouncer: ObservableObject {
    @Published var debouncedText = ""
    private var workItem: DispatchWorkItem?
    
    func debounce(_ text: String, delay: TimeInterval = 0.3) {
        workItem?.cancel()
        workItem = DispatchWorkItem {
            DispatchQueue.main.async {
                self.debouncedText = text
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

struct MainView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var inputDebouncer = InputDebouncer()
    @State private var todayEarningsInput: String = ""
    @State private var showingSettings = false
    @State private var showExpensiveComponents = false
    @FocusState private var isEarningsFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Premium Greeting Header
                    GreetingHeader(userName: dataManager.userProfile.userName)
                    
                    // Working status (if auto-calculate is enabled)
                    if dataManager.userProfile.workingHours.isAutoCalculateEnabled {
                        WorkingStatusCard(workingTimeInfo: dataManager.getWorkingTimeInfo())
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                
                    // Today's earnings input - Enhanced Design with debouncing
                    OptimizedEarningsInputCard(
                        earningsInput: $todayEarningsInput,
                        isFocused: $isEarningsFieldFocused,
                        dailyTarget: dataManager.userProfile.dailyTarget,
                        currentAmount: dataManager.todayEarnings.amount,
                        isAutoEnabled: dataManager.userProfile.workingHours.isAutoCalculateEnabled,
                        monthInfo: dataManager.getCurrentMonthInfo(),
                        onAmountChange: { amount in
                            // 使用防抖避免频繁更新
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                dataManager.updateTodayEarnings(amount)
                                HapticManager.selection()
                            }
                        }
                    )
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                hideKeyboard()
                            }
                            .foregroundColor(DesignTokens.Colors.primary)
                            .fontWeight(.medium)
                        }
                    }
                    
                    // 异步加载重要组件
                    if showExpensiveComponents {
                        // Premium Progress Display
                        OptimizedProgressSection()
                        
                        // Enhanced Motivational Message
                        MotivationalCard(message: dataManager.getMotivationalMessage())
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                        
                        // Enhanced Stats Display
                        OptimizedStatsSection()
                    } else {
                        // 显示加载占位符
                        LoadingPlaceholder()
                    }
                    
                    Spacer(minLength: DesignTokens.Spacing.xl)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
            .background(
                LinearGradient(
                    colors: [DesignTokens.Colors.background, DesignTokens.Colors.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button(action: {
                    firebaseManager.trackButtonTap(buttonName: "settings", screenName: "main")
                    hideKeyboard()
                    showingSettings = true
                    HapticManager.impact(.light)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            todayEarningsInput = String(format: "%.2f", dataManager.todayEarnings.amount)
            
            // Firebase分析：记录屏幕访问
            firebaseManager.trackScreenView(screenName: "main")
            
            // 延迟加载重要组件以提高初始响应速度
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showExpensiveComponents = true
                }
            }
        }
        .onChange(of: dataManager.todayEarnings.amount) { newAmount in
            // 只在有显著变化时更新输入框
            let formattedAmount = String(format: "%.2f", newAmount)
            if todayEarningsInput != formattedAmount {
                todayEarningsInput = formattedAmount
            }
        }
        .onChange(of: inputDebouncer.debouncedText) { newValue in
            if let amount = Double(newValue), amount != dataManager.todayEarnings.amount {
                dataManager.updateTodayEarnings(amount)
            }
        }
    }
    
    // MARK: - Optimized Progress Section
    @ViewBuilder
    private func OptimizedProgressSection() -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            HStack {
                Text("Today's Progress")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: DesignTokens.Spacing.xl) {
                // Animated Progress Ring - 使用优化的组件
                OptimizedProgressRing(
                    progress: dataManager.currentProgress,
                    colors: progressColors
                )
                
                // Progress Stats
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    StatItem(
                        title: "Current",
                        value: "$\(String(format: "%.2f", dataManager.todayEarnings.amount))",
                        color: DesignTokens.Colors.textPrimary
                    )
                    
                    StatItem(
                        title: "Target",
                        value: "$\(String(format: "%.2f", dataManager.userProfile.dailyTarget))",
                        color: DesignTokens.Colors.primary
                    )
                    
                    StatItem(
                        title: "Status",
                        value: progressStatus,
                        color: progressStatusColor
                    )
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Optimized Stats Section
    @ViewBuilder
    private func OptimizedStatsSection() -> some View {
        let progressInfo = dataManager.getDetailedProgressInfo()
        let paydayInfo = dataManager.getPaydayInfo()
        
        StatsGrid(
            monthInfo: progressInfo.monthInfo,
            remainingTarget: progressInfo.remainingTarget,
            averageNeeded: progressInfo.averageNeededPerRemainingDay,
            isOnTrack: progressInfo.isOnTrack,
            daysUntilPayday: paydayInfo.daysUntilNextPayday
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Loading Placeholder
    @ViewBuilder
    private func LoadingPlaceholder() -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Progress section placeholder
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.border)
                        .frame(width: 120, height: 20)
                    Spacer()
                }
                
                HStack(spacing: DesignTokens.Spacing.xl) {
                    Circle()
                        .fill(DesignTokens.Colors.border)
                        .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignTokens.Colors.border)
                                .frame(width: 80, height: 16)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .premiumCard()
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .redacted(reason: .placeholder)
        }
    }
    
    // MARK: - Computed Properties (cached for performance)
    private var progressColors: [Color] {
        // 使用缓存避免重复计算
        switch dataManager.currentProgress {
        case 0.0..<0.3:
            return [DesignTokens.Colors.error, Color(hex: "#FF6B6B")]
        case 0.3..<0.7:
            return DesignTokens.Colors.warningGradient
        case 0.7..<1.0:
            return DesignTokens.Colors.primaryGradient
        default:
            return DesignTokens.Colors.successGradient
        }
    }
    
    private var progressStatus: String {
        switch dataManager.currentProgress {
        case 0.0..<0.3:
            return "Getting Started"
        case 0.3..<0.7:
            return "Making Progress"
        case 0.7..<1.0:
            return "Almost There!"
        default:
            return "Goal Achieved!"
        }
    }
    
    private var progressStatusColor: Color {
        switch dataManager.currentProgress {
        case 0.0..<0.3:
            return DesignTokens.Colors.error
        case 0.3..<0.7:
            return DesignTokens.Colors.warning
        case 0.7..<1.0:
            return DesignTokens.Colors.primary
        default:
            return DesignTokens.Colors.success
        }
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        isEarningsFieldFocused = false
    }
}

// MARK: - Optimized Components

// 优化的输入卡片组件
struct OptimizedEarningsInputCard: View, Equatable {
    @Binding var earningsInput: String
    @FocusState.Binding var isFocused: Bool
    let dailyTarget: Double
    let currentAmount: Double
    let isAutoEnabled: Bool
    let monthInfo: MonthInfo
    let onAmountChange: (Double) -> Void
    
    @State private var showingHint = false
    @StateObject private var inputDebouncer = InputDebouncer()
    
    static func == (lhs: OptimizedEarningsInputCard, rhs: OptimizedEarningsInputCard) -> Bool {
        // 减少不必要的重绘
        lhs.dailyTarget == rhs.dailyTarget &&
        lhs.currentAmount == rhs.currentAmount &&
        lhs.isAutoEnabled == rhs.isAutoEnabled
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            HStack {
                Text("Today's Earnings")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                if isAutoEnabled {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(DesignTokens.Colors.success)
                            .frame(width: 8, height: 8)
                            .scaleEffect(showingHint ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(), value: showingHint)
                        
                        Text("Auto-updating")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.success)
                    }
                    .onAppear {
                        showingHint = true
                    }
                }
            }
            
            // Amount Input - 优化输入处理
            HStack {
                Text("$")
                    .font(DesignTokens.Typography.largeTitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                TextField("0.00", text: $earningsInput)
                    .font(DesignTokens.Typography.largeTitle)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.leading)
                    .onChange(of: earningsInput) { newValue in
                        // 使用防抖避免频繁调用
                        inputDebouncer.debounce(newValue)
                    }
                    .onChange(of: inputDebouncer.debouncedText) { debouncedValue in
                        if let amount = Double(debouncedValue) {
                            onAmountChange(amount)
                        }
                    }
                    .onTapGesture {
                        HapticManager.selection()
                    }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceSecondary)
            .cornerRadius(DesignTokens.CornerRadius.md)
            
            // Target and Progress Info - 缓存计算结果
            VStack(spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Text("Target: $\(String(format: "%.2f", dailyTarget))")
                        .font(DesignTokens.Typography.callout)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    DifferenceText(current: currentAmount, target: dailyTarget)
                }
                
                HStack {
                    Text("Method: \(monthInfo.calculationMethod.displayName)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    
                    Spacer()
                    
                    Text("This month: \(monthInfo.relevantDays) days")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassMorphism()
        .onTapGesture {
            if !isFocused {
                HapticManager.selection()
            }
        }
        // 双击手势设置目标金额
        .onTapGesture(count: 2) {
            earningsInput = String(format: "%.2f", dailyTarget)
            onAmountChange(dailyTarget)
            HapticManager.impact(.medium)
        }
    }
}

// 差值显示组件 - 减少重复计算
struct DifferenceText: View {
    let current: Double
    let target: Double
    
    private var difference: Double {
        current - target
    }
    
    var body: some View {
        if difference >= 0 {
            Text("+$\(String(format: "%.2f", difference))")
                .font(DesignTokens.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.success)
        } else {
            Text("$\(String(format: "%.2f", abs(difference))) to go")
                .font(DesignTokens.Typography.callout)
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.warning)
        }
    }
}

// 优化的进度环组件
struct OptimizedProgressRing: View, Equatable {
    let progress: Double
    let colors: [Color]
    
    @State private var animatedProgress: Double = 0
    
    static func == (lhs: OptimizedProgressRing, rhs: OptimizedProgressRing) -> Bool {
        abs(lhs.progress - rhs.progress) < 0.01
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(DesignTokens.Colors.border, lineWidth: 12)
                .frame(width: 120, height: 120)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
            
            // Center content
            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))%")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Complete")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .animation(.easeInOut(duration: 0.3), value: animatedProgress)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newProgress
            }
        }
    }
} 