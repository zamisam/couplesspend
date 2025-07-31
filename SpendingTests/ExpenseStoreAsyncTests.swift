//
//  ExpenseStoreAsyncTests.swift
//  SpendingTests
//
//  Created by GitHub Copilot on 2025-07-31.
//

import Testing
import Foundation
@testable import Spending

@MainActor
final class ExpenseStoreAsyncTests {
    
    // MARK: - Async Operation Tests
    
    @Test("ExpenseStore addExpense success")
    func testAddExpenseSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        let initialCount = store.expenses.count
        
        // When
        await store.addExpense(
            amount: 25.50,
            spender: .user,
            title: "Coffee",
            description: "Morning coffee",
            splitType: .equal
        )
        
        // Then
        #expect(store.expenses.count == initialCount + 1)
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
        #expect(mockService.lastCreatedExpense != nil)
        #expect(mockService.lastCreatedExpense?.amount == 25.50)
        #expect(mockService.lastCreatedExpense?.title == "Coffee")
    }
    
    @Test("ExpenseStore addExpense failure")
    func testAddExpenseFailure() async throws {
        // Given
        let mockService = MockSupabaseService()
        mockService.shouldFailNextOperation = true
        let store = ExpenseStore(supabaseService: mockService)
        let initialCount = store.expenses.count
        
        // When
        await store.addExpense(
            amount: 25.50,
            spender: .user,
            title: "Coffee"
        )
        
        // Then
        #expect(store.expenses.count == initialCount) // No change
        #expect(store.errorMessage != nil)
        #expect(store.errorMessage?.contains("Failed to add expense") == true)
        #expect(store.isLoading == false)
    }
    
    @Test("ExpenseStore updateExpense success")
    func testUpdateExpenseSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let originalExpense = Expense(amount: 50, spender: .user, title: "Original")
        store.expenses = [originalExpense]
        
        let updatedExpense = Expense(
            id: originalExpense.id,
            amount: 75,
            spender: .partner,
            date: originalExpense.date,
            title: "Updated",
            description: "Updated description"
        )
        
        // When
        await store.updateExpense(updatedExpense)
        
        // Then
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
        #expect(mockService.lastUpdatedExpense?.id == updatedExpense.id)
        #expect(mockService.lastUpdatedExpense?.title == "Updated")
        #expect(store.expenses.first?.title == "Updated")
    }
    
    @Test("ExpenseStore deleteExpense success")
    func testDeleteExpenseSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let expense1 = Expense(amount: 50, spender: .user)
        let expense2 = Expense(amount: 30, spender: .partner)
        store.expenses = [expense1, expense2]
        
        // When
        await store.deleteExpense(withId: expense1.id)
        
        // Then
        #expect(store.expenses.count == 1)
        #expect(store.expenses.first?.id == expense2.id)
        #expect(store.errorMessage == nil)
        #expect(mockService.lastDeletedExpenseId == expense1.id)
    }
    
    @Test("ExpenseStore loadExpenses success")
    func testLoadExpensesSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let mockExpenses = [
            Expense(amount: 50, spender: .user, title: "Expense 1"),
            Expense(amount: 30, spender: .partner, title: "Expense 2")
        ]
        mockService.mockExpenses = mockExpenses
        
        // When
        await store.loadExpenses()
        
        // Then
        #expect(store.expenses.count == 2)
        #expect(store.expenses[0].title == "Expense 1")
        #expect(store.expenses[1].title == "Expense 2")
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
    }
    
    @Test("ExpenseStore settleExpense success")
    func testSettleExpenseSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let unsettledExpense = Expense(amount: 50, spender: .user, title: "Unsettled")
        store.expenses = [unsettledExpense]
        mockService.mockExpenses = [unsettledExpense]
        
        // When
        await store.settleExpense(withId: unsettledExpense.id)
        
        // Then
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
        #expect(store.expenses.first?.settled == true)
        #expect(store.expenses.first?.settledDate != nil)
    }
    
    @Test("ExpenseStore settleExpenses success")
    func testSettleExpensesSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let expense1 = Expense(amount: 50, spender: .user, title: "Expense 1")
        let expense2 = Expense(amount: 30, spender: .partner, title: "Expense 2")
        let settledExpense = Expense(
            id: UUID(),
            amount: 25,
            spender: .user,
            date: Date(),
            settled: true
        )
        
        store.expenses = [expense1, expense2, settledExpense]
        mockService.mockExpenses = [expense1, expense2, settledExpense]
        
        // When
        await store.settleExpenses()
        
        // Then
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
        
        // All originally unsettled expenses should now be settled
        let unsettledCount = store.expenses.filter { !$0.settled }.count
        #expect(unsettledCount == 0)
    }
    
    @Test("ExpenseStore deleteAllExpenses success")
    func testDeleteAllExpensesSuccess() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let expenses = [
            Expense(amount: 50, spender: .user),
            Expense(amount: 30, spender: .partner),
            Expense(amount: 25, spender: .user)
        ]
        store.expenses = expenses
        mockService.mockExpenses = expenses
        
        // When
        await store.deleteAllExpenses()
        
        // Then
        #expect(store.expenses.isEmpty)
        #expect(store.errorMessage == nil)
        #expect(store.isLoading == false)
        #expect(mockService.mockExpenses.isEmpty)
    }
    
    // MARK: - Summary Update Tests
    
    @Test("ExpenseStore spendingSummary updates automatically")
    func testSpendingSummaryAutoUpdate() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // Initially empty
        #expect(store.spendingSummary.userTotal == 0)
        #expect(store.spendingSummary.partnerTotal == 0)
        
        // When
        let userExpense = Expense(amount: 100, spender: .user)
        let partnerExpense = Expense(amount: 50, spender: .partner)
        store.expenses = [userExpense, partnerExpense]
        
        // Give time for the publisher to update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        #expect(store.spendingSummary.userTotal == 100)
        #expect(store.spendingSummary.partnerTotal == 50)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ExpenseStore handles multiple operation failures gracefully")
    func testMultipleFailures() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // When - Multiple failing operations
        mockService.shouldFailNextOperation = true
        await store.addExpense(amount: 50, spender: .user)
        
        mockService.shouldFailNextOperation = true
        await store.loadExpenses()
        
        let expense = Expense(amount: 25, spender: .user)
        store.expenses = [expense]
        mockService.shouldFailNextOperation = true
        await store.deleteExpense(withId: expense.id)
        
        // Then - Store should be in consistent state
        #expect(store.isLoading == false)
        #expect(store.errorMessage != nil) // Should have the last error
        #expect(store.expenses.count == 1) // Delete should have failed
    }
    
    // MARK: - Edge Cases
    
    @Test("ExpenseStore handles empty operations gracefully")
    func testEmptyOperations() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // When - Operations on empty store
        await store.deleteAllExpenses() // Should not fail
        await store.settleExpenses() // Should not fail
        let unsettled = store.getUnsettledExpenses()
        let recent = store.getRecentExpenses(limit: 10)
        
        // Then
        #expect(store.errorMessage == nil)
        #expect(unsettled.isEmpty)
        #expect(recent.isEmpty)
        #expect(store.getTotalSpending(for: .user) == 0)
        #expect(store.getTotalSpending(for: .partner) == 0)
    }
    
    @Test("ExpenseStore getRecentExpenses respects limit")
    func testGetRecentExpensesLimit() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // Create more expenses than the limit
        let expenses = (1...10).map { i in
            Expense(amount: Decimal(i * 10), spender: .user, title: "Expense \(i)")
        }
        store.expenses = expenses
        
        // When
        let recent3 = store.getRecentExpenses(limit: 3)
        let recent5 = store.getRecentExpenses(limit: 5)
        let recentDefault = store.getRecentExpenses() // Default limit 50
        
        // Then
        #expect(recent3.count == 3)
        #expect(recent5.count == 5)
        #expect(recentDefault.count == 10) // All expenses, less than default limit
    }
    
    @Test("ExpenseStore getExpenses filters by person correctly")
    func testGetExpensesByPerson() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let userExpenses = [
            Expense(amount: 50, spender: .user, title: "User 1"),
            Expense(amount: 30, spender: .user, title: "User 2")
        ]
        let partnerExpenses = [
            Expense(amount: 25, spender: .partner, title: "Partner 1")
        ]
        
        store.expenses = userExpenses + partnerExpenses
        
        // When
        let userResults = store.getExpenses(for: .user)
        let partnerResults = store.getExpenses(for: .partner)
        
        // Then
        #expect(userResults.count == 2)
        #expect(partnerResults.count == 1)
        #expect(userResults.allSatisfy { $0.spender == .user })
        #expect(partnerResults.allSatisfy { $0.spender == .partner })
        #expect(userResults.contains { $0.title == "User 1" })
        #expect(partnerResults.contains { $0.title == "Partner 1" })
    }
}