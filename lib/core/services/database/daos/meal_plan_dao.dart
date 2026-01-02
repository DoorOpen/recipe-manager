import 'package:drift/drift.dart';
import '../database.dart';
import '../../../models/models.dart' as models;

part 'meal_plan_dao.g.dart';

/// Meal Plan Data Access Object
@DriftAccessor(tables: [MealPlanEntries])
class MealPlanDao extends DatabaseAccessor<AppDatabase> with _$MealPlanDaoMixin {
  MealPlanDao(AppDatabase database) : super(database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all meal plan entries
  Future<List<models.MealPlanEntry>> getAllEntries() async {
    final rows = await select(mealPlanEntries).get();
    return rows.map(_rowToModel).toList();
  }

  /// Get entries for a specific date
  Future<List<models.MealPlanEntry>> getEntriesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (select(mealPlanEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(startOfDay) & e.date.isSmallerThanValue(endOfDay)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  /// Get entries for a date range (e.g., a week)
  Future<List<models.MealPlanEntry>> getEntriesForRange(DateTime start, DateTime end) async {
    final rows = await (select(mealPlanEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(start) & e.date.isSmallerThanValue(end))
          ..orderBy([(e) => OrderingTerm.asc(e.date)]))
        .get();

    return rows.map(_rowToModel).toList();
  }

  /// Get entries by meal type
  Future<List<models.MealPlanEntry>> getEntriesByMealType(models.MealType mealType) async {
    final rows = await (select(mealPlanEntries)
          ..where((e) => e.mealType.equals(mealType.name)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  /// Get entry by ID
  Future<models.MealPlanEntry?> getEntryById(String id) async {
    final row = await (select(mealPlanEntries)..where((e) => e.id.equals(id))).getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Insert a new meal plan entry
  Future<int> insertEntry(models.MealPlanEntry entry) async {
    return await into(mealPlanEntries).insert(_modelToCompanion(entry));
  }

  /// Update an existing entry
  Future<bool> updateEntry(models.MealPlanEntry entry) async {
    return await update(mealPlanEntries).replace(_modelToCompanion(entry));
  }

  /// Delete an entry
  Future<int> deleteEntry(String id) async {
    return await (delete(mealPlanEntries)..where((e) => e.id.equals(id))).go();
  }

  /// Delete all entries for a specific date
  Future<int> deleteEntriesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await (delete(mealPlanEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(startOfDay) & e.date.isSmallerThanValue(endOfDay)))
        .go();
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  models.MealPlanEntry _rowToModel(MealPlanEntry row) {
    return models.MealPlanEntry(
      id: row.id,
      date: row.date,
      mealType: models.MealType.values.firstWhere((e) => e.name == row.mealType),
      recipeId: row.recipeId,
      customNote: row.customNote,
      servings: row.servings,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  MealPlanEntriesCompanion _modelToCompanion(models.MealPlanEntry entry) {
    return MealPlanEntriesCompanion(
      id: Value(entry.id),
      date: Value(entry.date),
      mealType: Value(entry.mealType.name),
      recipeId: Value(entry.recipeId),
      customNote: Value(entry.customNote),
      servings: Value(entry.servings),
      createdAt: Value(entry.createdAt),
      updatedAt: Value(entry.updatedAt),
    );
  }
}
