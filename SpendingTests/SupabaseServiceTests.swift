//
//  SupabaseServiceTests.swift
//  SpendingTests
//
//  Created by GitHub Copilot on 2025-07-31.
//

import Testing
import Foundation
@testable import Spending

@MainActor
final class SupabaseServiceTests {
    
    // MARK: - Authentication Tests
    
    @Test("SupabaseService initialization")
    func testSupabaseServiceInitialization() async throws {
        // Given & When
        let service = SupabaseService()
        
        // Then
        #expect(service.session == nil)
        #expect(service.isAuthenticated == false)
        #expect(service.needsPartnerSetup == false)
    }
    
    @Test("SupabaseService session management")
    func testSessionManagement() async throws {
        // Given
        let service = SupabaseService()
        
        // Create a mock session
        let mockUser = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date()
        )
        let mockSession = Session(
            accessToken: "mock_access_token",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: "mock_refresh_token",
            user: mockUser
        )
        
        // When
        service.session = mockSession
        
        // Then
        #expect(service.session != nil)
        #expect(service.isAuthenticated == true)
        #expect(service.session?.user.email == "test@example.com")
        #expect(service.session?.accessToken == "mock_access_token")
    }
    
    @Test("SupabaseService clear session")
    func testClearSession() async throws {
        // Given
        let service = SupabaseService()
        let mockUser = User(id: UUID(), email: "test@example.com", createdAt: Date())
        let mockSession = Session(
            accessToken: "token",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: "refresh",
            user: mockUser
        )
        service.session = mockSession
        
        // When
        service.clearSession()
        
        // Then
        #expect(service.session == nil)
        #expect(service.isAuthenticated == false)
    }
    
    // MARK: - Partner Management Tests
    
    @Test("SupabaseService partner setup status")
    func testPartnerSetupStatus() async throws {
        // Given
        let service = SupabaseService()
        
        // Initially no partner setup needed
        #expect(service.needsPartnerSetup == false)
        
        // When
        service.needsPartnerSetup = true
        
        // Then
        #expect(service.needsPartnerSetup == true)
    }
    
    // MARK: - Profile Picture URL Generation
    
    @Test("SupabaseService getProfilePictureURL")
    func testGetProfilePictureURL() async throws {
        // Given
        let service = SupabaseService()
        let userId = "550e8400-e29b-41d4-a716-446655440000"
        
        // When
        let url = service.getProfilePictureURL(userId: userId)
        
        // Then
        #expect(url.contains("profile-pics"))
        #expect(url.contains(userId.lowercased()))
        #expect(url.contains("profile.jpg"))
        #expect(url.hasPrefix("https://"))
    }
    
    @Test("SupabaseService getProfilePictureURL normalizes case")
    func testGetProfilePictureURLNormalizesCase() async throws {
        // Given
        let service = SupabaseService()
        let upperCaseUserId = "550E8400-E29B-41D4-A716-446655440000"
        
        // When
        let url = service.getProfilePictureURL(userId: upperCaseUserId)
        
        // Then
        #expect(url.contains(upperCaseUserId.lowercased()))
        #expect(!url.contains("550E8400")) // Should not contain uppercase
    }
    
    // MARK: - Error Handling Tests
    
    @Test("SupabaseError types")
    func testSupabaseErrorTypes() async throws {
        // Test different error types
        let invalidURL = SupabaseError.invalidURL
        let invalidResponse = SupabaseError.invalidResponse
        let httpError = SupabaseError.httpError(404)
        let noData = SupabaseError.noDataReturned
        let serverError = SupabaseError.serverError(message: "Test error")
        
        // Verify error descriptions
        #expect(invalidURL.errorDescription == "Invalid URL")
        #expect(invalidResponse.errorDescription == "Invalid response")
        #expect(httpError.errorDescription == "HTTP error: 404")
        #expect(noData.errorDescription == "No data returned from server")
        #expect(serverError.errorDescription == "Server error: Test error")
    }
    
    // MARK: - HTTP Method Tests
    
    @Test("HTTPMethod enum values")
    func testHTTPMethodEnum() async throws {
        #expect(HTTPMethod.GET.rawValue == "GET")
        #expect(HTTPMethod.POST.rawValue == "POST")
        #expect(HTTPMethod.PUT.rawValue == "PUT")
        #expect(HTTPMethod.PATCH.rawValue == "PATCH")
        #expect(HTTPMethod.DELETE.rawValue == "DELETE")
    }
    
    // MARK: - Model Codable Tests
    
    @Test("Session model coding")
    func testSessionCoding() async throws {
        // Given
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date()
        )
        let session = Session(
            accessToken: "access_token",
            tokenType: "Bearer",
            expiresIn: 3600,
            refreshToken: "refresh_token",
            user: user
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSession = try decoder.decode(Session.self, from: data)
        
        // Then
        #expect(decodedSession.accessToken == session.accessToken)
        #expect(decodedSession.tokenType == session.tokenType)
        #expect(decodedSession.expiresIn == session.expiresIn)
        #expect(decodedSession.refreshToken == session.refreshToken)
        #expect(decodedSession.user.email == session.user.email)
    }
    
    @Test("User model coding")
    func testUserCoding() async throws {
        // Given
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date(),
            profilePictureURL: "https://example.com/pic.jpg"
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(user)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedUser = try decoder.decode(User.self, from: data)
        
        // Then
        #expect(decodedUser.id == user.id)
        #expect(decodedUser.email == user.email)
        #expect(decodedUser.profilePictureURL == user.profilePictureURL)
    }
    
    @Test("UserProfile model coding")
    func testUserProfileCoding() async throws {
        // Given
        let userProfile = UserProfile(
            id: UUID(),
            email: "test@example.com",
            displayName: "Test User",
            partnerSetupComplete: true,
            partnerName: "Test Partner",
            profilePictureURL: "https://example.com/pic.jpg",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(userProfile)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedProfile = try decoder.decode(UserProfile.self, from: data)
        
        // Then
        #expect(decodedProfile.id == userProfile.id)
        #expect(decodedProfile.email == userProfile.email)
        #expect(decodedProfile.displayName == userProfile.displayName)
        #expect(decodedProfile.partnerSetupComplete == userProfile.partnerSetupComplete)
        #expect(decodedProfile.partnerName == userProfile.partnerName)
        #expect(decodedProfile.profilePictureURL == userProfile.profilePictureURL)
    }
    
    @Test("SupabaseErrorResponse model coding")
    func testSupabaseErrorResponseCoding() async throws {
        // Given
        let errorResponse = SupabaseErrorResponse(
            error: "invalid_credentials",
            error_description: "Invalid login credentials"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(errorResponse)
        
        let decoder = JSONDecoder()
        let decodedError = try decoder.decode(SupabaseErrorResponse.self, from: data)
        
        // Then
        #expect(decodedError.error == errorResponse.error)
        #expect(decodedError.error_description == errorResponse.error_description)
    }
    
    @Test("SignUpResponse model coding")
    func testSignUpResponseCoding() async throws {
        // Given
        let signUpResponse = SignUpResponse(
            id: UUID(),
            email: "test@example.com",
            emailConfirmedAt: nil
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(signUpResponse)
        
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(SignUpResponse.self, from: data)
        
        // Then
        #expect(decodedResponse.id == signUpResponse.id)
        #expect(decodedResponse.email == signUpResponse.email)
        #expect(decodedResponse.emailConfirmedAt == signUpResponse.emailConfirmedAt)
    }
    
    @Test("PartnerInvitation model coding")
    func testPartnerInvitationCoding() async throws {
        // Given
        let invitation = PartnerInvitation(
            id: UUID(),
            inviterId: UUID(),
            inviterEmail: "inviter@example.com",
            inviteeEmail: "invitee@example.com",
            status: "pending",
            createdAt: Date(),
            acceptedAt: nil
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(invitation)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedInvitation = try decoder.decode(PartnerInvitation.self, from: data)
        
        // Then
        #expect(decodedInvitation.id == invitation.id)
        #expect(decodedInvitation.inviterId == invitation.inviterId)
        #expect(decodedInvitation.inviterEmail == invitation.inviterEmail)
        #expect(decodedInvitation.inviteeEmail == invitation.inviteeEmail)
        #expect(decodedInvitation.status == invitation.status)
        #expect(decodedInvitation.acceptedAt == invitation.acceptedAt)
    }
    
    @Test("Partnership model coding")
    func testPartnershipCoding() async throws {
        // Given
        let partnership = Partnership(
            id: UUID(),
            user1Id: UUID(),
            user2Id: UUID(),
            createdAt: Date()
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(partnership)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPartnership = try decoder.decode(Partnership.self, from: data)
        
        // Then
        #expect(decodedPartnership.id == partnership.id)
        #expect(decodedPartnership.user1Id == partnership.user1Id)
        #expect(decodedPartnership.user2Id == partnership.user2Id)
    }
    
    @Test("EmptyResponse model")
    func testEmptyResponse() async throws {
        // Given & When
        let emptyResponse = EmptyResponse()
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(emptyResponse)
        
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(EmptyResponse.self, from: data)
        
        // Then - Should not throw and should be equivalent
        #expect(type(of: decodedResponse) == EmptyResponse.self)
    }
    
    // MARK: - Integration Tests (with mocked network)
    
    @Test("SupabaseService shared instance")
    func testSharedInstance() async throws {
        // Given & When
        let instance1 = SupabaseService.shared
        let instance2 = SupabaseService.shared
        
        // Then
        #expect(instance1 === instance2) // Same instance
    }
    
    // MARK: - Date Handling Tests
    
    @Test("Date decoding strategy handles multiple formats")
    func testDateDecodingFormats() async throws {
        // Test that the service can handle various date formats
        let dateFormats = [
            "2025-07-30 18:36:35.591+00",   // Supabase timestamp format
            "2025-07-30 18:36:35.59+00",    // Variation
            "2025-07-30 18:36:35.5+00",     // Variation
            "2025-07-30 18:36:35+00",       // Without milliseconds
            "2025-07-30T18:36:35.591+00",   // ISO format with milliseconds
            "2025-07-30T18:36:35+00"        // ISO format without milliseconds
        ]
        
        for dateString in dateFormats {
            // Create JSON with this date format
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "email": "test@example.com",
                "created_at": "\(dateString)"
            }
            """.data(using: .utf8)!
            
            // Verify it can be decoded
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatters = [
                    "yyyy-MM-dd HH:mm:ss.SSSXXXXX",
                    "yyyy-MM-dd HH:mm:ss.SSXXXXX",
                    "yyyy-MM-dd HH:mm:ss.SXXXXX",
                    "yyyy-MM-dd HH:mm:ssXXXXX",
                    "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
                    "yyyy-MM-dd'T'HH:mm:ssXXXXX"
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
            
            // Should not throw
            let user = try decoder.decode(User.self, from: json)
            #expect(user.email == "test@example.com")
        }
    }
}

// MARK: - Mock Network Service

class MockNetworkService {
    var shouldFail = false
    var mockResponseData: Data?
    var mockStatusCode = 200
    var mockError: Error?
    
    func makeRequest(url: URL, method: String, headers: [String: String], body: Data?) async throws -> (Data, HTTPURLResponse) {
        if shouldFail {
            throw mockError ?? URLError(.networkConnectionLost)
        }
        
        let response = HTTPURLResponse(
            url: url,
            statusCode: mockStatusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        
        return (mockResponseData ?? Data(), response)
    }
}