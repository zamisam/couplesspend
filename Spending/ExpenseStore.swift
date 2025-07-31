//
//  ExpenseStore.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation
import Combine

@MainActor
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var spendingSummary: SpendingSummary = SpendingSummary(expenses: [])
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let supabaseService: SupabaseService
    private var cancellables = Set<AnyCancellable>()
    
    init(supabaseService: SupabaseService = SupabaseService.shared) {
        print("ExpenseStore.init called")
        print("SupabaseService instance: \(ObjectIdentifier(supabaseService))")
        print("SupabaseService.shared instance: \(ObjectIdentifier(SupabaseService.shared))")
        print("Are they the same? \(supabaseService === SupabaseService.shared)")
        print("Session exists at init: \(supabaseService.session != nil)")
        
        self.supabaseService = supabaseService
        
        // Update summary whenever expenses change
        $expenses
            .map { SpendingSummary(expenses: $0) }
            .assign(to: \.spendingSummary, on: self)
            .store(in: &cancellables)
        
        // Listen for session changes and load expenses when authenticated
        supabaseService.$session
            .sink { [weak self] session in
                if session != nil {
                    Task { @MainActor in
                        await self?.loadExpenses()
                    }
                } else {
                    // Clear expenses when user logs out
                    self?.expenses = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new expense
    func addExpense(amount: Decimal, spender: Person, title: String? = nil, description: String? = nil, splitType: SplitType = .equal) async {
        print("=== ExpenseStore.addExpense called ===")
        print("ExpenseStore instance: \(ObjectIdentifier(self))")
        print("SupabaseService instance: \(ObjectIdentifier(supabaseService))")
        print("SupabaseService.shared instance: \(ObjectIdentifier(SupabaseService.shared))")
        print("Are service instances the same? \(supabaseService === SupabaseService.shared)")
        print("SupabaseService session exists: \(supabaseService.session != nil)")
        print("SupabaseService.shared session exists: \(SupabaseService.shared.session != nil)")
        
        if let session = supabaseService.session {
            print("ExpenseStore session user: \(session.user.email ?? "unknown")")
        } else {
            print("ExpenseStore: NO SESSION FOUND")
        }
        
        if let sharedSession = SupabaseService.shared.session {
            print("Shared service session user: \(sharedSession.user.email ?? "unknown")")
        } else {
            print("Shared service: NO SESSION FOUND")
        }

        do {
            isLoading = true
            errorMessage = nil
            
            let expense = Expense(amount: amount, spender: spender, title: title, description: description, splitType: splitType)
            let newExpense = try await supabaseService.createExpense(expense)            // Update local array
            expenses.insert(newExpense, at: 0) // Insert at beginning for newest first
            
        } catch {
            errorMessage = "Failed to add expense: \(error.localizedDescription)"
            print("Error adding expense: \(error)")
        }
        
        isLoading = false
    }
    
    /// Delete an expense by ID
    func deleteExpense(withId id: UUID) async {
        do {
            isLoading = true
            errorMessage = nil
            
            try await supabaseService.deleteExpense(withId: id)
            
            // Remove from local array
            expenses.removeAll { $0.id == id }
            
        } catch {
            errorMessage = "Failed to delete expense: \(error.localizedDescription)"
            print("Error deleting expense: \(error)")
        }
        
        isLoading = false
    }
    
    /// Update an existing expense
    func updateExpense(_ expense: Expense) async {
        do {
            isLoading = true
            errorMessage = nil
            
            let updatedExpense = try await supabaseService.updateExpense(expense)
            
            // Update local array
            if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[index] = updatedExpense
            }
            
        } catch {
            errorMessage = "Failed to update expense: \(error.localizedDescription)"
            print("Error updating expense: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load all expenses from Supabase
    func loadExpenses() async {
        do {
            isLoading = true
            errorMessage = nil
            
            expenses = try await supabaseService.fetchExpenses()
            
        } catch {
            errorMessage = "Failed to load expenses: \(error.localizedDescription)"
            print("Error loading expenses: \(error)")
        }
        
        isLoading = false
    }
    
    /// Delete all expenses
    func deleteAllExpenses() async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Delete all expenses one by one (Supabase doesn't have bulk delete in this implementation)
            for expense in expenses {
                try await supabaseService.deleteExpense(withId: expense.id)
            }
            
            expenses.removeAll()
            
        } catch {
            errorMessage = "Failed to delete all expenses: \(error.localizedDescription)"
            print("Error deleting all expenses: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Spending Summary Calculations
    
    /// Get total spending for a specific person
    func getTotalSpending(for person: Person) -> Decimal {
        return expenses
            .filter { $0.spender == person && !$0.settled }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Get the overall spending balance (positive means user spent more)
    func getSpendingBalance() -> Decimal {
        return getTotalSpending(for: .user) - getTotalSpending(for: .partner)
    }
    
    /// Get who owes money and how much
    func getDebtInfo() -> (whoOwes: Person?, amountOwed: Decimal) {
        let balance = getSpendingBalance()
        
        if balance > 0 {
            return (.partner, balance / 2)
        } else if balance < 0 {
            return (.user, abs(balance) / 2)
        } else {
            return (nil, 0)
        }
    }
    
    /// Get expenses for a specific person
    func getExpenses(for person: Person) -> [Expense] {
        return expenses.filter { $0.spender == person }
    }
    
    /// Get recent expenses (limited count)
    func getRecentExpenses(limit: Int = 50) -> [Expense] {
        return Array(expenses.prefix(limit))
    }
    
    /// Get unsettled expenses
    func getUnsettledExpenses() -> [Expense] {
        let unsettled = expenses.filter { !$0.settled }
        print("Total expenses: \(expenses.count)")
        print("Unsettled expenses: \(unsettled.count)")
        
        // Debug: Print all expenses with their settled status
        for (index, expense) in expenses.enumerated() {
            print("Expense \(index + 1): Amount: \(expense.amount), Settled: \(expense.settled), ID: \(expense.id)")
        }
        
        return unsettled
    }
    
    /// Settle an expense
    func settleExpense(withId id: UUID) async {
        do {
            isLoading = true
            errorMessage = nil
            
            let settledExpense = try await supabaseService.settleExpense(withId: id)
            
            // Update local array
            if let index = expenses.firstIndex(where: { $0.id == id }) {
                expenses[index] = settledExpense
            }
            
        } catch {
            errorMessage = "Failed to settle expense: \(error.localizedDescription)"
            print("Error settling expense: \(error)")
        }
        
        isLoading = false
    }
    
    /// Settle all unsettled expenses
    func settleExpenses() async {
        do {
            isLoading = true
            errorMessage = nil
            
            let unsettledExpenses = getUnsettledExpenses()
            print("Found \(unsettledExpenses.count) unsettled expenses to settle")
            
            if unsettledExpenses.isEmpty {
                print("No unsettled expenses to settle")
                isLoading = false
                return
            }
            
            for expense in unsettledExpenses {
                print("Settling expense: \(expense.id) - Amount: \(expense.amount)")
                let settledExpense = try await supabaseService.settleExpense(withId: expense.id)
                print("Successfully settled expense: \(settledExpense.id), settled: \(settledExpense.settled)")
                
                // Update the local expense in the array
                if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                    await MainActor.run {
                        expenses[index] = settledExpense
                    }
                }
            }
            
            // Reload expenses to get updated data
            print("Reloading expenses after settling...")
            await loadExpenses()
            print("Expenses reloaded. Total expenses: \(expenses.count)")
            
        } catch {
            errorMessage = "Failed to settle expenses: \(error.localizedDescription)"
            print("Error settling expenses: \(error)")
        }
        
        isLoading = false
    }
}