// services/recipe_service.dart
// Preset recipes removed — all recipes are added by you and your team.

import '../models/recipe.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  List<Recipe> getBuiltInRecipes() => [];
}
