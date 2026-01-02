import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

/// Core Recipe model representing a cooking recipe
@JsonSerializable()
class Recipe {
  final String id;
  final String title;
  final String? description;
  final List<Ingredient> ingredients;
  final List<String> directions;
  final List<String> categories;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int servings;
  final String? difficulty; // 'easy', 'medium', 'hard'
  final double? rating; // 0-5
  final List<String> photoUrls;
  final String? sourceUrl;
  final String? notes;
  final Nutrition? nutrition;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool hasCooked;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.ingredients,
    required this.directions,
    this.categories = const [],
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.servings = 4,
    this.difficulty,
    this.rating,
    this.photoUrls = const [],
    this.sourceUrl,
    this.notes,
    this.nutrition,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.hasCooked = false,
  });

  /// Total time in minutes
  int? get totalTimeMinutes {
    if (prepTimeMinutes == null && cookTimeMinutes == null) return null;
    return (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);
  }

  /// Create a copy with modified fields
  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    List<Ingredient>? ingredients,
    List<String>? directions,
    List<String>? categories,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    String? difficulty,
    double? rating,
    List<String>? photoUrls,
    String? sourceUrl,
    String? notes,
    Nutrition? nutrition,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? hasCooked,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      directions: directions ?? this.directions,
      categories: categories ?? this.categories,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      photoUrls: photoUrls ?? this.photoUrls,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      notes: notes ?? this.notes,
      nutrition: nutrition ?? this.nutrition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      hasCooked: hasCooked ?? this.hasCooked,
    );
  }

  /// JSON serialization
  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}

/// Ingredient model
@JsonSerializable()
class Ingredient {
  final String name;
  final double? quantity;
  final String? unit;
  final String? notes;
  final String? linkedRecipeId; // For sub-recipes

  Ingredient({
    required this.name,
    this.quantity,
    this.unit,
    this.notes,
    this.linkedRecipeId,
  });

  /// Display string for ingredient
  String get displayText {
    final buffer = StringBuffer();
    if (quantity != null) {
      // Format quantity nicely (remove .0 for whole numbers)
      final qty = quantity! % 1 == 0 ? quantity!.toInt().toString() : quantity.toString();
      buffer.write(qty);
      buffer.write(' ');
    }
    if (unit != null) {
      buffer.write(unit);
      buffer.write(' ');
    }
    buffer.write(name);
    if (notes != null) {
      buffer.write(' (');
      buffer.write(notes);
      buffer.write(')');
    }
    return buffer.toString();
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) => _$IngredientFromJson(json);
  Map<String, dynamic> toJson() => _$IngredientToJson(this);
}

/// Nutrition information
@JsonSerializable()
class Nutrition {
  final int? calories;
  final double? protein; // grams
  final double? carbs; // grams
  final double? fat; // grams
  final double? fiber; // grams
  final int? sodium; // mg

  Nutrition({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sodium,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => _$NutritionFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionToJson(this);
}
