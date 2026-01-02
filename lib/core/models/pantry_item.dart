import 'package:json_annotation/json_annotation.dart';

part 'pantry_item.g.dart';

/// Pantry/inventory item
@JsonSerializable()
class PantryItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final PantryLocation location;
  final DateTime? expirationDate;
  final DateTime? purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PantryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.location = PantryLocation.pantry,
    this.expirationDate,
    this.purchaseDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if item is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  /// Check if item is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return expirationDate!.isAfter(now) && expirationDate!.isBefore(sevenDaysFromNow);
  }

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

  PantryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    PantryLocation? location,
    DateTime? expirationDate,
    DateTime? purchaseDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      location: location ?? this.location,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PantryItem.fromJson(Map<String, dynamic> json) => _$PantryItemFromJson(json);
  Map<String, dynamic> toJson() => _$PantryItemToJson(this);
}

/// Storage location for pantry items
enum PantryLocation {
  pantry,
  refrigerator,
  freezer,
  spiceRack,
  other;

  String get displayName {
    switch (this) {
      case PantryLocation.pantry:
        return 'Pantry';
      case PantryLocation.refrigerator:
        return 'Refrigerator';
      case PantryLocation.freezer:
        return 'Freezer';
      case PantryLocation.spiceRack:
        return 'Spice Rack';
      case PantryLocation.other:
        return 'Other';
    }
  }
}
