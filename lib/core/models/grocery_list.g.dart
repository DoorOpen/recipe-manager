// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroceryList _$GroceryListFromJson(Map<String, dynamic> json) => GroceryList(
  id: json['id'] as String,
  name: json['name'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GroceryListToJson(GroceryList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

GroceryItem _$GroceryItemFromJson(Map<String, dynamic> json) => GroceryItem(
  id: json['id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  category:
      $enumDecodeNullable(_$GroceryCategoryEnumMap, json['category']) ??
      GroceryCategory.other,
  isChecked: json['isChecked'] as bool? ?? false,
  originRecipeIds: (json['originRecipeIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$GroceryItemToJson(GroceryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'category': _$GroceryCategoryEnumMap[instance.category]!,
      'isChecked': instance.isChecked,
      'originRecipeIds': instance.originRecipeIds,
      'notes': instance.notes,
    };

const _$GroceryCategoryEnumMap = {
  GroceryCategory.produce: 'produce',
  GroceryCategory.dairy: 'dairy',
  GroceryCategory.meat: 'meat',
  GroceryCategory.bakery: 'bakery',
  GroceryCategory.frozen: 'frozen',
  GroceryCategory.pantry: 'pantry',
  GroceryCategory.beverages: 'beverages',
  GroceryCategory.snacks: 'snacks',
  GroceryCategory.condiments: 'condiments',
  GroceryCategory.spices: 'spices',
  GroceryCategory.other: 'other',
};
