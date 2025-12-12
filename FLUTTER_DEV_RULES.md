# Flutter Development Master Rules

## Project Context
This file contains the master rules and best practices for Flutter development. Reference this file instead of repeating instructions. All agents must follow these standards.

---

## 1. UI/UX Frontend Agent Rules

### Core UX Principles
- **Usability**: Create intuitive, easy-to-use interfaces
- **Accessibility (a11y)**: Use Semantics widgets, semantic labels, screen reader support, sufficient touch targets
- **User-Centered Design**: Focus on user needs with clear information architecture
- **Minimize Cognitive Load**: Reduce mental effort required to use the interface

### Design Systems & Patterns
- Implement design systems with reusable widget libraries
- Follow atomic design - compose interfaces from small, reusable pieces
- Use Flutter's composition model for scalable components
- Apply established design patterns for common UI problems

### Visual Design Standards
- **Visual Hierarchy**: Use sized boxes, padding, colors and typography from Theme
- **Spacing**: Leverage SizedBox and Padding for readability and breathing room
- **Consistency**: Use ThemeData for colors, TextTheme for typography
- **Typography**: 16sp+ body text, 1.5-1.6 line height, limited font families
- **Color Contrast**: Ensure 4.5:1 minimum contrast ratios for text

### Interaction Design
- **Affordances**: Clear visual cues for interactive elements (InkWell ripples, button states)
- **Feedback**: Immediate response with CircularProgressIndicator, SnackBars, animations
- **Microinteractions**: Use AnimatedContainer and Hero widgets for smooth transitions
- **Touch Targets**: Minimum 48x48dp (Material Design standard)
- Support both tap and keyboard interactions

### Nielsen's 10 Usability Heuristics
1. Visibility of system status - keep users informed with clear feedback
2. Match between system and real world - use familiar language and concepts
3. User control and freedom - provide Navigator.pop, swipe gestures, undo actions
4. Consistency and standards - follow Material or Cupertino design guidelines
5. Error prevention - design to prevent errors before they occur
6. Recognition over recall - make options visible, don't rely on memory
7. Flexibility and efficiency - provide shortcuts for power users
8. Aesthetic and minimalist design - remove unnecessary elements
9. Help users with errors - clear error messages with solutions
10. Help and documentation - provide when needed, easy to access

### Responsive Design
- Implement responsive design using MediaQuery, LayoutBuilder
- Use adaptive widgets for different screen sizes and orientations
- Test on multiple device sizes and form factors
- Consider tablet and desktop layouts where appropriate

### Implementation Standards
- Write clean widget trees with proper const constructors
- Use Material or Cupertino widgets appropriately for platform
- Follow Flutter best practices with proper state management
- Optimize performance with const widgets and RepaintBoundary

---

## 2. Backend & Logic Architecture Rules

### Clean Architecture
- Implement clear separation of concerns: presentation, domain, business logic, data layers
- Use appropriate state management (Provider, Riverpod, Bloc, GetX) based on complexity
- Follow SOLID principles and design patterns (Repository, Factory, Singleton, Observer, Strategy)
- Use dependency injection for loose coupling and testability

### Data Layer Design
- Implement repository pattern to abstract data sources
- Handle errors robustly with proper error handling
- Create service classes for business logic separated from UI
- Use sealed classes or enums for network states (loading, success, error, empty)

### API Integration
- Use Dio or http package with interceptors for auth, logging, error handling
- Implement retry logic and offline support with caching strategies
- Handle network states gracefully
- Implement proper timeout and error recovery

### Local Storage
- SharedPreferences for simple key-value pairs
- Hive or Isar for complex data structures
- SQLite for relational data requirements
- secure_storage for sensitive data (tokens, credentials)
- Implement proper data serialization with json_serializable or freezed
- Handle data migrations and versioning

### Reactive Programming
- Use Streams and StreamControllers appropriately
- Implement proper async/await patterns, avoid callback hell
- Handle Future and Stream error cases
- Use FutureBuilder and StreamBuilder when appropriate or prefer state management alternatives

### Project Structure
- Use features-first or layers-first folder structure
- Create reusable business logic classes and mixins
- Implement proper logging with logger package
- Use environment configurations for build flavors (dev, staging, production)

### Type Safety & Validation
- Ensure strong typing throughout the codebase
- Full null safety compliance
- Use sealed classes or freezed for immutable data models
- Implement validation logic (form validation, business rules)
- Handle edge cases and error states comprehensively

### Testing Requirements
- Write testable code with unit tests for business logic
- Integration tests for data layer
- Widget tests for UI logic
- Use mocking libraries (mockito, mocktail)
- Aim for high test coverage on critical paths (80%+)

### Security Best Practices
- Secure API keys using environment variables and obfuscation
- Validate and sanitize user inputs
- Implement proper authentication flows (JWT, OAuth)
- Use certificate pinning for sensitive applications
- Encrypt sensitive local data

### Performance Optimization
- Avoid unnecessary rebuilds with const constructors
- Implement pagination for large datasets
- Use isolates for heavy computations
- Profile and optimize based on DevTools insights
- Lazy load resources when possible

---

## 3. Debugging & Testing Agent Rules

### Version Compliance
- **ALWAYS use latest stable Flutter and Dart versions**
- Check Flutter and Dart changelogs regularly
- Run `flutter upgrade` to stay current
- Run `flutter doctor` to ensure environment is up-to-date

### Deprecated API Management
- Use `flutter analyze` to detect deprecated warnings
- Proactively migrate deprecated APIs to modern replacements:
  - RaisedButton → ElevatedButton
  - FlatButton → TextButton
  - Scaffold.of → ScaffoldMessenger
  - WillPopScope → PopScope
  - FutureBuilder → Consider modern state management
- Update package dependencies to latest compatible versions
- Follow migration guides for breaking changes
- Refactor outdated patterns to current best practices

### Stay Current with Latest Features
- Use latest null safety patterns
- Leverage new Dart 3+ features (records, patterns, sealed classes)
- Adopt new widgets and APIs from recent releases
- Implement modern navigation (GoRouter when appropriate)
- Use Material 3 theming and components
- Apply updated performance optimizations

### Debugging Tools & Techniques
- **Flutter DevTools**: widget inspector, performance profiler, memory profiler, network inspector, logging view
- Analyze widget rebuilds and render issues
- Identify performance bottlenecks with timeline traces
- Detect memory leaks using heap snapshots
- Set breakpoints and step through code in IDE
- Use debugPrint and developer.log for runtime logging
- Leverage assert statements for development checks
- Use debugFillProperties for custom widget debugging
- Implement custom error handlers with FlutterError.onError

### Common Flutter Issues
- Layout overflow errors (use Flexible, Expanded, SingleChildScrollView)
- setState called during build (use addPostFrameCallback or SchedulerBinding)
- Null safety violations
- Async errors and race conditions
- Navigation stack issues
- State management bugs (lost state, stale data, unnecessary rebuilds)
- Deprecated API usage warnings

### Testing Strategy
- **Unit Tests**: business logic and utilities (test package, mockito/mocktail)
- **Widget Tests**: UI components and user interactions (testWidgets, find, expect, pump/pumpAndSettle)
- **Integration Tests**: complete user flows (integration_test package)
- **Minimum 80% code coverage** on critical paths

### Testing Best Practices
- Write descriptive test names (given-when-then pattern)
- Use arrange-act-assert structure
- Avoid test interdependencies
- Use test fixtures and setUp/tearDown properly
- Mock external dependencies and isolate units under test
- Use golden tests for visual regression testing
- Ensure tests pass on latest Flutter stable

### Edge Case Testing
- Null and empty states
- Network failures and timeouts
- Permission denials
- Low memory scenarios
- Different screen sizes and orientations
- Platform-specific behaviors (iOS vs Android)
- Slow devices and old OS versions
- Interrupted user flows (app backgrounding, phone calls)
- Compatibility with latest OS versions

### Error Handling Validation
- Try-catch blocks with specific exception types
- Graceful degradation with fallback UI
- User-friendly error messages
- Proper error logging for production debugging
- Crash reporting integration (Firebase Crashlytics, Sentry)

### Performance Profiling
- Identify expensive widgets with DevTools rebuild stats
- Optimize build methods to be pure functions
- Reduce widget tree depth
- Use const constructors aggressively
- Profile app startup time and optimize initialization
- Analyze bundle size and reduce dependencies
- Leverage latest performance improvements in Flutter engine

### Platform-Specific Debugging
- Use platform channels correctly with latest methodChannel patterns
- Handle iOS and Android lifecycle differences
- Test on physical devices with latest OS versions
- Use Xcode and Android Studio native debuggers for platform code
- Analyze native crash logs
- Ensure compatibility with latest platform requirements

### Dependency Management
- Run `flutter pub upgrade` regularly
- Resolve package version conflicts
- Identify packages using deprecated APIs
- Migrate to actively maintained alternatives when packages are abandoned
- Ensure all dependencies support latest Flutter/Dart versions
- Use dependency_validator to check for issues

### CI/CD Integration
- Automate test runs with latest Flutter version
- Enforce test coverage thresholds
- Run tests on multiple device configurations
- Integrate static analysis (flutter analyze, dart analyze)
- Prevent regressions with automated test suites
- Validate package compatibility

---

## 4. General Development Standards

### Code Quality
- Write clean, self-documenting code with meaningful variable names
- Add comments for complex business logic only
- Use linting rules (flutter_lints, very_good_analysis)
- Follow effective Dart style guide
- Keep functions small and focused (single responsibility)
- Avoid deep nesting (max 3-4 levels)

### Git & Version Control
- Write clear, descriptive commit messages
- Use feature branches for new development
- Keep commits atomic and focused
- Review code before merging

### Documentation
- Document complex business logic and architectural decisions
- Keep README.md updated with setup instructions
- Document API endpoints and data models
- Maintain changelog for significant changes

### Performance Guidelines
- Avoid expensive operations in build methods
- Dispose controllers, subscriptions, and streams properly
- Use ListView.builder for large lists
- Implement proper pagination
- Optimize images and assets
- Use lazy loading where appropriate

### Error Philosophy
- Fail fast and fail loudly in development
- Handle errors gracefully in production
- Log errors with sufficient context for debugging
- Never swallow exceptions silently
- Provide actionable error messages to users

---

## 5. Token Usage Optimization Rules

### For All Agents
- Reference this file instead of repeating instructions
- Only include context absolutely necessary for the specific task
- Avoid restating rules that are already in this document
- Focus responses on the specific problem at hand
- Use concise language and avoid redundant explanations

### When to Reference This File
- Any UI/UX implementation → Section 1
- Any backend/logic work → Section 2
- Any debugging/testing → Section 3
- Any general development → Section 4

### Communication Protocol
- State which section(s) of this file apply to current task
- Only elaborate on rules if clarification is needed
- Assume all agents have read and understood this file

---

## Version History
- v1.0 - Initial master rules document
- Created: November 2024
- Last Updated: November 2024

---

## Notes
- This is a living document - update as Flutter and best practices evolve
- All agents must comply with these rules unless explicitly overridden
- When rules conflict, prioritize: 1) Latest Flutter/Dart standards, 2) User requirements, 3) Performance, 4) Code quality
