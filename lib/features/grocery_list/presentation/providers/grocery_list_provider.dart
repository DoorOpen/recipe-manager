import 'package:flutter/foundation.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/grocery_repository.dart';

/// Provider for grocery list state management
class GroceryListProvider extends ChangeNotifier {
  final GroceryRepository _repository;

  GroceryListProvider(this._repository) {
    loadLists();
  }

  List<GroceryList> _lists = [];
  bool _isLoading = false;
  String? _error;

  List<GroceryList> get lists => _lists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lists = await _repository.getAllLists();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createList(String name) async {
    try {
      await _repository.createList(name);
      await loadLists();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteList(String id) async {
    try {
      await _repository.deleteList(id);
      await loadLists();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadLists();
  }
}
