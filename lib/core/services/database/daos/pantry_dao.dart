import 'package:drift/drift.dart';
import '../database.dart';
import '../../../models/models.dart' as models;

part 'pantry_dao.g.dart';

/// Pantry Data Access Object
@DriftAccessor(tables: [PantryItems])
class PantryDao extends DatabaseAccessor<AppDatabase> with _$PantryDaoMixin {
  PantryDao(AppDatabase database) : super(database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all pantry items
  Future<List<models.PantryItem>> getAllItems() async {
    final rows = await select(pantryItems).get();
    return rows.map(_rowToModel).toList();
  }

  /// Get item by ID
  Future<models.PantryItem?> getItemById(String id) async {
    final row = await (select(pantryItems)..where((i) => i.id.equals(id))).getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get item by name
  Future<models.PantryItem?> getItemByName(String name) async {
    final row = await (select(pantryItems)..where((i) => i.name.equals(name))).getSingleOrNull();
    return row != null ? _rowToModel(row) : null;
  }

  /// Get items by location
  Future<List<models.PantryItem>> getItemsByLocation(models.PantryLocation location) async {
    final rows = await (select(pantryItems)
          ..where((i) => i.location.equals(location.name)))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Get expired items
  Future<List<models.PantryItem>> getExpiredItems() async {
    final now = DateTime.now();
    final rows = await (select(pantryItems)
          ..where((i) => i.expirationDate.isSmallerThanValue(now)))
        .get();
    return rows.map(_rowToModel).toList();
  }

  /// Get items expiring soon (within 7 days)
  Future<List<models.PantryItem>> getExpiringSoonItems() async {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    final rows = await (select(pantryItems)
          ..where((i) =>
              i.expirationDate.isBiggerOrEqualValue(now) &
              i.expirationDate.isSmallerThanValue(sevenDaysFromNow)))
        .get();

    return rows.map(_rowToModel).toList();
  }

  /// Search items by name
  Future<List<models.PantryItem>> searchItems(String query) async {
    final lowercaseQuery = '%${query.toLowerCase()}%';
    final rows = await (select(pantryItems)
          ..where((i) => i.name.lower().like(lowercaseQuery)))
        .get();
    return rows.map(_rowToModel).toList();
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Add a new pantry item
  Future<int> insertItem(models.PantryItem item) async {
    return await into(pantryItems).insert(_modelToCompanion(item));
  }

  /// Update an existing item
  Future<bool> updateItem(models.PantryItem item) async {
    return await update(pantryItems).replace(_modelToCompanion(item));
  }

  /// Delete an item
  Future<int> deleteItem(String id) async {
    return await (delete(pantryItems)..where((i) => i.id.equals(id))).go();
  }

  /// Update item quantity
  Future<void> updateQuantity(String id, double newQuantity) async {
    await (update(pantryItems)..where((i) => i.id.equals(id))).write(
      PantryItemsCompanion(
        quantity: Value(newQuantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Decrease quantity (used when cooking a recipe)
  Future<void> decreaseQuantity(String id, double amount) async {
    final item = await getItemById(id);
    if (item != null && item.quantity != null) {
      final newQuantity = (item.quantity! - amount).clamp(0.0, double.infinity);
      await updateQuantity(id, newQuantity);
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  models.PantryItem _rowToModel(PantryItem row) {
    return models.PantryItem(
      id: row.id,
      name: row.name,
      quantity: row.quantity,
      unit: row.unit,
      location: models.PantryLocation.values.firstWhere(
        (e) => e.name == row.location,
        orElse: () => models.PantryLocation.pantry,
      ),
      expirationDate: row.expirationDate,
      purchaseDate: row.purchaseDate,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PantryItemsCompanion _modelToCompanion(models.PantryItem item) {
    return PantryItemsCompanion(
      id: Value(item.id),
      name: Value(item.name),
      quantity: Value(item.quantity),
      unit: Value(item.unit),
      location: Value(item.location.name),
      expirationDate: Value(item.expirationDate),
      purchaseDate: Value(item.purchaseDate),
      notes: Value(item.notes),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
  }
}
