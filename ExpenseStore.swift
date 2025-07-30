import SwiftUI
import CoreData

@MainActor
class ExpenseStore: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published private(set) var expenses: [ExpenseEntity] = []
    @Published private(set) var georgeTotalSpent: Decimal = 0
    @Published private(set) var jamesTotalSpent: Decimal = 0
    @Published private(set) var balance: Decimal = 0
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        Task {
            await loadExpenses()
        }
    }
    
    private func loadExpenses() async {
        let request = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        
        do {
            expenses = try viewContext.fetch(request)
            updateTotals()
        } catch {
            print("Error loading expenses: \(error)")
        }
    }
    
    private func updateTotals() {
        let georgeExpenses = expenses.filter { $0.person == .george }.map { $0.amount }
        let jamesExpenses = expenses.filter { $0.person == .james }.map { $0.amount }
        
        georgeTotalSpent = georgeExpenses.reduce(0, +)
        jamesTotalSpent = jamesExpenses.reduce(0, +)
        
        // Positive balance means George is owed money by James
        // Negative balance means James is owed money by George
        balance = (georgeTotalSpent - jamesTotalSpent) / 2
    }
    
    func addExpense(amount: Decimal, person: Person) async throws {
        let expense = ExpenseEntity(context: viewContext)
        expense.id = UUID()
        expense.amount = amount
        expense.person = person
        expense.date = Date()
        
        do {
            try viewContext.save()
            await loadExpenses()
        } catch {
            viewContext.rollback()
            throw error
        }
    }
    
    func deleteExpense(_ expense: ExpenseEntity) async throws {
        viewContext.delete(expense)
        
        do {
            try viewContext.save()
            await loadExpenses()
        } catch {
            viewContext.rollback()
            throw error
        }
    }
}
