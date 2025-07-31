//
//  ContentView.swift
//  Spending
//
//  Created by George Gausden on 2025-07-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var personDisplayService = PersonDisplayService.shared
    
    var body: some View {
        if supabaseService.session == nil {
            LoginView()
        } else {
            MainTabView()
                .onAppear {
                    loadPersonNames()
                }
                .onChange(of: supabaseService.session?.user.id) { _ in
                    loadPersonNames()
                }
        }
    }
    
    private func loadPersonNames() {
        Task {
            guard let session = supabaseService.session else { return }
            
            // Get user's display name from database, fallback to email prefix
            let customDisplayName = await supabaseService.getUserDisplayName()
            let userName = customDisplayName ?? session.user.email?.components(separatedBy: "@").first?.capitalized ?? "You"
            
            // Get partner name
            let partnerName = await supabaseService.getPartnerName()
            
            await MainActor.run {
                personDisplayService.updateNames(userName: userName, partnerName: partnerName)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SupabaseService())
}
