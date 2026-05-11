// lib/models/recipe.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> tags;
  final double rating;
  final bool isUserAdded;
  final String? createdBy;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.difficulty,
    required this.ingredients,
    required this.steps,
    required this.tags,
    this.rating = 0.0,
    this.isFavorite = false,
    this.isUserAdded = false,
    this.createdBy,
  });

  int get totalTime => prepTime + cookTime;

  Recipe copyWith({bool? isFavorite}) => Recipe(
        id: id, title: title, description: description,
        imageUrl: imageUrl, category: category,
        prepTime: prepTime, cookTime: cookTime, servings: servings,
        difficulty: difficulty, ingredients: ingredients,
        steps: steps, tags: tags, rating: rating,
        isFavorite: isFavorite ?? this.isFavorite,
        isUserAdded: isUserAdded, createdBy: createdBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'description': description,
        'imageUrl': imageUrl, 'category': category,
        'prepTime': prepTime, 'cookTime': cookTime, 'servings': servings,
        'difficulty': difficulty, 'ingredients': ingredients,
        'steps': steps, 'tags': tags, 'rating': rating,
        'isUserAdded': isUserAdded, 'createdBy': createdBy,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        category: json['category'] as String? ?? 'Other',
        prepTime: (json['prepTime'] as num?)?.toInt() ?? 0,
        cookTime: (json['cookTime'] as num?)?.toInt() ?? 0,
        servings: (json['servings'] as num?)?.toInt() ?? 1,
        difficulty: json['difficulty'] as String? ?? 'Easy',
        ingredients: _toList(json['ingredients']),
        steps: _toList(json['steps']),
        tags: _toList(json['tags']),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        isUserAdded: json['isUserAdded'] as bool? ?? false,
        createdBy: json['createdBy'] as String?,
      );

  factory Recipe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    return Recipe.fromJson(data);
  }

  static List<String> _toList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}
