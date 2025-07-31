import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var isSigningOut = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingImage = false
    @State private var imageURL: String?
    @State private var refreshImageID = UUID()
    @State private var showDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var showDeleteError = false
    @State private var hasPartner = false
    @State private var partnerName: String?
    @State private var showAddPartnerSheet = false
    @State private var showEditPartnerSheet = false
    @State private var currentUserName: String?
    @State private var showEditUsernameSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = supabaseService.session?.user {
                        // Profile Picture Section
                        VStack(spacing: 10) {
                            Group {
                                if let profileImage = profileImage {
                                    // Show the uploaded image directly
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    // Try to load from URL with cache busting
                                    AsyncImage(url: URL(string: "\(supabaseService.getProfilePictureURL(userId: user.id.uuidString))?v=\(refreshImageID)")) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure(_):
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(.gray)
                                        case .empty:
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            
                            PhotosPicker("Change Photo", selection: $selectedImage, matching: .images)
                                .disabled(isUploadingImage)
                        }
                        
                        // User Info Section
                        VStack(spacing: 15) {
                            HStack {
                                Text("Email: \(user.email ?? "N/A")")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            HStack {
                                Text("Name: \(currentUserName ?? "Set your name")")
                                    .foregroundColor(currentUserName == nil ? .secondary : .primary)
                                Spacer()
                                Button("Edit") {
                                    showEditUsernameSheet = true
                                }
                                .buttonStyle(BorderedButtonStyle())
                            }
                            
                            HStack {
                                Text("Partner: \(partnerName ?? "No partner set")")
                                    .foregroundColor(partnerName == nil ? .secondary : .primary)
                                Spacer()
                                if hasPartner {
                                    Button("Edit") {
                                        showEditPartnerSheet = true
                                    }
                                    .buttonStyle(BorderedButtonStyle())
                                } else {
                                    Button("Add Partner") {
                                        showAddPartnerSheet = true
                                    }
                                    .buttonStyle(BorderedProminentButtonStyle())
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Action Buttons Section
                        VStack(spacing: 15) {
                            Button(action: signOut) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                    Text("Sign Out")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .disabled(isSigningOut)
                            
                            Button(action: {
                                showDeleteAccountConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            .disabled(isDeletingAccount)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .refreshable {
                await loadUserData()
            }
        }
        .sheet(isPresented: $showAddPartnerSheet) {
            PartnerSetupView()
                .environmentObject(supabaseService)
        }
        .sheet(isPresented: $showEditPartnerSheet) {
            EditPartnerView()
                .environmentObject(supabaseService)
        }
        .sheet(isPresented: $showEditUsernameSheet) {
            EditUsernameView(currentName: currentUserName ?? "")
                .environmentObject(supabaseService)
        }
        .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showDeleteError) {
            Button("OK") { }
        } message: {
            Text(deleteAccountError ?? "An unknown error occurred")
        }
        .task {
            await loadUserData()
        }
        .onChange(of: selectedImage) { _, newValue in
            if newValue != nil {
                Task {
                    await uploadProfilePicture()
                }
            }
        }
    }
    
    private func signOut() {
        isSigningOut = true
        Task {
            do {
                try await supabaseService.signOut()
            } catch {
                print("Error signing out: \(error)")
            }
            isSigningOut = false
        }
    }
    
    private func uploadProfilePicture() async {
        guard let selectedImage = selectedImage else { return }
        
        isUploadingImage = true
        
        do {
            if let data = try await selectedImage.loadTransferable(type: Data.self) {
                let image = UIImage(data: data)
                self.profileImage = image
                
                if let user = supabaseService.session?.user {
                    try await supabaseService.uploadProfilePicture(imageData: data, userId: user.id.uuidString)
                    
                    // Refresh the image with a new cache-busting parameter
                    refreshImageID = UUID()
                }
            }
        } catch {
            print("Failed to upload profile picture: \(error)")
        }
        
        isUploadingImage = false
        self.selectedImage = nil
    }
    
    private func deleteAccount() async {
        isDeletingAccount = true
        deleteAccountError = nil
        
        do {
            try await supabaseService.deleteAccount()
        } catch {
            deleteAccountError = error.localizedDescription
            showDeleteError = true
        }
        
        isDeletingAccount = false
    }
    
    private func loadUserData() async {
        guard let user = supabaseService.session?.user else { return }
        
        do {
            // Load user display name
            let displayName = await supabaseService.getUserDisplayName()
            
            // Load partner info
            let partnerName = await supabaseService.getPartnerName()
            let hasActivePartner = await supabaseService.hasActivePartner()
            
            await MainActor.run {
                self.currentUserName = displayName
                self.partnerName = partnerName
                self.hasPartner = hasActivePartner
            }
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
}

struct EditPartnerView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Environment(\.dismiss) private var dismiss
    @State private var partnerEmail = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showRemovePartnerConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Partner")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Partner's Email:")
                        .font(.headline)
                    TextField("Enter partner's email", text: $partnerEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Button(action: updatePartner) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Update Partner")
                    }
                }
                .disabled(partnerEmail.isEmpty || isLoading)
                .buttonStyle(BorderedProminentButtonStyle())
                
                Button("Remove Partner") {
                    showRemovePartnerConfirmation = true
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Remove Partner", isPresented: $showRemovePartnerConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await removePartner()
                }
            }
        } message: {
            Text("Are you sure you want to remove your partner? This will also remove them as your partner.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func updatePartner() {
        isLoading = true
        Task {
            do {
                try await supabaseService.setupPartnerByName(partnerName: partnerEmail)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func removePartner() async {
        isLoading = true
        do {
            try await supabaseService.removePartner()
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

struct EditUsernameView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(currentName: String) {
        _username = State(initialValue: currentName)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Name")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Name:")
                        .font(.headline)
                    TextField("Enter your name", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: updateUsername) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Update Name")
                    }
                }
                .disabled(username.isEmpty || isLoading)
                .buttonStyle(BorderedProminentButtonStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func updateUsername() {
        isLoading = true
        Task {
            do {
                try await supabaseService.updateUserDisplayName(newDisplayName: username)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SupabaseService())
}
