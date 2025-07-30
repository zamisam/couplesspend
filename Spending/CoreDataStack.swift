//
//  CoreDataStack.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation
import CoreData

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    let persistentContainer: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "SpendingModel")
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        }
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In a production app, you should handle this error appropriately
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent context
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving Support
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Background Context for Heavy Operations
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Fetch Request Helpers
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
    
    // MARK: - Delete Operations
    func deleteExpense(_ expense: ExpenseEntity) {
        viewContext.delete(expense)
        save()
    }
    
    // MARK: - Batch Operations
    func deleteAllExpenses() {
        let request: NSFetchRequest<NSFetchRequestResult> = ExpenseEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
            save()
        } catch {
            print("Error deleting all expenses: \(error)")
        }
    }
}