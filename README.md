# ⚡ LightningTask

**Quick-entry macOS app for Reminders with AI-powered suggestions**

LightningTask provides a floating panel accessible via global hotkey (⌃Space) to quickly create reminders. Powered by Foundation Models (Apple Intelligence), it automatically suggests the best reminder list, extracts dates/times, and handles multiple tasks at once.

## ✨ Features

- **🎯 Global Hotkey Access**: Press ⌃Space from anywhere to open the quick-entry panel
- **🤖 AI-Powered Suggestions**: Automatically categorizes tasks and extracts due dates/times
- **📋 Smart List Detection**: Recognizes list names in your input ("Add milk to Shopping List")
- **⏰ Date & Time Parsing**: Understands natural language ("tomorrow at 9am", "Friday afternoon")
- **🔔 Optional Reminders**: Toggle notification alarms on/off
- **✅ Multiple Tasks**: Create several reminders at once ("Buy milk, eggs, and bread")
- **🎨 Native macOS Design**: Uses system materials and follows platform conventions

## 🏗️ Architecture

LightningTask follows a clean, modular architecture:

```
LightningTask/
├── App/                          # App entry point
├── Core/
│   ├── Models/                   # Data models (TaskSuggestion)
│   ├── Services/                 # Business logic layer
│   │   ├── ReminderService.swift # EventKit integration
│   │   └── AIService.swift       # Foundation Models integration
│   └── Extensions/               # Utility extensions
├── Features/
│   └── QuickEntry/               # Main feature
│       ├── ViewModels/           # ReminderViewModel
│       ├── Views/                # SwiftUI views
│       └── Controllers/          # NSPanel management
└── Tests/
```

### Key Components

#### **Services Layer**
- **`ReminderService`**: Handles all EventKit operations (authorization, list management, reminder creation)
- **`AIService`**: Generates task suggestions using Foundation Models with structured output

#### **ViewModel**
- **`ReminderViewModel`**: Coordinates between UI, services, and manages form state
- Observes user input and triggers debounced AI suggestions
- Handles saving reminders and state resets

#### **Views**
- **`LightningTaskPanelView`**: Main SwiftUI interface with text field and suggestion chips
- **`ChipView`**: Reusable chip component for lists and dates
- **`AlarmButton`**: Toggle for notification alarms

#### **Utilities**
- **`StringUtilities.swift`**: Token matching, Levenshtein distance, list name detection

## 🛠️ Technologies

- **Swift 6.2** & **SwiftUI**
- **EventKit** for Reminders integration
- **Foundation Models** (Apple Intelligence) for AI suggestions
- **AppKit** for global hotkey and floating panel
- **Sparkle** for automatic updates

## 🚀 Getting Started

### Prerequisites

- macOS 15.0 Sequoia or later
- Xcode 16.0 or later
- Apple Intelligence enabled (for AI features)

### Building

1. Clone the repository:
```bash
git clone https://github.com/yourusername/LightningTask.git
cd LightningTask
```

2. Open `LightningTask.xcodeproj` in Xcode

3. Build and run (⌘R)

### First Launch

1. Grant Reminders access when prompted
2. The app runs in the menu bar (⚡ icon)
3. Press ⌃Space to open the quick-entry panel
4. Right-click the menu bar icon for settings

## 📖 Usage

### Basic Usage

1. Press **⌃Space** to open LightningTask
2. Type your task: "Buy groceries tomorrow at 5pm"
3. LightningTask suggests:
   - List: "Shopping" (or similar)
   - Date: Tomorrow at 17:00
   - Creates alarm by default
4. Press **Return** to save and close
5. Press **⌘Return** to save and create another task

### Advanced Features

- **Multiple tasks**: "Buy milk, eggs, and bread" → creates 3 separate reminders
- **Explicit list**: "Meeting in Work tomorrow" → forces "Work" list
- **Date-only**: "Call mom Friday" → creates reminder on Friday without specific time
- **Time-only**: "Meeting at 3pm" → creates reminder today at 15:00

## 🧪 Testing

```bash
# Run unit tests
xcodebuild test -scheme LightningTask

# Or in Xcode
⌘U
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines

1. Follow Swift API Design Guidelines
2. Keep services focused and single-responsibility
3. Add tests for new features
4. Document public APIs with DocC-style comments
5. Use structured concurrency (async/await) over legacy patterns

## 📄 License

[Your chosen license, e.g., MIT]

## 🙏 Acknowledgments

- Built with Swift and SwiftUI
- Powered by Apple Intelligence (Foundation Models)
- Uses [Sparkle](https://sparkle-project.org/) for updates

### HotKey Implementation

This project includes a **vendored copy** of [HotKey by Sam Soffes](https://github.com/soffes/HotKey) instead of using it as an SPM dependency.

**Reasons for vendoring:**
1. **Minimal dependencies**: HotKey is a small, stable library (~200 LOC) that rarely changes
2. **Build reliability**: Eliminates external dependency resolution issues
3. **Customization**: Allows project-specific modifications if needed (e.g., added `isPaused` property)
4. **No maintenance burden**: The library is feature-complete and doesn't require frequent updates
5. **Reduced build complexity**: One less external dependency to manage in CI/CD

The vendored version includes the core HotKey functionality with our modifications:
- Added `isPaused` property for temporarily disabling hotkeys
- Maintained compatibility with modern Swift and macOS versions

**Credit**: Original HotKey library by [Sam Soffes](https://github.com/soffes), MIT License

## 📮 Contact

[Your contact information or links]

---

**Note**: Apple Intelligence features require macOS 15.0 Sequoia or later and may not be available in all regions.
