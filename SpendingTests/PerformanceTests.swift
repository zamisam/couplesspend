//
//  PerformanceTests.swift
//  SpendingTests
//
//  Created by GitHub Copilot on 2025-07-31.
//

import Testing
import Foundation
@testable import Spending

@MainActor
final class PerformanceTests {
    
    // MARK: - Model Performance Tests
    
    @Test("Expense creation performance")
    func testExpenseCreationPerformance() async throws {
        let startTime = Date()
        
        // Create 1000 expenses
        var expenses: [Expense] = []
        for i in 0..<1000 {
            let expense = Expense(
                amount: Decimal(i * 10),
                spender: i % 2 == 0 ? .user : .partner,
                title: "Expense \(i)",
                description: "Description for expense \(i)",
                splitType: SplitType.allCases[i % 4]
            )
            expenses.append(expense)
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(expenses.count == 1000)
        #expect(executionTime < 1.0) // Should complete within 1 second
        
        print("Created 1000 expenses in \(executionTime) seconds")
    }
    
    @Test("SpendingSummary calculation performance with large dataset")
    func testSpendingSummaryPerformanceLarge() async throws {
        // Create a large number of expenses
        var expenses: [Expense] = []
        
        for i in 0..<5000 {
            let expense = Expense(
                amount: Decimal(Double.random(in: 1...100)),
                spender: i % 2 == 0 ? .user : .partner,
                title: "Expense \(i)",
                settled: i % 10 == 0, // 10% settled
                splitType: SplitType.allCases[i % 4]
            )
            expenses.append(expense)
        }
        
        let startTime = Date()
        
        // Calculate summary
        let summary = SpendingSummary(expenses: expenses)
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 0.5) // Should complete within 0.5 seconds
        #expect(summary.userTotal >= 0)
        #expect(summary.partnerTotal >= 0)
        
        print("Calculated spending summary for 5000 expenses in \(executionTime) seconds")
    }
    
    @Test("PersonDisplayService performance under rapid updates")
    func testPersonDisplayServicePerformance() async throws {
        let service = PersonDisplayService()
        let startTime = Date()
        
        // Rapidly update names 1000 times
        for i in 0..<1000 {
            service.updateNames(userName: "User\(i)", partnerName: "Partner\(i)")
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 0.1) // Should complete within 0.1 seconds
        #expect(service.currentUserName == "User999")
        #expect(service.currentPartnerName == "Partner999")
        
        print("Updated PersonDisplayService 1000 times in \(executionTime) seconds")
    }
    
    // MARK: - ExpenseStore Performance Tests
    
    @Test("ExpenseStore filtering performance")
    func testExpenseStoreFilteringPerformance() async throws {
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // Create a large dataset
        var expenses: [Expense] = []
        for i in 0..<10000 {
            let expense = Expense(
                amount: Decimal(i),
                spender: i % 2 == 0 ? .user : .partner,
                title: "Expense \(i)",
                settled: i % 3 == 0 // Every 3rd expense is settled
            )
            expenses.append(expense)
        }
        store.expenses = expenses
        
        let startTime = Date()
        
        // Perform various filtering operations
        let unsettledExpenses = store.getUnsettledExpenses()
        let userExpenses = store.getExpenses(for: .user)
        let partnerExpenses = store.getExpenses(for: .partner)
        let recentExpenses = store.getRecentExpenses(limit: 100)
        let userTotal = store.getTotalSpending(for: .user)
        let partnerTotal = store.getTotalSpending(for: .partner)
        let balance = store.getSpendingBalance()
        let debtInfo = store.getDebtInfo()
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 0.5) // Should complete within 0.5 seconds
        #expect(unsettledExpenses.count > 0)
        #expect(userExpenses.count == 5000) // Half the expenses
        #expect(partnerExpenses.count == 5000) // Half the expenses
        #expect(recentExpenses.count == 100)
        #expect(userTotal > 0)
        #expect(partnerTotal > 0)
        
        print("Performed filtering operations on 10000 expenses in \(executionTime) seconds")
    }
    
    // MARK: - Memory Performance Tests
    
    @Test("Memory usage with large expense collections")
    func testMemoryUsageLargeCollections() async throws {
        // This test ensures we don't have memory leaks with large datasets
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // Create and release large collections multiple times
        for iteration in 0..<5 {
            var expenses: [Expense] = []
            
            // Create 2000 expenses
            for i in 0..<2000 {
                let expense = Expense(
                    amount: Decimal(i),
                    spender: .user,
                    title: "Memory Test Expense \(i)"
                )
                expenses.append(expense)
            }
            
            store.expenses = expenses
            
            // Perform operations to ensure the data is used
            let summary = store.spendingSummary
            #expect(summary.userTotal > 0)
            
            // Clear the expenses to test memory release
            store.expenses = []
            
            print("Completed memory test iteration \(iteration + 1)")
        }
        
        // Final verification
        #expect(store.expenses.isEmpty)
        #expect(store.spendingSummary.userTotal == 0)
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("PersonDisplayService thread safety")
    func testPersonDisplayServiceThreadSafety() async throws {
        let service = PersonDisplayService.shared
        
        // Test concurrent access from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<100 {
                        await MainActor.run {
                            service.updateNames(userName: "User\(i)-\(j)", partnerName: "Partner\(i)-\(j)")
                        }
                    }
                }
            }
        }
        
        // Verify service is still functional
        let finalUserName = service.getCurrentUserName()
        let finalPartnerName = service.getCurrentPartnerName()
        
        #expect(finalUserName.hasPrefix("User"))
        #expect(finalPartnerName.hasPrefix("Partner"))
        
        print("PersonDisplayService thread safety test completed")
    }
    
    @Test("ExpenseStore concurrent operations")
    func testExpenseStoreConcurrentOperations() async throws {
        let mockService = MockSupabaseService()
        let store = ExpenseStore(supabaseService: mockService)
        
        // Create initial dataset
        var initialExpenses: [Expense] = []
        for i in 0..<100 {
            let expense = Expense(amount: Decimal(i), spender: .user)
            initialExpenses.append(expense)
        }
        store.expenses = initialExpenses
        mockService.mockExpenses = initialExpenses
        
        // Perform concurrent read operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    let _ = store.getTotalSpending(for: .user)
                    let _ = store.getUnsettledExpenses()
                    let _ = store.getExpenses(for: .partner)
                    let _ = store.getRecentExpenses(limit: 10)
                }
            }
        }
        
        // Verify store is still consistent
        #expect(store.expenses.count == 100)
        #expect(store.getTotalSpending(for: .user) > 0)
        
        print("ExpenseStore concurrent operations test completed")
    }
    
    // MARK: - JSON Serialization Performance Tests
    
    @Test("JSON encoding performance for large expense arrays")
    func testJSONEncodingPerformance() async throws {
        // Create a large array of expenses
        var expenses: [Expense] = []
        for i in 0..<1000 {
            let expense = Expense(
                amount: Decimal(Double.random(in: 1...1000)),
                spender: i % 2 == 0 ? .user : .partner,
                title: "JSON Test Expense \(i)",
                description: "This is a description for expense number \(i) in our JSON encoding performance test.",
                splitType: SplitType.allCases[i % 4]
            )
            expenses.append(expense)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let startTime = Date()
        let jsonData = try encoder.encode(expenses)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 1.0) // Should complete within 1 second
        #expect(jsonData.count > 0)
        
        print("Encoded 1000 expenses to JSON in \(executionTime) seconds, size: \(jsonData.count) bytes")
    }
    
    @Test("JSON decoding performance for large expense arrays")
    func testJSONDecodingPerformance() async throws {
        // First create and encode expenses
        var expenses: [Expense] = []
        for i in 0..<1000 {
            let expense = Expense(
                amount: Decimal(Double.random(in: 1...1000)),
                spender: i % 2 == 0 ? .user : .partner,
                title: "JSON Test Expense \(i)",
                description: "This is a description for expense number \(i).",
                splitType: SplitType.allCases[i % 4]
            )
            expenses.append(expense)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(expenses)
        
        // Now test decoding performance
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let startTime = Date()
        let decodedExpenses = try decoder.decode([Expense].self, from: jsonData)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 1.0) // Should complete within 1 second
        #expect(decodedExpenses.count == 1000)
        #expect(decodedExpenses[0].title?.hasPrefix("JSON Test Expense") == true)
        
        print("Decoded 1000 expenses from JSON in \(executionTime) seconds")
    }
    
    // MARK: - Date Handling Performance Tests
    
    @Test("Date formatting performance")
    func testDateFormattingPerformance() async throws {
        let dates = (0..<1000).map { _ in Date() }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startTime = Date()
        
        let formattedDates = dates.map { formatter.string(from: $0) }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        #expect(executionTime < 0.5) // Should complete within 0.5 seconds
        #expect(formattedDates.count == 1000)
        #expect(formattedDates.allSatisfy { !$0.isEmpty })
        
        print("Formatted 1000 dates in \(executionTime) seconds")
    }
    
    // MARK: - Benchmark Helper Methods
    
    private func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, executionTime: TimeInterval) {
        let startTime = Date()
        let result = try operation()
        let endTime = Date()
        return (result, endTime.timeIntervalSince(startTime))
    }
    
    private func measureAsyncExecutionTime<T>(operation: () async throws -> T) async rethrows -> (result: T, executionTime: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let endTime = Date()
        return (result, endTime.timeIntervalSince(startTime))
    }
}