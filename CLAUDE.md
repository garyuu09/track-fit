# CLAUDE.md
必ず日本語で回答してください。
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrackFit is a SwiftUI-based iOS fitness tracking application (iOS 18.0+) that allows users to record workout sessions and sync them with Google Calendar. The app uses SwiftData for local persistence and follows MVVM architecture patterns.

## Development Commands

### Build and Run
- **Build**: Use Xcode's build system (⌘+B) or run from Xcode (⌘+R)
- **Test**: Use Xcode test runner (⌘+U) - uses Swift Testing framework, not XCTest

### Code Formatting
- **Automatic**: Swift-format runs automatically on each build via shell script
- **Manual**: `xcrun swift-format format --in-place --recursive TrackFit/`
- **Configuration**: Uses `.swift-format` with 100-character line length, 4-space indentation
- **重要**: ファイル修正後は必ずswift-formatでフォーマットを実行すること

### Linting and Quality
- Code formatting enforced via build phase script
- Strict Swift-format rules enabled (see `.swift-format` for details)

## Architecture

### MVVM Pattern
- **Models**: SwiftData-powered models (`DailyWorkout`, `WorkoutRecord`, `CalendarEvent`)
- **Views**: SwiftUI views organized by feature in `/Views/`
- **ViewModels**: `@MainActor` observable objects in `/ViewModels/`

### Key Directories
- `Models/` - SwiftData models with `@Model` decorators
- `Views/` - SwiftUI views organized by feature
- `ViewModels/` - Observable view models for state management  
- `Services/` - External API integration (GoogleCalendarAPI)
- `Utilities/` - Helper extensions and utility functions

### Data Persistence
- **SwiftData** for local storage with `@Query` property wrappers
- **UserDefaults** for app preferences and Google OAuth tokens
- **@AppStorage** property wrappers for user settings

## Dependencies

### Swift Package Manager Dependencies
- **GoogleSignIn-iOS** (v8.0.0+): OAuth2 authentication
- **GoogleSignInSwift**: SwiftUI Google Sign-In components

### Configuration Requirements
- **Secrets.xcconfig**: Contains Google OAuth client credentials
- **Bundle ID**: `com.ribereo.minami.TrackFit`
- **Development Team**: `HF42G63PQY` (Apple Developer account required)

## Google Calendar Integration

### OAuth Setup Required
1. Google Cloud Console project with Calendar API enabled
2. OAuth2 client configuration for iOS
3. Client ID and reverse client ID in `Secrets.xcconfig`

### Key Integration Points
- `GoogleCalendarAPI.swift` handles OAuth flow and API calls
- `CalendarViewModel` manages authentication state
- `GoogleCalendarIntegrationView` provides onboarding flow

## Testing

- **Framework**: Swift Testing (not XCTest)
- **Current Coverage**: Minimal - placeholder structure in place
- **Test Targets**: `TrackFitTests/` for unit tests, `TrackFitUITests/` for UI tests

## Navigation and UI Patterns

### SwiftUI Patterns
- `NavigationStack` for navigation
- `TabView` for main interface
- Sheet presentations for modal workflows
- `@State` and `@Binding` for local state management

### Theme Support
- Light/Dark/System theme options via `@AppStorage`
- Consistent color scheme throughout app

## Workflow Notes

- Feature-branch Git workflow with descriptive commits (English/Japanese)
- Automatic code signing enabled
- Modern iOS development practices with clean architecture
- Code follows Swift API Design Guidelines enforced by swift-format rules