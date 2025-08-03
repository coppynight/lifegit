# Project Structure

## Repository Organization

```
LifeGit/
├── .kiro/
│   ├── specs/life-git-ios/          # Project specifications
│   │   ├── requirements.md          # Detailed requirements document
│   │   ├── design.md               # Technical design document
│   │   └── tasks.md                # Implementation task breakdown
│   └── steering/                   # AI assistant guidance rules
├── LifeGit.xcodeproj              # Xcode project file
├── LifeGit/                       # Main application source
│   ├── App/                       # Application entry point
│   ├── Models/                    # SwiftData models
│   ├── Views/                     # SwiftUI views
│   ├── ViewModels/               # Business logic layer
│   ├── Services/                 # External services (AI, networking)
│   ├── Repositories/             # Data access layer
│   ├── Utils/                    # Utility functions and extensions
│   └── Resources/                # Assets, localizations
├── LifeGitTests/                 # Unit tests
├── LifeGitUITests/              # UI tests
└── README.md                     # Project documentation
```

## Code Organization Principles

### MVVM Architecture Layers
- **Models** (`/Models/`): SwiftData entities and enums
- **Views** (`/Views/`): SwiftUI view components organized by feature
- **ViewModels** (`/ViewModels/`): ObservableObject classes for business logic
- **Services** (`/Services/`): External integrations and utilities

### Feature-Based Organization
```
Views/
├── Master/                       # Master branch related views
│   ├── MasterBranchView.swift
│   └── CommitTimelineView.swift
├── Branch/                       # Branch management views
│   ├── BranchListView.swift
│   ├── BranchDetailView.swift
│   └── BranchSwitcher.swift
├── TaskPlan/                     # Task planning views
│   ├── TaskPlanView.swift
│   ├── TaskItemRowView.swift
│   └── TaskPlanEditView.swift
├── Commit/                       # Commit related views
│   ├── CommitCreationView.swift
│   └── CommitHistoryView.swift
└── Common/                       # Reusable UI components
    ├── FilterChip.swift
    └── LoadingView.swift
```

### Data Layer Structure
```
Models/
├── Core/                         # Core business entities
│   ├── User.swift
│   ├── Branch.swift
│   ├── Commit.swift
│   ├── TaskPlan.swift
│   └── TaskItem.swift
├── Enums/                        # Type definitions
│   ├── BranchStatus.swift
│   ├── CommitType.swift
│   └── TaskTimeScope.swift
└── Extensions/                   # Model extensions
    └── Branch+Extensions.swift

Repositories/
├── Protocols/                    # Repository interfaces
│   ├── BranchRepository.swift
│   ├── TaskPlanRepository.swift
│   └── CommitRepository.swift
└── SwiftData/                    # SwiftData implementations
    ├── SwiftDataBranchRepository.swift
    ├── SwiftDataTaskPlanRepository.swift
    └── SwiftDataCommitRepository.swift
```

## Naming Conventions

### Files and Classes
- **Views**: Descriptive names ending with `View` (e.g., `BranchDetailView`)
- **ViewModels**: Feature name + `Manager` (e.g., `BranchManager`, `TaskPlanManager`)
- **Models**: Entity names (e.g., `Branch`, `TaskPlan`)
- **Services**: Purpose + `Service` (e.g., `TaskPlanService`, `AIAssistantService`)
- **Repositories**: Entity + `Repository` (e.g., `BranchRepository`)

### Variables and Functions
- **Properties**: camelCase descriptive names (e.g., `currentBranch`, `isShowingBranchList`)
- **Functions**: Verb-based names (e.g., `createBranch`, `mergeBranch`, `generateTaskPlan`)
- **Constants**: UPPER_SNAKE_CASE for global constants

### SwiftUI Specific
- **State Variables**: Prefix with purpose (e.g., `@State private var isEditing`)
- **Environment Objects**: Descriptive names (e.g., `@EnvironmentObject var appState`)
- **Published Properties**: Clear, observable names (e.g., `@Published var branches`)

## File Organization Rules

### Import Order
1. Foundation/UIKit imports
2. SwiftUI imports  
3. Third-party frameworks
4. Internal modules

### Code Structure Within Files
1. Type definition and properties
2. Initializers
3. Public methods
4. Private methods
5. Extensions (in separate files when substantial)

### MVP Implementation Priority
Focus development on these core directories first:
1. `/Models/Core/` - Essential data models
2. `/Services/` - AI integration and core services
3. `/ViewModels/` - Business logic managers
4. `/Views/Branch/` and `/Views/Master/` - Core UI components
5. `/Repositories/SwiftData/` - Data persistence

### Testing Structure
- **Unit Tests**: Mirror main source structure in `LifeGitTests/`
- **UI Tests**: Feature-based organization in `LifeGitUITests/`
- **Mock Objects**: Separate `/Mocks/` directory for test doubles

## Configuration Files
- **Info.plist**: App configuration and permissions
- **Config.xcconfig**: Build configuration settings
- **Localizable.strings**: Internationalization (Chinese/English)
- **.gitignore**: Exclude build artifacts and sensitive files