# Design System Usage Guide

**Version**: 1.0  
**Last Updated**: March 18, 2026

This guide explains how to use the design system components and tokens in ProjectTracker. Follow these patterns across your entire application to maintain consistency and DRY principles.

---

## 📋 Quick Reference

### Colors
```swift
AppColors.primary        // Primary action blue
AppColors.success        // Green for success states
AppColors.warning        // Orange for warnings
AppColors.danger         // Red for destructive actions
AppColors.background     // Dark background
AppColors.surface        // Slightly lighter surface
AppColors.border         // Subtle dividers
AppColors.text           // Main text color
AppColors.textMuted      // Muted/secondary text
```

### Text Styles
```swift
AppTypography.title("Large Title")           // 28pt bold
AppTypography.title2("Medium Title")         // 22pt semibold
AppTypography.headline("Section Header")     // 18pt semibold
AppTypography.body("Regular paragraph text") // 14pt regular
AppTypography.caption("Small secondary")     // 12pt regular
AppTypography.label("UPPERCASE LABEL")       // 11pt semibold, uppercase
AppTypography.stat("99h 45m")                // 28pt monospaced bold
```

### Spacing
```swift
AppSpacing.xxs  // 4pt
AppSpacing.xs   // 8pt
AppSpacing.sm   // 12pt
AppSpacing.md   // 16pt
AppSpacing.lg   // 24pt
AppSpacing.xl   // 32pt
AppSpacing.xxl  // 48pt
```

### Button Styles
```swift
AppButton("Primary", style: .primary, fullWidth: true) {}
AppButton("Secondary", style: .secondary) {}
AppButton("Destructive", style: .destructive) {}
AppButton("Outline", style: .outline) {}
AppButton("Loading", isLoading: true) {}
AppButton("Disabled", isEnabled: false) {}
```

---

## 🎯 Usage Patterns

### ❌ WRONG: Using hardcoded colors/sizes
```swift
Text("Hello")
    .foregroundColor(Color(red: 0.9, green: 0.9, blue: 0.9))
    .font(.system(size: 18, weight: .bold))
    .padding(16)
```

### ✅ CORRECT: Using design tokens
```swift
AppTypography.headline("Hello")
    .padding(AppSpacing.md)
```

---

## 📐 Component Examples

### Dashboard Card
```swift
ProjectCardView(
    department: "Marketing",
    projectTitle: "Website Redesign",
    effortToday: "2h 15m"
) {
    // Handle tap action
}
```

### Stat Display
```swift
VStack(spacing: AppSpacing.xs) {
    AppTypography.label("TOTAL HOURS")
    AppTypography.stat("42h 15m")
}
```

### List Item
```swift
HStack(spacing: AppSpacing.md) {
    AppTypography.body("Task Name")
    Spacer()
    AppBadge(text: "In Progress", style: .info)
}
.padding(AppSpacing.md)
.background(AppColors.surface)
.cornerRadius(AppRadius.eight)
```

### Form Input
```swift
VStack(alignment: .leading, spacing: AppSpacing.xs) {
    AppTypography.label("Task Name")
    AppTextField("e.g., Code Review", text: $taskName)
}
```

### Alert/Info Box
```swift
VStack(alignment: .leading, spacing: AppSpacing.md) {
    AppTypography.headline("Export for Billing")
    AppTypography.bodyMuted("Generate a CSV report...")
    AppButton("Generate", style: .primary, fullWidth: true) {}
}
.padding(AppSpacing.lg)
.background(AppColors.primary.opacity(0.08))
.cornerRadius(AppRadius.twelve)
.overlay(
    RoundedRectangle(cornerRadius: AppRadius.twelve)
        .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
)
```

---

## 🔄 Data Flow Example

### Connecting to a ViewModel
```swift
struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Use viewModel data
            AppTypography.stat(viewModel.totalHoursToday)
            
            LazyVGrid(columns: gridColumns, spacing: AppSpacing.md) {
                ForEach(viewModel.projects) { project in
                    ProjectCardView(
                        department: project.clientName ?? "Unassigned",
                        projectTitle: project.name,
                        effortToday: project.todayHours
                    ) {
                        viewModel.selectProject(project)
                    }
                }
            }
        }
    }
}
```

---

## 🧪 Preview with Design System

```swift
#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        VStack(spacing: AppSpacing.lg) {
            AppTypography.title("Preview Title")
            ProjectCardView(
                department: "Development",
                projectTitle: "Sample Project",
                effortToday: "3h 30m"
            )
        }
        .padding(AppSpacing.lg)
    }
}
```

---

## 📏 Icons

All app icons use SF Symbols via the `AppIcons` enum:

```swift
AppIcons.play      // play.fill
AppIcons.pause     // pause.fill
AppIcons.timer     // timer
AppIcons.dashboard // square.grid.2x2
AppIcons.projects  // rectangle.on.rectangle
AppIcons.reports   // chart.bar
AppIcons.export    // arrow.up.doc
```

Use in views:
```swift
Image(systemName: AppIcons.play)
    .font(.system(size: AppSizes.iconDefault, weight: .semibold))
    .foregroundColor(AppColors.primary)
```

---

## 🎨 Custom Component Checklist

Before creating a new component, ensure it:

- [ ] Uses **AppColors** for all colors (never hardcoded)
- [ ] Uses **AppTypography** for all text (never raw `.font()`)
- [ ] Uses **AppSpacing** for all padding/gaps (never hardcoded numbers)
- [ ] Uses **AppRadius** for corner radius (never hardcoded values)
- [ ] Uses **AppSizes** for fixed dimensions
- [ ] Has **Preview** with dark theme enabled
- [ ] Supports **dynamic type** (accessibility)
- [ ] Is **reusable** (generic parameters if needed)
- [ ] Has **clear documentation** (comments for complex logic)
- [ ] Follows **naming convention**: `AppComponentName.swift`

---

## 🔗 File Organization

```
UI/
├── Components/          # Reusable UI components
│   ├── AppButton.swift
│   ├── AppTextField.swift
│   ├── ProjectCardView.swift   # Domain-specific card
│   └── ...
│
├── Screens/             # Full screen views
│   ├── DashboardView.swift
│   ├── ProjectDetailView.swift
│   ├── ReportsView.swift
│   └── RootNavigationView.swift
│
├── ViewModels/          # State management (to be created)
│   ├── DashboardViewModel.swift
│   ├── ProjectDetailViewModel.swift
│   └── ReportsViewModel.swift
│
└── Style/               # Design system
    ├── AppStyles.swift
    ├── AppTypography.swift
    ├── AppIcons.swift
    └── (AppAnimations.swift - for future use)
```

---

## 🚀 Adding a New Screen

1. Create view in `UI/Screens/YourScreen.swift`
2. Create viewmodel in `UI/ViewModels/YourScreenViewModel.swift`
3. Use components from `UI/Components/`
4. Use design tokens from `UI/Style/`
5. Add to `RootNavigationView.swift` navigation
6. Wire up to `ProjectTrackerApp.swift`

**Example**:
```swift
// UI/Screens/YourScreen.swift
struct YourScreen: View {
    @ObservedObject var viewModel: YourScreenViewModel
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            AppTypography.title("Your Screen")
            // Build using components and tokens
        }
        .padding(AppSpacing.lg)
        .background(AppColors.background)
    }
}
```

---

## 📚 Reference Files

- **AppStyles.swift** - Colors, Spacing, Radius, Sizes, Shadows, Animations
- **AppTypography.swift** - All text styles
- **AppIcons.swift** - All SF Symbol icon names
- **Components/** - Pre-built UI building blocks
- **IMPLEMENTATION_PLAN.md** - Overall project roadmap

---

## ❓ Troubleshooting

**Issue: "Cannot find AppColors in scope"**
- Ensure file is in `UI/Style/` folder
- Check import statements if in different module

**Issue: "Text looks different than design"**
- Are you using `AppTypography`?
- Check the exact style (title vs title2 vs headline)

**Issue: Spacing looks inconsistent**
- Don't hardcode padding (16, 24, etc)
- Always use `AppSpacing.md`, `AppSpacing.lg`, etc

**Issue: Colors don't match mockup**
- Use `AppColors.primary`, not `Color.blue`
- All semantic colors are in `AppColors` enum

---

**Last Reviewed**: March 18, 2026  
**Next Review**: When adding new component types
