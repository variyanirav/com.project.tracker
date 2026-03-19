# AI-Ready Documentation for TimeTracker

**Purpose:** This document provides complete context for AI assistants to understand the project structure, architecture, and patterns used in TimeTracker, enabling seamless feature additions and modifications.

**Last Updated:** March 19, 2026  
**Project Version:** 0.1.0

---

## 📐 Project Structure Overview

```
lib/
├── core/                 # Shared utilities, themes, widgets
│   ├── constants/        # App-wide constants (colors, sizes, values)
│   ├── theme/            # Theme definitions and text styles
│   ├── utils/            # Formatters, validators, extensions
│   └── widgets/          # Reusable UI components
├── data/                 # Data layer (repositories, models, database)
│   ├── datasources/      # Database operations
│   ├── models/           # Data models with JSON serialization
│   ├── repositories/     # Repository implementations
│   └── database/         # SQLite setup and migrations
├── domain/               # Business logic layer (entities, use cases)
│   ├── entities/         # Pure Dart models (no framework dependency)
│   ├── repositories/     # Abstract repository interfaces
│   └── usecases/         # Business logic operations
├── presentation/         # UI layer (screens, widgets, providers)
│   ├── providers/        # Riverpod state management
│   ├── screens/          # Full-page widgets
│   ├── widgets/          # Screen-specific components
│   └── routes/           # Navigation configuration
├── services/             # Business services (timer, export, notifications)
├── main.dart             # App entry point
└── app.dart              # Root app configuration
```

---

## 🏗️ Architecture Layers

### **1. Presentation Layer** (`presentation/`)
- **Responsibility:** Handle UI rendering and user interaction
- **Key Files:** Screens, Widgets, Providers
- **Pattern:** MVVM with Riverpod for state
- **Rules:**
  - Screens should not contain business logic
  - All data fetching via Riverpod providers
  - Use widgets from `core/widgets/` for consistency
  - Theme colors from `AppColors` and `AppTextStyles`

**Example: Adding a new screen**
```dart
// 1. Create screen in presentation/screens/
class MyNewScreen extends ConsumerStatefulWidget { ... }

// 2. Create Riverpod providers in presentation/providers/
final myDataProvider = FutureProvider<MyData>((ref) async { ... });

// 3. Build UI using core widgets
AppButton, AppCard, AppTextField, etc.
```

### **2. Domain Layer** (`domain/`)
- **Responsibility:** Define business logic contracts and entities
- **Key Files:** Entities, Repository Interfaces, Use Cases
- **Pattern:** Clean Architecture with Repository Pattern
- **Rules:**
  - Entities are pure Dart classes (immutable)
  - Repositories are abstract (interfaces only)
  - No Flutter imports in this layer
  - Use Cases encapsulate business operations

**Example: Adding new business logic**
```dart
// 1. Create entity: domain/entities/my_entity.dart
class MyEntity { final String id; final String name; }

// 2. Create interface: domain/repositories/imy_repository.dart
abstract class IMyRepository { Future<List<MyEntity>> getAll(); }

// 3. Implement in data layer: data/repositories/my_repository.dart
class MyRepository implements IMyRepository { ... }
```

### **3. Data Layer** (`data/`)
- **Responsibility:** Handle data persistence and network operations
- **Key Files:** Models, Database, Repository Implementations
- **Pattern:** Repository with SQLite
- **Rules:**
  - Models include JSON serialization
  - Database operations use Drift ORM
  - All queries prepared and type-safe
  - Repository converts models ↔ entities

**Example: Adding database table**
```dart
// 1. Define in database/tables/
class MyTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// 2. Add to AppDatabase class
@DataClassName('MyModel')
class MyTable extends Table { ... }

// 3. Run migrations
flutter pub run build_runner build

// 4. Use in repository
final items = await _db.select(_db.myTable).get();
```

---

## 🎯 Key Patterns & Conventions

### **Naming Conventions**
- **Screens:** `MyFeatureScreen` (extends ConsumerStatefulWidget)
- **Widgets:** `MyWidget` (reusable components)
- **Providers:** `myDataProvider` (lowercase with Provider suffix)
- **Entities:** `MyEntity`
- **Models:** `MyModel`
- **Repositories:** `MyRepository`
- **Tables:** `my_table` (snake_case in DB)

### **File Naming**
- Snake_case for all Dart files
- Match class name to filename
- One class per file (except related models)

### **Import Organization**
```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Relative imports
import '../../core/constants/colors.dart';
```

---

## 🔌 Riverpod State Management

### **Provider Types Used**

#### **StateProvider** - Mutable state
```dart
final myStateProvider = StateProvider<int>((ref) => 0);

// Usage
ref.watch(myStateProvider);           // Watch
ref.read(myStateProvider.notifier).state = 5; // Update
```

#### **FutureProvider** - Async data fetching
```dart
final myDataProvider = FutureProvider<Data>((ref) async {
  return await repository.fetchData();
});

// Usage
final state = ref.watch(myDataProvider);
if (state.when(
  data: (data) => show(data),
  loading: () => showLoader(),
  error: (err, stack) => showError(err),
))
```

#### **Provider** - Computed/derived state
```dart
final derivedProvider = Provider<String>((ref) {
  final count = ref.watch(countProvider);
  return 'Count is: $count';
});
```

### **Adding New Provider**
1. Create in `presentation/providers/`
2. Name: `[feature]_provider.dart`
3. Follow StateProvider/FutureProvider patterns
4. Inject dependencies via `ref`

---

## 🎨 UI Component System

### **Reusable Core Widgets** (`core/widgets/`)

| Component | Use Case | Props |
|-----------|----------|-------|
| `AppButton` | All buttons | label, variant (primary/secondary/danger/ghost), onPressed |
| `AppTextField` | Text inputs | label, validator, controller, keyboardType |
| `AppCard` | Containers | child, padding, onTap, backgroundColor |
| `AppIcon` | Icon display | icon, size, color, onTap |
| `AppAvatar` | User/project avatar | initials, image, backgroundColor |
| `CustomScaffold` | App layout | navItems, selectedIndex, child, trailing |

### **Using Components**
```dart
// Always use AppButton instead of ElevatedButton
AppButton(
  label: 'Click me',
  onPressed: () => print('Clicked'),
  variant: ButtonVariant.primary,
)

// Always use AppTextField instead of TextField
AppTextField(
  label: 'Email',
  hintText: 'user@example.com',
  validator: Validators.email,
)

// Always use AppCard for containers
AppCard(
  padding: EdgeInsets.all(16),
  child: Column(...),
)
```

---

## 🎨 Theme & Styling

### **Color System**
```dart
// Dark theme (primary)
AppColors.darkBg         // #0B111D - Background
AppColors.darkSurface    // #151C2C - Cards/Surface
AppColors.darkCard       // #1F2937 - Card bg
AppColors.darkBorder     // #334155 - Borders

// Brand colors
AppColors.brandPrimary   // #007BFF - Main color
AppColors.error          // #EF4444 - Error state
AppColors.success        // #10B981 - Success state

// Text colors
AppColors.darkTextPrimary       // Primary text
AppColors.darkTextSecondary     // Secondary text
AppColors.darkTextTertiary      // Tertiary/muted text
```

### **Text Styles**
```dart
AppTextStyles.heading1        // 32px, bold
AppTextStyles.heading2        // 28px, bold
AppTextStyles.titlesMedium    // 18px, semibold
AppTextStyles.bodyMedium      // 16px, regular
AppTextStyles.labelSmall      // 12px, semibold
AppTextStyles.timerDisplay   // 64px monospace (for timer)
```

### **Spacing System**
All spacing uses 4px grid:
```dart
AppConstants.spacing4    // 4px
AppConstants.spacing8    // 8px
AppConstants.spacing16   // 16px
AppConstants.spacing24   // 24px
AppConstants.spacing32   // 32px

// Examples
SizedBox(height: AppConstants.spacing16)
Padding(padding: EdgeInsets.all(AppConstants.spacing12), child: ...)
```

---

## 📊 Database Schema

### **Core Tables**

#### **projects**
```sql
id (TEXT PK), name (TEXT), description (TEXT), color (TEXT),
status (TEXT), created_at (INT), updated_at (INT)
```

#### **tasks**
```sql
id (TEXT PK), project_id (TEXT FK), task_name (TEXT),
description (TEXT), status (TEXT), total_seconds (INT),
is_running (BOOL), last_started_at (INT), last_session_id (TEXT),
created_at (INT), updated_at (INT)
```

#### **timer_sessions**
```sql
id (TEXT PK), task_id (TEXT FK), project_id (TEXT FK),
start_time (INT), pause_time (INT), resume_time (INT),
end_time (INT), total_seconds (INT), is_completed (BOOL),
session_date (TEXT), created_at (INT)
```

### **Adding New Table**
1. Create Drift table class: `data/database/tables/my_table.dart`
2. Add to `AppDatabase`: `data/database/app_database.dart`
3. Run: `flutter pub run build_runner build`
4. Create migration if needed
5. Use in repository via `_database.myTable`

---

## 🔄 Adding a New Feature

### **Step-by-Step Example: Adding "Project Categories"**

#### **1. Domain Layer**
```dart
// domain/entities/category_entity.dart
class CategoryEntity {
  final String id;
  final String name;
}

// domain/repositories/icategory_repository.dart
abstract class ICategoryRepository {
  Future<List<CategoryEntity>> getAll();
  Future<CategoryEntity> create(String name);
}
```

#### **2. Data Layer**
```dart
// data/database/tables/categories_table.dart
class CategoriesTable extends Table {
  TextColumn get id => text().primaryKey()();
  TextColumn get name => text()();
}

// data/repositories/category_repository.dart
class CategoryRepository implements ICategoryRepository {
  // Implementation using database
}
```

#### **3. Presentation Layer**
```dart
// presentation/providers/category_provider.dart
final categoriesProvider = FutureProvider((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

// presentation/screens/categories_screen.dart
class CategoriesScreen extends ConsumerWidget {
  // Implement UI using providers
}
```

#### **4. Test & Deploy**
- Run tests
- Check build: `flutter pub get && flutter build macos`
- Verify: `flutter run`

---

## 📦 Dependencies

### **Key Packages**
```yaml
flutter_riverpod: 2.4.0      # State management (watch instead of BLoC)
drift: 2.16.0                # SQLite ORM with migrations
intl: 0.19.0                 # Date/time formatting
uuid: 4.0.0                  # Generate unique IDs
csv: 6.0.0                   # CSV export
path_provider: 2.1.0        # App cache/documents directories
google_fonts: 6.1.0         # Inter font family
```

### **Adding New Package**
1. `flutter pub add package_name`
2. Run: `flutter pub get`
3. If it requires code generation: `flutter pub run build_runner build`
4. Import and use

---

## 🧪 Testing Guidelines

### **Unit Tests**
- Test entities, formatters, validators
- Located in `test/unit/`
- Use `test` package

### **Widget Tests**
- Test individual widgets
- Located in `test/widget/`
- Use `flutter_test`

### **Integration Tests**
- Test full user flows
- Located in `integration_test/`

**Example:**
```dart
void main() {
  test('TimeFormatter.secondsToTime', () {
    expect(TimeFormatter.secondsToTime(3661), '01:01:01');
  });
}
```

---

## 🚀 Common Tasks for AI

### **To Add a New Screen:**
1. Create file: `presentation/screens/my_screen.dart`
2. Create provider (if needed): `presentation/providers/my_provider.dart`
3. Create screen-specific widgets in: `presentation/widgets/my_feature/`
4. Use core widgets for reusable components
5. Follow MVVM pattern (UI calls providers, not repo directly)

### **To Modify Database Schema:**
1. Create/update table in: `data/database/tables/`
2. Add to `AppDatabase` class
3. Run: `flutter pub run build_runner build`
4. Update repository
5. Update Riverpod providers

### **To Add New Business Logic:**
1. Create entity: `domain/entities/my_entity.dart`
2. Create interface: `domain/repositories/imy_repository.dart`
3. Implement in data layer: `data/repositories/my_repository.dart`
4. Create provider: `presentation/providers/my_provider.dart`
5. Use in screens via `ref.watch()`

### **To Add New UI Component:**
1. Create in: `core/widgets/my_widget.dart`
2. Make 100% reusable (no business logic)
3. Use theme colors and text styles
4. Document with comments
5. Use in other screens consistently

---

## ⚠️ Important Rules

### **DO:**
- ✅ Use `AppColors`, `AppTextStyles`, `AppConstants` for everything
- ✅ Use Riverpod providers for all state
- ✅ Keep entities immutable
- ✅ Use validators for form inputs
- ✅ Follow naming conventions
- ✅ Keep layers separated
- ✅ Use core widgets for UI

### **DON'T:**
- ❌ Don't hardcode colors or sizes
- ❌ Don't use StatefulWidget in presentation layer (use Consumer)
- ❌ Don't put business logic in widgets
- ❌ Don't import directly to data layer from presentation
- ❌ Don't create tight coupling
- ❌ Don't use multiple state management tools
- ❌ Don't create duplicate widgets

---

## 📝 File Templates

### **New Screen Template**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNewScreen extends ConsumerStatefulWidget {
  const MyNewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends ConsumerState<MyNewScreen> {
  @override
  Widget build(BuildContext context) {
    // Implementation
    return Scaffold(
      body: Center(child: Text('MyNewScreen')),
    );
  }
}
```

### **New Provider Template**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myNewProvider = FutureProvider<MyData>((ref) async {
  // Fetch or compute data
  return MyData();
});
```

### **New Widget Template**
```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/text_styles.dart';

class MyNewWidget extends StatelessWidget {
  final String title;

  const MyNewWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Implementation
    );
  }
}
```

---

## 🔗 Quick Reference

| Need | Location | File |
|------|----------|------|
| Add color | `core/constants/` | `colors.dart` |
| Add text style | `core/theme/` | `text_styles.dart` |
| Add constant | `core/constants/` | `app_constants.dart` |
| Add utility | `core/utils/` | `extensions.dart` |
| Add widget | `core/widgets/` | `app_*.dart` |
| Add screen | `presentation/screens/` | `*_screen.dart` |
| Add provider | `presentation/providers/` | `*_provider.dart` |
| Add entity | `domain/entities/` | `*_entity.dart` |
| Add model | `data/models/` | `*_model.dart` |
| Add table | `data/database/tables/` | `*_table.dart` |
| Add repo | `data/repositories/` | `*_repository.dart` |

---

**Last Note:** This project follows Clean Architecture + SOLID principles strictly. When adding features, always maintain layer separation and immutability. Ask if something is unclear!
