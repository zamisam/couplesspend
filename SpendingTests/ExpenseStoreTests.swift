import Testing
import Foundation
@testable import Spending

@MainActor
final class ExpenseStoreTests {
    
    // MARK: - Model Tests
    
    @Test("Expense model creation with basic properties")
    func testExpenseModelCreation() async throws {
        // Given
        let amount: Decimal = 50.0
        let spender: Person = .user
        let title = "Coffee"
        let description = "Morning coffee"
        
        // When
        let expense = Expense(amount: amount, spender: spender, title: title, description: description)
        
        // Then
        #expect(expense.amount == amount)
        #expect(expense.spender == spender)
        #expect(expense.title == title)
        #expect(expense.description == description)
        #expect(expense.settled == false)
        #expect(expense.splitType == .equal)
        #expect(expense.id != nil)
        #expect(expense.date != nil)
    }
    
    @Test("Expense model creation with different split types")
    func testExpenseModelWithSplitTypes() async throws {
        let amount: Decimal = 100.0
        
        // Test equal split
        let equalExpense = Expense(amount: amount, spender: .user, splitType: .equal)
        #expect(equalExpense.splitType == .equal)
        #expect(equalExpense.debtAmount == 50.0)
        #expect(equalExpense.debtorPerson == .partner)
        
        // Test full payment by user
        let fullExpense = Expense(amount: amount, spender: .user, splitType: .full)
        #expect(fullExpense.splitType == .full)
        #expect(fullExpense.debtAmount == 50.0)
        #expect(fullExpense.debtorPerson == .partner)
        
        // Test partner pays full
        let partnerFullExpense = Expense(amount: amount, spender: .user, splitType: .partnerFull)
        #expect(partnerFullExpense.splitType == .partnerFull)
        #expect(partnerFullExpense.debtAmount == 50.0)
        #expect(partnerFullExpense.debtorPerson == .user)
        
        // Test no split
        let noSplitExpense = Expense(amount: amount, spender: .user, splitType: .noSplit)
        #expect(noSplitExpense.splitType == .noSplit)
        #expect(noSplitExpense.debtAmount == 0.0)
        #expect(noSplitExpense.debtorPerson == nil)
    }
    
    @Test("Person enum functionality")
    func testPersonEnum() async throws {
        #expect(Person.user.rawValue == "george")
        #expect(Person.partner.rawValue == "james")
        #expect(Person.allCases.count == 2)
        
        // Test display names through PersonDisplayService
        let service = PersonDisplayService.shared
        service.updateNames(userName: "TestUser", partnerName: "TestPartner")
        
        #expect(Person.user.displayName == "TestUser")
        #expect(Person.partner.displayName == "TestPartner")
    }
    
    @Test("SplitType enum functionality")
    func testSplitTypeEnum() async throws {
        #expect(SplitType.equal.rawValue == "equal")
        #expect(SplitType.full.rawValue == "full")
        #expect(SplitType.partnerFull.rawValue == "partner_full")
        #expect(SplitType.noSplit.rawValue == "no_split")
        #expect(SplitType.allCases.count == 4)
        
        // Test display names
        #expect(SplitType.equal.displayName == "Split Equally")
        #expect(SplitType.full.displayName == "I Pay Full")
        #expect(SplitType.partnerFull.displayName == "Partner Pays Full")
        #expect(SplitType.noSplit.displayName == "No Split")
        
        // Test descriptions
        #expect(SplitType.equal.description == "Both pay half")
        #expect(SplitType.full.description == "Partner owes half")
        #expect(SplitType.partnerFull.description == "I owe half")
        #expect(SplitType.noSplit.description == "Personal expense")
    }
    
    @Test("SpendingSummary calculations with equal split")
    func testSpendingSummaryEqualSplit() async throws {
        // Given: User spends $100, Partner spends $50, both equal split
        let userExpense = Expense(amount: 100, spender: .user, title: "User expense", splitType: .equal)
        let partnerExpense = Expense(amount: 50, spender: .partner, title: "Partner expense", splitType: .equal)
        let expenses = [userExpense, partnerExpense]
        
        // When
        let summary = SpendingSummary(expenses: expenses)
        
        // Then
        #expect(summary.userTotal == 100)
        #expect(summary.partnerTotal == 50)
        // User spent $100, owes $25 for partner's expense = net $75
        // Partner spent $50, owes $50 for user's expense = net -$25 (owes $25)
        #expect(summary.balance == 25)
        #expect(summary.whoOwes == .user)
        #expect(summary.amountOwed == 25)
    }
    
    @Test("SpendingSummary calculations with mixed split types")
    func testSpendingSummaryMixedSplits() async throws {
        // Given
        let userEqualExpense = Expense(amount: 60, spender: .user, splitType: .equal) // Partner owes $30
        let partnerFullExpense = Expense(amount: 40, spender: .partner, splitType: .full) // User owes $20
        let userNoSplitExpense = Expense(amount: 20, spender: .user, splitType: .noSplit) // No debt
        let expenses = [userEqualExpense, partnerFullExpense, userNoSplitExpense]
        
        // When
        let summary = SpendingSummary(expenses: expenses)
        
        // Then
        #expect(summary.userTotal == 80) // $60 + $20
        #expect(summary.partnerTotal == 40)
        // Partner owes $30, User owes $20, net: Partner owes $10
        #expect(summary.balance == -10) // Negative means partner owes
        #expect(summary.whoOwes == .partner)
        #expect(summary.amountOwed == 10)
    }
    
    @Test("SpendingSummary with settled expenses")
    func testSpendingSummaryWithSettledExpenses() async throws {
        // Given
        let settledExpense = Expense(
            id: UUID(),
            amount: 100,
            spender: .user,
            date: Date(),
            settled: true,
            splitType: .equal
        )
        let unsettledExpense = Expense(amount: 50, spender: .partner, splitType: .equal)
        let expenses = [settledExpense, unsettledExpense]
        
        // When
        let summary = SpendingSummary(expenses: expenses)
        
        // Then - Only unsettled expenses should be counted
        #expect(summary.userTotal == 0)
        #expect(summary.partnerTotal == 50)
        #expect(summary.balance == -25) // User owes $25
        #expect(summary.whoOwes == .user)
        #expect(summary.amountOwed == 25)
    }
    
    @Test("SpendingSummary with no debt")
    func testSpendingSummaryNoDebt() async throws {
        // Given: Equal amounts, equal splits
        let userExpense = Expense(amount: 50, spender: .user, splitType: .equal)
        let partnerExpense = Expense(amount: 50, spender: .partner, splitType: .equal)
        let expenses = [userExpense, partnerExpense]
        
        // When
        let summary = SpendingSummary(expenses: expenses)
        
        // Then
        #expect(summary.userTotal == 50)
        #expect(summary.partnerTotal == 50)
        #expect(summary.balance == 0)
        #expect(summary.whoOwes == nil)
        #expect(summary.amountOwed == 0)
    }
    
    // MARK: - PersonDisplayService Tests
    
    @Test("PersonDisplayService default values")
    func testPersonDisplayServiceDefaults() async throws {
        let service = PersonDisplayService()
        
        #expect(service.currentUserName == "You")
        #expect(service.currentPartnerName == "Partner")
        #expect(service.getCurrentUserName() == "You")
        #expect(service.getCurrentPartnerName() == "Partner")
    }
    
    @Test("PersonDisplayService update names")
    func testPersonDisplayServiceUpdateNames() async throws {
        let service = PersonDisplayService()
        
        // When
        service.updateNames(userName: "Alice", partnerName: "Bob")
        
        // Then
        #expect(service.currentUserName == "Alice")
        #expect(service.currentPartnerName == "Bob")
        #expect(service.getCurrentUserName() == "Alice")
        #expect(service.getCurrentPartnerName() == "Bob")
    }
    
    @Test("PersonDisplayService update with nil partner name")
    func testPersonDisplayServiceNilPartnerName() async throws {
        let service = PersonDisplayService()
        
        // When
        service.updateNames(userName: "Alice", partnerName: nil)
        
        // Then
        #expect(service.currentUserName == "Alice")
        #expect(service.currentPartnerName == "Partner") // Should fallback to default
    }
    
    // MARK: - ExpenseStore Tests (requires mocking)
    
    @Test("ExpenseStore initialization")
    func testExpenseStoreInitialization() async throws {
        // Given
        let mockService = MockSupabaseService()
        
        // When
        let store = ExpenseStore(supabaseService: mockService)
        
        // Then
        #expect(store.expenses.isEmpty)
        #expect(store.spendingSummary.userTotal == 0)
        #expect(store.spendingSummary.partnerTotal == 0)
        #expect(store.isLoading == false)
        #expect(store.errorMessage == nil)
    }
    
    @Test("ExpenseStore getTotalSpending")
    func testExpenseStoreGetTotalSpending() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let userExpense1 = Expense(amount: 50, spender: .user)
        let userExpense2 = Expense(amount: 30, spender: .user)
        let partnerExpense = Expense(amount: 25, spender: .partner)
        
        store.expenses = [userExpense1, userExpense2, partnerExpense]
        
        // When & Then
        #expect(store.getTotalSpending(for: .user) == 80)
        #expect(store.getTotalSpending(for: .partner) == 25)
    }
    
    @Test("ExpenseStore getSpendingBalance")
    func testExpenseStoreGetSpendingBalance() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let userExpense = Expense(amount: 100, spender: .user)
        let partnerExpense = Expense(amount: 40, spender: .partner)
        
        store.expenses = [userExpense, partnerExpense]
        
        // When & Then
        #expect(store.getSpendingBalance() == 60) // User spent $60 more
    }
    
    @Test("ExpenseStore getDebtInfo")
    func testExpenseStoreGetDebtInfo() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let userExpense = Expense(amount: 100, spender: .user)
        let partnerExpense = Expense(amount: 20, spender: .partner)
        
        store.expenses = [userExpense, partnerExpense]
        
        // When
        let debtInfo = store.getDebtInfo()
        
        // Then
        #expect(debtInfo.whoOwes == .partner)
        #expect(debtInfo.amountOwed == 40) // Partner owes half of the $80 difference
    }
    
    @Test("ExpenseStore getUnsettledExpenses")
    func testExpenseStoreGetUnsettledExpenses() async throws {
        // Given
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        let settledExpense = Expense(
            id: UUID(),
            amount: 50,
            spender: .user,
            date: Date(),
            settled: true
        )
        let unsettledExpense1 = Expense(amount: 30, spender: .user)
        let unsettledExpense2 = Expense(amount: 20, spender: .partner)
        
        store.expenses = [settledExpense, unsettledExpense1, unsettledExpense2]
        
        // When
        let unsettledExpenses = store.getUnsettledExpenses()
        
        // Then
        #expect(unsettledExpenses.count == 2)
        #expect(unsettledExpenses.contains { $0.id == unsettledExpense1.id })
        #expect(unsettledExpenses.contains { $0.id == unsettledExpense2.id })
        #expect(!unsettledExpenses.contains { $0.id == settledExpense.id })
    }
}

// MARK: - Mock Classes

class MockSupabaseService: SupabaseService {
    var mockSession: Session?
    var mockExpenses: [Expense] = []
    var shouldFailNextOperation = false
    var lastCreatedExpense: Expense?
    var lastUpdatedExpense: Expense?
    var lastDeletedExpenseId: UUID?
    
    override var session: Session? {
        get { mockSession }
        set { mockSession = newValue }
    }
    
    override func fetchExpenses() async throws -> [Expense] {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw MockError.fetchFailed
        }
        return mockExpenses
    }
    
    override func createExpense(_ expense: Expense) async throws -> Expense {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw MockError.createFailed
        }
        lastCreatedExpense = expense
        mockExpenses.append(expense)
        return expense
    }
    
    override func updateExpense(_ expense: Expense) async throws -> Expense {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw MockError.updateFailed
        }
        lastUpdatedExpense = expense
        if let index = mockExpenses.firstIndex(where: { $0.id == expense.id }) {
            mockExpenses[index] = expense
        }
        return expense
    }
    
    override func deleteExpense(withId id: UUID) async throws {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw MockError.deleteFailed
        }
        lastDeletedExpenseId = id
        mockExpenses.removeAll { $0.id == id }
    }
    
    override func settleExpense(withId id: UUID) async throws -> Expense {
        if shouldFailNextOperation {
            shouldFailNextOperation = false
            throw MockError.settleFailed
        }
        
        guard let index = mockExpenses.firstIndex(where: { $0.id == id }) else {
            throw MockError.expenseNotFound
        }
        
        let originalExpense = mockExpenses[index]
        let settledExpense = Expense(
            id: originalExpense.id,
            amount: originalExpense.amount,
            spender: originalExpense.spender,
            date: originalExpense.date,
            title: originalExpense.title,
            description: originalExpense.description,
            settled: true,
            settledDate: Date(),
            userId: originalExpense.userId,
            splitType: originalExpense.splitType,
            debtAmount: originalExpense.debtAmount,
            debtorPerson: originalExpense.debtorPerson
        )
        
        mockExpenses[index] = settledExpense
        return settledExpense
    }
}

enum MockError: Error, LocalizedError {
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    case settleFailed
    case expenseNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed: return "Failed to fetch expenses"
        case .createFailed: return "Failed to create expense"
        case .updateFailed: return "Failed to update expense"
        case .deleteFailed: return "Failed to delete expense"
        case .settleFailed: return "Failed to settle expense"
        case .expenseNotFound: return "Expense not found"
        }
    }
}
