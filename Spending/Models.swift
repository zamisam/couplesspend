//
//  Models.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation

// MARK: - Person Enum
enum Person: String, CaseIterable, Codable {
    case george = "George"
    case james = "James"
    
    var displayName: String { 
        return rawValue 
    }
}

// MARK: - Expense Struct
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Decimal
    let spender: Person
    let date: Date
    let description: String?
    
    init(amount: Decimal, spender: Person, description: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.spender = spender
        self.date = Date()
        self.description = description
    }
}

// MARK: - Spending Summary Model
struct SpendingSummary {
    let georgeTotal: Decimal
    let jamesTotal: Decimal
    let balance: Decimal
    let whoOwes: Person?
    let amountOwed: Decimal
    
    init(expenses: [Expense]) {
        let georgeExpenses = expenses.filter { $0.spender == .george }
        let jamesExpenses = expenses.filter { $0.spender == .james }
        
        self.georgeTotal = georgeExpenses.reduce(0) { $0 + $1.amount }
        self.jamesTotal = jamesExpenses.reduce(0) { $0 + $1.amount }
        self.balance = georgeTotal - jamesTotal
        
        if balance > 0 {
            self.whoOwes = .james
            self.amountOwed = balance / 2
        } else if balance < 0 {
            self.whoOwes = .george
            self.amountOwed = abs(balance) / 2
        } else {
            self.whoOwes = nil
            self.amountOwed = 0
        }
    }
}