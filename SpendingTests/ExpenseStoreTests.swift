import Testing
import Foundation
@testable import Spending

@MainActor
final class ExpenseStoreTests {
    
    @Test("Models can be created correctly")
    func testExpenseModelCreation() async throws {
        // Given
        let amount: Decimal = 50.0
        let spender: Person = .george
        let description = "Test expense"
        
        // When
        let expense = Expense(amount: amount, spender: spender, description: description)
        
        // Then
        #expect(expense.amount == amount)
        #expect(expense.spender == spender)
        #expect(expense.description == description)
        #expect(expense.settled == false)
    }
    
    @Test("Person enum has correct display names")
    func testPersonDisplayNames() async throws {
        // Then
        #expect(Person.george.displayName == "George")
        #expect(Person.james.displayName == "James")
    }
    
    @Test("SpendingSummary calculates totals correctly")
    func testSpendingSummaryCalculation() async throws {
        // Given
        let georgeExpense = Expense(amount: 100, spender: .george, description: "George's expense")
        let jamesExpense = Expense(amount: 50, spender: .james, description: "James's expense")
        let expenses = [georgeExpense, jamesExpense]
        
        // When
        let summary = SpendingSummary(expenses: expenses)
        
        // Then
        #expect(summary.georgeTotal == 100)
        #expect(summary.jamesTotal == 50)
        #expect(summary.amountOwed == 25) // George spent 50 more than James, so they owe George 25
    }
}
