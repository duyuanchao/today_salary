import SwiftUI

struct AchievementsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Premium Header Stats
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("🏆 Achievements")
                            .font(DesignTokens.Typography.largeTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("\(unlockedCount)/\(dataManager.achievements.count) Unlocked")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        // Premium progress ring instead of bar
                        AnimatedProgressRing(
                            progress: progressPercentage,
                            lineWidth: 8,
                            size: 100,
                            colors: [DesignTokens.Colors.warning, Color(hex: "#FFB84D")]
                        )
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .premiumCard()
                    
                    // Premium Achievements Grid
                    LazyVGrid(columns: gridColumns, spacing: DesignTokens.Spacing.md) {
                        ForEach(dataManager.achievements) { achievement in
                            PremiumAchievementCard(achievement: achievement)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [DesignTokens.Colors.background, DesignTokens.Colors.surface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .onAppear {
                firebaseManager.trackScreenView(screenName: "achievements")
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    private var unlockedCount: Int {
        dataManager.achievements.filter { $0.isUnlocked }.count
    }
    
    private var progressPercentage: Double {
        guard !dataManager.achievements.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(dataManager.achievements.count)
    }
}

struct PremiumAchievementCard: View {
    let achievement: Achievement
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Animated Icon
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignTokens.Colors.warning, Color(hex: "#FFB84D")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: DesignTokens.Colors.warning.opacity(0.3), radius: 10, x: 0, y: 5)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .white : DesignTokens.Colors.textTertiary)
            }
            .onAppear {
                if achievement.isUnlocked {
                    isAnimating = true
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(achievement.title)
                    .font(DesignTokens.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(achievement.isUnlocked ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Status Indicator
            if achievement.isUnlocked {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                    Text("Unlocked")
                        .font(DesignTokens.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.Colors.success)
                }
            } else {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                    Text("Locked")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(height: 180)
        .background(
            Group {
                if achievement.isUnlocked {
                    LinearGradient(
                        colors: [DesignTokens.Colors.warning.opacity(0.1), DesignTokens.Colors.surface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    DesignTokens.Colors.surfaceSecondary
                }
            }
        )
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(
                    achievement.isUnlocked ? DesignTokens.Colors.warning.opacity(0.3) : DesignTokens.Colors.border,
                    lineWidth: achievement.isUnlocked ? 2 : 1
                )
        )
        .shadow(
            color: achievement.isUnlocked ? DesignTokens.Colors.warning.opacity(0.2) : DesignTokens.Shadow.light,
            radius: achievement.isUnlocked ? 15 : 8,
            x: 0,
            y: achievement.isUnlocked ? 8 : 4
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
        .animation(DesignTokens.Animation.spring, value: achievement.isUnlocked)
    }
} 