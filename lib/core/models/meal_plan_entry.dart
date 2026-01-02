import 'package:json_annotation/json_annotation.dart';

part 'meal_plan_entry.g.dart';

/// Represents a planned meal on the calendar
@JsonSerializable()
class MealPlanEntry {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String? recipeId; // Reference to recipe
  final String? customNote; // For non-recipe entries like "Dinner out"
  final int? servings; // Number of servings to make (null = use recipe default)
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlanEntry({
    required this.id,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.customNote,
    this.servings,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this is a recipe-based entry
  bool get isRecipe => recipeId != null;

  /// Check if this is a custom note entry
  bool get isCustomNote => customNote != null && recipeId == null;

  MealPlanEntry copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    String? recipeId,
    String? customNote,
    int? servings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealPlanEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      customNote: customNote ?? this.customNote,
      servings: servings ?? this.servings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => _$MealPlanEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MealPlanEntryToJson(this);
}

/// Meal type enum
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
