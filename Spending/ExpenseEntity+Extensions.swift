//
//  ExpenseEntity+Extensions.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation
import CoreData

extension ExpenseEntity {
    
    // Convert ExpenseEntity to Expense model
    func toExpense() -> Expense? {
        guard let id = self.id,
              let spenderString = self.spender,
              let spender = Person(rawValue: spenderString),
              let dateCreated = self.dateCreated else {
            return nil
        }
        
        return Expense(
            id: id,
            amount: self.amount?.decimalValue ?? 0,
            spender: spender,
            date: dateCreated,
            description: self.descriptionText
        )
    }
    
    // Create ExpenseEntity from Expense model
    static func fromExpense(_ expense: Expense, context: NSManagedObjectContext) -> ExpenseEntity {
        let entity = ExpenseEntity(context: context)
        entity.id = expense.id
        entity.amount = expense.amount as NSDecimalNumber
        entity.spender = expense.spender.rawValue
        entity.dateCreated = expense.date
        entity.descriptionText = expense.description
        return entity
    }
}

// MARK: - Expense Model Extension
extension Expense {
    init?(id: UUID, amount: Decimal, spender: Person, date: Date, description: String?) {
        self.id = id
        self.amount = amount
        self.spender = spender
        self.date = date
        self.description = description
    }
}