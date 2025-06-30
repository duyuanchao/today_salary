import SwiftUI

struct WelcomeView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var monthlyIncome: String = ""
    @State private var userName: String = ""
    @State private var selectedCalculationMethod: CalculationMethod = .naturalDays
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var isIncomeFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: DesignTokens.Colors.backgroundGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        Spacer(minLength: DesignTokens.Spacing.lg)
                        
                        // Premium Logo and Welcome Text
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            // Animated logo with gradient
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 10)
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: true)
                            
                            VStack(spacing: DesignTokens.Spacing.md) {
                                Text("Welcome to")
                                    .font(DesignTokens.Typography.title3)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Daily Earnings")
                                    .font(DesignTokens.Typography.largeTitle)
                                    .foregroundColor(.white)
                                
                                Text("Track your progress, stay motivated!")
                                    .font(DesignTokens.Typography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Premium Input Form
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Your Name (Optional)")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your name", text: $userName)
                                    .font(DesignTokens.Typography.body)
                                    .focused($isNameFieldFocused)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        isNameFieldFocused = false
                                        isIncomeFieldFocused = true
                                    }
                                    .padding(DesignTokens.Spacing.md)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(DesignTokens.CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Monthly Income")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text("$")
                                        .font(DesignTokens.Typography.title2)
                                        .foregroundColor(.white)
                                        .padding(.leading, DesignTokens.Spacing.md)
                                    
                                    TextField("0", text: $monthlyIncome)
                                        .keyboardType(.decimalPad)
                                        .font(DesignTokens.Typography.title3)
                                        .focused($isIncomeFieldFocused)
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
                                        .padding(.trailing, DesignTokens.Spacing.md)
                                }
                                .padding(.vertical, DesignTokens.Spacing.md)
                                .background(.ultraThinMaterial)
                                .cornerRadius(DesignTokens.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // 计算方式选择
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Calculation Method")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                                        Button(action: {
                                            selectedCalculationMethod = method
                                        }) {
                                            HStack {
                                                Image(systemName: selectedCalculationMethod == method ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(.white)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(method.displayName)
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white)
                                                    
                                                    Text(method.description)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedCalculationMethod == method ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // 计算预览
                            if let income = Double(monthlyIncome), income > 0 {
                                let daysInMonth = selectedCalculationMethod == .naturalDays ? 
                                    DateCalculator.daysInMonth() : DateCalculator.workingDaysInMonth()
                                let dailyTarget = income / Double(daysInMonth)
                                
                                VStack(spacing: 12) {
                                    Divider()
                                        .background(Color.white.opacity(0.3))
                                    
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text("This Month:")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white.opacity(0.9))
                                            Spacer()
                                        }
                                        
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Total Days")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text("\(DateCalculator.daysInMonth())")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Working Days")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text("\(DateCalculator.workingDaysInMonth())")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Your Target")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text("\(daysInMonth) days")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        VStack(spacing: 6) {
                                            Text("Daily Target: $\(String(format: "%.2f", dailyTarget))")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            
                                            Text("≈ $\(String(format: "%.2f", dailyTarget / 8)) per hour (8-hour workday)")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Premium Get Started Button
                        Button(action: {
                            HapticManager.impact(.medium)
                            setupProfile()
                        }) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Get Started")
                                    .fontWeight(.semibold)
                            }
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignTokens.CornerRadius.xl)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .disabled(monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0)
                        .opacity((monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0) ? 0.6 : 1.0)
                        .scaleEffect((monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0) ? 0.95 : 1.0)
                        .animation(DesignTokens.Animation.spring, value: monthlyIncome)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .alert("Setup Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func hideKeyboard() {
        isIncomeFieldFocused = false
        isNameFieldFocused = false
    }
    
    private func setupProfile() {
        // 先收回键盘
        hideKeyboard()
        
        guard let income = Double(monthlyIncome), income > 0 else {
            alertMessage = "Please enter a valid monthly income amount."
            showingAlert = true
            return
        }
        
        let name = userName.isEmpty ? nil : userName
        dataManager.setupUserProfile(
            monthlyIncome: income, 
            userName: name, 
            calculationMethod: selectedCalculationMethod
        )
        dataManager.scheduleDailyReminder()
    }
} 