import '../services/database/database.dart';
import '../models/models.dart' as models;

/// Repository for grocery list data access
class GroceryRepository {
  final AppDatabase _database;

  GroceryRepository(this._database);

  // ============================================================================
  // LIST QUERIES
  // ============================================================================

  /// Get all grocery lists
  Future<List<models.GroceryList>> getAllLists() async {
    return await _database.groceryDao.getAllLists();
  }

  /// Get list by ID
  Future<models.GroceryList?> getListById(String id) async {
    return await _database.groceryDao.getListById(id);
  }

  // ============================================================================
  // ITEM QUERIES
  // ============================================================================

  /// Get all items for a specific list
  Future<List<models.GroceryItem>> getItemsForList(String listId) async {
    return await _database.groceryDao.getItemsForList(listId);
  }

  /// Get unchecked items for a list
  Future<List<models.GroceryItem>> getUncheckedItems(String listId) async {
    return await _database.groceryDao.getUncheckedItems(listId);
  }

  /// Get items by category
  Future<List<models.GroceryItem>> getItemsByCategory(
    String listId,
    models.GroceryCategory category,
  ) async {
    return await _database.groceryDao.getItemsByCategory(listId, category);
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Create a new list
  Future<String> createList(String name) async {
    return await _database.groceryDao.createList(name);
  }

  /// Update list name
  Future<void> updateListName(String id, String name) async {
    await _database.groceryDao.updateListName(id, name);
  }

  /// Delete a list and all its items
  Future<void> deleteList(String id) async {
    await _database.groceryDao.deleteList(id);
  }

  /// Add item to list
  Future<void> addItem(String listId, models.GroceryItem item) async {
    await _database.groceryDao.addItem(listId, item);
  }

  /// Update an item
  Future<void> updateItem(String listId, models.GroceryItem item) async {
    await _database.groceryDao.updateItem(listId, item);
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    await _database.groceryDao.deleteItem(itemId);
  }

  /// Toggle item checked status
  Future<void> toggleItemChecked(String itemId) async {
    await _database.groceryDao.toggleItemChecked(itemId);
  }

  /// Clear all checked items from a list
  Future<void> clearCheckedItems(String listId) async {
    await _database.groceryDao.clearCheckedItems(listId);
  }
}
