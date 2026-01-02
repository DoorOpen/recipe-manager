// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
      .toList(),
  directions: (json['directions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt(),
  cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
  servings: (json['servings'] as num?)?.toInt() ?? 4,
  difficulty: json['difficulty'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  photoUrls:
      (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sourceUrl: json['sourceUrl'] as String?,
  notes: json['notes'] as String?,
  nutrition: json['nutrition'] == null
      ? null
      : Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isFavorite: json['isFavorite'] as bool? ?? false,
  hasCooked: json['hasCooked'] as bool? ?? false,
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'ingredients': instance.ingredients,
  'directions': instance.directions,
  'categories': instance.categories,
  'prepTimeMinutes': instance.prepTimeMinutes,
  'cookTimeMinutes': instance.cookTimeMinutes,
  'servings': instance.servings,
  'difficulty': instance.difficulty,
  'rating': instance.rating,
  'photoUrls': instance.photoUrls,
  'sourceUrl': instance.sourceUrl,
  'notes': instance.notes,
  'nutrition': instance.nutrition,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isFavorite': instance.isFavorite,
  'hasCooked': instance.hasCooked,
};

Ingredient _$IngredientFromJson(Map<String, dynamic> json) => Ingredient(
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  notes: json['notes'] as String?,
  linkedRecipeId: json['linkedRecipeId'] as String?,
);

Map<String, dynamic> _$IngredientToJson(Ingredient instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'notes': instance.notes,
      'linkedRecipeId': instance.linkedRecipeId,
    };

Nutrition _$NutritionFromJson(Map<String, dynamic> json) => Nutrition(
  calories: (json['calories'] as num?)?.toInt(),
  protein: (json['protein'] as num?)?.toDouble(),
  carbs: (json['carbs'] as num?)?.toDouble(),
  fat: (json['fat'] as num?)?.toDouble(),
  fiber: (json['fiber'] as num?)?.toDouble(),
  sodium: (json['sodium'] as num?)?.toInt(),
);

Map<String, dynamic> _$NutritionToJson(Nutrition instance) => <String, dynamic>{
  'calories': instance.calories,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
  'fiber': instance.fiber,
  'sodium': instance.sodium,
};
