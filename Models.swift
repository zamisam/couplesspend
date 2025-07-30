import Foundation

enum Person: String, CaseIterable {
    case george
    case james
    
    var displayName: String {
        switch self {
        case .george:
            return "George"
        case .james:
            return "James"
        }
    }
}

struct Expense {
    let id: UUID
    let amount: Decimal
    let person: Person
    let date: Date
    
    init(id: UUID = UUID(), amount: Decimal, person: Person, date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.person = person
        self.date = date
    }
}
