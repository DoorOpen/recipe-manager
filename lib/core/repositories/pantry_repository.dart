import '../services/database/database.dart';
import '../models/models.dart' as models;

/// Repository for pantry item data access
class PantryRepository {
  final AppDatabase _database;

  PantryRepository(this._database);

  // ============================================================================
  // QUERIES
  // ============================================================================

  /// Get all pantry items
  Future<List<models.PantryItem>> getAllItems() async {
    return await _database.pantryDao.getAllItems();
  }

  /// Get item by ID
  Future<models.PantryItem?> getItemById(String id) async {
    return await _database.pantryDao.getItemById(id);
  }

  /// Get item by name
  Future<models.PantryItem?> getItemByName(String name) async {
    return await _database.pantryDao.getItemByName(name);
  }

  /// Get items by location
  Future<List<models.PantryItem>> getItemsByLocation(
    models.PantryLocation location,
  ) async {
    return await _database.pantryDao.getItemsByLocation(location);
  }

  /// Get expired items
  Future<List<models.PantryItem>> getExpiredItems() async {
    return await _database.pantryDao.getExpiredItems();
  }

  /// Get items expiring soon (within 7 days)
  Future<List<models.PantryItem>> getExpiringSoonItems() async {
    return await _database.pantryDao.getExpiringSoonItems();
  }

  /// Search items by query
  Future<List<models.PantryItem>> searchItems(String query) async {
    return await _database.pantryDao.searchItems(query);
  }

  // ============================================================================
  // MUTATIONS
  // ============================================================================

  /// Insert a new pantry item
  Future<void> insertItem(models.PantryItem item) async {
    await _database.pantryDao.insertItem(item);
  }

  /// Update an existing item
  Future<void> updateItem(models.PantryItem item) async {
    await _database.pantryDao.updateItem(item);
  }

  /// Delete an item
  Future<void> deleteItem(String id) async {
    await _database.pantryDao.deleteItem(id);
  }

  /// Update item quantity
  Future<void> updateQuantity(String id, double quantity) async {
    await _database.pantryDao.updateQuantity(id, quantity);
  }

  /// Decrease item quantity (e.g., after using in a recipe)
  Future<void> decreaseQuantity(String id, double amount) async {
    await _database.pantryDao.decreaseQuantity(id, amount);
  }
}
