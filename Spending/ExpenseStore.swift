//
//  ExpenseStore.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation
import CoreData
import Combine

@MainActor
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var spendingSummary: SpendingSummary = SpendingSummary(expenses: [])
    
    private let coreDataStack: CoreDataStack
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadExpenses()
        
        // Update summary whenever expenses change
        $expenses
            .map { SpendingSummary(expenses: $0) }
            .assign(to: \.spendingSummary, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new expense
    func addExpense(amount: Decimal, spender: Person, description: String? = nil) {
        let expense = Expense(amount: amount, spender: spender, description: description)
        
        // Save to Core Data
        let expenseEntity = ExpenseEntity.fromExpense(expense, context: coreDataStack.viewContext)
        coreDataStack.save()
        
        // Update local array
        expenses.insert(expense, at: 0) // Insert at beginning for newest first
    }
    
    /// Delete an expense by ID
    func deleteExpense(withId id: UUID) {
        // Remove from Core Data
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            if let expenseEntity = results.first {
                coreDataStack.viewContext.delete(expenseEntity)
                coreDataStack.save()
                
                // Remove from local array
                expenses.removeAll { $0.id == id }
            }
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    /// Update an existing expense
    func updateExpense(_ expense: Expense) {
        // Find and update in Core Data
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
        
        do {
            let results = try coreDataStack.viewContext.fetch(request)
            if let expenseEntity = results.first {
                expenseEntity.amount = expense.amount as NSDecimalNumber
                expenseEntity.spender = expense.spender.rawValue
                expenseEntity.descriptionText = expense.description
                coreDataStack.save()
                
                // Update local array
                if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
                    expenses[index] = expense
                }
            }
        } catch {
            print("Error updating expense: \(error)")
        }
    }
    
    /// Load all expenses from Core Data
    func loadExpenses() {
        let expenseEntities = coreDataStack.fetchExpenses()
        expenses = expenseEntities.compactMap { $0.toExpense() }
    }
    
    /// Delete all expenses
    func deleteAllExpenses() {
        coreDataStack.deleteAllExpenses()
        expenses.removeAll()
    }
    
    // MARK: - Spending Summary Calculations
    
    /// Get total spending for a specific person
    func getTotalSpending(for person: Person) -> Decimal {
        return expenses
            .filter { $0.spender == person }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Get the overall spending balance (positive means person one spent more)
    func getSpendingBalance() -> Decimal {
        return getTotalSpending(for: .george) - getTotalSpending(for: .james)
    }
    
    /// Get who owes money and how much
    func getDebtInfo() -> (whoOwes: Person?, amountOwed: Decimal) {
        let balance = getSpendingBalance()
        
        if balance > 0 {
            // George has paid more, James owes George
            return (.james, balance / 2)
        } else if balance < 0 {
            // James has paid more, George owes James
            return (.george, abs(balance) / 2)
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
}