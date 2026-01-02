import 'dart:convert';
import 'package:drift/drift.dart';
import '../database.dart';
import '../../../models/models.dart' as models;

part 'grocery_dao.g.dart';

/// Grocery List Data Access Object
@DriftAccessor(tables: [GroceryLists, GroceryItems])
class GroceryDao extends DatabaseAccessor<AppDatabase> with _$GroceryDaoMixin {
  GroceryDao(AppDatabase database) : super(database);

  // ============================================================================
  // LIST QUERIES
  // ============================================================================

  /// Get all grocery lists
  Future<List<models.GroceryList>> getAllLists() async {
    final lists = await select(groceryLists).get();

    return Future.wait(lists.map((list) async {
      final items = await getItemsForList(list.id);
      return _listRowToModel(list, items);
    }));
  }

  /// Get list by ID
  Future<models.GroceryList?> getListById(String id) async {
    final list = await (select(groceryLists)..where((l) => l.id.equals(id))).getSingleOrNull();
    if (list == null) return null;

    final items = await getItemsForList(id);
    return _listRowToModel(list, items);
  }

  // ============================================================================
  // ITEM QUERIES
  // ============================================================================

  /// Get all items for a specific list
  Future<List<models.GroceryItem>> getItemsForList(String listId) async {
    final rows = await (select(groceryItems)..where((i) => i.listId.equals(listId))).get();
    return rows.map(_itemRowToModel).toList();
  }

  /// Get unchecked items for a list
  Future<List<models.GroceryItem>> getUncheckedItems(String listId) async {
    final rows = await (select(groceryItems)
          ..where((i) => i.listId.equals(listId) & i.isChecked.equals(false)))
        .get();
    return rows.map(_itemRowToModel).toList();
  }

  /// Get items by category
  Future<List<models.GroceryItem>> getItemsByCategory(String listId, models.GroceryCategory category) async {
    final rows = await (select(groceryItems)
          ..where((i) => i.listId.equals(listId) & i.category.equals(category.name)))
        .get();
    return rows.map(_itemRowToModel).toList();
  }

  // ============================================================================
  // LIST MUTATIONS
  // ============================================================================

  /// Create a new grocery list
  Future<String> createList(String name) async {
    final now = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await into(groceryLists).insert(GroceryListsCompanion.insert(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    ));

    return id;
  }

  /// Update list name
  Future<bool> updateListName(String id, String newName) async {
    return await (update(groceryLists)..where((l) => l.id.equals(id))).write(
      GroceryListsCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ),
    ) >
        0;
  }

  /// Delete a grocery list (and all its items)
  Future<void> deleteList(String id) async {
    await (delete(groceryItems)..where((i) => i.listId.equals(id))).go();
    await (delete(groceryLists)..where((l) => l.id.equals(id))).go();
  }

  // ============================================================================
  // ITEM MUTATIONS
  // ============================================================================

  /// Add item to list
  Future<int> addItem(String listId, models.GroceryItem item) async {
    return await into(groceryItems).insert(_itemModelToCompanion(listId, item));
  }

  /// Update item
  Future<bool> updateItem(String listId, models.GroceryItem item) async {
    return await update(groceryItems).replace(_itemModelToCompanion(listId, item));
  }

  /// Delete item
  Future<int> deleteItem(String itemId) async {
    return await (delete(groceryItems)..where((i) => i.id.equals(itemId))).go();
  }

  /// Toggle item checked status
  Future<void> toggleItemChecked(String itemId) async {
    final item = await (select(groceryItems)..where((i) => i.id.equals(itemId))).getSingle();
    await (update(groceryItems)..where((i) => i.id.equals(itemId))).write(
      GroceryItemsCompanion(
        isChecked: Value(!item.isChecked),
      ),
    );
  }

  /// Clear all checked items from a list
  Future<int> clearCheckedItems(String listId) async {
    return await (delete(groceryItems)
          ..where((i) => i.listId.equals(listId) & i.isChecked.equals(true)))
        .go();
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  models.GroceryList _listRowToModel(GroceryList row, List<models.GroceryItem> items) {
    return models.GroceryList(
      id: row.id,
      name: row.name,
      items: items,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  models.GroceryItem _itemRowToModel(GroceryItem row) {
    return models.GroceryItem(
      id: row.id,
      name: row.name,
      quantity: row.quantity,
      unit: row.unit,
      category: models.GroceryCategory.values.firstWhere(
        (e) => e.name == row.category,
        orElse: () => models.GroceryCategory.other,
      ),
      isChecked: row.isChecked,
      originRecipeIds: row.originRecipeIdsJson != null
          ? List<String>.from(jsonDecode(row.originRecipeIdsJson!))
          : null,
      notes: row.notes,
    );
  }

  GroceryItemsCompanion _itemModelToCompanion(String listId, models.GroceryItem item) {
    return GroceryItemsCompanion(
      id: Value(item.id),
      listId: Value(listId),
      name: Value(item.name),
      quantity: Value(item.quantity),
      unit: Value(item.unit),
      category: Value(item.category.name),
      isChecked: Value(item.isChecked),
      originRecipeIdsJson: Value(
        item.originRecipeIds != null ? jsonEncode(item.originRecipeIds) : null,
      ),
      notes: Value(item.notes),
    );
  }
}
