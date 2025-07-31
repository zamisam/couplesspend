import SwiftUI

struct AuthView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var expenseStore: ExpenseStore
    
    init() {
        let service = SupabaseService.shared
        _supabaseService = StateObject(wrappedValue: service)
        _expenseStore = StateObject(wrappedValue: ExpenseStore(supabaseService: service))
    }
    
    var body: some View {
        Group {
            if supabaseService.session == nil {
                LoginView()
            } else if supabaseService.needsPartnerSetup {
                PartnerSetupView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(supabaseService)
        .environmentObject(expenseStore)
        .onAppear {
            Task {
                print("AuthView: Loading stored session...")
                await supabaseService.loadStoredSession()
                print("AuthView: Session loaded. Session exists: \(supabaseService.session != nil)")
                if let session = supabaseService.session {
                    print("AuthView: User: \(session.user.email ?? "unknown")")
                    // Check if user needs partner setup
                    await supabaseService.checkPartnerSetupStatus()
                }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
