import Testing
import CoreData
@testable import Spending

@MainActor
struct ExpenseStoreTests {
    var store: ExpenseStore!
    
    init() async {
        let coreDataStack = CoreDataStack(inMemory: true)
        store = ExpenseStore(coreDataStack: coreDataStack)
        await store.deleteAllExpenses() // Clean slate before each test
    }

    @Test func testAddExpenseForGeorge() async {
        // Given
        let initialGeorgeTotal = store.spendingSummary.georgeTotal
        let initialBalance = store.spendingSummary.balance
        
        // When
        let amount: Decimal = 50.0
        store.addExpense(amount: amount, spender: .george, description: "Groceries")
        
        // Then
        #expect(self.store.expenses.count == 1)
        #expect(self.store.expenses.first?.spender == .george)
        #expect(self.store.spendingSummary.georgeTotal == initialGeorgeTotal + amount)
        #expect(self.store.spendingSummary.balance == initialBalance + amount)
    }
    
    @Test func testAddExpenseForJames() async {
        // Given
        let initialJamesTotal = store.spendingSummary.jamesTotal
        let initialBalance = store.spendingSummary.balance
        
        // When
        let amount: Decimal = 30.0
        store.addExpense(amount: amount, spender: .james, description: "Coffee")
        
        // Then
        #expect(self.store.expenses.count == 1)
        #expect(self.store.expenses.first?.spender == .james)
        #expect(self.store.spendingSummary.jamesTotal == initialJamesTotal + amount)
        #expect(self.store.spendingSummary.balance == initialBalance - amount)
    }
    
    @Test func testDeleteExpense() async {
        // Given
        store.addExpense(amount: 100, spender: .george, description: "Dinner")
        let expenseToDelete = store.expenses.first!
        let initialCount = store.expenses.count
        let initialBalance = store.spendingSummary.balance
        
        // When
        store.deleteExpense(withId: expenseToDelete.id)
        
        // Then
        #expect(self.store.expenses.count == initialCount - 1)
        #expect(self.store.spendingSummary.georgeTotal == 0)
        #expect(self.store.spendingSummary.balance == initialBalance - 100)
    }
    
    @Test func testMultipleExpensesBalance() async {
        // Given
        store.addExpense(amount: 50, spender: .george, description: "Gas")
        store.addExpense(amount: 25, spender: .james, description: "Snacks")
        store.addExpense(amount: 75, spender: .george, description: "Tickets")
        
        // Then
        #expect(self.store.expenses.count == 3)
        #expect(self.store.spendingSummary.georgeTotal == 125)
        #expect(self.store.spendingSummary.jamesTotal == 25)
        #expect(self.store.spendingSummary.balance == 100)
    }
    
    @Test func testExpensesAreFetchedSorted() async {
        // Given
        store.addExpense(amount: 10, spender: .george, description: "First")
        try? await Task.sleep(for: .milliseconds(10)) // Ensure timestamp is different
        store.addExpense(amount: 20, spender: .james, description: "Second")
        try? await Task.sleep(for: .milliseconds(10))
        store.addExpense(amount: 30, spender: .george, description: "Third")
        
        // When
        store.loadExpenses()
        
        // Then
        #expect(self.store.expenses.count == 3)
        #expect(self.store.expenses.first?.description == "Third")
        #expect(self.store.expenses.last?.description == "First")
    }
}