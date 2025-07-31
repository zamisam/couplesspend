
//
//  ExpenseEntryView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI

struct ExpenseEntryView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    @State private var amount: String = ""
    @State private var spender: Person = .user
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var splitType: SplitType = .equal
    @State private var showingSuccess = false
    @State private var isSubmitting = false
    @FocusState private var isAmountFieldFocused: Bool
    @FocusState private var isTitleFieldFocused: Bool
    @FocusState private var isDescriptionFieldFocused: Bool
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with icon
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.gradient)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(showingSuccess ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showingSuccess)
                            
                            Text("Add New Expense")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Amount Input Card
                        VStack(spacing: 16) {
                            AmountInputCard(
                                amount: $amount,
                                isAmountFieldFocused: $isAmountFieldFocused,
                                onAmountChange: { 
                                    selectionFeedback.selectionChanged()
                                }
                            )
                            
                            // Title Input Card
                            InputCard(
                                title: "What did you buy?",
                                placeholder: "Coffee, Groceries, Gas...",
                                text: $title,
                                isFocused: $isTitleFieldFocused,
                                icon: "tag.fill",
                                shouldCapitalizeWords: true
                            )
                            
                            // Spender Selection Card
                            SpenderSelectionCard(
                                spender: $spender,
                                onSpenderChange: { newSpender in
                                    impactFeedback.impactOccurred()
                                    spender = newSpender
                                }
                            )
                            
                            // Split Type Selection Card
                            SplitTypeSelectionCard(
                                splitType: $splitType,
                                onSplitTypeChange: { newSplitType in
                                    selectionFeedback.selectionChanged()
                                    splitType = newSplitType
                                }
                            )
                            
                            // Expense Preview Card (only show if amount is valid)
                            if let amountValue = Decimal(string: amount), amountValue > 0 {
                                ExpensePreviewCard(
                                    amount: amountValue,
                                    spender: spender,
                                    splitType: splitType
                                )
                            }
                            
                            // Description Input Card
                            InputCard(
                                title: "Additional Notes",
                                placeholder: "Optional description...",
                                text: $description,
                                isFocused: $isDescriptionFieldFocused,
                                icon: "note.text",
                                isOptional: true
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Add Button
                        Button(action: {
                            impactFeedback.impactOccurred()
                            addExpense()
                        }) {
                            HStack(spacing: 12) {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                
                                Text(isSubmitting ? "Adding..." : "Add Expense")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isFormValid ? Color.blue.gradient : Color.gray.gradient)
                            )
                            .scaleEffect(isFormValid ? 1.0 : 0.95)
                            .animation(.easeInOut(duration: 0.2), value: isFormValid)
                        }
                        .disabled(!isFormValid || isSubmitting)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadPersonNames()
                // Prepare haptic feedback
                impactFeedback.prepare()
                selectionFeedback.prepare()
                notificationFeedback.prepare()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Decimal(string: amount) else { return false }
        return amountValue > 0 && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func hideKeyboard() {
        isAmountFieldFocused = false
        isTitleFieldFocused = false
        isDescriptionFieldFocused = false
    }
    
    private func addExpense() {
        Task {
            guard let amountValue = Decimal(string: amount) else { return }
            
            isSubmitting = true
            
            await expenseStore.addExpense(
                amount: amountValue, 
                spender: spender, 
                title: title.isEmpty ? nil : title,
                description: description.isEmpty ? nil : description,
                splitType: splitType
            )
            
            await MainActor.run {
                isSubmitting = false
                
                // Check if successful (assuming no error message means success)
                if expenseStore.errorMessage == nil {
                    // Success haptic and animation
                    notificationFeedback.notificationOccurred(.success)
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        showingSuccess = true
                    }
                    
                    // Clear form
                    amount = ""
                    title = ""
                    description = ""
                    spender = .user
                    splitType = .equal
                    
                    // Reset animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            showingSuccess = false
                        }
                    }
                } else {
                    // Error haptic
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func loadPersonNames() {
        Task {
            guard let session = supabaseService.session else { return }
            
            // Get user's display name from database, fallback to email prefix
            let customDisplayName = await supabaseService.getUserDisplayName()
            let userName = customDisplayName ?? session.user.email?.components(separatedBy: "@").first?.capitalized ?? "You"
            
            // Get partner name
            let partnerName = await supabaseService.getPartnerName()
            
            await MainActor.run {
                personDisplayService.updateNames(userName: userName, partnerName: partnerName)
            }
        }
    }
}

// MARK: - Custom Components

struct AmountInputCard: View {
    @Binding var amount: String
    @FocusState.Binding var isAmountFieldFocused: Bool
    let onAmountChange: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("Amount")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack {
                Text("$")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                TextField("0.00", text: $amount)
                    .font(.title)
                    .fontWeight(.bold)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFieldFocused)
                    .onChange(of: amount) { _, _ in
                        onAmountChange()
                    }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct InputCard: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let icon: String
    let shouldCapitalizeWords: Bool
    let isOptional: Bool
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        icon: String,
        shouldCapitalizeWords: Bool = false,
        isOptional: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self._isFocused = isFocused
        self.icon = icon
        self.shouldCapitalizeWords = shouldCapitalizeWords
        self.isOptional = isOptional
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                if isOptional {
                    Text("(Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .focused($isFocused)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SpenderSelectionCard: View {
    @Binding var spender: Person
    let onSpenderChange: (Person) -> Void
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Who spent this?")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            spenderSelectionButtons
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var spenderSelectionButtons: some View {
        HStack(spacing: 12) {
            ForEach(Person.allCases, id: \.self) { person in
                spenderButton(for: person)
            }
        }
        .padding(.horizontal)
    }
    
    private func spenderButton(for person: Person) -> some View {
        Button(action: {
            onSpenderChange(person)
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(spender == person ? AnyShapeStyle(Color.orange.gradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: person == .user ? "person.fill" : "person.2.fill")
                            .font(.title3)
                            .foregroundColor(spender == person ? .white : .gray)
                    )
                
                Text(person.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(spender == person ? .orange : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SplitTypeSelectionCard: View {
    @Binding var splitType: SplitType
    let onSplitTypeChange: (SplitType) -> Void
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "percent")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("How to split?")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(SplitType.allCases, id: \.self) { type in
                    splitTypeButton(for: type)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func splitTypeButton(for type: SplitType) -> some View {
        Button(action: {
            onSplitTypeChange(type)
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(splitType == type ? AnyShapeStyle(Color.purple.gradient) : AnyShapeStyle(Color.gray.opacity(0.2)))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(splitType == type ? Color.purple : Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(getDisplayName(for: type))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(getDescription(for: type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if splitType == type {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(splitType == type ? Color.purple.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getDisplayName(for type: SplitType) -> String {
        switch type {
        case .equal:
            return "Split Equally"
        case .full:
            return "I Pay Full"
        case .partnerFull:
            return "\(personDisplayService.currentPartnerName) Pays Full"
        case .noSplit:
            return "No Split"
        }
    }
    
    private func getDescription(for type: SplitType) -> String {
        switch type {
        case .equal:
            return "Both pay half"
        case .full:
            return "\(personDisplayService.currentPartnerName) owes half"
        case .partnerFull:
            return "I owe half"
        case .noSplit:
            return "Personal expense"
        }
    }
}

struct ExpensePreviewCard: View {
    let amount: Decimal
    let spender: Person
    let splitType: SplitType
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Preview")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Amount spent
                HStack {
                    Text("Amount spent:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(NumberFormatter.currency.string(from: amount as NSDecimalNumber) ?? "$0.00")
                        .fontWeight(.medium)
                }
                
                // Who paid
                HStack {
                    Text("Paid by:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(spender.displayName)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                // Debt calculation
                previewContent
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var previewContent: some View {
        switch splitType {
        case .equal:
            VStack(spacing: 8) {
                Text("Split Equally")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("\(getOtherPerson(spender).displayName) owes:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(NumberFormatter.currency.string(from: (amount / 2) as NSDecimalNumber) ?? "$0.00")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            
        case .full:
            VStack(spacing: 8) {
                Text("\(spender.displayName) Pays Full")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("\(getOtherPerson(spender).displayName) owes:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(NumberFormatter.currency.string(from: (amount / 2) as NSDecimalNumber) ?? "$0.00")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            
        case .partnerFull:
            VStack(spacing: 8) {
                Text("\(getOtherPerson(spender).displayName) Pays Full")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("\(spender.displayName) owes:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(NumberFormatter.currency.string(from: (amount / 2) as NSDecimalNumber) ?? "$0.00")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            
        case .noSplit:
            VStack(spacing: 8) {
                Text("Personal Expense")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                HStack {
                    Text("No debt created")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$0.00")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func getOtherPerson(_ person: Person) -> Person {
        return person == .user ? .partner : .user
    }
}

// MARK: - Number Formatter Extension
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

#Preview {
    ExpenseEntryView()
        .environmentObject(ExpenseStore())
        .environmentObject(SupabaseService.shared)
}