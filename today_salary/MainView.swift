import SwiftUI

struct MainView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var todayEarningsInput: String = ""
    @State private var showingSettings = false
    @FocusState private var isEarningsFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Greeting
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.top)
                
                // Working status (if auto-calculate is enabled)
                if dataManager.userProfile.workingHours.isAutoCalculateEnabled {
                    workingStatusCard
                }
                
                // Today's earnings input
                VStack(spacing: 15) {
                    HStack {
                        Text("Today's Earnings")
                            .font(.headline)
                        
                        Spacer()
                        
                        if dataManager.userProfile.workingHours.isAutoCalculateEnabled {
                            Text("(Auto-updating)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("$")
                            .font(.title)
                        
                        TextField("0.00", text: $todayEarningsInput)
                            .font(.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .focused($isEarningsFieldFocused)
                            .onChange(of: todayEarningsInput) { newValue in
                                if let amount = Double(newValue) {
                                    dataManager.updateTodayEarnings(amount)
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    // Target and method info
                    VStack(spacing: 8) {
                        let monthInfo = dataManager.getCurrentMonthInfo()
                        let difference = dataManager.todayEarnings.amount - dataManager.userProfile.dailyTarget
                        
                        HStack {
                            Text("Target: $\(String(format: "%.2f", dataManager.userProfile.dailyTarget))")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if difference >= 0 {
                                Text("+$\(String(format: "%.2f", difference))")
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            } else {
                                Text("$\(String(format: "%.2f", abs(difference))) to go")
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Text("Method: \(monthInfo.calculationMethod.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("This month: \(monthInfo.relevantDays) days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .onTapGesture {
                    // 点击收入卡片区域时不收回键盘
                }
                
                // Progress bar
                VStack(spacing: 10) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(dataManager.currentProgress * 100))%")
                            .fontWeight(.bold)
                            .foregroundColor(progressColor)
                    }
                    
                    ProgressView(value: dataManager.currentProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                        .scaleEffect(x: 1, y: 3)
                        .animation(.easeInOut(duration: 0.5), value: dataManager.currentProgress)
                    
                    HStack {
                        Text("$0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.0f", dataManager.userProfile.dailyTarget))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Motivational message
                VStack(spacing: 10) {
                    Text(dataManager.getMotivationalMessage().message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Text(dataManager.getMotivationalMessage().localizedReward)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .background(motivationalGradient)
                .cornerRadius(12)
                
                // Quick stats
                let progressInfo = dataManager.getDetailedProgressInfo()
                if progressInfo.remainingTarget > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Month Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.0f", progressInfo.remainingTarget))")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Days Left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(progressInfo.monthInfo.relevantRemainingDays)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Avg Needed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.0f", progressInfo.averageNeededPerRemainingDay))")
                                    .font(.headline)
                                    .foregroundColor(progressInfo.isOnTrack ? .green : .red)
                            }
                        }
                        
                        if !progressInfo.isOnTrack {
                            Text("⚠️ Behind target - need to increase daily earnings")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Payday countdown (if configured)
                let paydayInfo = dataManager.getPaydayInfo()
                if paydayInfo.daysUntilNextPayday > 0 {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next Payday")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(paydayInfo.daysUntilNextPayday) days to go")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        if let nextPayday = paydayInfo.nextPaydayDate {
                            Text(formatDate(nextPayday))
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .onTapGesture {
                // 点击空白区域收回键盘
                hideKeyboard()
            }
            .navigationTitle("Daily Earnings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: 
                Button("Settings") {
                    firebaseManager.trackButtonTap(buttonName: "settings", screenName: "main")
                    hideKeyboard()
                    showingSettings = true
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            // 使用当前收入（可能是自动计算的）
            todayEarningsInput = String(format: "%.2f", dataManager.todayEarnings.amount)
            
            // Firebase分析：记录屏幕访问
            firebaseManager.trackScreenView(screenName: "main")
        }
        .onChange(of: dataManager.todayEarnings.amount) { newAmount in
            // 当收入自动更新时，同步更新输入框
            todayEarningsInput = String(format: "%.2f", newAmount)
        }
    }
    
    @ViewBuilder
    private var workingStatusCard: some View {
        let workingTimeInfo = dataManager.getWorkingTimeInfo()
        
        VStack(spacing: 10) {
            HStack {
                Image(systemName: workingTimeInfo.isCurrentlyWorkingTime ? "clock.fill" : "clock")
                    .foregroundColor(workingTimeInfo.isCurrentlyWorkingTime ? .green : .gray)
                
                Text(workingTimeInfo.isCurrentlyWorkingTime ? "Currently Working" : "Off Hours")
                    .font(.headline)
                    .foregroundColor(workingTimeInfo.isCurrentlyWorkingTime ? .green : .secondary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Work Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(workingTimeInfo.startTime) - \(workingTimeInfo.endTime)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hours Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", workingTimeInfo.workedHours))/\(String(format: "%.1f", workingTimeInfo.totalWorkingHours))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // Working progress bar
            ProgressView(value: workingTimeInfo.workedHours / workingTimeInfo.totalWorkingHours)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2)
            
            HStack {
                Text("Hourly Rate: $\(String(format: "%.2f", workingTimeInfo.hourlyRate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Auto: $\(String(format: "%.2f", workingTimeInfo.timeBasedEarnings))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func hideKeyboard() {
        isEarningsFieldFocused = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private var progressColor: Color {
        switch dataManager.currentProgress {
        case 0.0..<0.3:
            return .red
        case 0.3..<0.7:
            return .orange
        case 0.7..<1.0:
            return .blue
        default:
            return .green
        }
    }
    
    private var motivationalGradient: LinearGradient {
        let message = dataManager.getMotivationalMessage()
        switch message {
        case .excellent:
            return LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .good:
            return LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .average:
            return LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .needsWork:
            return LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case .justStarted:
            return LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
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
        
        if let name = dataManager.userProfile.userName {
            return "\(greeting), \(name)!"
        } else {
            return "\(greeting)!"
        }
    }
} 