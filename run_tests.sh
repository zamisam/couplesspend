#!/bin/bash

# run_tests.sh
# Test runner script for Spending iOS App
# Usage: ./run_tests.sh [test-type] [specific-test]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT="Spending.xcodeproj"
SCHEME="Spending"
SIMULATOR="iPhone 16"
DESTINATION="platform=iOS Simulator,name=${SIMULATOR}"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Xcode command line tools are available
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild not found. Please install Xcode command line tools."
        exit 1
    fi
    
    if ! xcrun simctl list devices | grep -q "${SIMULATOR}"; then
        print_warning "Simulator '${SIMULATOR}' not found. Using default simulator."
        SIMULATOR="iPhone 15"
        DESTINATION="platform=iOS Simulator,name=${SIMULATOR}"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    if [ -n "$1" ]; then
        print_status "Running specific test: $1"
        xcodebuild test \
            -project "${PROJECT}" \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -only-testing:"$1" \
            -quiet
    else
        xcodebuild test \
            -project "${PROJECT}" \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -only-testing:SpendingTests \
            -quiet
    fi
    
    print_success "Unit tests completed"
}

# Function to run UI tests
run_ui_tests() {
    print_status "Running UI tests..."
    
    if [ -n "$1" ]; then
        print_status "Running specific UI test: $1"
        xcodebuild test \
            -project "${PROJECT}" \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -only-testing:"$1" \
            -quiet
    else
        xcodebuild test \
            -project "${PROJECT}" \
            -scheme "${SCHEME}" \
            -destination "${DESTINATION}" \
            -only-testing:SpendingUITests \
            -quiet
    fi
    
    print_success "UI tests completed"
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."
    
    xcodebuild test \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -quiet
    
    print_success "All tests completed"
}

# Function to run performance tests only
run_performance_tests() {
    print_status "Running performance tests..."
    
    xcodebuild test \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -only-testing:SpendingTests/PerformanceTests \
        -quiet
    
    print_success "Performance tests completed"
}

# Function to run model tests only
run_model_tests() {
    print_status "Running model tests..."
    
    xcodebuild test \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -only-testing:SpendingTests/ExpenseStoreTests \
        -only-testing:SpendingTests/ModelValidationTests \
        -quiet
    
    print_success "Model tests completed"
}

# Function to run service tests only
run_service_tests() {
    print_status "Running service tests..."
    
    xcodebuild test \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -only-testing:SpendingTests/SupabaseServiceTests \
        -only-testing:SpendingTests/ExpenseStoreAsyncTests \
        -quiet
    
    print_success "Service tests completed"
}

# Function to clean build directory
clean_build() {
    print_status "Cleaning build directory..."
    
    xcodebuild clean \
        -project "${PROJECT}" \
        -scheme "${SCHEME}" \
        -quiet
    
    print_success "Build directory cleaned"
}

# Function to show test coverage (requires additional setup)
show_coverage() {
    print_warning "Test coverage reporting requires additional Xcode configuration."
    print_status "To enable code coverage:"
    print_status "1. Edit Scheme in Xcode"
    print_status "2. Go to Test tab"
    print_status "3. Check 'Gather coverage for some targets'"
    print_status "4. Select Spending target"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [SPECIFIC_TEST]"
    echo ""
    echo "Commands:"
    echo "  unit          Run unit tests (default)"
    echo "  ui            Run UI tests"
    echo "  all           Run all tests"
    echo "  performance   Run performance tests only"
    echo "  models        Run model tests only"
    echo "  services      Run service tests only"
    echo "  clean         Clean build directory"
    echo "  coverage      Show coverage information"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 unit                                    # Run all unit tests"
    echo "  $0 ui                                      # Run all UI tests"
    echo "  $0 unit SpendingTests/ExpenseStoreTests   # Run specific test class"
    echo "  $0 performance                             # Run performance tests"
    echo "  $0 models                                  # Run model tests"
    echo ""
    echo "Test Class Names:"
    echo "  SpendingTests/ExpenseStoreTests"
    echo "  SpendingTests/ExpenseStoreAsyncTests"
    echo "  SpendingTests/SupabaseServiceTests"
    echo "  SpendingTests/ModelValidationTests"
    echo "  SpendingTests/PerformanceTests"
    echo "  SpendingUITests/SpendingUITests"
    echo ""
}

# Main script logic
main() {
    local command="${1:-unit}"
    local specific_test="$2"
    
    print_status "Starting test execution for Spending iOS App"
    print_status "Command: ${command}"
    
    check_prerequisites
    
    case "${command}" in
        "unit")
            run_unit_tests "${specific_test}"
            ;;
        "ui")
            run_ui_tests "${specific_test}"
            ;;
        "all")
            run_all_tests
            ;;
        "performance")
            run_performance_tests
            ;;
        "models")
            run_model_tests
            ;;
        "services")
            run_service_tests
            ;;
        "clean")
            clean_build
            ;;
        "coverage")
            show_coverage
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: ${command}"
            show_help
            exit 1
            ;;
    esac
    
    print_success "Test execution completed successfully!"
}

# Run main function with all arguments
main "$@"