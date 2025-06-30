import SwiftUI

struct AchievementsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    VStack(spacing: 12) {
                        Text("🏆 Achievements")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(unlockedCount)/\(dataManager.achievements.count) Unlocked")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Achievements Grid
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(dataManager.achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
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

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(achievement.isUnlocked ? .orange : .gray.opacity(0.5))
            
            Text(achievement.title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            if achievement.isUnlocked {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Unlocked")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else {
                Text("🔒 Locked")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.orange.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(achievement.isUnlocked ? 1.0 : 0.95)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
} 