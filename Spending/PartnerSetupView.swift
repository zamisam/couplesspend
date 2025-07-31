//
//  PartnerSetupView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI

struct PartnerSetupView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var partnerName = ""
    @State private var partnerEmail = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showSkipConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("Set Up Your Partner")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Enter your partner's name to start tracking shared expenses together")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Input Section
                VStack(spacing: 16) {
                    TextField("Partner's name", text: $partnerName)
                        .autocapitalization(.words)
                        .disableAutocorrection(false)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    Button(action: setupPartner) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoading ? "Setting Up..." : "Add Partner")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    // Optional invite section
                    VStack(spacing: 12) {
                        Text("Want to invite them to use the app?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Partner's email (optional)", text: $partnerEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        
                        Button("Send Invitation") {
                            // TODO: Implement actual invitation functionality
                            errorMessage = "Invitation feature coming soon!"
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(true)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                
                // Messages
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                if let successMessage = successMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Skip option
                VStack(spacing: 12) {
                    Text("You can always add a partner later in your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Skip for Now") {
                        showSkipConfirmation = true
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Welcome!")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Skip Partner Setup?", isPresented: $showSkipConfirmation) {
                Button("Skip", role: .destructive) {
                    completeSetup()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can add your partner later from your profile settings.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupPartner() {
        Task {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            
            do {
                try await supabaseService.setupPartnerByName(partnerName: partnerName.trimmingCharacters(in: .whitespacesAndNewlines))
                successMessage = "Partner '\(partnerName)' added successfully! You can now track shared expenses together."
                
                // Auto-complete setup after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // Setup is already marked complete in setupPartnerByName
                }
            } catch {
                errorMessage = "Failed to add partner: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func completeSetup() {
        Task {
            await supabaseService.markPartnerSetupComplete()
        }
    }
}

#Preview {
    PartnerSetupView()
        .environmentObject(SupabaseService.shared)
}
