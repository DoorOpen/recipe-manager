import 'package:flutter/foundation.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/meal_plan_repository.dart';
import '../../../../core/repositories/recipe_repository.dart';

/// Provider for meal plan state management
class MealPlanProvider extends ChangeNotifier {
  final MealPlanRepository _mealPlanRepository;
  final RecipeRepository _recipeRepository;

  MealPlanProvider(this._mealPlanRepository, this._recipeRepository) {
    _loadWeekEntries();
  }

  // State
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = _getWeekStart(DateTime.now());
  final Map<DateTime, List<MealPlanEntry>> _entriesByDate = {};
  final Map<String, Recipe> _recipesCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  DateTime get selectedDate => _selectedDate;
  DateTime get weekStart => _weekStart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get entries for a specific date
  List<MealPlanEntry> getEntriesForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _entriesByDate[key] ?? [];
  }

  /// Get recipe from cache
  Recipe? getRecipe(String recipeId) {
    return _recipesCache[recipeId];
  }

  /// Get week dates (7 days starting from weekStart)
  List<DateTime> get weekDates {
    return List.generate(7, (index) => _weekStart.add(Duration(days: index)));
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  /// Select a date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Navigate to previous week
  Future<void> previousWeek() async {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    await _loadWeekEntries();
  }

  /// Navigate to next week
  Future<void> nextWeek() async {
    _weekStart = _weekStart.add(const Duration(days: 7));
    await _loadWeekEntries();
  }

  /// Jump to today
  Future<void> goToToday() async {
    _selectedDate = DateTime.now();
    _weekStart = _getWeekStart(DateTime.now());
    await _loadWeekEntries();
  }

  /// Add a meal plan entry
  Future<void> addEntry({
    required DateTime date,
    required MealType mealType,
    String? recipeId,
    String? customNote,
    int? servings,
  }) async {
    try {
      _error = null;

      final entry = MealPlanEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date,
        mealType: mealType,
        recipeId: recipeId,
        customNote: customNote,
        servings: servings,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _mealPlanRepository.insertEntry(entry);

      // Reload entries for this date
      await _loadEntriesForDate(date);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update a meal plan entry
  Future<void> updateEntry(MealPlanEntry entry) async {
    try {
      _error = null;

      final updated = entry.copyWith(updatedAt: DateTime.now());
      await _mealPlanRepository.updateEntry(updated);

      // Reload entries for this date
      await _loadEntriesForDate(entry.date);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a meal plan entry
  Future<void> deleteEntry(String id, DateTime date) async {
    try {
      _error = null;
      await _mealPlanRepository.deleteEntry(id);

      // Reload entries for this date
      await _loadEntriesForDate(date);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _loadWeekEntries();
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Load entries for the current week
  Future<void> _loadWeekEntries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final weekEnd = _weekStart.add(const Duration(days: 7));
      final entries = await _mealPlanRepository.getEntriesForRange(
        _weekStart,
        weekEnd,
      );

      // Group by date
      _entriesByDate.clear();
      for (final entry in entries) {
        final key = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        _entriesByDate.putIfAbsent(key, () => []).add(entry);
      }

      // Load recipes for entries with recipeId
      final recipeIds = entries
          .where((e) => e.recipeId != null)
          .map((e) => e.recipeId!)
          .toSet();

      for (final recipeId in recipeIds) {
        final recipe = await _recipeRepository.getRecipeById(recipeId);
        if (recipe != null) {
          _recipesCache[recipeId] = recipe;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load entries for a specific date
  Future<void> _loadEntriesForDate(DateTime date) async {
    try {
      final entries = await _mealPlanRepository.getEntriesForDate(date);

      final key = DateTime(date.year, date.month, date.day);
      _entriesByDate[key] = entries;

      // Load recipes
      final recipeIds = entries
          .where((e) => e.recipeId != null)
          .map((e) => e.recipeId!)
          .toSet();

      for (final recipeId in recipeIds) {
        if (!_recipesCache.containsKey(recipeId)) {
          final recipe = await _recipeRepository.getRecipeById(recipeId);
          if (recipe != null) {
            _recipesCache[recipeId] = recipe;
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Get the start of the week (Monday) for a given date
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }
}
