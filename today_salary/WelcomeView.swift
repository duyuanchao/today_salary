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
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击空白区域收回键盘
                    hideKeyboard()
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 20)
                        
                        // Logo and Welcome Text
                        VStack(spacing: 20) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text("Welcome to")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("Daily Earnings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Track your progress, stay motivated!")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Input Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Name (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("Enter your name", text: $userName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                                    .focused($isNameFieldFocused)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        isNameFieldFocused = false
                                        isIncomeFieldFocused = true
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monthly Income")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text("$")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    TextField("0", text: $monthlyIncome)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.decimalPad)
                                        .font(.body)
                                        .focused($isIncomeFieldFocused)
                                        .toolbar {
                                            ToolbarItemGroup(placement: .keyboard) {
                                                Spacer()
                                                Button("完成") {
                                                    hideKeyboard()
                                                }
                                                .foregroundColor(.blue)
                                                .fontWeight(.medium)
                                            }
                                        }
                                }
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
                        
                        // Get Started Button
                        Button(action: setupProfile) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Get Started")
                                    .fontWeight(.semibold)
                            }
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(28)
                            .shadow(radius: 10)
                        }
                        .padding(.horizontal, 30)
                        .disabled(monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0)
                        .opacity((monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0) ? 0.6 : 1.0)
                        
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