import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import DAOs
import 'daos/recipe_dao.dart';
import 'daos/meal_plan_dao.dart';
import 'daos/grocery_dao.dart';
import 'daos/pantry_dao.dart';

part 'database.g.dart';

// ============================================================================
// TABLE DEFINITIONS
// ============================================================================

/// Recipes table
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get ingredientsJson => text()(); // JSON array of ingredients
  TextColumn get directionsJson => text()(); // JSON array of directions
  TextColumn get categoriesJson => text()(); // JSON array of categories
  IntColumn get prepTimeMinutes => integer().nullable()();
  IntColumn get cookTimeMinutes => integer().nullable()();
  IntColumn get servings => integer().withDefault(const Constant(4))();
  TextColumn get difficulty => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get photoUrlsJson => text()(); // JSON array of URLs
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get nutritionJson => text().nullable()(); // JSON object
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get hasCooked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Meal Plan Entries table
class MealPlanEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // enum as string: breakfast, lunch, dinner, snack
  TextColumn get recipeId => text().nullable()();
  TextColumn get customNote => text().nullable()();
  IntColumn get servings => integer().nullable()(); // Number of servings to make (null = use recipe default)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grocery Lists table
class GroceryLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grocery Items table
class GroceryItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get category => text()(); // enum as string
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get originRecipeIdsJson => text().nullable()(); // JSON array
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pantry Items table
class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get location => text()(); // enum as string: pantry, refrigerator, freezer
  DateTimeColumn get expirationDate => dateTime().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync Queue table (for tracking changes to sync to cloud)
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // recipe, meal_plan, grocery_list, etc.
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get dataJson => text().nullable()(); // JSON payload
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

// ============================================================================
// DATABASE
// ============================================================================

/// Main database class
@DriftDatabase(
  tables: [
    Recipes,
    MealPlanEntries,
    GroceryLists,
    GroceryItems,
    PantryItems,
    SyncQueue,
  ],
  daos: [
    RecipeDao,
    MealPlanDao,
    GroceryDao,
    PantryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from version 1 to 2: Add servings column to MealPlanEntries
        if (from == 1 && to == 2) {
          await m.addColumn(mealPlanEntries, mealPlanEntries.servings);
        }
      },
    );
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'recipe_manager.db'));
    return NativeDatabase(file);
  });
}
