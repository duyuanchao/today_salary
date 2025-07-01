import SwiftUI
import Combine

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    @Published var monthlyIncome: String = ""
    @Published var userName: String = ""
    @Published var selectedCalculationMethod: CalculationMethod = .naturalDays
    @Published var startTime = Date()
    @Published var endTime = Date()
    @Published var isAutoCalculateEnabled = true
    @Published var paydayOfMonth = 1
    @Published var isLastDayOfMonth = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    private var originalSettings: UserSettings?
    private var cancellables = Set<AnyCancellable>()
    private let inputDebouncer = PassthroughSubject<String, Never>()
    
    var hasChanges: Bool {
        guard let original = originalSettings else { return false }
        return original != currentSettings
    }
    
    private var currentSettings: UserSettings {
        UserSettings(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            userName: userName.isEmpty ? nil : userName,
            calculationMethod: selectedCalculationMethod,
            workingHours: WorkingHours(
                startTime: startTime,
                endTime: endTime,
                isAutoCalculateEnabled: isAutoCalculateEnabled
            ),
            paydaySettings: PaydaySettings(
                paydayOfMonth: paydayOfMonth,
                isLastDayOfMonth: isLastDayOfMonth
            )
        )
    }
    
    init() {
        setupDebouncing()
    }
    
    private func setupDebouncing() {
        // 对收入输入进行防抖处理
        inputDebouncer
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.monthlyIncome = value
            }
            .store(in: &cancellables)
    }
    
    func handleIncomeInput(_ text: String) {
        inputDebouncer.send(text)
    }
    
    func loadCurrentSettings() {
        let dataManager = DataManager.shared
        monthlyIncome = String(format: "%.2f", dataManager.userProfile.monthlyIncome)
        userName = dataManager.userProfile.userName ?? ""
        selectedCalculationMethod = dataManager.userProfile.calculationMethod
        
        let workingHours = dataManager.userProfile.workingHours
        startTime = workingHours.startTime
        endTime = workingHours.endTime
        isAutoCalculateEnabled = workingHours.isAutoCalculateEnabled
        
        let paydaySettings = dataManager.userProfile.paydaySettings
        paydayOfMonth = paydaySettings.paydayOfMonth
        isLastDayOfMonth = paydaySettings.isLastDayOfMonth
        
        // 保存原始设置用于比较
        originalSettings = currentSettings
    }
    
    func saveSettings() -> Bool {
        guard let income = Double(monthlyIncome), income > 0 else {
            alertMessage = "Please enter a valid monthly income amount."
            showingAlert = true
            return false
        }
        
        let dataManager = DataManager.shared
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
        return true
    }
}

// MARK: - User Settings Model
struct UserSettings: Equatable {
    let monthlyIncome: Double
    let userName: String?
    let calculationMethod: CalculationMethod
    let workingHours: WorkingHours
    let paydaySettings: PaydaySettings
}

extension WorkingHours {
    init(startTime: Date, endTime: Date, isAutoCalculateEnabled: Bool) {
        self.init()
        self.startTime = startTime
        self.endTime = endTime
        self.isAutoCalculateEnabled = isAutoCalculateEnabled
    }
}

extension PaydaySettings {
    init(paydayOfMonth: Int, isLastDayOfMonth: Bool) {
        self.init()
        self.paydayOfMonth = paydayOfMonth
        self.isLastDayOfMonth = isLastDayOfMonth
    }
}

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isIncomeFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    PersonalInfoSection()
                    WorkingHoursSection()
                    PaydaySection()
                    ActionSection()
                }
                .padding()
            }
            .background(DesignTokens.Colors.background)
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        hideKeyboard()
                        HapticManager.impact(.light)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            viewModel.loadCurrentSettings()
            firebaseManager.trackScreenView(screenName: "settings")
        }
        .alert("Settings", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {
                if viewModel.alertMessage.contains("successfully") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    // MARK: - Personal Info Section
    @ViewBuilder
    private func PersonalInfoSection() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "Personal Information")
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                OptimizedInputField(
                    title: "Name",
                    placeholder: "Optional",
                    text: $viewModel.userName,
                    isFocused: $isNameFieldFocused,
                    keyboardType: .default,
                    onSubmit: {
                        isNameFieldFocused = false
                        isIncomeFieldFocused = true
                    }
                )
                
                OptimizedInputField(
                    title: "Monthly Income",
                    placeholder: "$0",
                    text: $viewModel.monthlyIncome,
                    isFocused: $isIncomeFieldFocused,
                    keyboardType: .decimalPad,
                    isDebounced: true,
                    onTextChange: viewModel.handleIncomeInput
                )
                
                CalculationMethodPicker()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
    }
    
    // MARK: - Working Hours Section
    @ViewBuilder
    private func WorkingHoursSection() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "Working Hours")
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Toggle("Auto Calculate Earnings", isOn: $viewModel.isAutoCalculateEnabled)
                    .tint(DesignTokens.Colors.primary)
                
                if viewModel.isAutoCalculateEnabled {
                    Group {
                        DatePicker("Start Time", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                    }
                    .transition(.opacity.combined(with: .scale))
                    
                    Text("When enabled, your earnings will be automatically calculated based on the current time and your working hours.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.top, DesignTokens.Spacing.xs)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
        .animation(.easeInOut(duration: 0.3), value: viewModel.isAutoCalculateEnabled)
    }
    
    // MARK: - Payday Section
    @ViewBuilder
    private func PaydaySection() -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            SectionHeader(title: "Payday Settings")
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Toggle("Last Day of Month", isOn: $viewModel.isLastDayOfMonth)
                    .tint(DesignTokens.Colors.primary)
                
                if !viewModel.isLastDayOfMonth {
                    Stepper("Day \(viewModel.paydayOfMonth) of month", value: $viewModel.paydayOfMonth, in: 1...31)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .premiumCard()
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLastDayOfMonth)
    }
    
    // MARK: - Action Section
    @ViewBuilder
    private func ActionSection() -> some View {
        Button(action: {
            firebaseManager.trackButtonTap(buttonName: "save_settings", screenName: "settings")
            hideKeyboard()
            
            if viewModel.saveSettings() {
                HapticManager.notification(.success)
            } else {
                HapticManager.notification(.error)
            }
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("Save Changes")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: viewModel.hasChanges ? DesignTokens.Colors.primaryGradient : [DesignTokens.Colors.textSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignTokens.CornerRadius.md)
            .shadow(color: DesignTokens.Shadow.medium, radius: 8, x: 0, y: 4)
        }
        .disabled(!viewModel.hasChanges || viewModel.monthlyIncome.isEmpty || Double(viewModel.monthlyIncome) == nil || Double(viewModel.monthlyIncome)! <= 0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasChanges)
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Calculation Method Picker
    @ViewBuilder
    private func CalculationMethodPicker() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Calculation Method")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            ForEach(CalculationMethod.allCases, id: \.self) { method in
                MethodOptionRow(
                    method: method,
                    isSelected: viewModel.selectedCalculationMethod == method,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedCalculationMethod = method
                        }
                        HapticManager.selection()
                    }
                )
            }
        }
    }
    
    private func hideKeyboard() {
        isIncomeFieldFocused = false
        isNameFieldFocused = false
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            Spacer()
        }
    }
}

struct OptimizedInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let keyboardType: UIKeyboardType
    let isDebounced: Bool
    let onSubmit: (() -> Void)?
    let onTextChange: ((String) -> Void)?
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        keyboardType: UIKeyboardType = .default,
        isDebounced: Bool = false,
        onSubmit: (() -> Void)? = nil,
        onTextChange: ((String) -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self._isFocused = isFocused
        self.keyboardType = keyboardType
        self.isDebounced = isDebounced
        self.onSubmit = onSubmit
        self.onTextChange = onTextChange
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .submitLabel(.next)
                .onSubmit {
                    onSubmit?()
                }
                .onChange(of: text) { newValue in
                    if isDebounced {
                        onTextChange?(newValue)
                    }
                }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}

struct MethodOptionRow: View {
    let method: CalculationMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(method.description)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 