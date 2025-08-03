# Technology Stack

## Platform & Requirements
- **Platform**: iOS native development
- **Minimum Version**: iOS 17.0+
- **Target Devices**: iPhone全系列 (All iPhone series)
- **Architecture**: MVVM (Model-View-ViewModel) with SwiftUI

## Core Technologies

### Frontend
- **SwiftUI**: Declarative UI framework for all user interfaces
- **Combine**: Reactive programming for data binding and state management
- **Swift Concurrency**: async/await for AI API calls and data operations

### Data & Persistence
- **SwiftData**: Primary data persistence layer (iOS 17+ native ORM)
- **ModelContainer & ModelContext**: SwiftData configuration for data management
- **Local Storage**: All data stored locally on device with encryption support
- **Future**: iCloud sync support planned for v2.0+

### AI Integration
- **Deepseek-R1 API**: AI task breakdown and planning generation
- **HTTP Client**: URLSession-based API client with retry mechanisms
- **JSON Parsing**: Codable protocol for API response handling

### Architecture Patterns
- **Repository Pattern**: Data access abstraction layer
- **Dependency Injection**: Service management and testability
- **ObservableObject**: SwiftUI state management
- **Environment Objects**: Global state sharing across views

## Key Services & Managers

### Core Business Logic
- `AppStateManager`: Global application state and branch switching
- `BranchManager`: Branch lifecycle management (create, merge, abandon)
- `TaskPlanService`: AI integration for task plan generation
- `CommitManager`: Progress tracking and commit management

### Data Layer
- `BranchRepository`: Branch CRUD operations
- `TaskPlanRepository`: Task plan persistence
- `CommitRepository`: Commit history management

## Common Commands

### Development Setup
```bash
# Open project in Xcode
open LifeGit.xcodeproj

# Build for simulator
xcodebuild -project LifeGit.xcodeproj -scheme LifeGit -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -project LifeGit.xcodeproj -scheme LifeGit -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Generation & Tools
```bash
# Generate SwiftData models (if using code generation)
swiftgen config run

# Format code
swiftformat .

# Lint code
swiftlint
```

## Performance Requirements
- **App Launch**: < 2 seconds startup time
- **UI Response**: < 1 second for user interactions
- **AI Response**: < 10 seconds for task plan generation
- **Branch Switching**: < 2 seconds transition time

## API Configuration
- **Deepseek-R1 Endpoint**: `https://api.deepseek.com/v1/chat/completions`
- **Model**: `deepseek-r1`
- **Max Tokens**: 2000 for task plan generation
- **Temperature**: 0.7 for balanced creativity/consistency

## Data Models Structure
```swift
// Core entities
@Model class User
@Model class Branch  
@Model class Commit
@Model class TaskPlan
@Model class TaskItem

// Enums
enum BranchStatus: active, completed, abandoned
enum CommitType: taskComplete, learning, reflection, milestone  
enum TaskTimeScope: daily, weekly, monthly
```

## Build Configuration
- **Debug**: Local development with verbose logging
- **Release**: Production build with optimizations
- **Derived Data**: Custom path for build artifacts
- **Code Signing**: Automatic signing for development