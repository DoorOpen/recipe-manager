import '../services/database/database.dart';
import '../models/models.dart' as models;

/// Repository for meal plan data access
class MealPlanRepository {
  final AppDatabase _database;

  MealPlanRepository(this._database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all meal plan entries
  Future<List<models.MealPlanEntry>> getAllEntries() async {
    return await _database.mealPlanDao.getAllEntries();
  }

  /// Get entries for a specific date
  Future<List<models.MealPlanEntry>> getEntriesForDate(DateTime date) async {
    return await _database.mealPlanDao.getEntriesForDate(date);
  }

  /// Get entries for a date range
  Future<List<models.MealPlanEntry>> getEntriesForRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _database.mealPlanDao.getEntriesForRange(start, end);
  }

  /// Get entries by meal type
  Future<List<models.MealPlanEntry>> getEntriesByMealType(
    models.MealType mealType,
  ) async {
    return await _database.mealPlanDao.getEntriesByMealType(mealType);
  }

  /// Get entry by ID
  Future<models.MealPlanEntry?> getEntryById(String id) async {
    return await _database.mealPlanDao.getEntryById(id);
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Insert a new meal plan entry
  Future<void> insertEntry(models.MealPlanEntry entry) async {
    await _database.mealPlanDao.insertEntry(entry);
  }

  /// Update an existing entry
  Future<void> updateEntry(models.MealPlanEntry entry) async {
    await _database.mealPlanDao.updateEntry(entry);
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    await _database.mealPlanDao.deleteEntry(id);
  }

  /// Delete all entries for a specific date
  Future<void> deleteEntriesForDate(DateTime date) async {
    await _database.mealPlanDao.deleteEntriesForDate(date);
  }
}
