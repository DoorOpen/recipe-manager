import 'package:flutter/foundation.dart';
import '../../../../core/models/models.dart' as models;
import '../../../../core/repositories/pantry_repository.dart';

/// Provider for pantry state management
class PantryProvider extends ChangeNotifier {
  final PantryRepository _repository;

  PantryProvider(this._repository) {
    loadItems();
  }

  // State
  List<models.PantryItem> _items = [];
  List<models.PantryItem> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  models.PantryLocation? _selectedLocation;
  models.PantryLocation? get selectedLocation => _selectedLocation;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _showExpiredOnly = false;
  bool get showExpiredOnly => _showExpiredOnly;

  bool _showExpiringSoonOnly = false;
  bool get showExpiringSoonOnly => _showExpiringSoonOnly;

  /// Load all items
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _items = await _repository.searchItems(_searchQuery);
      } else if (_showExpiredOnly) {
        _items = await _repository.getExpiredItems();
      } else if (_showExpiringSoonOnly) {
        _items = await _repository.getExpiringSoonItems();
      } else if (_selectedLocation != null) {
        _items = await _repository.getItemsByLocation(_selectedLocation!);
      } else {
        _items = await _repository.getAllItems();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new item
  Future<void> addItem(models.PantryItem item) async {
    try {
      await _repository.insertItem(item);
      await loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an existing item
  Future<void> updateItem(models.PantryItem item) async {
    try {
      await _repository.updateItem(item);
      await loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete an item
  Future<void> deleteItem(String id) async {
    try {
      await _repository.deleteItem(id);
      await loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String id, double quantity) async {
    try {
      await _repository.updateQuantity(id, quantity);
      await loadItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Filter by location
  void filterByLocation(models.PantryLocation? location) {
    _selectedLocation = location;
    _showExpiredOnly = false;
    _showExpiringSoonOnly = false;
    loadItems();
  }

  /// Search items
  void searchItems(String query) {
    _searchQuery = query;
    _selectedLocation = null;
    _showExpiredOnly = false;
    _showExpiringSoonOnly = false;
    loadItems();
  }

  /// Show expired items only
  void toggleExpiredOnly() {
    _showExpiredOnly = !_showExpiredOnly;
    _showExpiringSoonOnly = false;
    _selectedLocation = null;
    _searchQuery = '';
    loadItems();
  }

  /// Show expiring soon items only
  void toggleExpiringSoonOnly() {
    _showExpiringSoonOnly = !_showExpiringSoonOnly;
    _showExpiredOnly = false;
    _selectedLocation = null;
    _searchQuery = '';
    loadItems();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedLocation = null;
    _searchQuery = '';
    _showExpiredOnly = false;
    _showExpiringSoonOnly = false;
    loadItems();
  }

  /// Refresh
  Future<void> refresh() async {
    await loadItems();
  }
}
