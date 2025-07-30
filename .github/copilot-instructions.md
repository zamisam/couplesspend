# Copilot Instructions for Spending iOS App

## Project Architecture

This is a **SwiftUI iOS application** targeting iOS 18.5+ with Swift 5.0. The project follows standard iOS app architecture patterns:

- **Main App**: `Spending/SpendingApp.swift` - App entry point with `@main` struct
- **UI Layer**: `Spending/ContentView.swift` - Primary SwiftUI view structure  
- **Bundle ID**: `ggeorge.Spending` - Used for app identification and provisioning

## Project Structure

```
Spending/                    # Main source code
├── SpendingApp.swift       # App entry point (@main)
├── ContentView.swift       # Root SwiftUI view
└── Assets.xcassets/        # App icons, colors, images

SpendingTests/              # Unit tests using Swift Testing framework
└── SpendingTests.swift     # Test cases with @Test attribute

SpendingUITests/            # UI automation tests
├── SpendingUITests.swift   # Main UI test cases
└── SpendingUITestsLaunchTests.swift  # App launch tests with screenshots
```

## Testing Framework

This project uses **Swift Testing** (not XCTest) for unit tests:
- Use `@Test` attribute instead of `func test*()`
- Use `#expect(...)` instead of `XCTAssert*`
- Import with `@testable import Spending`

- **Async Test Functions**: Always add `async` to test function signatures when planning to test them individually. For example:

  ```swift
  // Instead of:
  func testAddExpense() {
      // ... test implementation
  }

  // Use:
  func testAddExpense() async {
      // ... test implementation
  }
  ```

UI tests still use XCTest framework with `XCUIApplication()`.

## Development Workflow

### Building & Running
- **Xcode Project**: Use `Spending.xcodeproj` to open in Xcode
- **Schemes**: Main app target + test targets available
- **Simulator**: iOS 18.5+ required for deployment target

### Testing Commands
```bash
# Run unit tests
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests  
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan SpendingUITests
```

## Code Conventions

- **SwiftUI Views**: Use `struct` conforming to `View` protocol
- **Previews**: Include `#Preview` blocks for SwiftUI view development
- **File Headers**: Standard Apple template with creation date and author
- **Target Membership**: Source files in `Spending/` directory belong to main target

## Key Dependencies

- **SwiftUI**: Primary UI framework
- **XCTest**: UI testing framework
- **Swift Testing**: Unit testing framework (new Apple testing framework)

## Common Patterns

When adding new features:
1. Create SwiftUI views in `Spending/` directory
2. Add unit tests in `SpendingTests/` using Swift Testing syntax
3. Add UI tests in `SpendingUITests/` for user workflows
4. Update `ContentView.swift` for navigation integration

This is a fresh project template - expand architecture as features are implemented.
