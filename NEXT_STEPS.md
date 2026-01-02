# 🎯 Next Development Steps - Recipe Manager

**Current Status:** ~45% Complete (Foundation built, features need implementation)

**Goal:** Build core recipe management functionality to reach functional MVP

---

## 🚀 **PHASE 1: Database Integration & Recipe CRUD (Week 1-2)**

### **Priority 1: Connect Database to UI** (Day 1-2)

The database exists but isn't connected to the UI. We need to:

#### **Step 1.1: Initialize Database in main.dart**
```dart
// lib/main.dart - Add database initialization
import 'package:provider/provider.dart';
import 'core/services/database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        // Add other providers here
      ],
      child: const RecipeManagerApp(),
    ),
  );
}
```

**Files to modify:**
- `lib/main.dart` - Add database initialization and Provider setup

**Estimated time:** 30 minutes

---

#### **Step 1.2: Create Repository Layer**

We need a repository to abstract database access from the UI.

**Create:** `lib/core/repositories/recipe_repository.dart`
```dart
import '../services/database/database.dart';
import '../models/models.dart' as models;

class RecipeRepository {
  final AppDatabase _database;

  RecipeRepository(this._database);

  // CRUD Operations
  Future<List<models.Recipe>> getAllRecipes() async {
    return await _database.recipeDao.getAllRecipes();
  }

  Future<models.Recipe?> getRecipeById(String id) async {
    return await _database.recipeDao.getRecipeById(id);
  }

  Future<void> insertRecipe(models.Recipe recipe) async {
    await _database.recipeDao.insertRecipe(recipe);
  }

  Future<void> updateRecipe(models.Recipe recipe) async {
    await _database.recipeDao.updateRecipe(recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await _database.recipeDao.deleteRecipe(id);
  }

  // Search & Filter
  Future<List<models.Recipe>> searchRecipes(String query) async {
    return await _database.recipeDao.searchRecipes(query);
  }

  Future<List<models.Recipe>> getFavorites() async {
    return await _database.recipeDao.getFavoriteRecipes();
  }

  // Favorites & Cooked
  Future<void> toggleFavorite(String id) async {
    await _database.recipeDao.toggleFavorite(id);
  }

  Future<void> markAsCooked(String id) async {
    await _database.recipeDao.markAsCooked(id);
  }
}
```

**Files to create:**
- `lib/core/repositories/recipe_repository.dart`
- `lib/core/repositories/meal_plan_repository.dart` (similar pattern)
- `lib/core/repositories/grocery_repository.dart` (similar pattern)
- `lib/core/repositories/pantry_repository.dart` (similar pattern)

**Estimated time:** 1-2 hours

---

#### **Step 1.3: Create ViewModels with ChangeNotifier**

ViewModels manage state and business logic for screens.

**Create:** `lib/features/recipes/presentation/providers/recipe_list_provider.dart`
```dart
import 'package:flutter/foundation.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/models/models.dart' as models;

class RecipeListProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  List<models.Recipe> _recipes = [];
  List<models.Recipe> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';

  RecipeListProvider(this._repository) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_searchQuery.isEmpty) {
        _recipes = await _repository.getAllRecipes();
      } else {
        _recipes = await _repository.searchRecipes(_searchQuery);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchRecipes(String query) {
    _searchQuery = query;
    loadRecipes();
  }

  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
    await loadRecipes(); // Refresh list
  }

  Future<void> deleteRecipe(String id) async {
    await _repository.deleteRecipe(id);
    await loadRecipes();
  }
}
```

**Files to create:**
- `lib/features/recipes/presentation/providers/recipe_list_provider.dart`
- `lib/features/recipes/presentation/providers/recipe_detail_provider.dart`
- `lib/features/recipes/presentation/providers/add_edit_recipe_provider.dart`

**Estimated time:** 2 hours

---

### **Priority 2: Build Recipe List Screen** (Day 2-3)

Update the existing RecipesScreen to show real data.

#### **Step 2.1: Update RecipesScreen with Provider**

**Modify:** `lib/features/recipes/presentation/screens/recipes_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_list_provider.dart';
import '../widgets/recipe_card.dart'; // We'll create this

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecipeListProvider(
        context.read<RecipeRepository>(),
      ),
      child: const _RecipesScreenBody(),
    );
  }
}

class _RecipesScreenBody extends StatelessWidget {
  const _RecipesScreenBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeListProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddRecipe(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
    );
  }

  Widget _buildBody(RecipeListProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${provider.error}'),
            ElevatedButton(
              onPressed: () => provider.loadRecipes(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.recipes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadRecipes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.recipes.length,
        itemBuilder: (context, index) {
          final recipe = provider.recipes[index];
          return RecipeCard(
            recipe: recipe,
            onTap: () => _navigateToRecipeDetail(context, recipe.id),
            onFavoriteToggle: () => provider.toggleFavorite(recipe.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No Recipes Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first recipe to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // Implement search dialog
  }

  void _showFilters(BuildContext context) {
    // Implement filters bottom sheet
  }

  void _navigateToAddRecipe(BuildContext context) {
    // Navigator.push to AddEditRecipeScreen
  }

  void _navigateToRecipeDetail(BuildContext context, String recipeId) {
    // Navigator.push to RecipeDetailScreen
  }
}
```

**Estimated time:** 3-4 hours

---

#### **Step 2.2: Create Recipe Card Widget**

**Create:** `lib/features/recipes/presentation/widgets/recipe_card.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../core/models/models.dart' as models;

class RecipeCard extends StatelessWidget {
  final models.Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            if (recipe.photos.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  recipe.photos.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                ),
              )
            else
              _buildPlaceholderImage(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          recipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                          color: recipe.isFavorite
                            ? Colors.red
                            : null,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Metadata (time, servings, difficulty)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (recipe.prepTime != null)
                        _buildMetadata(
                          Icons.timer_outlined,
                          '${recipe.prepTime} min',
                        ),
                      if (recipe.servings != null)
                        _buildMetadata(
                          Icons.people_outline,
                          '${recipe.servings} servings',
                        ),
                      if (recipe.difficulty != null)
                        _buildMetadata(
                          Icons.bar_chart,
                          recipe.difficulty!,
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Categories
                  if (recipe.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: recipe.categories.take(3).map((cat) =>
                        Chip(
                          label: Text(cat),
                          visualDensity: VisualDensity.compact,
                        ),
                      ).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.restaurant_menu,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMetadata(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
```

**Estimated time:** 1-2 hours

---

### **Priority 3: Build Add/Edit Recipe Form** (Day 3-5)

This is the most complex part - a full form for creating/editing recipes.

#### **Step 3.1: Create AddEditRecipeScreen**

**Create:** `lib/features/recipes/presentation/screens/add_edit_recipe_screen.dart`

Key features:
- Title input
- Ingredient list builder (add/remove rows)
- Directions text editor
- Category multi-select
- Photo upload
- Prep/cook time inputs
- Servings input
- Difficulty selector
- Rating (if editing)
- Save/Cancel buttons

**Estimated time:** 6-8 hours (complex form with validation)

---

### **Priority 4: Recipe Detail Screen** (Day 5-6)

Display full recipe information with cooking mode.

**Create:** `lib/features/recipes/presentation/screens/recipe_detail_screen.dart`

Features:
- Display all recipe info
- Edit/Delete buttons
- Add to meal plan button
- Add ingredients to grocery list button
- Start cooking mode button
- Share button

**Estimated time:** 3-4 hours

---

## 📅 **PHASE 2: Meal Planning (Week 2-3)**

Once recipes work, implement meal planning:

1. **Calendar Widget** - Use `table_calendar` package
2. **Drag-drop recipes** to calendar
3. **Meal plan → Grocery list** auto-generation
4. **Weekly/Monthly views**

---

## 🛒 **PHASE 3: Grocery Lists (Week 3-4)**

1. **List management UI**
2. **Item checking/unchecking**
3. **Smart categorization**
4. **Item merging** (combine duplicates)

---

## 🥫 **PHASE 4: Pantry Management (Week 4)**

1. **CRUD for pantry items**
2. **Expiration tracking**
3. **Integration with grocery lists**

---

## 🌐 **PHASE 5: Recipe Import from Web (Week 5-6)**

1. **URL input screen**
2. **HTML parser** implementation
3. **Recipe preview** before saving
4. **Handle various recipe sites**

---

## ☁️ **PHASE 6: Cloud Sync (Week 7-10)**

1. **AWS backend setup** (Cognito, Lambda, DynamoDB, S3)
2. **Authentication screens**
3. **Sync service** implementation
4. **Conflict resolution**

---

## 🎯 **TODAY'S TASKS (Start Here!)**

### **Task 1: Database Integration** (2-3 hours)
1. ✅ Initialize AppDatabase in `main.dart`
2. ✅ Set up Provider/MultiProvider
3. ✅ Create RecipeRepository
4. ✅ Create RecipeListProvider

### **Task 2: Recipe List UI** (3-4 hours)
1. ✅ Update RecipesScreen to use Provider
2. ✅ Create RecipeCard widget
3. ✅ Add loading/error/empty states
4. ✅ Test with sample data

### **Task 3: Add Sample Recipes** (30 min)
Create a script to insert test data so you can see results immediately.

---

## 📝 **Development Tips**

### **Testing Strategy**
1. **Add sample data first** - Insert 5-10 recipes manually via database
2. **Test incrementally** - Build one screen at a time
3. **Hot reload** - Use `r` in terminal for instant updates

### **Common Patterns**
```dart
// Pattern 1: Provider setup in screen
ChangeNotifierProvider(
  create: (context) => SomeProvider(context.read<Repository>()),
  child: SomeScreen(),
)

// Pattern 2: Watch for changes
final provider = context.watch<SomeProvider>();

// Pattern 3: Call methods without rebuild
context.read<SomeProvider>().someMethod();
```

### **File Organization**
```
lib/features/recipes/
├── data/              (Future: for API calls)
├── domain/            (Future: business logic)
└── presentation/
    ├── providers/     ← ViewModels go here
    ├── screens/       ← Full page screens
    └── widgets/       ← Reusable components
```

---

## ✅ **Success Criteria for Phase 1**

By end of Week 2, you should have:
- [ ] Recipes display in list
- [ ] Add new recipe (full form)
- [ ] Edit existing recipe
- [ ] Delete recipe
- [ ] Search recipes
- [ ] Toggle favorites
- [ ] View recipe details
- [ ] Basic navigation working

**This makes it a USABLE app!** 🎉

---

## 🚨 **Common Gotchas to Avoid**

1. **Forgot to call notifyListeners()** - UI won't update
2. **Not using context.read vs context.watch** correctly
3. **Forgetting to initialize database** in main.dart
4. **Not handling null safety** properly
5. **Image URLs** - Handle network errors gracefully

---

## 🎯 **Start Coding!**

Begin with **Task 1** - Let's connect that database to the UI!

```bash
# Make sure app is not running, then start fresh
cd "/home/host/Documents/CPR LLC/recipe_manager"
~/flutter/bin/flutter run -d linux
```

Use hot reload (`r`) to see changes instantly as you code! 🔥
