# How to Build and Test the Recipe Manager App

## ✅ Prerequisites

- Flutter SDK installed (`~/flutter/bin/flutter`)
- Linux desktop environment (for local testing)
- OR Android device/emulator
- OR iOS device (requires macOS)

---

## 🚀 Quick Start Guide

### 1. **Install Dependencies**

```bash
cd "/home/host/Documents/CPR LLC/recipe_manager"
~/flutter/bin/flutter pub get
```

### 2. **Generate Code** (for database & models)

```bash
~/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `.g.dart` files for Drift database
- `.g.dart` files for JSON serialization

### 3. **Build the App**

#### **Option A: Linux Desktop** (Fastest for development)

```bash
# Debug build (recommended for testing)
~/flutter/bin/flutter build linux --debug

# Release build (optimized)
~/flutter/bin/flutter build linux --release
```

**Output location:**
- Debug: `build/linux/x64/debug/bundle/recipe_manager`
- Release: `build/linux/x64/release/bundle/recipe_manager`

#### **Option B: Android**

```bash
# Connect Android device or start emulator
~/flutter/bin/flutter devices

# Build APK
~/flutter/bin/flutter build apk --debug

# OR install directly to device
~/flutter/bin/flutter install
```

#### **Option C: Web** (requires Chrome)

```bash
~/flutter/bin/flutter build web
```

---

## ▶️ Running the App

### **Linux Desktop**

```bash
# Run in debug mode (hot reload enabled)
~/flutter/bin/flutter run -d linux

# OR run the built executable directly
./build/linux/x64/debug/bundle/recipe_manager
```

### **Android**

```bash
# Run on connected device/emulator
~/flutter/bin/flutter run -d android

# OR run on specific device
~/flutter/bin/flutter run -d <device-id>
```

### **Web**

```bash
# Run in Chrome (if installed)
~/flutter/bin/flutter run -d chrome

# OR serve the built web app
cd build/web
python3 -m http.server 8000
# Then open http://localhost:8000
```

---

## 🧪 Testing Features

### **Current App State (MVP Phase 1 - ~45% Complete)**

#### ✅ **What Works:**
1. **Navigation** - Bottom tab bar with 5 sections
2. **Theme** - Light/dark mode (follows system)
3. **Database** - SQLite with Drift (offline-first)
4. **Empty States** - Placeholder UI for all screens

#### ⚠️ **What's NOT Implemented Yet:**
- Recipe CRUD (no data shows, forms not built)
- Web recipe import
- Meal planning calendar
- Grocery list functionality
- Pantry management
- Cloud sync
- All premium features (OCR, Instacart, etc.)

### **Testing Checklist**

When the app launches, you should see:

1. ✅ **Bottom Navigation Bar**
   - 5 tabs: Recipes, Meal Plan, Shopping, Pantry, Settings
   - Icons change when selected
   - Smooth tab switching

2. ✅ **Recipes Screen**
   - Empty state with recipe icon
   - "Add Recipe" floating button (not functional yet)
   - Search/filter icons in app bar (not functional yet)

3. ✅ **Meal Plan Screen**
   - Calendar-themed empty state
   - "Jump to Today" button (not functional yet)
   - FAB for adding meals (not functional yet)

4. ✅ **Shopping Lists Screen**
   - Shopping cart empty state
   - "New List" button (not functional yet)

5. ✅ **Pantry Screen**
   - Kitchen-themed empty state
   - Search in app bar (not functional yet)

6. ✅ **Settings Screen**
   - Sections: General, Data, About
   - Theme selector (placeholder)
   - Units selector (placeholder)
   - App version displayed
   - All buttons are placeholders

7. ✅ **Theme Switching**
   - Light mode (default)
   - Dark mode (when system is in dark mode)
   - Colors: Indigo primary, Amber accent

---

## 🐛 Troubleshooting

### **Build Errors**

#### "CMake cache error"
```bash
# Clean and rebuild
~/flutter/bin/flutter clean
rm -rf build/
~/flutter/bin/flutter build linux
```

#### "Code generation failed"
```bash
# Re-run build_runner
~/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs
```

#### "Drift database errors"
```bash
# Make sure all .g.dart files are generated
find lib -name "*.g.dart"

# Should see:
# - lib/core/models/recipe.g.dart
# - lib/core/models/meal_plan_entry.g.dart
# - lib/core/models/grocery_list.g.dart
# - lib/core/models/pantry_item.g.dart
# - lib/core/services/database/database.g.dart
# - lib/core/services/database/daos/*.g.dart
```

### **Runtime Errors**

#### "Database not found"
- The database is created automatically on first run
- Location: System temp directory or app data
- No manual setup needed

#### "Blank screen on launch"
- Check console for errors: `~/flutter/bin/flutter run -d linux -v`
- Verify hot reload is working (make a small change and save)

### **Performance Issues**

#### Slow startup
- Use release build: `~/flutter/bin/flutter build linux --release`
- Debug builds are slower due to debugging overhead

#### High memory usage
- Expected in debug mode
- Release builds are optimized

---

## 📝 Development Workflow

### **Making Changes**

1. **Edit code** in `lib/` directory

2. **Hot reload** (if running in debug mode)
   - Press `r` in terminal
   - OR save file (auto hot-reload)

3. **Hot restart** (if hot reload doesn't work)
   - Press `R` in terminal

4. **Full rebuild** (for major changes)
   - Stop app (Ctrl+C)
   - `~/flutter/bin/flutter run -d linux`

### **After Changing Models or Database**

```bash
# Re-run code generator
~/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

# Then restart app
~/flutter/bin/flutter run -d linux
```

---

## 🔍 Checking App State

### **Database Location**

The SQLite database is stored locally:

```bash
# On Linux
~/.local/share/recipe_manager/

# Check if database was created
find ~/.local -name "*.sqlite*" 2>/dev/null
```

### **Logs and Debugging**

```bash
# Run with verbose logging
~/flutter/bin/flutter run -d linux -v

# Check for errors in console
# Common issues:
# - Widget errors (red screen)
# - Database errors (check code generation)
# - Navigation errors
```

---

## 📦 Build Outputs

### **Debug Build**
- **Path:** `build/linux/x64/debug/bundle/`
- **Size:** ~50-100 MB (includes debug symbols)
- **Use:** Local testing, development

### **Release Build**
- **Path:** `build/linux/x64/release/bundle/`
- **Size:** ~20-30 MB (optimized)
- **Use:** Production, distribution

### **APK (Android)**
- **Path:** `build/app/outputs/flutter-apk/app-debug.apk`
- **Install:** `adb install build/app/outputs/flutter-apk/app-debug.apk`

---

## ✅ Success Indicators

If the app is working correctly, you should:

1. ✅ See the app window open
2. ✅ See bottom navigation with 5 tabs
3. ✅ Be able to switch between tabs smoothly
4. ✅ See appropriate empty states on each screen
5. ✅ See floating action buttons on relevant screens
6. ✅ See the app respond to system theme changes (light/dark)
7. ❌ NOT see any red error screens
8. ❌ NOT see console errors (warnings are OK)

---

## 🎯 Next Steps for Development

### **To Make the App Functional:**

1. **Connect UI to Database** (~1 day)
   - Initialize database in `main.dart`
   - Provide via Provider
   - Fetch data in screens

2. **Build Recipe List** (~2 days)
   - RecipeListViewModel
   - Recipe cards with data
   - Search/filter

3. **Build Add/Edit Recipe Form** (~3 days)
   - Full form implementation
   - Save to database
   - Photo upload

4. **Implement Remaining Features** (~2-3 weeks)
   - See `PRD_CHECKLIST.md` for full list

---

## 📚 Useful Commands Reference

```bash
# Check Flutter setup
~/flutter/bin/flutter doctor

# List available devices
~/flutter/bin/flutter devices

# Clean project
~/flutter/bin/flutter clean

# Get dependencies
~/flutter/bin/flutter pub get

# Generate code
~/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs

# Build for Linux (debug)
~/flutter/bin/flutter build linux --debug

# Build for Linux (release)
~/flutter/bin/flutter build linux --release

# Run on Linux
~/flutter/bin/flutter run -d linux

# Run with hot reload
~/flutter/bin/flutter run -d linux --hot

# Run tests
~/flutter/bin/flutter test

# Analyze code
~/flutter/bin/flutter analyze

# Format code
~/flutter/bin/flutter format lib/
```

---

## 🎉 You're Ready to Test!

The app is built and ready to run. Navigate to the recipe_manager directory and use:

```bash
~/flutter/bin/flutter run -d linux
```

**Expected behavior:** The app will launch with the bottom navigation and empty state screens. No data will show yet because database integration is the next step!
