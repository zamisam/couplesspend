import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var supabaseService: SupabaseService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Spending")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                Task {
                    await authenticate()
                }
            }) {
                Text(isSigningUp ? "Sign Up" : "Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                isSigningUp.toggle()
                errorMessage = nil
            }) {
                Text(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
            }
        }
        .padding()
    }
    
    private func authenticate() async {
        errorMessage = nil
        do {
            if isSigningUp {
                try await supabaseService.signUp(email: email, password: password)
                errorMessage = "Confirmation email sent. Please check your inbox."
            } else {
                try await supabaseService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SupabaseService())
    }
}
