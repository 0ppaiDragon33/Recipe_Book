// lib/services/local_storage_service.dart
// Handles all local-only persistence: theme, font size, collections,
// notes, shopping list, recently viewed, display name.
// Uses only shared_preferences (no Firebase changes needed).

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();
  static final instance = LocalStorageService._();

  // ─── Keys ────────────────────────────────────────────────────────────────
  static const _kTheme = 'pref_theme_mode'; // 'dark'|'light'|'auto'
  static const _kFontSize = 'pref_font_size'; // double 0.8–1.4
  static const _kDefCategory = 'pref_def_category'; // string
  static const _kDefCuisine = 'pref_def_cuisine'; // string
  static const _kDisplayName = 'pref_display_name'; // string
  static const _kCollections = 'local_collections'; // json map
  static const _kNotes = 'local_notes'; // json map
  static const _kShoppingList = 'local_shopping_list'; // json list
  static const _kRecentlyViewed = 'local_recently_viewed'; // json list of ids

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'Call LocalStorageService.instance.init() first');
    return _prefs!;
  }

  // ─── Theme ───────────────────────────────────────────────────────────────
  String getThemeMode() => _p.getString(_kTheme) ?? 'dark';
  Future<void> setThemeMode(String mode) => _p.setString(_kTheme, mode);

  // ─── Font size ────────────────────────────────────────────────────────────
  double getFontScale() => _p.getDouble(_kFontSize) ?? 1.0;
  Future<void> setFontScale(double v) => _p.setDouble(_kFontSize, v);

  // ─── Default preferences ─────────────────────────────────────────────────
  String getDefaultCategory() => _p.getString(_kDefCategory) ?? 'All';
  Future<void> setDefaultCategory(String v) => _p.setString(_kDefCategory, v);

  String getDefaultCuisine() => _p.getString(_kDefCuisine) ?? 'Any';
  Future<void> setDefaultCuisine(String v) => _p.setString(_kDefCuisine, v);

  // ─── Display name ─────────────────────────────────────────────────────────
  String? getDisplayName() => _p.getString(_kDisplayName);
  Future<void> setDisplayName(String v) => _p.setString(_kDisplayName, v);

  // ─── Collections ─────────────────────────────────────────────────────────
  // Map<collectionId, RecipeCollection>
  Map<String, RecipeCollection> getCollections() {
    final raw = _p.getString(_kCollections);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, RecipeCollection.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCollections(Map<String, RecipeCollection> cols) async {
    final map = cols.map((k, v) => MapEntry(k, v.toJson()));
    await _p.setString(_kCollections, jsonEncode(map));
  }

  Future<RecipeCollection> createCollection(String name) async {
    final cols = getCollections();
    final id = 'col_${DateTime.now().millisecondsSinceEpoch}';
    final col = RecipeCollection(id: id, name: name, recipeIds: const []);
    cols[id] = col;
    await saveCollections(cols);
    return col;
  }

  Future<void> renameCollection(String id, String name) async {
    final cols = getCollections();
    if (cols.containsKey(id)) {
      cols[id] =
          RecipeCollection(id: id, name: name, recipeIds: cols[id]!.recipeIds);
      await saveCollections(cols);
    }
  }

  Future<void> deleteCollection(String id) async {
    final cols = getCollections();
    cols.remove(id);
    await saveCollections(cols);
  }

  Future<void> addRecipeToCollection(String colId, String recipeId) async {
    final cols = getCollections();
    if (!cols.containsKey(colId)) return;
    final ids = List<String>.from(cols[colId]!.recipeIds);
    if (!ids.contains(recipeId)) ids.add(recipeId);
    cols[colId] =
        RecipeCollection(id: colId, name: cols[colId]!.name, recipeIds: ids);
    await saveCollections(cols);
  }

  Future<void> removeRecipeFromCollection(String colId, String recipeId) async {
    final cols = getCollections();
    if (!cols.containsKey(colId)) return;
    final ids = List<String>.from(cols[colId]!.recipeIds)..remove(recipeId);
    cols[colId] =
        RecipeCollection(id: colId, name: cols[colId]!.name, recipeIds: ids);
    await saveCollections(cols);
  }

  // ─── Personal Notes ───────────────────────────────────────────────────────
  Map<String, String> getNotes() {
    final raw = _p.getString(_kNotes);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw));
    } catch (_) {
      return {};
    }
  }

  String? getNote(String recipeId) => getNotes()[recipeId];

  Future<void> saveNote(String recipeId, String note) async {
    final notes = getNotes();
    if (note.isEmpty) {
      notes.remove(recipeId);
    } else {
      notes[recipeId] = note;
    }
    await _p.setString(_kNotes, jsonEncode(notes));
  }

  // ─── Shopping List ────────────────────────────────────────────────────────
  List<ShoppingItem> getShoppingList() {
    final raw = _p.getString(_kShoppingList);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => ShoppingItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveShoppingList(List<ShoppingItem> items) async {
    await _p.setString(
        _kShoppingList, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> addShoppingItems(List<String> items) async {
    final list = getShoppingList();
    for (final item in items) {
      if (!list.any((e) => e.text.toLowerCase() == item.toLowerCase())) {
        list.add(ShoppingItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_${list.length}',
            text: item,
            checked: false));
      }
    }
    await saveShoppingList(list);
  }

  Future<void> toggleShoppingItem(String id) async {
    final list = getShoppingList();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx != -1) {
      list[idx] = ShoppingItem(
          id: list[idx].id, text: list[idx].text, checked: !list[idx].checked);
      await saveShoppingList(list);
    }
  }

  Future<void> removeShoppingItem(String id) async {
    final list = getShoppingList()..removeWhere((e) => e.id == id);
    await saveShoppingList(list);
  }

  Future<void> clearCheckedItems() async {
    final list = getShoppingList()..removeWhere((e) => e.checked);
    await saveShoppingList(list);
  }

  // ─── Recently Viewed ──────────────────────────────────────────────────────
  List<String> getRecentlyViewed() {
    return _p.getStringList(_kRecentlyViewed) ?? [];
  }

  Future<void> recordView(String recipeId) async {
    final list = getRecentlyViewed();
    list.remove(recipeId);
    list.insert(0, recipeId);
    if (list.length > 20) list.removeLast();
    await _p.setStringList(_kRecentlyViewed, list);
  }

  Future<void> clearRecentlyViewed() async {
    await _p.remove(_kRecentlyViewed);
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

@immutable
class RecipeCollection {
  final String id;
  final String name;
  final List<String> recipeIds;

  const RecipeCollection({
    required this.id,
    required this.name,
    required this.recipeIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recipeIds': recipeIds,
      };

  factory RecipeCollection.fromJson(Map<String, dynamic> j) => RecipeCollection(
        id: j['id'] as String,
        name: j['name'] as String,
        recipeIds: List<String>.from(j['recipeIds'] ?? []),
      );
}

@immutable
class ShoppingItem {
  final String id;
  final String text;
  final bool checked;

  const ShoppingItem({
    required this.id,
    required this.text,
    required this.checked,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'checked': checked,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
        id: j['id'] as String,
        text: j['text'] as String,
        checked: j['checked'] as bool? ?? false,
      );
}
