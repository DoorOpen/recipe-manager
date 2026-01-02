import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../../../models/models.dart' as models;

part 'recipe_dao.g.dart';

/// Recipe Data Access Object
@DriftAccessor(tables: [Recipes])
class RecipeDao extends DatabaseAccessor<AppDatabase> with _$RecipeDaoMixin {
  RecipeDao(AppDatabase database) : super(database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all recipes
  Future<List<models.Recipe>> getAllRecipes() async {
    final rows = await select(recipes).get();
    return rows.map(_rowToModel).toList();
  }

  /// Get recipe by ID
  Future<models.Recipe?> getRecipeById(String id) async {
    final row = await (select(recipes)..where((r) => r.id.equals(id))).getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get favorite recipes
  Future<List<models.Recipe>> getFavoriteRecipes() async {
    final rows = await (select(recipes)..where((r) => r.isFavorite.equals(true))).get();
    return rows.map(_rowToModel).toList();
  }

  /// Get recipes by category
  Future<List<models.Recipe>> getRecipesByCategory(String category) async {
    final rows = await select(recipes).get();
    return rows
        .map(_rowToModel)
        .where((recipe) => recipe.categories.contains(category))
        .toList();
  }

  /// Search recipes by title or ingredients
  Future<List<models.Recipe>> searchRecipes(String query) async {
    final lowercaseQuery = query.toLowerCase();
    final rows = await select(recipes).get();

    return rows
        .map(_rowToModel)
        .where((recipe) {
          // Search in title
          if (recipe.title.toLowerCase().contains(lowercaseQuery)) return true;

          // Search in ingredients
          if (recipe.ingredients.any((ing) =>
              ing.name.toLowerCase().contains(lowercaseQuery))) return true;

          return false;
        })
        .toList();
  }

  /// Get recently added recipes
  Future<List<models.Recipe>> getRecentRecipes({int limit = 10}) async {
    final rows = await (select(recipes)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_rowToModel).toList();
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Insert a new recipe
  Future<int> insertRecipe(models.Recipe recipe) async {
    return await into(recipes).insert(_modelToCompanion(recipe));
  }

  /// Update an existing recipe
  Future<bool> updateRecipe(models.Recipe recipe) async {
    return await update(recipes).replace(_modelToCompanion(recipe));
  }

  /// Delete a recipe
  Future<int> deleteRecipe(String id) async {
    return await (delete(recipes)..where((r) => r.id.equals(id))).go();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    final recipe = await getRecipeById(id);
    if (recipe != null) {
      await updateRecipe(recipe.copyWith(
        isFavorite: !recipe.isFavorite,
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Mark recipe as cooked
  Future<void> markAsCooked(String id, {bool cooked = true}) async {
    final recipe = await getRecipeById(id);
    if (recipe != null) {
      await updateRecipe(recipe.copyWith(
        hasCooked: cooked,
        updatedAt: DateTime.now(),
      ));
    }
  }

  // ============================================================================
  // HELPERS - Convert between DB rows and models
  // ============================================================================

  models.Recipe _rowToModel(Recipe row) {
    return models.Recipe(
      id: row.id,
      title: row.title,
      description: row.description,
      ingredients: (jsonDecode(row.ingredientsJson) as List)
          .map((json) => models.Ingredient.fromJson(json))
          .toList(),
      directions: List<String>.from(jsonDecode(row.directionsJson)),
      categories: List<String>.from(jsonDecode(row.categoriesJson)),
      prepTimeMinutes: row.prepTimeMinutes,
      cookTimeMinutes: row.cookTimeMinutes,
      servings: row.servings,
      difficulty: row.difficulty,
      rating: row.rating,
      photoUrls: List<String>.from(jsonDecode(row.photoUrlsJson)),
      sourceUrl: row.sourceUrl,
      notes: row.notes,
      nutrition: row.nutritionJson != null
          ? models.Nutrition.fromJson(jsonDecode(row.nutritionJson!))
          : null,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isFavorite: row.isFavorite,
      hasCooked: row.hasCooked,
    );
  }

  RecipesCompanion _modelToCompanion(models.Recipe recipe) {
    return RecipesCompanion(
      id: Value(recipe.id),
      title: Value(recipe.title),
      description: Value(recipe.description),
      ingredientsJson: Value(jsonEncode(recipe.ingredients.map((i) => i.toJson()).toList())),
      directionsJson: Value(jsonEncode(recipe.directions)),
      categoriesJson: Value(jsonEncode(recipe.categories)),
      prepTimeMinutes: Value(recipe.prepTimeMinutes),
      cookTimeMinutes: Value(recipe.cookTimeMinutes),
      servings: Value(recipe.servings),
      difficulty: Value(recipe.difficulty),
      rating: Value(recipe.rating),
      photoUrlsJson: Value(jsonEncode(recipe.photoUrls)),
      sourceUrl: Value(recipe.sourceUrl),
      notes: Value(recipe.notes),
      nutritionJson: Value(recipe.nutrition != null ? jsonEncode(recipe.nutrition!.toJson()) : null),
      createdAt: Value(recipe.createdAt),
      updatedAt: Value(recipe.updatedAt),
      isFavorite: Value(recipe.isFavorite),
      hasCooked: Value(recipe.hasCooked),
    );
  }
}
