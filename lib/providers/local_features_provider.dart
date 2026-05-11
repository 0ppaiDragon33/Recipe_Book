// lib/providers/local_features_provider.dart
// Manages: recipe collections, personal notes, shopping list, recently viewed.
// All data is local-only (shared_preferences via LocalStorageService).

import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';

class LocalFeaturesProvider extends ChangeNotifier {
  Map<String, RecipeCollection> _collections = {};
  Map<String, String> _notes = {};
  List<ShoppingItem> _shoppingList = [];
  List<String> _recentlyViewed = [];
  bool _initialized = false;

  bool get initialized => _initialized;
  Map<String, RecipeCollection> get collections => Map.unmodifiable(_collections);
  Map<String, String> get notes => Map.unmodifiable(_notes);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  List<String> get recentlyViewed => List.unmodifiable(_recentlyViewed);
  int get shoppingUncheckedCount =>
      _shoppingList.where((e) => !e.checked).length;

  Future<void> initialize() async {
    if (_initialized) return;
    await LocalStorageService.instance.init();
    _collections   = LocalStorageService.instance.getCollections();
    _notes         = LocalStorageService.instance.getNotes();
    _shoppingList  = LocalStorageService.instance.getShoppingList();
    _recentlyViewed = LocalStorageService.instance.getRecentlyViewed();
    _initialized = true;
    notifyListeners();
  }

  // ─── Collections ─────────────────────────────────────────────────────────
  Future<RecipeCollection> createCollection(String name) async {
    final col = await LocalStorageService.instance.createCollection(name);
    _collections = LocalStorageService.instance.getCollections();
    notifyListeners();
    return col;
  }

  Future<void> renameCollection(String id, String name) async {
    await LocalStorageService.instance.renameCollection(id, name);
    _collections = LocalStorageService.instance.getCollections();
    notifyListeners();
  }

  Future<void> deleteCollection(String id) async {
    await LocalStorageService.instance.deleteCollection(id);
    _collections = LocalStorageService.instance.getCollections();
    notifyListeners();
  }

  Future<void> addRecipeToCollection(String colId, String recipeId) async {
    await LocalStorageService.instance.addRecipeToCollection(colId, recipeId);
    _collections = LocalStorageService.instance.getCollections();
    notifyListeners();
  }

  Future<void> removeRecipeFromCollection(String colId, String recipeId) async {
    await LocalStorageService.instance
        .removeRecipeFromCollection(colId, recipeId);
    _collections = LocalStorageService.instance.getCollections();
    notifyListeners();
  }

  List<String> collectionsForRecipe(String recipeId) => _collections.values
      .where((c) => c.recipeIds.contains(recipeId))
      .map((c) => c.id)
      .toList();

  // ─── Notes ────────────────────────────────────────────────────────────────
  String? getNote(String recipeId) => _notes[recipeId];

  Future<void> saveNote(String recipeId, String note) async {
    await LocalStorageService.instance.saveNote(recipeId, note);
    _notes = LocalStorageService.instance.getNotes();
    notifyListeners();
  }

  // ─── Shopping List ────────────────────────────────────────────────────────
  Future<void> addItems(List<String> items) async {
    await LocalStorageService.instance.addShoppingItems(items);
    _shoppingList = LocalStorageService.instance.getShoppingList();
    notifyListeners();
  }

  Future<void> toggleItem(String id) async {
    await LocalStorageService.instance.toggleShoppingItem(id);
    _shoppingList = LocalStorageService.instance.getShoppingList();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    await LocalStorageService.instance.removeShoppingItem(id);
    _shoppingList = LocalStorageService.instance.getShoppingList();
    notifyListeners();
  }

  Future<void> clearChecked() async {
    await LocalStorageService.instance.clearCheckedItems();
    _shoppingList = LocalStorageService.instance.getShoppingList();
    notifyListeners();
  }

  // ─── Recently Viewed ──────────────────────────────────────────────────────
  Future<void> recordView(String recipeId) async {
    await LocalStorageService.instance.recordView(recipeId);
    _recentlyViewed = LocalStorageService.instance.getRecentlyViewed();
    notifyListeners();
  }

  Future<void> clearRecentlyViewed() async {
    await LocalStorageService.instance.clearRecentlyViewed();
    _recentlyViewed = [];
    notifyListeners();
  }
}
