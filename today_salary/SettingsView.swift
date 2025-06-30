import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var monthlyIncome: String = ""
    @State private var userName: String = ""
    @State private var selectedCalculationMethod: CalculationMethod = .naturalDays
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isIncomeFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    
    // 工作时间设置
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isAutoCalculateEnabled = true
    
    // 发薪日设置
    @State private var paydayOfMonth = 1
    @State private var isLastDayOfMonth = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Optional", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .focused($isNameFieldFocused)
                            .submitLabel(.next)
                            .onSubmit {
                                isNameFieldFocused = false
                                isIncomeFieldFocused = true
                            }
                    }
                    
                    HStack {
                        Text("Monthly Income")
                        Spacer()
                        TextField("$0", text: $monthlyIncome)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
                    
                    // 计算方式选择
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculation Method")
                            .font(.headline)
                        
                        ForEach(CalculationMethod.allCases, id: \.self) { method in
                            Button(action: {
                                selectedCalculationMethod = method
                            }) {
                                HStack {
                                    Image(systemName: selectedCalculationMethod == method ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedCalculationMethod == method ? .blue : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(method.displayName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text(method.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 工作时间设置
                Section(header: Text("Working Hours")) {
                    Toggle("Auto Calculate Earnings", isOn: $isAutoCalculateEnabled)
                    
                    if isAutoCalculateEnabled {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                        
                        Text("When enabled, your earnings will be automatically calculated based on the current time and your working hours.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 发薪日设置
                Section(header: Text("Payday Settings")) {
                    Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                    
                    if !isLastDayOfMonth {
                        Stepper("Day \(paydayOfMonth) of month", value: $paydayOfMonth, in: 1...31)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveSettings()
                    }
                    .disabled(monthlyIncome.isEmpty || Double(monthlyIncome) == nil || Double(monthlyIncome)! <= 0)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hideKeyboard()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadCurrentSettings() {
        monthlyIncome = String(format: "%.2f", dataManager.userProfile.monthlyIncome)
        userName = dataManager.userProfile.userName ?? ""
        selectedCalculationMethod = dataManager.userProfile.calculationMethod
        
        // 加载工作时间设置
        let workingHours = dataManager.userProfile.workingHours
        startTime = workingHours.startTime
        endTime = workingHours.endTime
        isAutoCalculateEnabled = workingHours.isAutoCalculateEnabled
        
        // 加载发薪日设置
        let paydaySettings = dataManager.userProfile.paydaySettings
        paydayOfMonth = paydaySettings.paydayOfMonth
        isLastDayOfMonth = paydaySettings.isLastDayOfMonth
    }
    
    private func hideKeyboard() {
        isIncomeFieldFocused = false
        isNameFieldFocused = false
    }
    
    private func saveSettings() {
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
        
        // 更新工作时间设置
        var workingHours = dataManager.userProfile.workingHours
        workingHours.startTime = startTime
        workingHours.endTime = endTime
        workingHours.isAutoCalculateEnabled = isAutoCalculateEnabled
        dataManager.updateWorkingHours(workingHours)
        
        // 更新发薪日设置
        var paydaySettings = dataManager.userProfile.paydaySettings
        paydaySettings.paydayOfMonth = paydayOfMonth
        paydaySettings.isLastDayOfMonth = isLastDayOfMonth
        dataManager.updatePaydaySettings(paydaySettings)
        
        alertMessage = "Settings saved successfully!"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presentationMode.wrappedValue.dismiss()
        }
    }
} 