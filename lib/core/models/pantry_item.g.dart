// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PantryItem _$PantryItemFromJson(Map<String, dynamic> json) => PantryItem(
  id: json['id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  location:
      $enumDecodeNullable(_$PantryLocationEnumMap, json['location']) ??
      PantryLocation.pantry,
  expirationDate: json['expirationDate'] == null
      ? null
      : DateTime.parse(json['expirationDate'] as String),
  purchaseDate: json['purchaseDate'] == null
      ? null
      : DateTime.parse(json['purchaseDate'] as String),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PantryItemToJson(PantryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'location': _$PantryLocationEnumMap[instance.location]!,
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$PantryLocationEnumMap = {
  PantryLocation.pantry: 'pantry',
  PantryLocation.refrigerator: 'refrigerator',
  PantryLocation.freezer: 'freezer',
  PantryLocation.spiceRack: 'spiceRack',
  PantryLocation.other: 'other',
};
