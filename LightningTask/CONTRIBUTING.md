# Contributing to LightningTask

Thank you for your interest in contributing to LightningTask! This document provides guidelines and best practices for contributing.

## 🎯 Ways to Contribute

- **🐛 Bug Reports**: Found a bug? Open an issue with detailed steps to reproduce
- **💡 Feature Requests**: Have an idea? Share it via GitHub Issues
- **📝 Documentation**: Improve README, code comments, or add examples
- **🔧 Code Contributions**: Fix bugs or implement new features
- **🎨 Design Feedback**: Suggest UI/UX improvements

## 🚀 Getting Started

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/LightningTask.git
   cd LightningTask
   ```
3. **Create a branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```
4. **Make your changes**
5. **Test thoroughly**
6. **Commit with clear messages**:
   ```bash
   git commit -m "Add: Feature description"
   # or
   git commit -m "Fix: Bug description"
   ```
7. **Push and create a Pull Request**

## 📋 Code Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful names: `createReminder` not `create`
- Prefer clarity over brevity
- Use `// MARK: -` to organize code sections

### Architecture

```swift
// Good: Service handles business logic
class ReminderService {
    func createReminder(options: ReminderOptions) async throws { }
}

// Good: ViewModel coordinates
@Observable class ReminderViewModel {
    private let service = ReminderService()
    func save() async { await service.createReminder(...) }
}
```

### Concurrency

- **Always** use Swift Concurrency (async/await, actors)
- Avoid Dispatch and callbacks in new code
- Mark actor-isolated code appropriately

```swift
// Good ✅
actor AIService {
    func suggest() async throws -> TaskSuggestion { }
}

// Avoid ❌
class AIService {
    func suggest(completion: @escaping (TaskSuggestion) -> Void) { }
}
```

### Documentation

Use DocC-style documentation for public APIs:

```swift
/// Creates a new reminder with the specified options
/// 
/// - Parameter options: Configuration for the reminder
/// - Throws: `ReminderError` if creation fails
/// - Returns: The created reminder's identifier
func createReminder(options: ReminderOptions) async throws -> String {
    // implementation
}
```

### Error Handling

```swift
// Good: Specific errors
enum ReminderError: Error {
    case accessDenied
    case listNotFound(String)
    case saveFailed(underlying: Error)
}

// Good: Proper propagation
func save() async throws {
    do {
        try await service.save()
    } catch {
        print("❌ Save failed: \(error)")
        throw ReminderError.saveFailed(underlying: error)
    }
}
```

## 🧪 Testing

All contributions should include tests when applicable:

```swift
import Testing

@Suite("Reminder Creation")
struct ReminderCreationTests {
    
    @Test("Creates reminder with date")
    func createWithDate() async throws {
        let service = ReminderService()
        let options = ReminderOptions(
            text: "Test task",
            listName: "Inbox",
            dueDate: "2026-07-05",
            dueTime: ""
        )
        
        try await service.createReminder(options: options)
        // Verify reminder was created
    }
}
```

## 🏗️ Project Structure

When adding new features, follow the existing structure:

```
Features/
└── YourFeature/
    ├── ViewModels/
    │   └── YourFeatureViewModel.swift
    ├── Views/
    │   ├── YourFeatureView.swift
    │   └── Components/
    └── Models/
        └── YourFeatureModel.swift
```

## 📝 Pull Request Process

1. **Update documentation** if you're changing APIs
2. **Add tests** for new functionality
3. **Update README.md** if adding user-facing features
4. **Keep PRs focused**: One feature/fix per PR
5. **Write a clear PR description**:
   - What does this PR do?
   - Why is this change needed?
   - How has it been tested?
   - Screenshots (if UI changes)

### PR Title Format

```
Add: Quick entry keyboard shortcuts
Fix: Date parsing for relative dates
Refactor: Extract AI logic to service layer
Docs: Improve architecture documentation
```

## 🐛 Bug Reports

When filing a bug report, please include:

1. **Description**: What happened vs. what you expected
2. **Steps to reproduce**:
   1. Open LightningTask
   2. Type "..."
   3. Press Return
   4. Bug occurs
3. **Environment**:
   - macOS version
   - LightningTask version
   - Is Apple Intelligence enabled?
4. **Logs/Screenshots**: If applicable

## 💡 Feature Requests

For feature requests, please describe:

1. **Use case**: What problem does this solve?
2. **Proposed solution**: How should it work?
3. **Alternatives considered**: Other ways to solve this?
4. **Additional context**: Mockups, examples, etc.

## 🔒 Security Issues

**Do not** file public issues for security vulnerabilities. Instead, email:
[your-security-email@example.com]

## ⚖️ Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy toward others

## 📜 License

By contributing to LightningTask, you agree that your contributions will be licensed under the same license as the project.

## 🙏 Thank You!

Every contribution, no matter how small, helps make LightningTask better. We appreciate your time and effort!

---

**Questions?** Open a discussion on GitHub or reach out to the maintainers.
