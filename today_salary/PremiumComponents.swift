import SwiftUI

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let colors: [Color]
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, 
         lineWidth: CGFloat = 12, 
         size: CGFloat = 120, 
         colors: [Color] = DesignTokens.Colors.primaryGradient,
         showPercentage: Bool = true) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.colors = colors
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(DesignTokens.Colors.border, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(DesignTokens.Animation.spring, value: animatedProgress)
            
            // Center content
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(DesignTokens.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Complete")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .animation(DesignTokens.Animation.easeInOut, value: animatedProgress)
            }
        }
        .onAppear {
            withAnimation(DesignTokens.Animation.spring.delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(DesignTokens.Animation.spring) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Premium Avatar
struct PremiumAvatar: View {
    let name: String?
    let size: CGFloat
    let gradientColors: [Color]
    
    init(name: String?, size: CGFloat = 50, gradientColors: [Color] = DesignTokens.Colors.primaryGradient) {
        self.name = name
        self.size = size
        self.gradientColors = gradientColors
    }
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Text(avatarText)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            )
            .shadow(color: DesignTokens.Shadow.medium, radius: 8, x: 0, y: 4)
    }
    
    private var avatarText: String {
        if let name = name, !name.isEmpty {
            return String(name.prefix(1).uppercased())
        } else {
            return "💰"
        }
    }
}

// MARK: - Greeting Header
struct GreetingHeader: View {
    let userName: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(greetingText)
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Ready to earn your goals?")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            PremiumAvatar(name: userName)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 0..<12:
            greeting = "Good Morning"
        case 12..<17:
            greeting = "Good Afternoon"
        default:
            greeting = "Good Evening"
        }
        
        if let name = userName {
            return "\(greeting), \(name)!"
        } else {
            return "\(greeting)!"
        }
    }
}

// MARK: - Enhanced Display Card
struct EarningsDisplayCard: View {
    let dailyTarget: Double
    let currentAmount: Double
    let isAutoEnabled: Bool
    let monthInfo: MonthInfo
    
    @State private var showingHint = false
    
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
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(), value: showingHint)
                        
                        Text("Auto-updating")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.success)
                    }
                    .onAppear {
                        showingHint = true
                    }
                } else {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "eye.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.info)
                        
                        Text("Display only")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.info)
                    }
                }
            }
            
            // Amount Display
            HStack {
                Text("$")
                    .font(DesignTokens.Typography.largeTitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(String(format: "%.2f", currentAmount))
                    .font(DesignTokens.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: currentAmount)
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceSecondary)
            .cornerRadius(DesignTokens.CornerRadius.md)
            
            // Target and Progress Info
            VStack(spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Text("Target: $\(String(format: "%.2f", dailyTarget))")
                        .font(DesignTokens.Typography.callout)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    let difference = currentAmount - dailyTarget
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
    }
}

// MARK: - Enhanced Motivational Card
struct MotivationalCard: View {
    let message: MotivationalMessage
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Icon with animation
            Image(systemName: iconForMessage)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(message.message)
                    .font(DesignTokens.Typography.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                Text(message.localizedReward)
                    .font(DesignTokens.Typography.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            LinearGradient(
                colors: gradientForMessage,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .shadow(color: DesignTokens.Shadow.medium, radius: 15, x: 0, y: 8)
        .onAppear {
            isAnimating = true
        }
    }
    
    private var iconForMessage: String {
        switch message {
        case .excellent:
            return "star.fill"
        case .good:
            return "checkmark.circle.fill"
        case .average:
            return "arrow.up.circle.fill"
        case .needsWork:
            return "flame.fill"
        case .justStarted:
            return "rocket.fill"
        }
    }
    
    private var gradientForMessage: [Color] {
        switch message {
        case .excellent:
            return [Color(hex: "#667eea"), Color(hex: "#764ba2")]
        case .good:
            return DesignTokens.Colors.successGradient
        case .average:
            return DesignTokens.Colors.warningGradient
        case .needsWork:
            return [DesignTokens.Colors.error, Color(hex: "#FF6B6B")]
        case .justStarted:
            return DesignTokens.Colors.primaryGradient
        }
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    let monthInfo: MonthInfo
    let remainingTarget: Double
    let averageNeeded: Double
    let isOnTrack: Bool
    let daysUntilPayday: Int
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if remainingTarget > 0 {
                // Month Progress
                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Text("Month Progress")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                    }
                    
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        StatItem(
                            title: "Remaining", 
                            value: "$\(String(format: "%.0f", remainingTarget))",
                            color: DesignTokens.Colors.warning
                        )
                        
                        StatItem(
                            title: "Days Left", 
                            value: "\(monthInfo.relevantRemainingDays)",
                            color: DesignTokens.Colors.info
                        )
                        
                        StatItem(
                            title: "Avg Needed", 
                            value: "$\(String(format: "%.0f", averageNeeded))",
                            color: isOnTrack ? DesignTokens.Colors.success : DesignTokens.Colors.error
                        )
                    }
                    
                    if !isOnTrack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignTokens.Colors.warning)
                            
                            Text("Behind target - need to increase daily earnings")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.warning)
                        }
                        .padding(.top, DesignTokens.Spacing.xs)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .premiumCard()
            }
            
            // Payday countdown
            if daysUntilPayday > 0 {
                PaydayCountdown(daysLeft: daysUntilPayday)
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(DesignTokens.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Payday Countdown
struct PaydayCountdown: View {
    let daysLeft: Int
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(DesignTokens.Colors.primary)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("Next Payday")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Text("\(daysLeft) days to go")
                    .font(DesignTokens.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            
            Spacer()
            
            // Countdown circles
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(0..<min(daysLeft, 7), id: \.self) { day in
                    Circle()
                        .fill(DesignTokens.Colors.primary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.5).delay(Double(day) * 0.1), value: daysLeft)
                }
                
                if daysLeft > 7 {
                    Text("+\(daysLeft - 7)")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
    }
}

// MARK: - Working Status Card
struct WorkingStatusCard: View {
    let workingTimeInfo: WorkingTimeInfo
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Status Header
            HStack {
                Image(systemName: workingTimeInfo.isCurrentlyWorkingTime ? "clock.fill" : "clock")
                    .foregroundColor(workingTimeInfo.isCurrentlyWorkingTime ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary)
                    .font(.title2)
                
                Text(workingTimeInfo.isCurrentlyWorkingTime ? "Currently Working" : "Off Hours")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(workingTimeInfo.isCurrentlyWorkingTime ? DesignTokens.Colors.success : DesignTokens.Colors.textSecondary)
                
                Spacer()
            }
            
            // Time Info
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Work Hours")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("\(workingTimeInfo.startTime) - \(workingTimeInfo.endTime)")
                        .font(DesignTokens.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text("Hours Today")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text("\(String(format: "%.1f", workingTimeInfo.workedHours))/\(String(format: "%.1f", workingTimeInfo.totalWorkingHours))")
                        .font(DesignTokens.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.info)
                }
            }
            
            // Progress Bar
            ProgressView(value: workingTimeInfo.workedHours / workingTimeInfo.totalWorkingHours)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.info))
                .scaleEffect(x: 1, y: 3)
                .animation(DesignTokens.Animation.spring, value: workingTimeInfo.workedHours)
            
            // Rates Info
            HStack {
                Text("Hourly Rate: $\(String(format: "%.2f", workingTimeInfo.hourlyRate))")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                Text("Auto: $\(String(format: "%.2f", workingTimeInfo.timeBasedEarnings))")
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.Colors.success)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .glassMorphism()
    }
} 