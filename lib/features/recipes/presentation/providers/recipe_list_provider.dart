import 'package:flutter/foundation.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/models/models.dart' as models;

/// Sort options for recipes
enum SortOption {
  nameAsc,
  nameDesc,
  ratingDesc,
  ratingAsc,
  timeAsc,
  timeDesc,
}

/// Provider for managing the recipe list state
class RecipeListProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  RecipeListProvider(this._repository) {
    loadRecipes();
  }

  // ============================================================================
  // STATE
  // ============================================================================

  List<models.Recipe> _recipes = [];
  List<models.Recipe> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;

  String? _selectedDifficulty;
  String? get selectedDifficulty => _selectedDifficulty;

  double? _minRating;
  double? get minRating => _minRating;

  SortOption _sortOption = SortOption.nameAsc;
  SortOption get sortOption => _sortOption;

  // ============================================================================
  // ACTIONS
  // ============================================================================

  /// Load all recipes
  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<models.Recipe> recipes;

      if (_showFavoritesOnly) {
        recipes = await _repository.getFavorites();
      } else if (_searchQuery.isNotEmpty) {
        recipes = await _repository.searchRecipes(_searchQuery);
      } else if (_selectedCategory != null) {
        recipes = await _repository.getRecipesByCategory(_selectedCategory!);
      } else {
        recipes = await _repository.getAllRecipes();
      }

      // Apply additional filters
      if (_selectedDifficulty != null) {
        recipes = recipes.where((r) => r.difficulty == _selectedDifficulty).toList();
      }

      if (_minRating != null) {
        recipes = recipes.where((r) => r.rating != null && r.rating! >= _minRating!).toList();
      }

      // Apply sorting
      _recipes = _sortRecipes(recipes);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading recipes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sort recipes based on selected sort option
  List<models.Recipe> _sortRecipes(List<models.Recipe> recipes) {
    final sorted = List<models.Recipe>.from(recipes);

    switch (_sortOption) {
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.ratingDesc:
        sorted.sort((a, b) {
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return b.rating!.compareTo(a.rating!);
        });
        break;
      case SortOption.ratingAsc:
        sorted.sort((a, b) {
          if (a.rating == null && b.rating == null) return 0;
          if (a.rating == null) return 1;
          if (b.rating == null) return -1;
          return a.rating!.compareTo(b.rating!);
        });
        break;
      case SortOption.timeAsc:
        sorted.sort((a, b) {
          final aTime = (a.prepTimeMinutes ?? 0) + (a.cookTimeMinutes ?? 0);
          final bTime = (b.prepTimeMinutes ?? 0) + (b.cookTimeMinutes ?? 0);
          return aTime.compareTo(bTime);
        });
        break;
      case SortOption.timeDesc:
        sorted.sort((a, b) {
          final aTime = (a.prepTimeMinutes ?? 0) + (a.cookTimeMinutes ?? 0);
          final bTime = (b.prepTimeMinutes ?? 0) + (b.cookTimeMinutes ?? 0);
          return bTime.compareTo(aTime);
        });
        break;
    }

    return sorted;
  }

  /// Search recipes by query
  void searchRecipes(String query) {
    _searchQuery = query;
    loadRecipes();
  }

  /// Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    loadRecipes();
  }

  /// Toggle show favorites only
  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    loadRecipes();
  }

  /// Filter by difficulty
  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    loadRecipes();
  }

  /// Filter by minimum rating
  void filterByRating(double? minRating) {
    _minRating = minRating;
    loadRecipes();
  }

  /// Set sort option
  void setSortOption(SortOption option) {
    _sortOption = option;
    loadRecipes();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDifficulty = null;
    _minRating = null;
    _showFavoritesOnly = false;
    loadRecipes();
  }

  /// Toggle favorite status for a recipe
  Future<void> toggleFavorite(String id) async {
    try {
      await _repository.toggleFavorite(id);
      await loadRecipes(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    try {
      await _repository.deleteRecipe(id);
      await loadRecipes(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark recipe as cooked
  Future<void> markAsCooked(String id) async {
    try {
      await _repository.markAsCooked(id);
      await loadRecipes(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh recipes (for pull-to-refresh)
  Future<void> refresh() async {
    await loadRecipes();
  }
}
