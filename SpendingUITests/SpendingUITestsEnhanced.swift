//
//  SpendingUITests.swift
//  SpendingUITests
//
//  Created by George Gausden on 2025-07-30.
//

import XCTest

final class SpendingUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Clear any stored session data for clean tests
        app.launchArguments = ["--uitesting"]
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunch() throws {
        // UI tests must launch the application that they test.
        app.launch()

        // Verify the app launches successfully
        XCTAssertTrue(app.exists)
        
        // Should show login screen initially (no session stored)
        let loginTitle = app.staticTexts["Spending"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    // MARK: - Authentication Flow Tests
    
    @MainActor
    func testLoginFormElements() throws {
        app.launch()
        
        // Verify login form elements exist
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        let toggleButton = app.buttons["Don't have an account? Sign Up"]
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(signInButton.exists)
        XCTAssertTrue(toggleButton.exists)
    }
    
    @MainActor
    func testSignUpToggle() throws {
        app.launch()
        
        // Initially should show Sign In
        XCTAssertTrue(app.buttons["Sign In"].exists)
        XCTAssertTrue(app.buttons["Don't have an account? Sign Up"].exists)
        
        // Tap toggle to switch to Sign Up
        app.buttons["Don't have an account? Sign Up"].tap()
        
        // Should now show Sign Up
        XCTAssertTrue(app.buttons["Sign Up"].exists)
        XCTAssertTrue(app.buttons["Already have an account? Sign In"].exists)
        
        // Toggle back to Sign In
        app.buttons["Already have an account? Sign In"].tap()
        
        // Should be back to Sign In
        XCTAssertTrue(app.buttons["Sign In"].exists)
        XCTAssertTrue(app.buttons["Don't have an account? Sign Up"].exists)
    }
    
    @MainActor
    func testLoginFormValidation() throws {
        app.launch()
        
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        // Try to sign in without filling fields
        signInButton.tap()
        
        // Should not proceed (would need to check for error message if implemented)
        
        // Fill in email only
        emailField.tap()
        emailField.typeText("test@example.com")
        signInButton.tap()
        
        // Should not proceed without password
        
        // Fill in password
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Now should be able to attempt sign in (would fail in real app without valid credentials)
        signInButton.tap()
    }
    
    // MARK: - Navigation Tests (for authenticated state)
    
    @MainActor
    func testMainTabNavigation() throws {
        // Note: This test would require a way to bypass authentication or use test credentials
        // For now, we'll test the UI elements that should exist
        
        app.launch()
        
        // If we were authenticated, we should see these tabs:
        // - Add Expense
        // - Summary  
        // - History
        // - Profile
        
        // This test would need to be implemented with actual authentication
        // or by mocking the authentication state
    }
    
    // MARK: - Expense Entry Tests
    
    @MainActor
    func testExpenseEntryFormElements() throws {
        // This would test the expense entry form if we could get to authenticated state
        // Elements to test:
        // - Amount input field
        // - Title field
        // - Spender selection
        // - Split type selection
        // - Description field
        // - Add button
        
        // Implementation would require authenticated state
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibilityElements() throws {
        app.launch()
        
        // Test that key UI elements are accessible
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        // Verify accessibility identifiers and labels
        XCTAssertTrue(emailField.isEnabled)
        XCTAssertTrue(passwordField.isEnabled)
        XCTAssertTrue(signInButton.isEnabled)
        
        // Test that elements are accessible to VoiceOver
        XCTAssertNotNil(emailField.label)
        XCTAssertNotNil(passwordField.label)
        XCTAssertNotNil(signInButton.label)
    }
    
    // MARK: - Keyboard and Input Tests
    
    @MainActor
    func testKeyboardInteraction() throws {
        app.launch()
        
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        // Test email field
        emailField.tap()
        emailField.typeText("test@example.com")
        XCTAssertEqual(emailField.value as? String, "test@example.com")
        
        // Test password field
        passwordField.tap()
        passwordField.typeText("password123")
        // Password field value is typically hidden for security
        
        // Test keyboard dismissal
        app.tap() // Tap outside to dismiss keyboard
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testErrorMessageDisplay() throws {
        app.launch()
        
        // This would test error message display
        // Implementation would depend on how errors are shown in the UI
        
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        // Enter invalid credentials
        emailField.tap()
        emailField.typeText("invalid@example.com")
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        signInButton.tap()
        
        // Should show error message (implementation would check for specific error text)
    }
    
    // MARK: - Interface Orientation Tests
    
    @MainActor
    func testInterfaceOrientations() throws {
        app.launch()
        
        // Test portrait orientation (default)
        XCTAssertTrue(app.staticTexts["Spending"].exists)
        
        // Test landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Spending"].waitForExistence(timeout: 2))
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["Spending"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testUIResponsiveness() throws {
        app.launch()
        
        measure {
            // Test responsiveness of key interactions
            let emailField = app.textFields["Email"]
            emailField.tap()
            emailField.typeText("test@example.com")
            
            let passwordField = app.secureTextFields["Password"]
            passwordField.tap()
            passwordField.typeText("password")
            
            // Clear fields
            emailField.tap()
            emailField.clearText()
            passwordField.tap()
            passwordField.clearText()
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForElementToAppear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
    
    func tapCenter() {
        let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}