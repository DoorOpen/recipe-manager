import 'package:json_annotation/json_annotation.dart';

part 'grocery_list.g.dart';

/// Grocery list model
@JsonSerializable()
class GroceryList {
  final String id;
  final String name;
  final List<GroceryItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroceryList({
    required this.id,
    required this.name,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get unchecked items count
  int get uncheckedCount => items.where((item) => !item.isChecked).length;

  /// Get checked items count
  int get checkedCount => items.where((item) => item.isChecked).length;

  /// Check if all items are checked
  bool get isComplete => items.isNotEmpty && items.every((item) => item.isChecked);

  GroceryList copyWith({
    String? id,
    String? name,
    List<GroceryItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryList(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GroceryList.fromJson(Map<String, dynamic> json) => _$GroceryListFromJson(json);
  Map<String, dynamic> toJson() => _$GroceryListToJson(this);
}

/// Individual grocery item
@JsonSerializable()
class GroceryItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final GroceryCategory category;
  final bool isChecked;
  final List<String>? originRecipeIds; // Recipes that contributed this item
  final String? notes;

  GroceryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.category = GroceryCategory.other,
    this.isChecked = false,
    this.originRecipeIds,
    this.notes,
  });

  /// Display text for the item
  String get displayText {
    final buffer = StringBuffer();
    if (quantity != null) {
      final qty = quantity! % 1 == 0 ? quantity!.toInt().toString() : quantity.toString();
      buffer.write(qty);
      buffer.write(' ');
    }
    if (unit != null) {
      buffer.write(unit);
      buffer.write(' ');
    }
    buffer.write(name);
    return buffer.toString();
  }

  GroceryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    GroceryCategory? category,
    bool? isChecked,
    List<String>? originRecipeIds,
    String? notes,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      originRecipeIds: originRecipeIds ?? this.originRecipeIds,
      notes: notes ?? this.notes,
    );
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) => _$GroceryItemFromJson(json);
  Map<String, dynamic> toJson() => _$GroceryItemToJson(this);
}

/// Grocery categories (aisles)
enum GroceryCategory {
  produce,
  dairy,
  meat,
  bakery,
  frozen,
  pantry,
  beverages,
  snacks,
  condiments,
  spices,
  other;

  String get displayName {
    switch (this) {
      case GroceryCategory.produce:
        return 'Produce';
      case GroceryCategory.dairy:
        return 'Dairy';
      case GroceryCategory.meat:
        return 'Meat & Seafood';
      case GroceryCategory.bakery:
        return 'Bakery';
      case GroceryCategory.frozen:
        return 'Frozen';
      case GroceryCategory.pantry:
        return 'Pantry';
      case GroceryCategory.beverages:
        return 'Beverages';
      case GroceryCategory.snacks:
        return 'Snacks';
      case GroceryCategory.condiments:
        return 'Condiments';
      case GroceryCategory.spices:
        return 'Spices & Herbs';
      case GroceryCategory.other:
        return 'Other';
    }
  }
}
