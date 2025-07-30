import CoreData

extension ExpenseEntity {
    var person: Person {
        get {
            Person(rawValue: personRawValue ?? "") ?? .george
        }
        set {
            personRawValue = newValue.rawValue
        }
    }
    
    convenience init(context: NSManagedObjectContext, expense: Expense) {
        self.init(context: context)
        self.id = expense.id
        self.amount = expense.amount as NSDecimalNumber
        self.personRawValue = expense.person.rawValue
        self.dateCreated = expense.date
    }
    
    func toExpense() -> Expense {
        Expense(
            id: id ?? UUID(),
            amount: amount?.decimalValue ?? 0,
            person: person,
            date: dateCreated ?? Date()
        )
    }
}
