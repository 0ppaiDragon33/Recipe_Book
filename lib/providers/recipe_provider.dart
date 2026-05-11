// lib/providers/recipe_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  Set<String> _favoriteIds = {};
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Default';
  bool _isLoading = true;
  String? _error;

  // Guard against double-initializing (e.g. user skips PIN then sets one later)
  bool _initialized = false;
  StreamSubscription<List<Recipe>>? _recipesSub;
  StreamSubscription<Set<String>>? _favoritesSub;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  List<Recipe> get recipes => _applyFilters(_recipes);
  List<Recipe> get favoriteRecipes =>
      _recipes.where((r) => r.isFavorite).toList();

  Future<void> initialize() async {
    // Prevent duplicate Firestore listeners across re-auth or PIN flows
    if (_initialized) return;
    _initialized = true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favoriteIds = await FirestoreService.instance.loadFavoriteIds();

      _recipesSub = FirestoreService.instance.recipesStream().listen(
        (recipes) {
          _recipes = recipes
              .map((r) => r.copyWith(isFavorite: _favoriteIds.contains(r.id)))
              .toList();
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (_) {
          _error = 'Failed to load recipes. Check your connection.';
          _isLoading = false;
          notifyListeners();
        },
      );

      _favoritesSub = FirestoreService.instance.favoritesStream().listen((ids) {
        _favoriteIds = ids;
        _recipes = _recipes
            .map((r) => r.copyWith(isFavorite: ids.contains(r.id)))
            .toList();
        notifyListeners();
      });
    } catch (_) {
      _error = 'Failed to connect to database.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Call this on sign-out so the next sign-in can re-initialize cleanly
  void reset() {
    _recipesSub?.cancel();
    _favoritesSub?.cancel();
    _recipesSub = null;
    _favoritesSub = null;
    _initialized = false;
    _recipes = [];
    _favoriteIds = {};
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortBy(String s) {
    _sortBy = s;
    notifyListeners();
  }

  List<Recipe> _applyFilters(List<Recipe> source) {
    List<Recipe> result = List.from(source);
    if (_selectedCategory != 'All') {
      result = result.where((r) => r.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              r.category.toLowerCase().contains(q) ||
              r.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
    switch (_sortBy) {
      case 'Rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Time':
        result.sort((a, b) => a.totalTime.compareTo(b.totalTime));
        break;
      case 'Name':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return result;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _recipes.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final newVal = !_recipes[index].isFavorite;
    _recipes[index] = _recipes[index].copyWith(isFavorite: newVal);
    notifyListeners();
    if (newVal) {
      await FirestoreService.instance.addFavorite(id);
    } else {
      await FirestoreService.instance.removeFavorite(id);
    }
  }

  Future<void> addRecipe(Recipe recipe, {Uint8List? imageBytes}) async {
    String imageUrl = recipe.imageUrl;
    if (imageBytes != null) {
      imageUrl = await CloudinaryService.instance.uploadImage(imageBytes);
    }
    final withImage = Recipe(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      imageUrl: imageUrl,
      category: recipe.category,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      servings: recipe.servings,
      difficulty: recipe.difficulty,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      tags: recipe.tags,
      rating: recipe.rating,
      isUserAdded: true,
      createdBy: recipe.createdBy,
    );
    await FirestoreService.instance.addRecipe(withImage);
  }

  Future<void> updateRecipe(Recipe recipe, {Uint8List? imageBytes}) async {
    String imageUrl = recipe.imageUrl;
    if (imageBytes != null) {
      imageUrl = await CloudinaryService.instance.uploadImage(imageBytes);
    }
    final updated = Recipe(
      id: recipe.id,
      title: recipe.title,
      description: recipe.description,
      imageUrl: imageUrl,
      category: recipe.category,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      servings: recipe.servings,
      difficulty: recipe.difficulty,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      tags: recipe.tags,
      rating: recipe.rating,
      isUserAdded: recipe.isUserAdded,
      createdBy: recipe.createdBy,
    );
    await FirestoreService.instance.updateRecipe(updated);
  }

  Future<void> deleteRecipe(String id) async {
    await FirestoreService.instance.deleteRecipe(id);
  }

  Future<void> rateRecipe(String id, double stars) async {
    await FirestoreService.instance.rateRecipe(id, stars);
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _recipesSub?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }
}
