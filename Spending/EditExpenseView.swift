//
//  EditExpenseView.swift
//  Spending
//
//  Created by GitHub Copilot on 2025-07-31.
//

import SwiftUI

struct EditExpenseView: View {
    @EnvironmentObject var expenseStore: ExpenseStore
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var amount: Double
    @State private var title: String
    @State private var description: String
    @State private var selectedSpender: Person
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isAmountFieldFocused: Bool
    
    let expense: Expense
    let onExpenseUpdated: () -> Void
    
    init(expense: Expense, onExpenseUpdated: @escaping () -> Void) {
        self.expense = expense
        self.onExpenseUpdated = onExpenseUpdated
        self._amount = State(initialValue: Double(truncating: expense.amount as NSDecimalNumber))
        self._title = State(initialValue: expense.title ?? "")
        self._description = State(initialValue: expense.description ?? "")
        self._selectedSpender = State(initialValue: expense.spender)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    
                    HStack {
                        TextField("Amount", value: $amount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Spender", selection: $selectedSpender) {
                        Text("You").tag(Person.user)
                        Text("Partner").tag(Person.partner)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Description (optional)", text: $description)
                } header: {
                    Text("Expense Details")
                }
                
                Section {
                    Button(action: updateExpense) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Updating..." : "Update Expense")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormInvalid ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isFormInvalid || isLoading)
                    .listRowBackground(Color.clear)
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Expense")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isAmountFieldFocused = false
                    }
                }
            }
            .alert("Delete Expense?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteExpense()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private var isFormInvalid: Bool {
        return amount <= 0
    }
    
    private func updateExpense() {
        Task {
            isLoading = true
            
            let updatedExpense = Expense(
                id: expense.id,
                amount: Decimal(amount),
                spender: selectedSpender,
                date: expense.date,
                title: title.isEmpty ? nil : title,
                description: description.isEmpty ? nil : description,
                settled: expense.settled,
                settledDate: expense.settledDate,
                userId: expense.userId
            )
            
            await expenseStore.updateExpense(updatedExpense)
            
            isLoading = false
            
            // Notify parent and dismiss
            onExpenseUpdated()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func deleteExpense() {
        Task {
            isLoading = true
            await expenseStore.deleteExpense(withId: expense.id)
            isLoading = false
            
            // Notify parent and dismiss
            onExpenseUpdated()
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    EditExpenseView(
        expense: Expense(
            amount: 25.50,
            spender: .user,
            title: "Groceries",
            description: "Weekly shopping"
        ),
        onExpenseUpdated: {}
    )
    .environmentObject(ExpenseStore(supabaseService: SupabaseService.shared))
    .environmentObject(SupabaseService.shared)
}
