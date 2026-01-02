// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealPlanEntry _$MealPlanEntryFromJson(Map<String, dynamic> json) =>
    MealPlanEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: $enumDecode(_$MealTypeEnumMap, json['mealType']),
      recipeId: json['recipeId'] as String?,
      customNote: json['customNote'] as String?,
      servings: (json['servings'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MealPlanEntryToJson(MealPlanEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'mealType': _$MealTypeEnumMap[instance.mealType]!,
      'recipeId': instance.recipeId,
      'customNote': instance.customNote,
      'servings': instance.servings,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};
