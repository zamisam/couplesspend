//
//  SummaryView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI
import Charts

// MARK: - Monthly Spending Data
struct MonthlySpending: Identifiable {
    let id = UUID()
    let month: String
    let date: Date
    let userAmount: Decimal
    let partnerAmount: Decimal
    let totalAmount: Decimal
    
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

struct SummaryView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var personDisplayService = PersonDisplayService.shared
    @State private var showingSettleConfirmation = false
    @State private var showSettleSuccess = false
    @State private var settleErrorMessage: String?
    @State private var showSettleError = false
    @State private var monthlySpendingData: [MonthlySpending] = []
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Totals Card
                        TotalsCard(
                            userTotal: expenseStore.spendingSummary.userTotal,
                            partnerTotal: expenseStore.spendingSummary.partnerTotal,
                            userName: personDisplayService.currentUserName,
                            partnerName: personDisplayService.currentPartnerName
                        )
                        
                        // Balance Card
                        BalanceCard(
                            spendingSummary: expenseStore.spendingSummary,
                            userName: personDisplayService.currentUserName,
                            partnerName: personDisplayService.currentPartnerName
                        )
                        
                        // Analytics Card
                        AnalyticsCard(
                            monthlySpendingData: monthlySpendingData,
                            userName: personDisplayService.currentUserName,
                            partnerName: personDisplayService.currentPartnerName
                        )
                        
                        // Settle Button (if needed)
                        if expenseStore.spendingSummary.whoOwes != nil {
                            SettleButtonCard(
                                isLoading: expenseStore.isLoading,
                                onSettle: {
                                    impactFeedback.impactOccurred()
                                    showingSettleConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Summary")
            .onAppear {
                loadPersonNames()
            }
            .task {
                await expenseStore.loadExpenses()
                await calculateMonthlySpending()
            }
            .alert("Are you sure you want to settle the balances?", isPresented: $showingSettleConfirmation) {
                Button("Settle") {
                    Task {
                        notificationFeedback.notificationOccurred(.success)
                        print("Starting settle balances process...")
                        await expenseStore.settleExpenses()
                        
                        if expenseStore.errorMessage == nil {
                            print("Settle completed successfully")
                            showSettleSuccess = true
                        } else {
                            print("Settle failed with error: \(expenseStore.errorMessage ?? "Unknown error")")
                            settleErrorMessage = expenseStore.errorMessage
                            showSettleError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will mark all expenses as settled and cannot be undone.")
            }
            .alert("Success!", isPresented: $showSettleSuccess) {
                Button("OK") { }
            } message: {
                Text("All expenses have been successfully settled.")
            }
            .alert("Error", isPresented: $showSettleError) {
                Button("OK") { }
            } message: {
                Text(settleErrorMessage ?? "Failed to settle expenses")
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
    
    // MARK: - Monthly Spending Calculations
    private func calculateMonthlySpending() async {
        let expenses = expenseStore.expenses
        
        // Group expenses by month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        var monthlyGroups: [String: [Expense]] = [:]
        
        for expense in expenses {
            let monthKey = dateFormatter.string(from: expense.date)
            if monthlyGroups[monthKey] == nil {
                monthlyGroups[monthKey] = []
            }
            monthlyGroups[monthKey]?.append(expense)
        }
        
        // Calculate totals for each month
        var monthlyData: [MonthlySpending] = []
        
        for (monthKey, monthExpenses) in monthlyGroups.sorted(by: { $0.key < $1.key }) {
            let userExpenses = monthExpenses.filter { $0.spender == .user }
            let partnerExpenses = monthExpenses.filter { $0.spender == .partner }
            
            let userTotal = userExpenses.reduce(0) { $0 + $1.amount }
            let partnerTotal = partnerExpenses.reduce(0) { $0 + $1.amount }
            let totalAmount = userTotal + partnerTotal
            
            // Create a date for the first day of the month for proper sorting
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let monthDate = dateFormatter.date(from: "\(monthKey)-01") ?? Date()
            
            let monthlySpending = MonthlySpending(
                month: monthKey,
                date: monthDate,
                userAmount: userTotal,
                partnerAmount: partnerTotal,
                totalAmount: totalAmount
            )
            
            monthlyData.append(monthlySpending)
        }
        
        await MainActor.run {
            // Keep only the last 6 months for better chart readability
            self.monthlySpendingData = Array(monthlyData.suffix(6))
        }
    }
    
    private func calculateAverageMonthlySpending() -> (userAverage: Decimal, partnerAverage: Decimal, totalAverage: Decimal)? {
        guard !monthlySpendingData.isEmpty else { return nil }
        
        let userTotal = monthlySpendingData.reduce(0) { $0 + $1.userAmount }
        let partnerTotal = monthlySpendingData.reduce(0) { $0 + $1.partnerAmount }
        let combinedTotal = monthlySpendingData.reduce(0) { $0 + $1.totalAmount }
        
        let monthCount = Decimal(monthlySpendingData.count)
        
        return (
            userAverage: userTotal / monthCount,
            partnerAverage: partnerTotal / monthCount,
            totalAverage: combinedTotal / monthCount
        )
    }
}

// MARK: - Custom Card Components
struct TotalsCard: View {
    let userTotal: Decimal
    let partnerTotal: Decimal
    let userName: String
    let partnerName: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Spending Totals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text(userName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(userTotal, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text(partnerName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(partnerTotal, format: .currency(code: "USD"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct BalanceCard: View {
    let spendingSummary: SpendingSummary
    let userName: String
    let partnerName: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: spendingSummary.whoOwes == nil ? "checkmark.circle.fill" : "scale.3d")
                    .foregroundColor(spendingSummary.whoOwes == nil ? .green : .orange)
                    .font(.title2)
                Text("Balance")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let whoOwes = spendingSummary.whoOwes {
                VStack(spacing: 8) {
                    let owesTo = whoOwes == .user ? partnerName : userName
                    Text("\(whoOwes.displayName) owes \(owesTo)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(spendingSummary.amountOwed, format: .currency(code: "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(whoOwes == .user ? .red : .green)
                }
            } else {
                VStack(spacing: 8) {
                    Text("All settled up!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("No outstanding balances")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct AnalyticsCard: View {
    let monthlySpendingData: [MonthlySpending]
    let userName: String
    let partnerName: String
    
    private func calculateAverageMonthlySpending() -> (userAverage: Decimal, partnerAverage: Decimal, totalAverage: Decimal)? {
        guard !monthlySpendingData.isEmpty else { return nil }
        
        let userTotal = monthlySpendingData.reduce(0) { $0 + $1.userAmount }
        let partnerTotal = monthlySpendingData.reduce(0) { $0 + $1.partnerAmount }
        let combinedTotal = monthlySpendingData.reduce(0) { $0 + $1.totalAmount }
        
        let monthCount = Decimal(monthlySpendingData.count)
        
        return (
            userAverage: userTotal / monthCount,
            partnerAverage: partnerTotal / monthCount,
            totalAverage: combinedTotal / monthCount
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Spending Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if !monthlySpendingData.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Monthly Spending Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Spending Trends")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Chart {
                            ForEach(monthlySpendingData) { monthData in
                                BarMark(
                                    x: .value("Month", monthData.formattedMonth),
                                    y: .value("Amount", monthData.userAmount)
                                )
                                .foregroundStyle(Color.blue)
                                .cornerRadius(4)
                                
                                BarMark(
                                    x: .value("Month", monthData.formattedMonth),
                                    y: .value("Amount", monthData.partnerAmount)
                                )
                                .foregroundStyle(Color.green)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine()
                                AxisValueLabel() {
                                    if let stringValue = value.as(String.self) {
                                        Text(stringValue)
                                            .font(.caption2)
                                            .rotationEffect(.degrees(-45))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine()
                                AxisValueLabel() {
                                    if let doubleValue = value.as(Double.self) {
                                        Text("$\(Int(doubleValue))")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartLegend(position: .bottom) {
                            HStack {
                                Label(userName, systemImage: "circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Label(partnerName, systemImage: "circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    // Monthly Average
                    if let averageSpending = calculateAverageMonthlySpending() {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Averages")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 4) {
                                HStack {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text(userName)
                                    }
                                    Spacer()
                                    Text(averageSpending.userAverage, format: .currency(code: "USD"))
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                .font(.caption)
                                
                                HStack {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text(partnerName)
                                    }
                                    Spacer()
                                    Text(averageSpending.partnerAverage, format: .currency(code: "USD"))
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                                .font(.caption)
                                
                                Divider()
                                    .padding(.vertical, 2)
                                
                                HStack {
                                    Text("Combined Average")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(averageSpending.totalAverage, format: .currency(code: "USD"))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.purple)
                                }
                                .font(.caption)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No spending data available")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Start adding expenses to see spending trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct SettleButtonCard: View {
    let isLoading: Bool
    let onSettle: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Settling expenses...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Button(action: onSettle) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Settle All Balances")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(isLoading ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isLoading)
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    SummaryView()
        .environmentObject(ExpenseStore())
        .environmentObject(SupabaseService.shared)
}
