# Test Suite Documentation

## Overview

This comprehensive test suite covers all major functionality of the Spending iOS application, including unit tests, integration tests, UI tests, and performance tests. The tests are designed to ensure reliability, correctness, and performance of the couples' spending tracker app.

## Test Architecture

### Testing Frameworks Used
- **Swift Testing**: Primary framework for unit tests (new Apple testing framework)
- **XCTest**: Framework for UI tests and some integration tests
- **@MainActor**: Used for tests that interact with UI components

### Test Organization

```
SpendingTests/
├── ExpenseStoreTests.swift           # Core model and ExpenseStore tests
├── ExpenseStoreAsyncTests.swift      # Async operations and error handling
├── SupabaseServiceTests.swift       # Service layer and API tests
├── ModelValidationTests.swift       # Edge cases and validation tests
└── PerformanceTests.swift           # Performance and load tests

SpendingUITests/
├── SpendingUITests.swift            # Basic UI flow tests
├── SpendingUITestsEnhanced.swift    # Comprehensive UI tests
└── SpendingUITestsLaunchTests.swift # App launch and performance tests
```

## Test Categories

### 1. Model Tests (`ExpenseStoreTests.swift`, `ModelValidationTests.swift`)

#### Core Model Tests
- **Expense Model Creation**: Tests basic expense creation with various parameters
- **Split Type Calculations**: Validates debt calculations for different split types (equal, full, partner_full, no_split)
- **Person Enum**: Tests display names and raw values
- **SpendingSummary**: Tests balance calculations and debt determinations

#### Edge Case Tests
- **Zero and Negative Amounts**: Validates handling of edge case monetary values
- **Empty/Nil Strings**: Tests handling of empty titles and descriptions
- **Large Numbers**: Tests with very large monetary amounts
- **Special Characters**: Tests with Unicode, emojis, and special characters
- **Date Handling**: Tests date creation, formatting, and edge cases

#### Validation Tests
- **UUID Uniqueness**: Ensures unique identifiers for expenses
- **Enum Coverage**: Validates all enum cases are handled
- **Debt Calculation Accuracy**: Precise testing of financial calculations

### 2. Service Layer Tests (`SupabaseServiceTests.swift`)

#### Authentication Tests
- **Session Management**: Tests login/logout state handling
- **Token Handling**: Validates access token and refresh token management
- **Error Handling**: Tests authentication error scenarios

#### API Integration Tests
- **Model Serialization**: Tests JSON encoding/decoding for all models
- **Date Format Handling**: Tests multiple date format parsing
- **Error Response Handling**: Validates error message parsing
- **Profile Picture URL Generation**: Tests URL construction and normalization

#### Mock Integration
- **Service Mocking**: Comprehensive mock implementations for testing
- **Network Simulation**: Simulates various network conditions and responses

### 3. ExpenseStore Tests (`ExpenseStoreAsyncTests.swift`)

#### CRUD Operations
- **Add Expense**: Tests successful and failed expense creation
- **Update Expense**: Tests expense modification
- **Delete Expense**: Tests single and bulk expense deletion
- **Load Expenses**: Tests data fetching and error handling

#### Business Logic
- **Settle Operations**: Tests expense settling (single and bulk)
- **Summary Calculations**: Tests automatic summary updates
- **Filtering Operations**: Tests expense filtering by various criteria
- **Total Calculations**: Tests spending total calculations

#### Error Handling
- **Network Failures**: Tests handling of network errors
- **Data Consistency**: Tests state consistency during failures
- **Recovery Scenarios**: Tests error recovery and retry logic

### 4. Performance Tests (`PerformanceTests.swift`)

#### Load Testing
- **Large Datasets**: Tests with thousands of expenses
- **Memory Usage**: Validates memory efficiency
- **Calculation Performance**: Tests summary calculation speed
- **Filtering Performance**: Tests search and filter operations

#### Concurrency Testing
- **Thread Safety**: Tests concurrent access to shared resources
- **Async Operations**: Tests parallel async operations
- **Data Race Prevention**: Validates thread-safe implementations

#### Serialization Performance
- **JSON Encoding/Decoding**: Tests performance with large data sets
- **Date Formatting**: Tests date parsing performance
- **Memory Management**: Tests for memory leaks

### 5. UI Tests (`SpendingUITests.swift`, `SpendingUITestsEnhanced.swift`)

#### Authentication Flow
- **Login/Signup Forms**: Tests form elements and validation
- **Toggle Between Modes**: Tests switching between login and signup
- **Keyboard Interaction**: Tests text input and keyboard handling
- **Error Display**: Tests error message presentation

#### Navigation Testing
- **Tab Navigation**: Tests main tab bar functionality
- **Modal Presentations**: Tests sheet and modal presentations
- **Back Navigation**: Tests navigation stack behavior

#### Accessibility Testing
- **VoiceOver Support**: Tests accessibility labels and hints
- **Dynamic Type**: Tests text scaling support
- **Contrast and Colors**: Tests visual accessibility

#### Device Testing
- **Orientation Changes**: Tests landscape and portrait modes
- **Different Screen Sizes**: Tests on various device sizes
- **Keyboard Appearance**: Tests software keyboard interaction

## Mock Infrastructure

### MockSupabaseService
- **Complete API Simulation**: Implements all SupabaseService methods
- **Error Injection**: Configurable failure modes for testing error handling
- **State Tracking**: Tracks operations for verification
- **Data Persistence**: Maintains mock data state across operations

### Mock Features
- **Network Simulation**: Simulates various network conditions
- **Authentication States**: Mock session management
- **Data Operations**: Complete CRUD operation simulation
- **Error Scenarios**: Comprehensive error condition testing

## Running Tests

### Unit Tests (Swift Testing)
```bash
# Run all unit tests
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingTests

# Run specific test file
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingTests/ExpenseStoreTests

# Run specific test method
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingTests/ExpenseStoreTests/testExpenseModelCreation
```

### UI Tests (XCTest)
```bash
# Run all UI tests
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingUITests

# Run specific UI test file
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingUITests/SpendingUITests
```

### Performance Tests
```bash
# Run performance tests
xcodebuild test -project Spending.xcodeproj -scheme Spending -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SpendingTests/PerformanceTests
```

## Test Coverage Goals

### Core Functionality Coverage
- ✅ **Models**: 100% coverage of all model classes and enums
- ✅ **Business Logic**: 95%+ coverage of expense calculations and summaries
- ✅ **Service Layer**: 90%+ coverage of API interactions (with mocking)
- ✅ **Error Handling**: 100% coverage of error scenarios

### UI Coverage
- ✅ **Authentication Flow**: Complete login/signup process
- ⚠️ **Main Application**: Requires authenticated state for full testing
- ✅ **Accessibility**: Basic accessibility element testing
- ✅ **Responsive Design**: Orientation and device size testing

### Performance Coverage
- ✅ **Load Testing**: Large dataset handling
- ✅ **Memory Testing**: Memory leak detection
- ✅ **Concurrency**: Thread safety validation
- ✅ **Serialization**: JSON performance testing

## Continuous Integration

### Test Automation
- Tests should be run automatically on every PR
- Performance tests should run on scheduled basis
- UI tests require simulator environment

### Test Reporting
- Unit test results should be integrated with CI/CD pipeline
- Performance benchmarks should be tracked over time
- Test coverage reports should be generated

## Best Practices

### Test Writing Guidelines
1. **Use descriptive test names** that explain the scenario being tested
2. **Follow Given-When-Then** structure for clarity
3. **Test one thing at a time** to make failures easier to diagnose
4. **Use meaningful assertions** with specific expected values
5. **Mock external dependencies** to ensure test isolation

### Mock Guidelines
1. **Keep mocks simple** and focused on the interface being tested
2. **Use configurable failures** to test error handling
3. **Verify interactions** with mocks when appropriate
4. **Reset mock state** between tests

### Performance Test Guidelines
1. **Set realistic performance expectations** based on device capabilities
2. **Test with representative data sizes** that match real-world usage
3. **Monitor memory usage** to detect leaks
4. **Use consistent test environments** for reliable benchmarks

## Future Improvements

### Additional Test Coverage
- **Integration Tests**: Full end-to-end testing with real backend
- **Visual Regression Tests**: Screenshot-based UI testing
- **Accessibility Tests**: Comprehensive accessibility validation
- **Localization Tests**: Multi-language support testing

### Test Infrastructure
- **Test Data Factories**: Centralized test data creation
- **Test Utilities**: Common testing helper functions
- **Custom Matchers**: Domain-specific assertion helpers
- **Test Reporting**: Enhanced reporting and metrics

### Automation
- **Parallel Test Execution**: Faster test runs
- **Flaky Test Detection**: Automatic identification of unreliable tests
- **Performance Regression Detection**: Automatic performance monitoring
- **Test Selection**: Smart test selection based on code changes

## Troubleshooting

### Common Issues
1. **Async Test Timeouts**: Increase timeout values for slow operations
2. **UI Test Flakiness**: Add proper wait conditions and element checks
3. **Mock State Pollution**: Ensure mocks are reset between tests
4. **Performance Test Variability**: Run multiple iterations and average results

### Debugging Tips
1. **Use breakpoints** in test code to inspect state
2. **Print statements** can help understand test flow
3. **Check mock configurations** when tests fail unexpectedly
4. **Verify test data setup** is correct for the scenario being tested