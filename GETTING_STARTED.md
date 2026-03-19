# Getting Started - TimeTracker Development

**Last Updated:** March 19, 2026

This guide will help you get started with the TimeTracker development environment.

---

## ✅ Prerequisites

- **macOS 12+** with latest updates
- **Xcode 14+** (for iOS/macOS builds)
- **Flutter 3.9.2+** with Dart 3.5.2+
- **VS Code** with Flutter extension

---

## 🚀 Quick Start

### **1. Run the Application**

```bash
cd /Users/niravvariya/Documents/Projects/Desktop/com.project.tracker

# Get dependencies
flutter pub get

# Run in debug mode (macOS desktop)
flutter run -d macos
```

### **2. Project Structure**

The project follows **Clean Architecture** with 3 layers:

```
lib/
├── core/          → Shared utilities, themes, reusable widgets
├── data/          → Database, models, repository implementations
├── domain/        → Business logic entities, interfaces
└── presentation/  → UI screens, widgets, state management (Riverpod)
```

**Read:** [ARCHITECTURE.md](ARCHITECTURE.md) for detailed structure.

---

## 🎨 UI/Design System

### **Colors**
- **Dark Mode (Default):** Dark navy background (#0B111D)
- **Brand Color:** Blue (#007BFF)
- **Light Mode:** Available (toggle in app)

### **Typography**
- **Font:** Inter (Google Fonts)
- **Text Styles:** Defined in `core/theme/text_styles.dart`

### **Components**
All UI uses reusable components from `core/widgets/`:
- `AppButton` - All buttons
- `AppTextField` - Text inputs
- `AppCard` - Containers
- `AppIcon` - Icons
- `AppAvatar` - Avatars
- `CustomScaffold` - App layout

**Read:** [COMPONENT_LIBRARY.md](COMPONENT_LIBRARY.md) for details.

---

## 📦 Key Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| `flutter_riverpod` | State management | 2.6.1 |
| `drift` | SQLite ORM | 2.28.2 |
| `intl` | Date/time formatting | 0.19.0 |
| `uuid` | Unique ID generation | 4.0.0 |
| `csv` | CSV export | 6.0.0 |
| `google_fonts` | Inter font | 6.3.3 |

**No build_runner yet?** Run: `flutter pub run build_runner build`

---

## 🎯 Current Status - MVP Phase 1

### ✅ Completed
- Architecture design & documentation
- Folder structure setup
- Theme system (dark/light mode)
- Reusable component library
- Data models & entities
- Riverpod providers (placeholder)
- Dashboard screen UI (clickable prototype)
- AI-ready documentation

### ⏳ Next Steps (Phase 2)
1. **Project Detail + Timer Screen** - Build from HTML mockup
2. **Reports & Export Screen** - Build from HTML mockup
3. **Database Integration** - Drift ORM + SQLite
4. **Timer Logic** - Start/pause/stop functionality
5. **Background Tracking** - Continue timer when app minimized
6. **CSV Export** - Generate billing reports

---

## 🔧 Development Workflow

### **Running the App**
```bash
# Development mode (hot reload)
flutter run -d macos

# Profile mode (performance testing)
flutter run -d macos --profile

# Release mode (final build)
flutter run -d macos --release
```

### **Code Generation**
```bash
# After modifying Drift tables or Riverpod generators
flutter pub run build_runner build

# Watch mode (auto-rebuild on changes)
flutter pub run build_runner watch
```

### **Checking Errors**
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/

# Check for issues
flutter pub get --dry-run
```

---

## 📝 Project Files Orientation

### **Documentation Files**
- [ARCHITECTURE.md](ARCHITECTURE.md) - Complete architecture detail
- [AI_README.md](AI_README.md) - AI assistant guideline
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Database design (to be created)
- [COMPONENT_LIBRARY.md](COMPONENT_LIBRARY.md) - Component reference (to be created)

### **Configuration Files**
- `pubspec.yaml` - Dependencies and metadata
- `analysis_options.yaml` - Linter rules
- `build.yaml` - Build configuration (for Drift)

### **Key Directories**
- `lib/core/` - Theme, colors, utilities, base widgets
- `lib/presentation/` - Screens and current UI
- `lib/domain/entities/` - Business logic models
- `lib/services/` - Business services (timer, export, etc.)

---

## 💡 Common Tasks

### **Add a New Screen**
1. Create file: `lib/presentation/screens/my_screen.dart`
2. Extend `ConsumerStatefulWidget`
3. Create provider (if needed): `lib/presentation/providers/my_provider.dart`
4. Use core widgets for UI components
5. Read [ARCHITECTURE.md](ARCHITECTURE.md) section "Adding New Feature"

### **Add a New Reusable Widget**
1. Create file: `lib/core/widgets/my_widget.dart`
2. Make it 100% reusable (no business logic)
3. Use theme colors & text styles
4. Export from `lib/core/widgets/` imports

### **Modify Colors/Themes**
1. Edit: `lib/core/constants/colors.dart`
2. Edit: `lib/core/theme/app_theme.dart`
3. All changes propagate automatically

### **Add Database Table**
1. Create: `lib/data/database/tables/my_table.dart`
2. Add to `AppDatabase` class
3. Run: `flutter pub run build_runner build`
4. Create repository in: `lib/data/repositories/`

---

## 🚨 Important Notes

### **Style Guide**
- ✅ Always use `AppColors`, `AppTextStyles`, `AppConstants`
- ✅ Use core widgets from `lib/core/widgets/`
- ✅ Keep layer separation strict (no cross-layer imports)
- ✅ Use Riverpod for all state management

### **Formatting**
```bash
# Auto-format all code
dart format lib/

# Format single file
dart format lib/core/theme/app_theme.dart
```

### **Testing**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/formatters_test.dart
```

---

## 🔗 Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Drift Documentation](https://drift.simonbinder.eu)
- [Clean Architecture](https://resocoder.com/clean-architecture-tdd)

---

## 📞 Support

For architecture questions, feature additions, or debugging:
1. Check [AI_README.md](AI_README.md) for patterns
2. Refer to [ARCHITECTURE.md](ARCHITECTURE.md) for layer rules
3. Look at existing code in similar screens/widgets

---

## 🎉 Next Steps

1. **Run the app:** `flutter run -d macos`
2. **Explore the dashboard screen** to see the clickable prototype
3. **Read [AI_README.md](AI_README.md)** to understand how to add features
4. **Build project detail screen** from the HTML mockup
5. **Integrate database** with Drift ORM

Happy coding! 🚀
