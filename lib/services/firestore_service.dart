// lib/services/firestore_service.dart
// All Firestore read/write operations for recipes and favorites.
//
// Firestore structure:
//   /recipes/{recipeId}          ← user-added recipes
//   /users/{uid}/favorites/{id}  ← per-user favorites subcollection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Collection references ─────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  CollectionReference<Map<String, dynamic>>? get _favoritesCol {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('favorites');
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  /// Stream all recipes — real-time updates (Firestore listener).
  Stream<List<Recipe>> recipesStream() {
    return _recipes
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Recipe.fromJson(data);
            }).toList());
  }

  /// Fetch all recipes once.
  Future<List<Recipe>> fetchRecipes() async {
    final snap = await _recipes.orderBy('createdAt', descending: false).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Recipe.fromJson(data);
    }).toList();
  }

  /// Add a new recipe (user-created).
  Future<String> addRecipe(Recipe recipe) async {
    final data = recipe.toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    // Always use the authenticated user's UID — no 'system' fallback.
    // Firestore rules enforce that createdBy == request.auth.uid anyway.
    data['createdBy'] = _auth.currentUser!.uid;
    data.remove('isFavorite');

    final ref = await _recipes.add(data);
    return ref.id;
  }

  /// Update an existing recipe.
  Future<void> updateRecipe(Recipe recipe) async {
    final data = recipe.toJson();
    data.remove('isFavorite');
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _recipes.doc(recipe.id).update(data);
  }

  /// Delete a recipe (owner-only — enforced by Firestore rules).
  Future<void> deleteRecipe(String id) async {
    await _recipes.doc(id).delete();
  }

  /// Returns the rating the current user previously gave this recipe, or null.
  Future<double?> getUserRating(String recipeId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .doc(recipeId)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['stars'] as num?)?.toDouble();
  }

  /// Submit a star rating for a recipe.
  /// Prevents double-counting by storing each user's rating separately.
  Future<void> rateRecipe(String id, double stars) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final recipeSnap = await _recipes.doc(id).get();
    if (!recipeSnap.exists) return;

    final userRatingRef = _db
        .collection('users')
        .doc(uid)
        .collection('ratings')
        .doc(id);

    final userRatingSnap = await userRatingRef.get();
    final data = recipeSnap.data()!;
    double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    int ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

    double newRating;
    int newCount;

    if (userRatingSnap.exists) {
      // User already rated — replace their old stars in the average
      final oldStars =
          (userRatingSnap.data()?['stars'] as num?)?.toDouble() ?? stars;
      newCount = ratingCount; // count stays the same
      newRating = newCount == 0
          ? stars
          : ((currentRating * ratingCount) - oldStars + stars) / newCount;
    } else {
      // First-time rating — add to average
      newCount = ratingCount + 1;
      newRating = ((currentRating * ratingCount) + stars) / newCount;
    }

    final batch = _db.batch();
    batch.update(_recipes.doc(id), {
      'rating': double.parse(newRating.toStringAsFixed(1)),
      'ratingCount': newCount,
    });
    batch.set(userRatingRef, {
      'stars': stars,
      'ratedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ── Favorites (per-user subcollection) ───────────────────────────────────

  /// Load all favorite IDs for the current user.
  Future<Set<String>> loadFavoriteIds() async {
    final col = _favoritesCol;
    if (col == null) return {};
    final snap = await col.get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Stream favorite IDs — real-time.
  Stream<Set<String>> favoritesStream() {
    final col = _favoritesCol;
    if (col == null) return Stream.value({});
    return col.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Add a recipe to favorites.
  Future<void> addFavorite(String recipeId) async {
    final col = _favoritesCol;
    if (col == null) return;
    await col.doc(recipeId).set({'addedAt': FieldValue.serverTimestamp()});
  }

  /// Remove a recipe from favorites.
  Future<void> removeFavorite(String recipeId) async {
    final col = _favoritesCol;
    if (col == null) return;
    await col.doc(recipeId).delete();
  }
}
