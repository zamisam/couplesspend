//
//  Models.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation

// MARK: - Person Enum
enum Person: String, CaseIterable, Codable {
    case user = "george"     // Maps to the database "george" value
    case partner = "james"   // Maps to the database "james" value
    
    var displayName: String {
        // This will be dynamically populated by the PersonDisplayService
        switch self {
        case .user:
            return PersonDisplayService.shared.currentUserName
        case .partner:
            return PersonDisplayService.shared.currentPartnerName
        }
    }
}

// MARK: - Person Display Service
class PersonDisplayService: ObservableObject {
    static let shared = PersonDisplayService()
    
    @Published var currentUserName: String = "You"
    @Published var currentPartnerName: String = "Partner"
    
    private init() {}
    
    func updateNames(userName: String, partnerName: String?) {
        currentUserName = userName
        currentPartnerName = partnerName ?? "Partner"
    }
    
    func getCurrentUserName() -> String {
        return currentUserName
    }
    
    func getCurrentPartnerName() -> String {
        return currentPartnerName
    }
}

// MARK: - Split Type Enum
enum SplitType: String, CaseIterable, Codable {
    case equal = "equal"           // Split equally (both pay half)
    case full = "full"             // Spender pays full, partner owes half
    case partnerFull = "partner_full" // Partner pays full, spender owes half
    case noSplit = "no_split"      // No split (personal expense)
    
    var displayName: String {
        switch self {
        case .equal:
            return "Split Equally"
        case .full:
            return "I Pay Full"
        case .partnerFull:
            return "Partner Pays Full"
        case .noSplit:
            return "No Split"
        }
    }
    
    var description: String {
        switch self {
        case .equal:
            return "Both pay half"
        case .full:
            return "Partner owes half"
        case .partnerFull:
            return "I owe half"
        case .noSplit:
            return "Personal expense"
        }
    }
}

// MARK: - Expense Struct
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Decimal
    let spender: Person
    let date: Date
    let title: String?
    let description: String?
    var settled: Bool
    var settledDate: Date?
    let userId: UUID?
    let splitType: SplitType
    let debtAmount: Decimal
    let debtorPerson: Person?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, date, settled
        case spender = "person"
        case userId = "user_id"
        case title
        case description
        case settledDate = "settled_date"
        case splitType = "split_type"
        case debtAmount = "debt_amount"
        case debtorPerson = "debtor_person"
    }
    
    init(amount: Decimal, spender: Person, title: String? = nil, description: String? = nil, settled: Bool = false, userId: UUID? = nil, splitType: SplitType = .equal) {
        self.id = UUID()
        self.amount = amount
        self.spender = spender
        self.date = Date()
        self.title = title
        self.description = description
        self.settled = settled
        self.settledDate = nil
        self.userId = userId
        self.splitType = splitType
        
        // Calculate debt based on split type
        switch splitType {
        case .equal:
            self.debtAmount = amount / 2
            self.debtorPerson = spender == .user ? .partner : .user
        case .full:
            self.debtAmount = amount / 2
            self.debtorPerson = spender == .user ? .partner : .user
        case .partnerFull:
            self.debtAmount = amount / 2
            self.debtorPerson = spender == .user ? .user : .partner
        case .noSplit:
            self.debtAmount = 0
            self.debtorPerson = nil
        }
    }
    
    // Complete initializer for editing existing expenses
    init(id: UUID, amount: Decimal, spender: Person, date: Date, title: String? = nil, description: String? = nil, settled: Bool = false, settledDate: Date? = nil, userId: UUID? = nil, splitType: SplitType = .equal, debtAmount: Decimal = 0, debtorPerson: Person? = nil) {
        self.id = id
        self.amount = amount
        self.spender = spender
        self.date = date
        self.title = title
        self.description = description
        self.settled = settled
        self.settledDate = settledDate
        self.userId = userId
        self.splitType = splitType
        self.debtAmount = debtAmount
        self.debtorPerson = debtorPerson
    }
}

// MARK: - Spending Summary Model
struct SpendingSummary {
    let userTotal: Decimal
    let partnerTotal: Decimal
    let balance: Decimal
    let whoOwes: Person?
    let amountOwed: Decimal
    
    init(expenses: [Expense]) {
        // Only count unsettled expenses for the summary
        let unsettledExpenses = expenses.filter { !$0.settled }
        
        // Calculate totals based on actual spending
        let userExpenses = unsettledExpenses.filter { $0.spender == .user }
        let partnerExpenses = unsettledExpenses.filter { $0.spender == .partner }
        
        self.userTotal = userExpenses.reduce(0) { $0 + $1.amount }
        self.partnerTotal = partnerExpenses.reduce(0) { $0 + $1.amount }
        
        // Calculate net debt based on split types
        var userOwesAmount: Decimal = 0
        var partnerOwesAmount: Decimal = 0
        
        for expense in unsettledExpenses {
            switch expense.splitType {
            case .equal:
                // Both owe half to each other
                if expense.spender == .user {
                    partnerOwesAmount += expense.debtAmount
                } else {
                    userOwesAmount += expense.debtAmount
                }
            case .full:
                // Spender paid full, partner owes half
                if expense.spender == .user {
                    partnerOwesAmount += expense.debtAmount
                } else {
                    userOwesAmount += expense.debtAmount
                }
            case .partnerFull:
                // Partner paid full, spender owes half
                if expense.spender == .user {
                    userOwesAmount += expense.debtAmount
                } else {
                    partnerOwesAmount += expense.debtAmount
                }
            case .noSplit:
                // No debt created
                break
            }
        }
        
        self.balance = partnerOwesAmount - userOwesAmount
        
        print("SpendingSummary calculation:")
        print("  Total expenses: \(expenses.count)")
        print("  Unsettled expenses: \(unsettledExpenses.count)")
        print("  User total (actual spending): \(userTotal)")
        print("  Partner total (actual spending): \(partnerTotal)")
        print("  User owes: \(userOwesAmount)")
        print("  Partner owes: \(partnerOwesAmount)")
        print("  Net balance: \(balance)")
        
        if balance > 0 {
            self.whoOwes = .user
            self.amountOwed = balance
        } else if balance < 0 {
            self.whoOwes = .partner
            self.amountOwed = abs(balance)
        } else {
            self.whoOwes = nil
            self.amountOwed = 0
        }
    }
}