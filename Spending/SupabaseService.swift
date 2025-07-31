//
//  SupabaseService.swift
//  Spending
//
//  Created by Kiro on 2025-07-30.
//

import Foundation
import Combine

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let baseURL = "https://tpeqjngxqlznrwsteprc.supabase.co"
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwZXFqbmd4cWx6bnJ3c3RlcHJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4OTkxMTksImV4cCI6MjA2OTQ3NTExOX0.v7JE6YD22ls4EWVjsD4ngGMtw6QvfRvSK1Fqz5DmOGE" // Replace with your valid Supabase anon key
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("SupabaseService init called - instance: \(ObjectIdentifier(self))")
    }
    
    // MARK: - HTTP Client
    
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/rest/v1\(endpoint)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Use authenticated user's token if available, otherwise use anon key
        if let session = session {
            request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("return=representation", forHTTPHeaderField: "Prefer")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Error Response: \(responseString)")
                
                // If we get authentication errors, clear the session
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    clearSession()
                }
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }
        
        if responseType == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        let decoder = JSONDecoder()
        // Use a custom date decoding strategy that handles Supabase's timestamp formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats that Supabase might use
            let formatters = [
                "yyyy-MM-dd HH:mm:ss.SSSXXXXX",  // 2025-07-30 18:36:35.591+00
                "yyyy-MM-dd HH:mm:ss.SSXXXXX",   // 2025-07-30 18:36:35.59+00  
                "yyyy-MM-dd HH:mm:ss.SXXXXX",    // 2025-07-30 18:36:35.5+00
                "yyyy-MM-dd HH:mm:ssXXXXX",      // 2025-07-30 18:36:35+00
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX", // ISO format with milliseconds
                "yyyy-MM-dd'T'HH:mm:ssXXXXX"     // ISO format without milliseconds
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
        
        return try decoder.decode(responseType, from: data)
    }
    
    // MARK: - Expense Operations
    
    func fetchExpenses() async throws -> [Expense] {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to fetch expenses")
        }
        
        return try await makeRequest(
            endpoint: "/expenses?user_id=eq.\(session.user.id)&order=date.desc",
            responseType: [Expense].self
        )
    }
    
    func createExpense(_ expense: Expense) async throws -> Expense {
        print("=== CreateExpense called ===")
        print("SupabaseService instance: \(ObjectIdentifier(self))")
        print("SupabaseService.shared instance: \(ObjectIdentifier(SupabaseService.shared))")
        print("Are they the same? \(self === SupabaseService.shared)")
        print("Session exists: \(session != nil)")
        print("SupabaseService.shared session exists: \(SupabaseService.shared.session != nil)")
        
        if let session = session {
            print("This instance session user: \(session.user.email ?? "unknown")")
        } else {
            print("ERROR: This instance has NO SESSION")
        }
        
        if let sharedSession = SupabaseService.shared.session {
            print("Shared instance session user: \(sharedSession.user.email ?? "unknown")")
        } else {
            print("ERROR: Shared instance has NO SESSION")
        }
        
        guard let session = session else {
            print("ERROR: No session found when trying to create expense")
            throw SupabaseError.serverError(message: "No user logged in.")
        }
        
        // Create a new expense with the authenticated user's ID
        var expenseWithUserId = expense
        expenseWithUserId = Expense(
            amount: expense.amount,
            spender: expense.spender,
            title: expense.title,
            description: expense.description,
            settled: expense.settled,
            userId: session.user.id,
            splitType: expense.splitType
        )
        
        let encoder = JSONEncoder()
        // Use ISO8601 for encoding as it's widely supported
        encoder.dateEncodingStrategy = .iso8601
        
        let body = try encoder.encode(expenseWithUserId)
        
        let result: [Expense] = try await makeRequest(
            endpoint: "/expenses",
            method: .POST,
            body: body,
            responseType: [Expense].self
        )
        
        guard let createdExpense = result.first else {
            throw SupabaseError.noDataReturned
        }
        
        return createdExpense
    }
    
    func updateExpense(_ expense: Expense) async throws -> Expense {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to update expenses")
        }
        
        let encoder = JSONEncoder()
        // Use ISO8601 for encoding as it's widely supported
        encoder.dateEncodingStrategy = .iso8601
        
        let body = try encoder.encode(expense)
        
        let result: [Expense] = try await makeRequest(
            endpoint: "/expenses?id=eq.\(expense.id)&user_id=eq.\(session.user.id)",
            method: .PATCH,
            body: body,
            responseType: [Expense].self
        )
        
        guard let updatedExpense = result.first else {
            throw SupabaseError.noDataReturned
        }
        
        return updatedExpense
    }
    
    func deleteExpense(withId id: UUID) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to delete expenses")
        }
        
        let _: EmptyResponse = try await makeRequest(
            endpoint: "/expenses?id=eq.\(id)&user_id=eq.\(session.user.id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    func settleExpense(withId id: UUID) async throws -> Expense {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to settle expenses")
        }
        
        print("Attempting to settle expense with ID: \(id)")
        
        // Include both settled flag and settled_date
        let settleData: [String: Any] = [
            "settled": true,
            "settled_date": ISO8601DateFormatter().string(from: Date())
        ]
        let body = try JSONSerialization.data(withJSONObject: settleData)
        
        let result: [Expense] = try await makeRequest(
            endpoint: "/expenses?id=eq.\(id)&user_id=eq.\(session.user.id)",
            method: .PATCH,
            body: body,
            responseType: [Expense].self
        )
        
        print("Settle expense API response: \(result)")
        
        guard let settledExpense = result.first else {
            throw SupabaseError.noDataReturned
        }
        
        print("Successfully settled expense: \(settledExpense.id), settled: \(settledExpense.settled), settled_date: \(settledExpense.settledDate?.description ?? "nil")")
        return settledExpense
    }
    
    // MARK: - Storage Operations
    
    func uploadProfilePicture(imageData: Data, userId: String) async throws -> String {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to upload profile picture")
        }
        
        // Use the authenticated user's UUID directly from the session
        let authenticatedUserId = session.user.id.uuidString.lowercased()
        let fileName = "\(authenticatedUserId)/profile.jpg"
        
        guard let url = URL(string: "\(baseURL)/storage/v1/object/profile-pics/\(fileName)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Use the authenticated user's access token (required for RLS policies)
        request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.addValue("public", forHTTPHeaderField: "Cache-Control")
        
        request.httpBody = imageData
        
        print("Uploading to URL: \(url)")
        print("Using access token: \(session.accessToken.prefix(20))...")
        print("Authenticated User ID: \(authenticatedUserId)")
        print("Session User ID: \(session.user.id)")
        print("File path: \(fileName)")
        print("File size: \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        print("Upload response status: \(httpResponse.statusCode)")
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Storage Error Response: \(responseString)")
                
                // If we get a 403 with bad_jwt, clear the session
                if httpResponse.statusCode == 403 && responseString.contains("bad_jwt") {
                    clearSession()
                }
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }
        
        // Return the public URL for the uploaded image
        let publicURL = "\(baseURL)/storage/v1/object/public/profile-pics/\(fileName)"
        print("Public URL: \(publicURL)")
        return publicURL
    }
    
    func deleteProfilePicture(userId: String) async throws {
        let fileName = "\(userId)/profile.jpg"
        
        guard let url = URL(string: "\(baseURL)/storage/v1/object/profile-pics/\(fileName)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Storage Delete Error Response: \(responseString)")
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }
    }
    
    func getProfilePictureURL(userId: String) -> String {
        // Ensure UUID is lowercase to match what we use in upload
        let normalizedUserId = userId.lowercased()
        return "\(baseURL)/storage/v1/object/public/profile-pics/\(normalizedUserId)/profile.jpg"
    }

    // MARK: - Authentication
    
    @Published var session: Session? {
        didSet {
            print("SupabaseService session changed - instance: \(ObjectIdentifier(self))")
            print("New session exists: \(session != nil)")
            if let session = session {
                print("Session user: \(session.user.email ?? "unknown")")
            }
        }
    }
    
    @Published var needsPartnerSetup: Bool = false

    var isAuthenticated: Bool {
        return session != nil
    }

    func loadStoredSession() async {
        if let sessionData = UserDefaults.standard.data(forKey: "supabase_session"),
           let storedSession = try? JSONDecoder().decode(Session.self, from: sessionData) {
            
            // Check if the session is expired or invalid
            let currentTime = Date().timeIntervalSince1970
            let tokenIssuedAt = storedSession.user.createdAt.timeIntervalSince1970
            let expirationTime = tokenIssuedAt + TimeInterval(storedSession.expiresIn)
            
            if currentTime < expirationTime {
                DispatchQueue.main.async {
                    self.session = storedSession
                    print("Loaded stored session for user: \(storedSession.user.email ?? "unknown")")
                }
            } else {
                // Session is expired, clear it
                print("Stored session is expired, clearing it")
                DispatchQueue.main.async {
                    self.session = nil
                }
                UserDefaults.standard.removeObject(forKey: "supabase_session")
            }
        }
    }

    private func saveSession(_ session: Session?) {
        if let session = session {
            if let sessionData = try? JSONEncoder().encode(session) {
                UserDefaults.standard.set(sessionData, forKey: "supabase_session")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "supabase_session")
        }
    }
    
    func clearSession() {
        DispatchQueue.main.async {
            self.session = nil
            self.saveSession(nil)
        }
        print("Session cleared due to authentication error")
    }

    func signUp(email: String, password: String) async throws {
        let body = ["email": email, "password": password]
        let bodyData = try JSONEncoder().encode(body)

        let _: SignUpResponse = try await makeAuthRequest(
            endpoint: "/signup",
            method: .POST,
            body: bodyData,
            responseType: SignUpResponse.self
        )
    }

    func signIn(email: String, password: String) async throws {
        let body = ["email": email, "password": password]
        let bodyData = try JSONEncoder().encode(body)

        let session: Session = try await makeAuthRequest(
            endpoint: "/token?grant_type=password",
            method: .POST,
            body: bodyData,
            responseType: Session.self
        )

        DispatchQueue.main.async {
            self.session = session
            self.saveSession(session)
        }
        
        print("signIn: Session set for user: \(session.user.email ?? "unknown")")
        print("signIn: About to check partner setup status...")
        
        // Check partner setup status after sign in
        await checkPartnerSetupStatus()
        
        print("signIn: Partner setup status check completed. needsPartnerSetup = \(needsPartnerSetup)")
    }

    func signOut() async throws {
        // Always clear the local session, even if the server request fails
        let currentSession = session
        
        DispatchQueue.main.async {
            self.session = nil
            self.saveSession(nil)
        }
        
        // Try to notify the server, but don't fail if it doesn't work
        if let currentSession = currentSession {
            do {
                let body = ["refresh_token": currentSession.refreshToken]
                let bodyData = try JSONEncoder().encode(body)

                let _: EmptyResponse = try await makeAuthRequest(
                    endpoint: "/logout",
                    method: .POST,
                    body: bodyData,
                    responseType: EmptyResponse.self
                )
                print("Successfully signed out from server")
            } catch {
                // Log the error but don't throw it - local signout is more important
                print("Failed to sign out from server (but local session cleared): \(error.localizedDescription)")
            }
        }
    }

    private func makeAuthRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .POST,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)/auth/v1\(endpoint)") else {
            throw SupabaseError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Print the response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Auth Error Response: \(responseString)")
            }
            
            if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                throw SupabaseError.serverError(message: errorResponse.error_description)
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        let decoder = JSONDecoder()
        // Use the same flexible date decoding strategy as the main requests
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try multiple date formats that Supabase might use
            let formatters = [
                "yyyy-MM-dd HH:mm:ss.SSSXXXXX",  // 2025-07-30 18:36:35.591+00
                "yyyy-MM-dd HH:mm:ss.SSXXXXX",   // 2025-07-30 18:36:35.59+00  
                "yyyy-MM-dd HH:mm:ss.SXXXXX",    // 2025-07-30 18:36:35.5+00
                "yyyy-MM-dd HH:mm:ssXXXXX",      // 2025-07-30 18:36:35+00
                "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX", // ISO format with milliseconds
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",     // ISO format without milliseconds
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ" // Auth specific format
            ]
            
            for formatString in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = formatString
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw SupabaseError.decodingError(error)
        }
    }
    
    // MARK: - Partner Management
    
    func setupPartnerByName(partnerName: String) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to set up partner")
        }
        
        // Create or update user profile with partner name
        let profileData: [String: Any] = [
            "id": session.user.id.uuidString,
            "email": session.user.email ?? "",
            "partner_name": partnerName,
            "partner_setup_complete": true,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: profileData)
        
        // Try to update first, if no rows affected, then insert
        do {
            let result: [UserProfile] = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)",
                method: .PATCH,
                body: bodyData,
                responseType: [UserProfile].self
            )
            
            if result.isEmpty {
                // Profile doesn't exist, create it
                let _: [UserProfile] = try await makeRequest(
                    endpoint: "/user_profiles",
                    method: .POST,
                    body: bodyData,
                    responseType: [UserProfile].self
                )
            }
            
            print("Partner setup completed with name: \(partnerName)")
            
            // Update local state
            DispatchQueue.main.async {
                self.needsPartnerSetup = false
            }
            
        } catch {
            print("Failed to setup partner: \(error)")
            throw error
        }
    }
    
    func getPartnerName() async -> String? {
        guard let session = session else { return nil }
        
        do {
            let profiles: [UserProfile] = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)",
                method: .GET,
                responseType: [UserProfile].self
            )
            
            return profiles.first?.partnerName
        } catch {
            print("Failed to get partner name: \(error)")
            return nil
        }
    }
    
    func updatePartnerName(newName: String) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to update partner")
        }
        
        let updateData = [
            "partner_name": newName,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: updateData)
        
        let _: [UserProfile] = try await makeRequest(
            endpoint: "/user_profiles?id=eq.\(session.user.id)",
            method: .PATCH,
            body: bodyData,
            responseType: [UserProfile].self
        )
        
        print("Partner name updated to: \(newName)")
    }
    
    // MARK: - User Display Name Management
    
    func getUserDisplayName() async -> String? {
        guard let session = session else { return nil }
        
        do {
            let profiles: [UserProfile] = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)",
                method: .GET,
                responseType: [UserProfile].self
            )
            
            return profiles.first?.displayName
        } catch {
            print("Failed to get user display name: \(error)")
            return nil
        }
    }
    
    func updateUserDisplayName(newDisplayName: String) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to update display name")
        }
        
        let updateData = [
            "display_name": newDisplayName,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: updateData)
        
        let _: [UserProfile] = try await makeRequest(
            endpoint: "/user_profiles?id=eq.\(session.user.id)",
            method: .PATCH,
            body: bodyData,
            responseType: [UserProfile].self
        )
        
        print("User display name updated to: \(newDisplayName)")
    }
    
    func removePartner() async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to remove partner")
        }
        
        let updateData = [
            "partner_name": NSNull(),
            "partner_setup_complete": false,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ] as [String : Any]
        
        let bodyData = try JSONSerialization.data(withJSONObject: updateData)
        
        let _: [UserProfile] = try await makeRequest(
            endpoint: "/user_profiles?id=eq.\(session.user.id)",
            method: .PATCH,
            body: bodyData,
            responseType: [UserProfile].self
        )
        
        print("Partner removed")
        
        // Update local state
        DispatchQueue.main.async {
            self.needsPartnerSetup = true
        }
    }
    
    // MARK: - Email Invitation Functions (Currently Disabled)
    // These functions will be re-enabled when proper SMTP is configured
    
    /*
    private func inviteUserViaSupabase(email: String) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated")
        }
        
        // Use Supabase Admin API to invite user
        guard let url = URL(string: "\(baseURL)/auth/v1/invite") else {
            throw SupabaseError.invalidURL
        }
        
        let inviteData: [String: Any] = [
            "email": email,
            "data": [
                "invited_by": session.user.email ?? "",
                "invitation_type": "partner"
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: inviteData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Note: For invite API, we need to use service role key, but we'll try with user token first
        request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode == 403 {
            // If user token doesn't have permission, try with Edge Function approach
            try await inviteUserViaEdgeFunction(email: email)
            return
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Supabase invite error response: \(responseString)")
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }
        
        print("User invitation sent successfully via Supabase Auth")
    }
    
    private func inviteUserViaEdgeFunction(email: String) async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated")
        }
        
        guard let url = URL(string: "\(baseURL)/functions/v1/invite-partner") else {
            throw SupabaseError.invalidURL
        }
        
        let inviteData = [
            "email": email,
            "inviterEmail": session.user.email ?? ""
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: inviteData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Edge Function invite error response: \(responseString)")
            }
            throw SupabaseError.httpError(httpResponse.statusCode)
        }
        
        print("User invitation sent successfully via Edge Function")
    }
    */
    
    func markPartnerSetupComplete() async {
        guard let session = session else { return }
        
        do {
            let updateData = ["partner_setup_complete": true]
            let bodyData = try JSONSerialization.data(withJSONObject: updateData)
            
            let _: [UserProfile] = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)",
                method: .PATCH,
                body: bodyData,
                responseType: [UserProfile].self
            )
            
            DispatchQueue.main.async {
                self.needsPartnerSetup = false
            }
        } catch {
            print("Failed to mark partner setup complete: \(error)")
        }
    }
    
    func checkPartnerSetupStatus() async {
        guard let session = session else { 
            print("checkPartnerSetupStatus: No session found")
            return 
        }
        
        print("checkPartnerSetupStatus: Checking for user ID: \(session.user.id)")
        
        do {
            let profiles: [UserProfile] = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)",
                method: .GET,
                responseType: [UserProfile].self
            )
            
            print("checkPartnerSetupStatus: Found \(profiles.count) profiles")
            
            if let profile = profiles.first {
                let setupComplete = profile.partnerSetupComplete ?? false
                print("checkPartnerSetupStatus: Profile found, partner_setup_complete = \(setupComplete)")
                DispatchQueue.main.async {
                    // If partnerSetupComplete is nil or false, show setup
                    let needsSetup = !setupComplete
                    print("checkPartnerSetupStatus: Setting needsPartnerSetup = \(needsSetup)")
                    self.needsPartnerSetup = needsSetup
                }
            } else {
                // No profile found, user needs setup
                print("checkPartnerSetupStatus: No profile found, user needs setup")
                DispatchQueue.main.async {
                    self.needsPartnerSetup = true
                }
            }
        } catch {
            print("Failed to check partner setup status: \(error)")
            // Default to showing setup on error
            DispatchQueue.main.async {
                self.needsPartnerSetup = true
            }
        }
    }
    
    func hasActivePartner() async -> Bool {
        guard let session = session else { return false }
        
        do {
            // Check if user has a partner name set
            let userProfile: UserProfile = try await makeRequest(
                endpoint: "/user_profiles?id=eq.\(session.user.id)&select=partner_name",
                method: .GET,
                responseType: [UserProfile].self
            ).first ?? UserProfile(
                id: session.user.id, 
                email: session.user.email ?? "", 
                displayName: nil,
                partnerSetupComplete: nil, 
                partnerName: nil, 
                profilePictureURL: nil, 
                createdAt: Date(), 
                updatedAt: Date()
            )
            
            return userProfile.partnerName != nil && !userProfile.partnerName!.isEmpty
        } catch {
            print("Failed to check partner status: \(error)")
            return false
        }
    }
    
    func deleteAccount() async throws {
        guard let session = session else {
            throw SupabaseError.serverError(message: "User must be authenticated to delete account")
        }
        
        do {
            // Call the Edge Function to delete all user data and the auth user
            guard let url = URL(string: "\(baseURL)/functions/v1/delete-user-account") else {
                throw SupabaseError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue(apiKey, forHTTPHeaderField: "apikey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Delete account error response: \(responseString)")
                }
                throw SupabaseError.httpError(httpResponse.statusCode)
            }
            
            print("Account and all data successfully deleted via Edge Function")
            
            // Clear local session
            DispatchQueue.main.async {
                self.session = nil
                self.saveSession(nil)
                self.needsPartnerSetup = false
            }
            
        } catch {
            print("Error deleting account: \(error)")
            throw SupabaseError.serverError(message: "Failed to delete account: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

enum SupabaseError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noDataReturned
    case decodingError(Error)
    case serverError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noDataReturned:
            return "No data returned from server"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

struct EmptyResponse: Codable {
    init() {}
}

// MARK: - Supporting Types for Auth

struct Session: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case user
    }
}

struct User: Codable, Identifiable {
    let id: UUID
    let email: String?
    let createdAt: Date
    var profilePictureURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case profilePictureURL = "profile_picture_url"
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String?
    let displayName: String?
    let partnerSetupComplete: Bool?
    let partnerName: String?
    let profilePictureURL: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case partnerSetupComplete = "partner_setup_complete"
        case partnerName = "partner_name"
        case profilePictureURL = "profile_picture_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseErrorResponse: Codable {
    let error: String
    let error_description: String
}

struct SignUpResponse: Codable {
    let id: UUID?
    let email: String?
    let emailConfirmedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case emailConfirmedAt = "email_confirmed_at"
    }
}

struct PartnerInvitation: Codable, Identifiable {
    let id: UUID
    let inviterId: UUID
    let inviterEmail: String
    let inviteeEmail: String
    let status: String // "pending", "accepted", "declined"
    let createdAt: Date
    let acceptedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case inviterId = "inviter_id"
        case inviterEmail = "inviter_email"
        case inviteeEmail = "invitee_email"
        case status
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
    }
}

struct Partnership: Codable, Identifiable {
    let id: UUID
    let user1Id: UUID
    let user2Id: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case createdAt = "created_at"
    }
}
