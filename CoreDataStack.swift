import CoreData

class CoreDataStack {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "SpendingModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func fetchExpenses() -> [ExpenseEntity] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.dateCreated, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching expenses: \(error)")
            return []
        }
    }
    
    func deleteExpense(_ expense: ExpenseEntity) {
        viewContext.delete(expense)
        save()
    }
    
    func deleteAllExpenses() {
        let request: NSFetchRequest<NSFetchRequestResult> = ExpenseEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try container.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
            save()
        } catch {
            print("Error deleting all expenses: \(error)")
        }
    }
}
