// lib/utils/constants.dart
// ✅ No API keys or secrets hardcoded here.
// Sensitive values are stored in FlutterSecureStorage at runtime.

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Culinary Cookbook';
  static const String appVersion = '1.0.0';

  // Secure storage keys
  static const String keyUserPin = 'user_pin';
  static const String keyOnboarded = 'onboarded';

  // Validation
  static const int pinMinLength = 4;
  static const int pinMaxLength = 6;
  static const int recipeNameMinLength = 3;
  static const int recipeNameMaxLength = 80;
  static const int notesMaxLength = 500;

  // UI
  static const double cardRadius = 20.0;
  static const double pageHPadding = 24.0;
  static const double pageHPaddingWide = 48.0;

  // Default placeholder image (Unsplash — HTTPS only)
  static const String defaultImageUrl =
      'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=800';

  // Meal-type categories (shown in filter chips)
  // Nationality/cuisine is stored as a tag and shown as a badge on the image.
  static const List<String> categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Quick',
    'Healthy',
    'Vegetarian',
    'Comfort Food',
    'Drinks',
  ];

  // All known cuisine tags — stored in recipe.tags, shown as image badges
  static const List<String> cuisines = [
    'Italian',
    'Japanese',
    'Mexican',
    'Indian',
    'French',
    'Thai',
    'Korean',
    'Chinese',
    'Vietnamese',
    'Spanish',
    'Greek',
    'Middle Eastern',
    'American',
    'Filipino',
  ];
}
