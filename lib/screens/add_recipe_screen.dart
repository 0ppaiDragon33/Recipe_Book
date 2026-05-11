// lib/screens/add_recipe_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? existingRecipe;
  const AddRecipeScreen({super.key, this.existingRecipe});
  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _prepCtrl = TextEditingController();
  final _cookCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _ingredientCtrl = TextEditingController();
  final _stepCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String _category = 'Dinner';
  String _cuisine = 'Filipino';
  String _difficulty = 'Easy';
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  final List<String> _extraTags = [];
  Uint8List? _imageBytes;
  bool _saving = false;

  bool get _isEditing => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecipe;
    if (r != null) {
      _titleCtrl.text = r.title;
      _descCtrl.text = r.description;
      _prepCtrl.text = r.prepTime.toString();
      _cookCtrl.text = r.cookTime.toString();
      _servingsCtrl.text = r.servings.toString();
      _category = r.category;
      _difficulty = r.difficulty;
      _ingredients.addAll(r.ingredients);
      _steps.addAll(r.steps);
      final mealCats =
          AppConstants.categories.map((c) => c.toLowerCase()).toSet();
      final cuisineTag = r.tags.firstWhere(
          (t) => !mealCats.contains(t.toLowerCase()),
          orElse: () => '');
      if (cuisineTag.isNotEmpty) _cuisine = cuisineTag;
      _extraTags.addAll(r.tags.where((t) =>
          !mealCats.contains(t.toLowerCase()) &&
          t.toLowerCase() != cuisineTag.toLowerCase()));
    }
  }

  static const _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _prepCtrl,
      _cookCtrl,
      _servingsCtrl,
      _ingredientCtrl,
      _stepCtrl,
      _tagCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  void _addIngredient() {
    final val = _ingredientCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _ingredients.add(Validators.sanitize(val));
      _ingredientCtrl.clear();
    });
  }

  Future<void> _editIngredient(int index) async {
    final ctrl = TextEditingController(text: _ingredients[index]);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Ingredient',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.cream : AppTheme.lightTextDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.lora(
              fontSize: 14,
              color: isDark ? AppTheme.cream : AppTheme.lightTextDark),
          decoration: InputDecoration(
              hintText: 'e.g. 200g pasta',
              hintStyle: GoogleFonts.lora(
                  color:
                      isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(
                      color:
                          isDark ? AppTheme.textMid : AppTheme.lightTextMid))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Save',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _ingredients[index] = Validators.sanitize(result));
    }
  }

  Future<void> _editStep(int index) async {
    final ctrl = TextEditingController(text: _steps[index]);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Step ${index + 1}',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.cream : AppTheme.lightTextDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          style: GoogleFonts.lora(
              fontSize: 14,
              color: isDark ? AppTheme.cream : AppTheme.lightTextDark),
          decoration: InputDecoration(
              hintText: 'Describe this step…',
              hintStyle: GoogleFonts.lora(
                  color:
                      isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(
                      color:
                          isDark ? AppTheme.textMid : AppTheme.lightTextMid))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Save',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _steps[index] = result);
    }
  }

  void _addStep() {
    final val = _stepCtrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      _steps.add(Validators.sanitize(val));
      _stepCtrl.clear();
    });
  }

  void _addTag() {
    final val = _tagCtrl.text.trim().toLowerCase();
    if (val.isEmpty) return;
    final mealCats =
        AppConstants.categories.map((c) => c.toLowerCase()).toSet();
    if (mealCats.contains(val) || val == _cuisine.toLowerCase()) {
      _showSnack('That tag is already used by Meal Type or Cuisine.');
      return;
    }
    if (_extraTags.contains(val)) {
      _tagCtrl.clear();
      return;
    }
    setState(() {
      _extraTags.add(val);
      _tagCtrl.clear();
    });
  }

  static const _foodKeywords = {
    'chicken',
    'beef',
    'pork',
    'fish',
    'shrimp',
    'prawn',
    'tuna',
    'salmon',
    'tilapia',
    'crab',
    'squid',
    'meat',
    'egg',
    'eggs',
    'tofu',
    'lentils',
    'beans',
    'lamb',
    'turkey',
    'bacon',
    'sausage',
    'ham',
    'onion',
    'garlic',
    'tomato',
    'potato',
    'carrot',
    'pepper',
    'spinach',
    'cabbage',
    'broccoli',
    'celery',
    'mushroom',
    'ginger',
    'eggplant',
    'zucchini',
    'corn',
    'peas',
    'lettuce',
    'cucumber',
    'leek',
    'radish',
    'kangkong',
    'pechay',
    'sitaw',
    'ampalaya',
    'malunggay',
    'rice',
    'flour',
    'pasta',
    'noodle',
    'bread',
    'oats',
    'cornstarch',
    'wheat',
    'biscuit',
    'cracker',
    'tortilla',
    'pancake',
    'milk',
    'butter',
    'cream',
    'cheese',
    'yogurt',
    'oil',
    'lard',
    'margarine',
    'condensed',
    'banana',
    'mango',
    'apple',
    'lemon',
    'lime',
    'orange',
    'coconut',
    'pineapple',
    'strawberry',
    'blueberry',
    'avocado',
    'grape',
    'watermelon',
    'salt',
    'sugar',
    'vinegar',
    'soy sauce',
    'soy',
    'sauce',
    'broth',
    'stock',
    'water',
    'honey',
    'syrup',
    'ketchup',
    'mayonnaise',
    'mustard',
    'chili',
    'cumin',
    'paprika',
    'turmeric',
    'cinnamon',
    'vanilla',
    'baking soda',
    'baking powder',
    'yeast',
    'cocoa',
    'chocolate',
    'cook',
    'boil',
    'fry',
    'bake',
    'grill',
    'roast',
    'sauté',
    'saute',
    'simmer',
    'stir',
    'mix',
    'blend',
    'chop',
    'slice',
    'dice',
    'marinate',
    'season',
    'heat',
    'add',
    'pour',
    'drain',
    'steam',
    'whisk',
    'knead',
    'peel',
    'mince',
    'combine',
    'serve',
    'sprinkle',
    'toss',
    'fold',
  };
  static const _nonFoodIndicators = {
    'javascript',
    'python',
    'html',
    'css',
    'code',
    'function',
    'variable',
    'algorithm',
    'database',
    'server',
    'router',
    'component',
    'class',
    'lorem ipsum',
    'test test',
    'asdf',
    'qwerty',
    '1234',
    'buy now',
    'click here',
    'subscribe',
    'follow me',
  };

  String? _validateRecipeContent() {
    final title = _titleCtrl.text.trim().toLowerCase();
    final allIngredients = _ingredients.join(' ').toLowerCase();
    final allSteps = _steps.join(' ').toLowerCase();
    final everything =
        '$title ${_descCtrl.text.toLowerCase()} $allIngredients $allSteps';
    for (final bad in _nonFoodIndicators) {
      if (everything.contains(bad)) {
        return 'This doesn\'t look like a recipe. Please submit food-related content only.';
      }
    }
    if (title.length < 3 || RegExp(r'^\d+$').hasMatch(title)) {
      return 'Please enter a proper recipe title.';
    }
    int foodMatches = 0;
    for (final kw in _foodKeywords) {
      if (allIngredients.contains(kw) || allSteps.contains(kw)) {
        foodMatches++;
        if (foodMatches >= 2) break;
      }
    }
    if (foodMatches < 2) {
      return 'Your recipe doesn\'t seem to contain recognizable food ingredients or cooking steps.';
    }
    final cookVerbs = {
      'cook',
      'boil',
      'fry',
      'bake',
      'grill',
      'roast',
      'sauté',
      'saute',
      'simmer',
      'stir',
      'mix',
      'blend',
      'chop',
      'slice',
      'dice',
      'marinate',
      'season',
      'heat',
      'add',
      'pour',
      'drain',
      'steam',
      'whisk',
      'knead',
      'peel',
      'mince',
      'combine',
      'serve',
      'sprinkle',
      'toss',
      'fold'
    };
    final hasVerb = cookVerbs.any((verb) => allSteps.contains(verb));
    if (!hasVerb) {
      return 'Your cooking steps don\'t seem to describe food preparation.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      _showSnack('Add at least one ingredient.');
      return;
    }
    if (_steps.isEmpty) {
      _showSnack('Add at least one step.');
      return;
    }
    setState(() => _saving = true);
    final validationError = _validateRecipeContent();
    if (validationError != null) {
      if (mounted) {
        setState(() => _saving = false);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? AppTheme.surfaceAlt : AppTheme.lightSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.block_rounded, color: AppTheme.error),
              const SizedBox(width: 10),
              Text('Not Approved',
                  style: GoogleFonts.cormorantGaramond(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.cream : AppTheme.lightTextDark,
                      fontSize: 20)),
            ]),
            content: Text(validationError,
                style: GoogleFonts.lora(
                    fontSize: 14,
                    color: isDark ? AppTheme.textMid : AppTheme.lightTextMid)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Got it',
                      style: GoogleFonts.dmSans(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)))
            ],
          ),
        );
      }
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final existing = widget.existingRecipe;
      final tags = [
        _category.toLowerCase(),
        _cuisine.toLowerCase(),
        ..._extraTags
      ];
      final recipe = Recipe(
        id: _isEditing ? existing!.id : const Uuid().v4(),
        title: Validators.sanitize(_titleCtrl.text.trim()),
        description: Validators.sanitize(_descCtrl.text.trim()),
        imageUrl: _isEditing
            ? existing!.imageUrl
            : 'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=800',
        category: _category,
        prepTime: int.tryParse(_prepCtrl.text) ?? 0,
        cookTime: int.tryParse(_cookCtrl.text) ?? 0,
        servings: int.tryParse(_servingsCtrl.text) ?? 1,
        difficulty: _difficulty,
        ingredients: List.from(_ingredients),
        steps: List.from(_steps),
        tags: tags,
        rating: _isEditing ? existing!.rating : 0.0,
        isUserAdded: true,
        createdBy: _isEditing ? existing!.createdBy : uid,
      );
      final provider = context.read<RecipeProvider>();
      if (_isEditing) {
        await provider.updateRecipe(recipe, imageBytes: _imageBytes);
      } else {
        await provider.addRecipe(recipe, imageBytes: _imageBytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Recipe updated!' : 'Recipe saved!',
              style: GoogleFonts.dmSans(color: AppTheme.cream)),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to save recipe. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: AppTheme.cream)),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final inputTextColor = isDark ? AppTheme.textDark : AppTheme.lightTextDark;
    final surfaceAlt = isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;
    final hintColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? AppTheme.textMid : AppTheme.lightTextMid,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit Recipe' : 'New Recipe',
            style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w600, fontSize: 22, color: textColor)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary))
                : TextButton(
                    onPressed: _save,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 14)),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWide
                      ? AppConstants.pageHPaddingWide
                      : AppConstants.pageHPadding,
                  vertical: 20),
              children: [
                _buildImagePicker(isDark),
                const SizedBox(height: 32),
                _sectionTitle('Basic Info', textColor),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  style: GoogleFonts.lora(fontSize: 15, color: inputTextColor),
                  decoration: const InputDecoration(
                      labelText: 'Recipe Name *',
                      hintText: 'e.g. Classic Carbonara'),
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.recipeName,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  style: GoogleFonts.lora(fontSize: 14, color: inputTextColor),
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of the dish'),
                  maxLines: 3,
                  validator: Validators.notes,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: surfaceAlt,
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                    style:
                        GoogleFonts.lora(fontSize: 14, color: inputTextColor),
                    items: AppConstants.categories
                        .where((c) => c != 'All')
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.lora(
                                    fontSize: 14, color: inputTextColor))))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    dropdownColor: surfaceAlt,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    style:
                        GoogleFonts.lora(fontSize: 14, color: inputTextColor),
                    items: _difficulties
                        .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d,
                                style: GoogleFonts.lora(
                                    fontSize: 14, color: inputTextColor))))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  )),
                ]),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: _cuisine,
                  style: GoogleFonts.lora(fontSize: 14, color: inputTextColor),
                  decoration: const InputDecoration(
                      labelText: 'Cuisine / Nationality',
                      hintText: 'e.g. Filipino, Cebuano, Fusion…',
                      helperText: 'Shown as a badge on the recipe card'),
                  onChanged: (v) => setState(() => _cuisine = v.trim()),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                          controller: _prepCtrl,
                          style: GoogleFonts.lora(
                              fontSize: 14, color: inputTextColor),
                          decoration: const InputDecoration(
                              labelText: 'Prep (min)', hintText: '15'),
                          keyboardType: TextInputType.number,
                          validator: _numValidator)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextFormField(
                          controller: _cookCtrl,
                          style: GoogleFonts.lora(
                              fontSize: 14, color: inputTextColor),
                          decoration: const InputDecoration(
                              labelText: 'Cook (min)', hintText: '30'),
                          keyboardType: TextInputType.number,
                          validator: _numValidator)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextFormField(
                          controller: _servingsCtrl,
                          style: GoogleFonts.lora(
                              fontSize: 14, color: inputTextColor),
                          decoration: const InputDecoration(
                              labelText: 'Serves', hintText: '4'),
                          keyboardType: TextInputType.number,
                          validator: _numValidator)),
                ]),
                const SizedBox(height: 32),
                _sectionTitle('Ingredients', textColor),
                const SizedBox(height: 14),
                ..._ingredients.asMap().entries.map((e) => _listTile(
                    '${e.key + 1}. ${e.value}',
                    onDelete: () =>
                        setState(() => _ingredients.removeAt(e.key)),
                    onEdit: () => _editIngredient(e.key),
                    surfaceAlt: surfaceAlt,
                    borderColor: borderColor,
                    subColor: subColor,
                    hintColor: hintColor)),
                _addRow(
                    controller: _ingredientCtrl,
                    hint: 'e.g. 200g pasta',
                    onAdd: _addIngredient,
                    inputTextColor: inputTextColor),
                const SizedBox(height: 32),
                _sectionTitle('Steps', textColor),
                const SizedBox(height: 14),
                ..._steps.asMap().entries.map((e) => _listTile(
                    'Step ${e.key + 1}: ${e.value}',
                    onDelete: () => setState(() => _steps.removeAt(e.key)),
                    onEdit: () => _editStep(e.key),
                    surfaceAlt: surfaceAlt,
                    borderColor: borderColor,
                    subColor: subColor,
                    hintColor: hintColor)),
                _addRow(
                    controller: _stepCtrl,
                    hint: 'e.g. Bring water to a boil',
                    onAdd: _addStep,
                    multiline: true,
                    inputTextColor: inputTextColor),
                const SizedBox(height: 32),
                _sectionTitle('Extra Tags', textColor),
                const SizedBox(height: 6),
                Text('Add searchable tags (e.g. spicy, healthy, quick).',
                    style: GoogleFonts.dmSans(fontSize: 12, color: hintColor)),
                const SizedBox(height: 12),
                if (_extraTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _extraTags
                        .map((t) => Chip(
                              label: Text(t,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: inputTextColor)),
                              backgroundColor: surfaceAlt,
                              side: BorderSide(color: borderColor, width: 1),
                              deleteIcon:
                                  Icon(Icons.close, size: 14, color: hintColor),
                              onDeleted: () =>
                                  setState(() => _extraTags.remove(t)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                _addRow(
                    controller: _tagCtrl,
                    hint: 'e.g. spicy, healthy, quick',
                    onAdd: _addTag,
                    inputTextColor: inputTextColor),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    final surfaceAlt = isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final hintColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: surfaceAlt,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: borderColor, width: 1),
          image: _imageBytes != null
              ? DecorationImage(
                  image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
              : null,
        ),
        child: _imageBytes == null
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: AppTheme.primary),
                ),
                const SizedBox(height: 10),
                Text('Tap to add a photo',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subColor)),
                const SizedBox(height: 2),
                Text('Optional',
                    style: GoogleFonts.dmSans(fontSize: 11, color: hintColor)),
              ])
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: GestureDetector(
                    onTap: () => setState(() => _imageBytes = null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color textColor) => Row(children: [
        Container(
            width: 3,
            height: 20,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2))),
        Text(t,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
      ]);

  Widget _listTile(String text,
          {required VoidCallback onDelete,
          VoidCallback? onEdit,
          required Color surfaceAlt,
          required Color borderColor,
          required Color subColor,
          required Color hintColor}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1)),
        child: Row(children: [
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.edit_outlined,
                    size: 15, color: AppTheme.primary),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Text(text,
                  style: GoogleFonts.lora(fontSize: 13, color: subColor)),
            ),
          ),
          GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: 15, color: hintColor)),
        ]),
      );

  Widget _addRow(
          {required TextEditingController controller,
          required String hint,
          required VoidCallback onAdd,
          bool multiline = false,
          required Color inputTextColor}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child: TextFormField(
          controller: controller,
          style: GoogleFonts.lora(fontSize: 14, color: inputTextColor),
          decoration: InputDecoration(hintText: hint),
          maxLines: multiline ? 2 : 1,
          onFieldSubmitted: (_) => onAdd(),
        )),
        const SizedBox(width: 10),
        SizedBox(
            height: 48,
            width: 48,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Icon(Icons.add_rounded, size: 22),
            )),
      ]);

  String? _numValidator(String? v) =>
      (v != null && v.isNotEmpty && int.tryParse(v) == null)
          ? 'Must be a number'
          : null;
}
