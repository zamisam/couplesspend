# Design Document

## Overview

The spending tracker app will be built using SwiftUI with a clean, minimalist interface optimized for quick expense entry and clear spending visualization. The app follows iOS design principles with a focus on accessibility and ease of use for two-person expense tracking.

## Architecture

### App Structure
- **MVVM Pattern**: Using SwiftUI's native data binding with ObservableObject for state management
- **Single Window App**: Main interface with tab-based navigation for different views
- **Local Data Persistence**: Core Data for reliable local storage with automatic saving
- **No Network Dependencies**: Fully offline-capable application

### Core Components
```
SpendingApp (App Entry Point)
├── MainTabView (Primary Navigation)
│   ├── ExpenseEntryView (Quick Add)
│   ├── SummaryView (Balance Overview)
│   └── HistoryView (Recent Expenses)
├── ExpenseStore (Data Management)
├── Models (Data Structures)
└── Core Data Stack
```

## Components and Interfaces

### 1. Data Models

#### Expense Model
```swift
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Decimal
    let spender: Person
    let date: Date
    let description: String?
}
```

#### Person Model
```swift
enum Person: String, CaseIterable, Codable {
    case personOne = "Person 1"
    case personTwo = "Person 2"
    
    var displayName: String { rawValue }
}
```

#### Spending Summary Model
```swift
struct SpendingSummary {
    let personOneTotal: Decimal
    let personTwoTotal: Decimal
    let balance: Decimal
    let whoOwes: Person?
    let amountOwed: Decimal
}
```

### 2. Views

#### ExpenseEntryView
- **Purpose**: Primary expense input interface
- **Layout**: Vertical stack with amount input, person selector, and add button
- **Features**: 
  - Large numeric keypad-friendly amount field
  - Prominent person toggle buttons
  - One-tap expense addition
  - Form validation and feedback

#### SummaryView
- **Purpose**: Spending balance overview
- **Layout**: Card-based design showing totals and balance
- **Features**:
  - Individual spending totals
  - Clear balance indicator
  - Visual debt/credit representation
  - Real-time updates

#### HistoryView
- **Purpose**: Recent expense list with management
- **Layout**: List view with swipe actions
- **Features**:
  - Chronological expense display
  - Swipe-to-delete functionality
  - Expense details (amount, person, date)
  - Confirmation dialogs for deletions

### 3. Data Management

#### ExpenseStore (ObservableObject)
- **Responsibilities**:
  - Expense CRUD operations
  - Real-time summary calculations
  - Core Data integration
  - State management for UI updates

#### Core Data Stack
- **Entity**: ExpenseEntity with attributes for amount, spender, date
- **Configuration**: Local SQLite store with automatic migrations
- **Performance**: Batch operations and efficient queries

## Data Models

### Core Data Schema

#### ExpenseEntity
- `id: UUID` (Primary Key)
- `amount: Decimal` (Required)
- `spender: String` (Required, Person enum raw value)
- `dateCreated: Date` (Required, auto-generated)
- `descriptionText: String?` (Optional, for future expansion)

### Calculated Properties
- **Individual Totals**: Sum of expenses per person
- **Balance**: Difference between person totals
- **Debt Indicator**: Who owes whom and amount

## Error Handling

### Input Validation
- **Amount Field**: Numeric validation with decimal support, maximum reasonable limits
- **Person Selection**: Required field validation
- **Form State**: Clear error messaging and input guidance

### Data Persistence Errors
- **Core Data Failures**: Graceful degradation with user notification
- **Storage Full**: Warning messages with cleanup suggestions
- **Data Corruption**: Recovery mechanisms and data integrity checks

### User Experience Errors
- **Delete Confirmations**: Clear confirmation dialogs with cancel options
- **Network Unavailable**: No impact (offline-first design)
- **App State Recovery**: Automatic form state preservation

## Testing Strategy

### Unit Testing
- **Model Logic**: Expense calculations, summary generation, data validation
- **Data Operations**: Core Data CRUD operations, migration testing
- **Business Logic**: Balance calculations, debt determination algorithms

### UI Testing
- **Expense Entry Flow**: Complete add expense workflow testing
- **Navigation**: Tab switching and view state management
- **Data Display**: Summary accuracy and list updates
- **Delete Operations**: Confirmation flows and data consistency

### Integration Testing
- **Core Data Integration**: Full data persistence workflow
- **View Model Integration**: Data binding and state updates
- **Cross-View Updates**: Real-time updates across different views

### Accessibility Testing
- **VoiceOver Support**: All interactive elements properly labeled
- **Dynamic Type**: Text scaling support across all views
- **Color Contrast**: Sufficient contrast ratios for all UI elements
- **Touch Targets**: Minimum 44pt touch target sizes

## User Interface Design

### Design Principles
- **Minimalism**: Clean interface with essential elements only
- **Accessibility**: Full VoiceOver and Dynamic Type support
- **Consistency**: iOS Human Interface Guidelines compliance
- **Speed**: Optimized for quick expense entry

### Color Scheme
- **Primary**: iOS system accent color for consistency
- **Success**: Green for positive balances
- **Warning**: Orange for debt indicators
- **Neutral**: System grays for secondary information

### Typography
- **Headers**: Large, bold system font
- **Body**: Regular system font with good contrast
- **Numbers**: Monospaced font for amount displays
- **Dynamic Type**: Full support for user font size preferences

### Layout Considerations
- **Safe Areas**: Proper handling of notches and home indicators
- **Keyboard Avoidance**: Automatic view adjustment for input fields
- **Orientation**: Portrait-optimized with landscape support
- **Device Sizes**: Responsive design for all iPhone screen sizes