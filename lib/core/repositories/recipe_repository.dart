import '../services/database/database.dart';
import '../models/models.dart' as models;

/// Repository for recipe data access
/// Abstracts database operations from the UI layer
class RecipeRepository {
  final AppDatabase _database;

  RecipeRepository(this._database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all recipes
  Future<List<models.Recipe>> getAllRecipes() async {
    return await _database.recipeDao.getAllRecipes();
  }

  /// Get recipe by ID
  Future<models.Recipe?> getRecipeById(String id) async {
    return await _database.recipeDao.getRecipeById(id);
  }

  /// Get favorite recipes
  Future<List<models.Recipe>> getFavorites() async {
    return await _database.recipeDao.getFavoriteRecipes();
  }

  /// Get recipes by category
  Future<List<models.Recipe>> getRecipesByCategory(String category) async {
    return await _database.recipeDao.getRecipesByCategory(category);
  }

  /// Search recipes by query
  Future<List<models.Recipe>> searchRecipes(String query) async {
    return await _database.recipeDao.searchRecipes(query);
  }

  /// Get recently added recipes
  Future<List<models.Recipe>> getRecentRecipes({int limit = 10}) async {
    return await _database.recipeDao.getRecentRecipes(limit: limit);
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Insert a new recipe
  Future<void> insertRecipe(models.Recipe recipe) async {
    await _database.recipeDao.insertRecipe(recipe);
  }

  /// Update an existing recipe
  Future<void> updateRecipe(models.Recipe recipe) async {
    await _database.recipeDao.updateRecipe(recipe);
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String id) async {
    await _database.recipeDao.deleteRecipe(id);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    await _database.recipeDao.toggleFavorite(id);
  }

  /// Mark recipe as cooked
  Future<void> markAsCooked(String id) async {
    await _database.recipeDao.markAsCooked(id);
  }
}
