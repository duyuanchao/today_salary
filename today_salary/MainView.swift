import SwiftUI

struct MainView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var showingSettings = false
    
    // 性能优化：缓存复杂计算结果
    @State private var cachedProgressInfo: DetailedProgressInfo?
    @State private var cachedPaydayInfo: PaydayInfo?
    @State private var lastUpdateTime = Date()
    private let cacheTimeout: TimeInterval = 30
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) { // 性能优化：使用LazyVStack
                    // Premium Greeting Header
                    GreetingHeader(userName: dataManager.userProfile.userName)
                    
                    // Working status (if auto-calculate is enabled)
                    if dataManager.userProfile.workingHours.isAutoCalculateEnabled {
                        WorkingStatusCard(workingTimeInfo: dataManager.getWorkingTimeInfo())
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                
                    // Today's earnings input - Enhanced Design
                    earningsInputSection
                    
                    // Premium Progress Display
                    progressDisplaySection
                    
                    // Enhanced Motivational Message
                    MotivationalCard(message: dataManager.getMotivationalMessage())
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    // Enhanced Stats Display
                    statsSection
                    
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
            .contentShape(Rectangle())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: settingsButton)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            refreshCache()
            trackScreenView()
        }
    }
    
    // MARK: - View Sections
    private var earningsInputSection: some View {
        EarningsDisplayCard(
            dailyTarget: dataManager.userProfile.dailyTarget,
            currentAmount: dataManager.todayEarnings.amount,
            isAutoEnabled: dataManager.userProfile.workingHours.isAutoCalculateEnabled,
            monthInfo: dataManager.getCurrentMonthInfo()
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var progressDisplaySection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            HStack {
                Text("Today's Progress")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Spacer()
            }
            
            HStack(spacing: DesignTokens.Spacing.xl) {
                // Animated Progress Ring
                AnimatedProgressRing(
                    progress: dataManager.currentProgress,
                    colors: progressColors
                )
                
                // Progress Stats
                progressStatsView
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var progressStatsView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Current Amount
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Current")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text("$\(String(format: "%.2f", dataManager.todayEarnings.amount))")
                    .font(DesignTokens.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            // Target Amount
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Target")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text("$\(String(format: "%.2f", dataManager.userProfile.dailyTarget))")
                    .font(DesignTokens.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            // Status
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Status")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text(progressStatus)
                    .font(DesignTokens.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(progressStatusColor)
            }
        }
    }
    
    private var statsSection: some View {
        Group {
            let progressInfo = getCachedProgressInfo()
            let paydayInfo = getCachedPaydayInfo()
            
            StatsGrid(
                monthInfo: progressInfo.monthInfo,
                remainingTarget: progressInfo.remainingTarget,
                averageNeeded: progressInfo.averageNeededPerRemainingDay,
                isOnTrack: progressInfo.isOnTrack,
                daysUntilPayday: paydayInfo.daysUntilNextPayday
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
    
    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundColor(DesignTokens.Colors.primary)
        }
    }
    
    // MARK: - Computed Properties
    private var progressColors: [Color] {
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
    private func trackScreenView() {
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async {
            firebaseManager.trackScreenView(screenName: "main")
        }
    }
    
    private func openSettings() {
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async {
            firebaseManager.trackButtonTap(buttonName: "settings", screenName: "main")
        }
        
        showingSettings = true
        HapticManager.impact(.light)
    }
    
    // MARK: - 性能优化：缓存管理
    private func refreshCache() {
        lastUpdateTime = Date()
        cachedProgressInfo = nil
        cachedPaydayInfo = nil
    }
    
    private func isCacheValid() -> Bool {
        Date().timeIntervalSince(lastUpdateTime) < cacheTimeout
    }
    
    private func getCachedProgressInfo() -> DetailedProgressInfo {
        if let cached = cachedProgressInfo, isCacheValid() {
            return cached
        }
        
        let progressInfo = dataManager.getDetailedProgressInfo()
        cachedProgressInfo = progressInfo
        return progressInfo
    }
    
    private func getCachedPaydayInfo() -> PaydayInfo {
        if let cached = cachedPaydayInfo, isCacheValid() {
            return cached
        }
        
        let paydayInfo = dataManager.getPaydayInfo()
        cachedPaydayInfo = paydayInfo
        return paydayInfo
    }
} 