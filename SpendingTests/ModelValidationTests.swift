//
//  ModelValidationTests.swift
//  SpendingTests
//
//  Created by GitHub Copilot on 2025-07-31.
//

import Testing
import Foundation
@testable import Spending

@MainActor
final class ModelValidationTests {
    
    // MARK: - Expense Validation Tests
    
    @Test("Expense model validation with edge cases")
    func testExpenseValidationEdgeCases() async throws {
        // Test with zero amount
        let zeroExpense = Expense(amount: 0, spender: .user, title: "Zero expense")
        #expect(zeroExpense.amount == 0)
        #expect(zeroExpense.debtAmount == 0) // For equal split of zero
        
        // Test with very large amount
        let largeExpense = Expense(amount: 999999.99, spender: .user, splitType: .equal)
        #expect(largeExpense.amount == 999999.99)
        #expect(largeExpense.debtAmount == 499999.995) // Half for equal split
        
        // Test with very small amount
        let smallExpense = Expense(amount: 0.01, spender: .partner, splitType: .equal)
        #expect(smallExpense.amount == 0.01)
        #expect(smallExpense.debtAmount == 0.005)
        
        // Test with negative amount (though this shouldn't happen in UI)
        let negativeExpense = Expense(amount: -50, spender: .user, splitType: .equal)
        #expect(negativeExpense.amount == -50)
        #expect(negativeExpense.debtAmount == -25) // Half of negative
    }
    
    @Test("Expense model with empty and nil strings")
    func testExpenseWithEmptyStrings() async throws {
        // Test with empty title and description
        let emptyExpense = Expense(amount: 50, spender: .user, title: "", description: "")
        #expect(emptyExpense.title == "")
        #expect(emptyExpense.description == "")
        
        // Test with nil title and description
        let nilExpense = Expense(amount: 50, spender: .user, title: nil, description: nil)
        #expect(nilExpense.title == nil)
        #expect(nilExpense.description == nil)
        
        // Test with whitespace-only strings
        let whitespaceExpense = Expense(amount: 50, spender: .user, title: "   ", description: "\n\t")
        #expect(whitespaceExpense.title == "   ")
        #expect(whitespaceExpense.description == "\n\t")
    }
    
    @Test("Expense model with very long strings")
    func testExpenseWithLongStrings() async throws {
        let longTitle = String(repeating: "A", count: 1000)
        let longDescription = String(repeating: "B", count: 5000)
        
        let longExpense = Expense(
            amount: 50,
            spender: .user,
            title: longTitle,
            description: longDescription
        )
        
        #expect(longExpense.title == longTitle)
        #expect(longExpense.description == longDescription)
        #expect(longExpense.title?.count == 1000)
        #expect(longExpense.description?.count == 5000)
    }
    
    @Test("Expense model with special characters")
    func testExpenseWithSpecialCharacters() async throws {
        let specialTitle = "Coffee ☕️ & Pastry 🥐 - @Café München (€15.50)"
        let specialDescription = "Business meeting with John & Jane\nIncluded: 2x coffee, 1x croissant\n#work #breakfast"
        
        let specialExpense = Expense(
            amount: 15.50,
            spender: .user,
            title: specialTitle,
            description: specialDescription
        )
        
        #expect(specialExpense.title == specialTitle)
        #expect(specialExpense.description == specialDescription)
    }
    
    // MARK: - Date Handling Tests
    
    @Test("Expense model date handling")
    func testExpenseDateHandling() async throws {
        let specificDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        
        let expense = Expense(
            id: UUID(),
            amount: 50,
            spender: .user,
            date: specificDate,
            title: "New Year Expense"
        )
        
        #expect(expense.date == specificDate)
        
        // Test that new expenses get current date
        let newExpense = Expense(amount: 25, spender: .partner)
        let now = Date()
        let timeDifference = abs(newExpense.date.timeIntervalSince(now))
        #expect(timeDifference < 1.0) // Should be within 1 second
    }
    
    @Test("Expense model settled date handling")
    func testExpenseSettledDateHandling() async throws {
        let settledDate = Date()
        
        let settledExpense = Expense(
            id: UUID(),
            amount: 50,
            spender: .user,
            date: Date(),
            settled: true,
            settledDate: settledDate
        )
        
        #expect(settledExpense.settled == true)
        #expect(settledExpense.settledDate == settledDate)
        
        // Test unsettled expense
        let unsettledExpense = Expense(amount: 30, spender: .partner)
        #expect(unsettledExpense.settled == false)
        #expect(unsettledExpense.settledDate == nil)
    }
    
    // MARK: - UUID Handling Tests
    
    @Test("Expense model UUID uniqueness")
    func testExpenseUUIDUniqueness() async throws {
        let expense1 = Expense(amount: 50, spender: .user)
        let expense2 = Expense(amount: 50, spender: .user)
        
        #expect(expense1.id != expense2.id)
        #expect(expense1.id.uuidString != expense2.id.uuidString)
    }
    
    @Test("Expense model with specific UUID")
    func testExpenseWithSpecificUUID() async throws {
        let specificUUID = UUID()
        
        let expense = Expense(
            id: specificUUID,
            amount: 50,
            spender: .user,
            date: Date()
        )
        
        #expect(expense.id == specificUUID)
    }
    
    // MARK: - Person Enum Validation Tests
    
    @Test("Person enum case coverage")
    func testPersonEnumCases() async throws {
        let allCases = Person.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.user))
        #expect(allCases.contains(.partner))
    }
    
    @Test("Person enum raw values")
    func testPersonEnumRawValues() async throws {
        #expect(Person.user.rawValue == "george")
        #expect(Person.partner.rawValue == "james")
        
        // Test round-trip conversion
        #expect(Person(rawValue: "george") == .user)
        #expect(Person(rawValue: "james") == .partner)
        #expect(Person(rawValue: "invalid") == nil)
    }
    
    // MARK: - SplitType Enum Validation Tests
    
    @Test("SplitType enum case coverage")
    func testSplitTypeEnumCases() async throws {
        let allCases = SplitType.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.equal))
        #expect(allCases.contains(.full))
        #expect(allCases.contains(.partnerFull))
        #expect(allCases.contains(.noSplit))
    }
    
    @Test("SplitType enum raw values")
    func testSplitTypeEnumRawValues() async throws {
        #expect(SplitType.equal.rawValue == "equal")
        #expect(SplitType.full.rawValue == "full")
        #expect(SplitType.partnerFull.rawValue == "partner_full")
        #expect(SplitType.noSplit.rawValue == "no_split")
        
        // Test round-trip conversion
        #expect(SplitType(rawValue: "equal") == .equal)
        #expect(SplitType(rawValue: "full") == .full)
        #expect(SplitType(rawValue: "partner_full") == .partnerFull)
        #expect(SplitType(rawValue: "no_split") == .noSplit)
        #expect(SplitType(rawValue: "invalid") == nil)
    }
    
    // MARK: - Debt Calculation Validation Tests
    
    @Test("Debt calculation accuracy for equal split")
    func testDebtCalculationEqualSplit() async throws {
        let testCases: [(amount: Decimal, expectedDebt: Decimal)] = [
            (100, 50),
            (50.50, 25.25),
            (33.33, 16.665),
            (0.01, 0.005),
            (999.99, 499.995)
        ]
        
        for testCase in testCases {
            let userExpense = Expense(amount: testCase.amount, spender: .user, splitType: .equal)
            #expect(userExpense.debtAmount == testCase.expectedDebt)
            #expect(userExpense.debtorPerson == .partner)
            
            let partnerExpense = Expense(amount: testCase.amount, spender: .partner, splitType: .equal)
            #expect(partnerExpense.debtAmount == testCase.expectedDebt)
            #expect(partnerExpense.debtorPerson == .user)
        }
    }
    
    @Test("Debt calculation for full payment scenarios")
    func testDebtCalculationFullPayment() async throws {
        let amount: Decimal = 100
        
        // User pays full
        let userFullExpense = Expense(amount: amount, spender: .user, splitType: .full)
        #expect(userFullExpense.debtAmount == 50)
        #expect(userFullExpense.debtorPerson == .partner)
        
        // Partner pays full (initiated by user)
        let partnerFullExpense = Expense(amount: amount, spender: .user, splitType: .partnerFull)
        #expect(partnerFullExpense.debtAmount == 50)
        #expect(partnerFullExpense.debtorPerson == .user)
        
        // Partner pays full (initiated by partner)
        let partnerFullExpense2 = Expense(amount: amount, spender: .partner, splitType: .partnerFull)
        #expect(partnerFullExpense2.debtAmount == 50)
        #expect(partnerFullExpense2.debtorPerson == .partner)
    }
    
    @Test("Debt calculation for no split")
    func testDebtCalculationNoSplit() async throws {
        let amounts: [Decimal] = [0, 50, 100.50, 999.99]
        
        for amount in amounts {
            let userNoSplitExpense = Expense(amount: amount, spender: .user, splitType: .noSplit)
            #expect(userNoSplitExpense.debtAmount == 0)
            #expect(userNoSplitExpense.debtorPerson == nil)
            
            let partnerNoSplitExpense = Expense(amount: amount, spender: .partner, splitType: .noSplit)
            #expect(partnerNoSplitExpense.debtAmount == 0)
            #expect(partnerNoSplitExpense.debtorPerson == nil)
        }
    }
    
    // MARK: - SpendingSummary Edge Cases
    
    @Test("SpendingSummary with empty expense list")
    func testSpendingSummaryEmpty() async throws {
        let summary = SpendingSummary(expenses: [])
        
        #expect(summary.userTotal == 0)
        #expect(summary.partnerTotal == 0)
        #expect(summary.balance == 0)
        #expect(summary.whoOwes == nil)
        #expect(summary.amountOwed == 0)
    }
    
    @Test("SpendingSummary with only settled expenses")
    func testSpendingSummaryOnlySettled() async throws {
        let settledExpenses = [
            Expense(
                id: UUID(),
                amount: 100,
                spender: .user,
                date: Date(),
                settled: true
            ),
            Expense(
                id: UUID(),
                amount: 50,
                spender: .partner,
                date: Date(),
                settled: true
            )
        ]
        
        let summary = SpendingSummary(expenses: settledExpenses)
        
        #expect(summary.userTotal == 0)
        #expect(summary.partnerTotal == 0)
        #expect(summary.balance == 0)
        #expect(summary.whoOwes == nil)
        #expect(summary.amountOwed == 0)
    }
    
    @Test("SpendingSummary with mixed split types complex scenario")
    func testSpendingSummaryComplexScenario() async throws {
        let expenses = [
            // User pays $100, equal split -> Partner owes $50
            Expense(amount: 100, spender: .user, splitType: .equal),
            
            // Partner pays $60, equal split -> User owes $30
            Expense(amount: 60, spender: .partner, splitType: .equal),
            
            // User pays $80, full payment -> Partner owes $40
            Expense(amount: 80, spender: .user, splitType: .full),
            
            // Partner pays $40, user gets full benefit -> User owes $20
            Expense(amount: 40, spender: .partner, splitType: .partnerFull),
            
            // User personal expense $20 -> No debt
            Expense(amount: 20, spender: .user, splitType: .noSplit),
            
            // Partner personal expense $30 -> No debt
            Expense(amount: 30, spender: .partner, splitType: .noSplit)
        ]
        
        let summary = SpendingSummary(expenses: expenses)
        
        // Total spending
        #expect(summary.userTotal == 200) // $100 + $80 + $20
        #expect(summary.partnerTotal == 130) // $60 + $40 + $30
        
        // Net debt calculation:
        // Partner owes: $50 (equal) + $40 (full) = $90
        // User owes: $30 (equal) + $20 (partner full) = $50
        // Net: Partner owes $40
        #expect(summary.balance == -40)
        #expect(summary.whoOwes == .partner)
        #expect(summary.amountOwed == 40)
    }
    
    @Test("SpendingSummary with fractional amounts")
    func testSpendingSummaryFractional() async throws {
        let expenses = [
            Expense(amount: 33.33, spender: .user, splitType: .equal),    // Partner owes $16.665
            Expense(amount: 66.67, spender: .partner, splitType: .equal)  // User owes $33.335
        ]
        
        let summary = SpendingSummary(expenses: expenses)
        
        #expect(summary.userTotal == 33.33)
        #expect(summary.partnerTotal == 66.67)
        
        // Net: User owes $33.335 - $16.665 = $16.67
        #expect(summary.balance == 16.67)
        #expect(summary.whoOwes == .user)
        #expect(summary.amountOwed == 16.67)
    }
}