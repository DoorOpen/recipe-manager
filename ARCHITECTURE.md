# Recipe Manager - Architecture

## Overview
This app follows a **Feature-First Clean Architecture** approach with an **offline-first** design pattern.

## Project Structure

```
lib/
├── core/                    # Core business logic shared across features
│   ├── models/             # Shared data models
│   ├── services/           # Core services (sync, auth, etc.)
│   └── utils/              # Utilities and helpers
├── features/               # Feature modules
│   ├── recipes/           # Recipe management
│   ├── meal_plan/         # Meal planning calendar
│   ├── grocery_list/      # Shopping list management
│   ├── pantry/            # Pantry/inventory tracking
│   └── settings/          # App settings
└── shared/                 # Shared UI components
    ├── constants/         # App-wide constants
    ├── theme/             # Theme configuration
    └── widgets/           # Reusable widgets
```

## Architecture Layers

Each feature follows a 3-layer architecture:

### 1. **Data Layer** (`data/`)
- Local database (Drift/SQLite)
- Repository implementations
- Data sources (local, remote)

### 2. **Domain Layer** (`domain/`)
- Business logic
- Use cases
- Repository interfaces

### 3. **Presentation Layer** (`presentation/`)
- UI screens (`screens/`)
- Widgets (`widgets/`)
- State management (Provider/ChangeNotifier)

## Key Technologies

- **UI Framework**: Flutter 3.35+
- **State Management**: Provider
- **Local Database**: Drift (SQLite)
- **HTTP Client**: Dio
- **Navigation**: Navigator 2.0 (GoRouter - to be added)
- **Code Generation**: build_runner

## Data Flow

1. **User Action** → UI (Presentation)
2. **UI** → ViewModel/Provider
3. **Provider** → Repository (Domain)
4. **Repository** → Data Source (Local DB / API)
5. **Data flows back** up the chain
6. **Sync Service** pushes changes to cloud in background

## Offline-First Strategy

1. All data stored locally in SQLite via Drift
2. User actions immediately update local DB
3. Changes queued for sync when online
4. Background sync service uploads changes
5. Conflict resolution: last-write-wins (configurable)

## Database Schema (Drift Tables)

- **recipes**: Core recipe data
- **ingredients**: Recipe ingredients (with quantities)
- **meal_plan_entries**: Calendar meal planning
- **grocery_lists**: Shopping lists
- **grocery_items**: Individual list items
- **pantry_items**: Pantry inventory
- **sync_queue**: Changes pending upload

## MVP Features (Phase 1)

1. ✅ Recipe management (CRUD)
2. ✅ Recipe import from web (HTML parsing)
3. ✅ Meal planning calendar
4. ✅ Grocery list generation from recipes
5. ✅ Pantry tracking
6. ✅ Offline-first with local storage
7. ⏳ Cloud sync (Phase 2)

## Future Enhancements

- OCR recipe scanning
- Instacart/grocery delivery integration
- Voice assistant integration
- Nutrition calculation
- Multi-user collaboration
- Web app version
