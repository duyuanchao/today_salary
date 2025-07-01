import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    // 性能优化：使用本地状态减少绑定复杂度
    @State private var monthlyIncome: String = ""
    @State private var userName: String = ""
    @State private var selectedCalculationMethod: CalculationMethod = .naturalDays
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
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
            ZStack {
                // 主要内容
                Form {
                    personalInfoSection
                    workingHoursSection
                    paydaySettingsSection
                    saveButtonSection
                }
                .background(DesignTokens.Colors.background)
                .onTapGesture {
                    hideKeyboard()
                }
                .disabled(isLoading)
                
                // 加载指示器
                if isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismissView) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettingsAsync()
            
            // Firebase分析：异步执行
            DispatchQueue.global(qos: .utility).async {
                firebaseManager.trackScreenView(screenName: "settings")
            }
        }
        .alert("Settings", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { 
                if alertMessage.contains("successfully") {
                    dismissView()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - View Sections
    private var personalInfoSection: some View {
        Section(header: Text("Personal Information")) {
            nameField
            incomeField
            calculationMethodPicker
        }
    }
    
    private var nameField: some View {
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
    }
    
    private var incomeField: some View {
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
    }
    
    private var calculationMethodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calculation Method")
                .font(.headline)
            
            LazyVStack(spacing: 4) { // 性能优化：使用LazyVStack
                ForEach(CalculationMethod.allCases, id: \.self) { method in
                    CalculationMethodRow(
                        method: method,
                        isSelected: selectedCalculationMethod == method
                    ) {
                        selectedCalculationMethod = method
                        HapticManager.selection() // 添加触觉反馈
                    }
                }
            }
        }
    }
    
    private var workingHoursSection: some View {
        Section(header: Text("Working Hours")) {
            Toggle("Auto Calculate Earnings", isOn: $isAutoCalculateEnabled)
                .onChange(of: isAutoCalculateEnabled) { _ in
                    HapticManager.selection()
                }
            
            if isAutoCalculateEnabled {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                
                Text("When enabled, your earnings will be automatically calculated based on the current time and your working hours.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var paydaySettingsSection: some View {
        Section(header: Text("Payday Settings")) {
            Toggle("Last Day of Month", isOn: $isLastDayOfMonth)
                .onChange(of: isLastDayOfMonth) { _ in
                    HapticManager.selection()
                }
            
            if !isLastDayOfMonth {
                Stepper("Day \(paydayOfMonth) of month", value: $paydayOfMonth, in: 1...31)
            }
        }
    }
    
    private var saveButtonSection: some View {
        Section {
            Button("Save Changes") {
                saveSettingsAsync()
            }
            .disabled(isLoading || !isFormValid)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !monthlyIncome.isEmpty && 
        Double(monthlyIncome) != nil && 
        Double(monthlyIncome)! > 0
    }
    
    // MARK: - Methods
    private func loadCurrentSettingsAsync() {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let profile = DataManager.shared.userProfile
            let formattedIncome = String(format: "%.2f", profile.monthlyIncome)
            let name = profile.userName ?? ""
            let method = profile.calculationMethod
            let workingHours = profile.workingHours
            let paydaySettings = profile.paydaySettings
            
            DispatchQueue.main.async {
                monthlyIncome = formattedIncome
                userName = name
                selectedCalculationMethod = method
                startTime = workingHours.startTime
                endTime = workingHours.endTime
                isAutoCalculateEnabled = workingHours.isAutoCalculateEnabled
                paydayOfMonth = paydaySettings.paydayOfMonth
                isLastDayOfMonth = paydaySettings.isLastDayOfMonth
            }
        }
    }
    
    private func hideKeyboard() {
        isIncomeFieldFocused = false
        isNameFieldFocused = false
    }
    
    private func dismissView() {
        hideKeyboard()
        HapticManager.impact(.light)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveSettingsAsync() {
        hideKeyboard()
        
        guard let income = Double(monthlyIncome), income > 0 else {
            alertMessage = "Please enter a valid monthly income amount."
            showingAlert = true
            return
        }
        
        isLoading = true
        HapticManager.selection()
        
        // Firebase分析：异步执行
        DispatchQueue.global(qos: .utility).async {
            firebaseManager.trackButtonTap(buttonName: "save_settings", screenName: "settings")
        }
        
        // 在后台线程处理数据更新
        DispatchQueue.global(qos: .userInitiated).async {
            let name = userName.isEmpty ? nil : userName
            
            DispatchQueue.main.async {
                // 更新用户配置
                DataManager.shared.setupUserProfile(
                    monthlyIncome: income, 
                    userName: name, 
                    calculationMethod: selectedCalculationMethod
                )
                
                // 更新工作时间设置
                var workingHours = DataManager.shared.userProfile.workingHours
                workingHours.startTime = startTime
                workingHours.endTime = endTime
                workingHours.isAutoCalculateEnabled = isAutoCalculateEnabled
                DataManager.shared.updateWorkingHours(workingHours)
                
                // 更新发薪日设置
                var paydaySettings = DataManager.shared.userProfile.paydaySettings
                paydaySettings.paydayOfMonth = paydayOfMonth
                paydaySettings.isLastDayOfMonth = isLastDayOfMonth
                DataManager.shared.updatePaydaySettings(paydaySettings)
                
                isLoading = false
                alertMessage = "Settings saved successfully!"
                showingAlert = true
                
                HapticManager.notification(.success)
            }
        }
    }
}

// MARK: - Supporting Views
struct CalculationMethodRow: View {
    let method: CalculationMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 16))
                
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

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Saving...")
                    .foregroundColor(.white)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
} 