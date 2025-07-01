import SwiftUI

struct MainView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var todayEarningsInput: String = ""
    @State private var showingSettings = false
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
                
                // Today's earnings input - Enhanced Design
                EarningsInputCard(
                    earningsInput: $todayEarningsInput,
                    isFocused: $isEarningsFieldFocused,
                    dailyTarget: dataManager.userProfile.dailyTarget,
                    currentAmount: dataManager.todayEarnings.amount,
                    isAutoEnabled: dataManager.userProfile.workingHours.isAutoCalculateEnabled,
                    monthInfo: dataManager.getCurrentMonthInfo(),
                    onAmountChange: { amount in
                        dataManager.updateTodayEarnings(amount)
                        HapticManager.selection()
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
                
                // Premium Progress Display
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
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text("Current")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Text("$\(String(format: "%.2f", dataManager.todayEarnings.amount))")
                                    .font(DesignTokens.Typography.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text("Target")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                Text("$\(String(format: "%.2f", dataManager.userProfile.dailyTarget))")
                                    .font(DesignTokens.Typography.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                            
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
                        
                        Spacer()
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .premiumCard()
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // Enhanced Motivational Message
                MotivationalCard(message: dataManager.getMotivationalMessage())
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // Enhanced Stats Display
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
        }
        .onChange(of: dataManager.todayEarnings.amount) { newAmount in
            todayEarningsInput = String(format: "%.2f", newAmount)
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
    private func hideKeyboard() {
        isEarningsFieldFocused = false
    }
} 