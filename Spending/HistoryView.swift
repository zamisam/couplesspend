//
//  HistoryView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    @State private var expenseToEdit: Expense?
    @State private var showEditExpenseSheet = false
    
    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Computed properties to group expenses
    private var unsettledExpenses: [Expense] {
        expenseStore.expenses.filter { !$0.settled }.sorted { $0.date > $1.date }
    }
    
    private var settledExpenses: [Expense] {
        expenseStore.expenses.filter { $0.settled }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header Statistics Card
                        ExpenseStatsCard(
                            unsettledCount: unsettledExpenses.count,
                            settledCount: settledExpenses.count,
                            totalExpenses: expenseStore.expenses.count
                        )
                        
                        // Unsettled Expenses Section
                        if !unsettledExpenses.isEmpty {
                            ExpenseSectionCard(
                                title: "Pending Expenses",
                                count: unsettledExpenses.count,
                                expenses: unsettledExpenses,
                                isSettled: false,
                                onExpenseTap: { expense in
                                    impactFeedback.impactOccurred()
                                    expenseToEdit = expense
                                    showEditExpenseSheet = true
                                }
                            )
                        }
                        
                        // Settled Expenses Section
                        if !settledExpenses.isEmpty {
                            ExpenseSectionCard(
                                title: "Settled Expenses",
                                count: settledExpenses.count,
                                expenses: settledExpenses,
                                isSettled: true,
                                onExpenseTap: { expense in
                                    impactFeedback.impactOccurred()
                                    expenseToEdit = expense
                                    showEditExpenseSheet = true
                                }
                            )
                        }
                        
                        // Empty state
                        if expenseStore.expenses.isEmpty {
                            EmptyStateCard()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Expense History")
        }
        .onAppear {
            loadPersonNames()
        }
        .task {
            await expenseStore.loadExpenses()
        }
        .sheet(isPresented: $showEditExpenseSheet) {
            if let expense = expenseToEdit {
                EditExpenseView(expense: expense) {
                    showEditExpenseSheet = false
                    expenseToEdit = nil
                    Task {
                        await expenseStore.loadExpenses()
                    }
                }
                .environmentObject(expenseStore)
                .environmentObject(supabaseService)
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

// MARK: - Custom Card Components
struct ExpenseStatsCard: View {
    let unsettledCount: Int
    let settledCount: Int
    let totalExpenses: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Expense Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Pending expenses
                VStack(spacing: 4) {
                    Text("\(unsettledCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Settled expenses
                VStack(spacing: 4) {
                    Text("\(settledCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Settled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                // Total expenses
                VStack(spacing: 4) {
                    Text("\(totalExpenses)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ExpenseSectionCard: View {
    let title: String
    let count: Int
    let expenses: [Expense]
    let isSettled: Bool
    let onExpenseTap: (Expense) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: isSettled ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(isSettled ? .green : .orange)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(expenses) { expense in
                    ModernExpenseRow(expense: expense, isSettled: isSettled)
                        .onTapGesture {
                            onExpenseTap(expense)
                        }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ModernExpenseRow: View {
    let expense: Expense
    let isSettled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isSettled ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                // Expense title or spender name
                if let title = expense.title, !title.isEmpty {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSettled ? .secondary : .primary)
                    
                    Text(expense.spender.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(expense.spender.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSettled ? .secondary : .primary)
                }
                
                if let description = expense.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Date
                Text(expense.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.amount, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSettled ? .secondary : .primary)
                
                // Status badge
                Text(isSettled ? "Settled" : "Pending")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isSettled ? Color.green : Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .opacity(isSettled ? 0.7 : 1.0)
    }
}

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                )
            
            VStack(spacing: 8) {
                Text("No expenses yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Start adding expenses to see your history here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Expense Row View (Legacy - keeping for compatibility)
struct ExpenseRowView: View {
    let expense: Expense
    let isSettled: Bool
    
    var body: some View {
        ModernExpenseRow(expense: expense, isSettled: isSettled)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ExpenseStore())
        .environmentObject(SupabaseService.shared)
}
