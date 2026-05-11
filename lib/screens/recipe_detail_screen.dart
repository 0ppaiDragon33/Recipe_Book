// lib/screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/local_features_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import 'add_recipe_screen.dart';
import 'cook_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  double _userRating = 0;
  bool _submitted = false;
  double _servingScale = 1.0; // multiplier for serving scaler

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _loadPreviousRating();
    // Record view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocalFeaturesProvider>().recordView(widget.recipeId);
    });
  }

  Future<void> _loadPreviousRating() async {
    final previous =
        await FirestoreService.instance.getUserRating(widget.recipeId);
    if (previous != null && mounted) {
      setState(() {
        _userRating = previous;
        _submitted = true;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Scale an ingredient string for serving size ─────────────────────────
  String _scaleIngredient(String ingredient, double scale) {
    if (scale == 1.0) return ingredient;
    // Very naive: replace leading numbers
    return ingredient.replaceFirstMapped(
      RegExp(r'^(\d+(?:\.\d+)?(?:/\d+)?)'),
      (m) {
        final orig = m.group(1)!;
        double val;
        if (orig.contains('/')) {
          final parts = orig.split('/');
          val = double.parse(parts[0]) / double.parse(parts[1]);
        } else {
          val = double.parse(orig);
        }
        final scaled = val * scale;
        if (scaled == scaled.truncateToDouble()) {
          return scaled.toInt().toString();
        }
        return scaled.toStringAsFixed(1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final localP = context.watch<LocalFeaturesProvider>();
    final settings = context.watch<SettingsProvider>();
    final recipe = provider.getRecipeById(widget.recipeId);
    final isWide = MediaQuery.of(context).size.width > 800;
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final fontScale = settings.fontScale;

    if (recipe == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppTheme.background : AppTheme.lightBackground,
        appBar: AppBar(
            backgroundColor:
                isDark ? AppTheme.background : AppTheme.lightBackground),
        body: Center(
            child: Text('Recipe not found.',
                style: GoogleFonts.lora(color: subColor))),
      );
    }

    final isOwner = recipe.isUserAdded && recipe.createdBy == uid;
    final note = localP.getNote(recipe.id);
    final scaledServings = (recipe.servings * _servingScale).round();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.background : AppTheme.lightBackground,
      body: CustomScrollView(slivers: [
        // ── Hero app bar ─────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: isWide ? 420 : 320,
          pinned: true,
          backgroundColor:
              isDark ? AppTheme.background : AppTheme.lightBackground,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: (isDark ? AppTheme.background : Colors.white)
                  .withValues(alpha: 0.85),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    size: 18,
                    color: isDark ? AppTheme.textMid : AppTheme.lightTextMid),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: (isDark ? AppTheme.background : Colors.white)
                    .withValues(alpha: 0.85),
                child: IconButton(
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: recipe.isFavorite
                        ? AppTheme.primary
                        : (isDark ? AppTheme.textMid : AppTheme.lightTextMid),
                  ),
                  onPressed: () => provider.toggleFavorite(recipe.id),
                ),
              ),
            ),
            // More actions menu
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: CircleAvatar(
                backgroundColor: (isDark ? AppTheme.background : Colors.white)
                    .withValues(alpha: 0.85),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18,
                      color: isDark ? AppTheme.textMid : AppTheme.lightTextMid),
                  color: isDark ? AppTheme.surfaceAlt : AppTheme.lightSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) =>
                      _handleMenuAction(v, context, provider, recipe),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'cook',
                        child: Row(children: [
                          const Icon(Icons.restaurant_rounded,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Text('Cook Mode',
                              style: GoogleFonts.dmSans(color: textColor))
                        ])),
                    PopupMenuItem(
                        value: 'shopping',
                        child: Row(children: [
                          const Icon(Icons.shopping_basket_outlined,
                              size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 10),
                          Text('Add to Shopping List',
                              style: GoogleFonts.dmSans(color: textColor))
                        ])),
                    PopupMenuItem(
                        value: 'collection',
                        child: Row(children: [
                          const Icon(Icons.folder_outlined,
                              size: 16, color: AppTheme.accent),
                          const SizedBox(width: 10),
                          Text('Add to Collection',
                              style: GoogleFonts.dmSans(color: textColor))
                        ])),
                    PopupMenuItem(
                        value: 'share',
                        child: Row(children: [
                          const Icon(Icons.share_outlined,
                              size: 16, color: AppTheme.textLight),
                          const SizedBox(width: 10),
                          Text('Share Recipe',
                              style: GoogleFonts.dmSans(color: textColor))
                        ])),
                    if (isOwner) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            const Icon(Icons.edit_outlined,
                                size: 16, color: AppTheme.textLight),
                            const SizedBox(width: 10),
                            Text('Edit',
                                style: GoogleFonts.dmSans(color: textColor))
                          ])),
                      PopupMenuItem(
                          value: 'duplicate',
                          child: Row(children: [
                            const Icon(Icons.copy_outlined,
                                size: 16, color: AppTheme.textLight),
                            const SizedBox(width: 10),
                            Text('Duplicate',
                                style: GoogleFonts.dmSans(color: textColor))
                          ])),
                      PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppTheme.error),
                            const SizedBox(width: 10),
                            Text('Delete',
                                style:
                                    GoogleFonts.dmSans(color: AppTheme.error))
                          ])),
                    ],
                  ],
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Image.network(recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: isDark
                          ? AppTheme.surfaceAlt
                          : AppTheme.lightSurfaceAlt,
                      child: const Icon(Icons.restaurant_menu_rounded,
                          size: 64, color: AppTheme.textLight))),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? AppTheme.background : Colors.white)
                          .withValues(alpha: 0.85)
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: isWide
                    ? AppConstants.pageHPaddingWide
                    : AppConstants.pageHPadding,
                right: isWide
                    ? AppConstants.pageHPaddingWide
                    : AppConstants.pageHPadding,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        final cuisine = recipe.tags.firstWhere(
                          (t) => AppConstants.cuisines
                              .any((c) => c.toLowerCase() == t.toLowerCase()),
                          orElse: () => recipe.category,
                        );
                        return _CuisinePill(cuisine);
                      }),
                      const SizedBox(height: 10),
                      Text(recipe.title,
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: isWide ? 38 : 28 * fontScale,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.cream
                                  : AppTheme.lightTextDark,
                              height: 1.15)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.15),
                              width: 1),
                        ),
                        child: Text(recipe.category,
                            style: GoogleFonts.dmSans(
                                fontSize: 11 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : Colors.white,
                                letterSpacing: 0.5)),
                      ),
                    ]),
              ),
            ]),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide
                  ? AppConstants.pageHPaddingWide
                  : AppConstants.pageHPadding,
              vertical: 28,
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Description
              Text(recipe.description,
                  style: GoogleFonts.lora(
                      fontSize: 15 * fontScale, color: subColor, height: 1.7)),
              const SizedBox(height: 26),

              // Stats card with serving scaler
              _buildStatsWithScaler(recipe, scaledServings, isDark),
              const SizedBox(height: 26),

              // Cook mode button
              _buildCookModeButton(context, recipe),
              const SizedBox(height: 20),

              // Rating
              _buildRatingSection(recipe, provider, isDark, fontScale),
              const SizedBox(height: 26),

              // Personal notes
              _buildNotesSection(context, localP, note, isDark, fontScale),
              const SizedBox(height: 26),

              // Tags
              if (recipe.tags.isNotEmpty) ...[
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recipe.tags.map((t) => _TagChip(t)).toList()),
                const SizedBox(height: 28),
              ],

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? AppTheme.border : AppTheme.lightBorder,
                      width: 1),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                  indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(11)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.dmSans(
                      fontSize: 13 * fontScale, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 13 * fontScale, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Ingredients'),
                    Tab(text: 'Instructions')
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _tabs.index == 0
                  ? _buildIngredients(recipe, fontScale)
                  : _buildSteps(recipe, isDark, fontScale),

              const SizedBox(height: 60),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Stats with serving scaler ─────────────────────────────────────────────
  Widget _buildStatsWithScaler(Recipe recipe, int scaledServings, bool isDark) {
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(children: [
        IntrinsicHeight(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
                child: _Stat(
                    icon: Icons.timer_outlined,
                    label: 'Prep',
                    value: _formatMin(recipe.prepTime))),
            _VDivider(),
            Expanded(
                child: _Stat(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Cook',
                    value: _formatMin(recipe.cookTime))),
            _VDivider(),
            Expanded(
                child: _Stat(
                    icon: Icons.star_outline_rounded,
                    label: 'Rating',
                    value: recipe.rating > 0
                        ? recipe.rating.toStringAsFixed(1)
                        : '—',
                    valueColor: AppTheme.accent)),
          ]),
        ),
        const SizedBox(height: 16),
        // Serving scaler
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.18), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.people_outline_rounded,
                color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Text('Servings',
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_rounded,
                  size: 18, color: AppTheme.primary),
              onPressed: _servingScale > 0.5
                  ? () => setState(() =>
                      _servingScale = (_servingScale - 0.5).clamp(0.5, 10.0))
                  : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              width: 52,
              alignment: Alignment.center,
              child: Text('$scaledServings',
                  style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary)),
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppTheme.primary),
              onPressed: () => setState(
                  () => _servingScale = (_servingScale + 0.5).clamp(0.5, 10.0)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            if (_servingScale != 1.0) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _servingScale = 1.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('Reset',
                      style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildCookModeButton(BuildContext context, Recipe recipe) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CookModeScreen(recipe: recipe))),
          icon: const Icon(Icons.restaurant_rounded, size: 18),
          label: const Text('Start Cook Mode'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  String _formatMin(int m) => m == 0
      ? '—'
      : (m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 > 0 ? " ${m % 60}m" : ""}');

  // ── Notes ─────────────────────────────────────────────────────────────────
  Widget _buildNotesSection(BuildContext context, LocalFeaturesProvider p,
      String? note, bool isDark, double fontScale) {
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sticky_note_2_outlined,
              color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Text('My Notes',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const Spacer(),
          TextButton(
            onPressed: () => _showNotesDialog(context, p, note),
            child: Text(note == null ? 'Add note' : 'Edit',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(note,
              style: GoogleFonts.lora(
                  fontSize: 13 * fontScale,
                  color: isDark ? AppTheme.textMid : AppTheme.lightTextMid,
                  height: 1.6)),
        ] else ...[
          Text('Tap "Add note" to write personal notes about this recipe.',
              style: GoogleFonts.lora(
                  fontSize: 12 * fontScale,
                  color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                  fontStyle: FontStyle.italic)),
        ],
      ]),
    );
  }

  void _showNotesDialog(
      BuildContext context, LocalFeaturesProvider p, String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceAlt,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Notes',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.cream)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 5,
                style: GoogleFonts.lora(fontSize: 14, color: AppTheme.textMid),
                decoration:
                    const InputDecoration(hintText: 'Write your notes here…'),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: TextButton(
                  onPressed: () {
                    p.saveNote(widget.recipeId, '');
                    Navigator.pop(context);
                  },
                  child: Text('Clear',
                      style: GoogleFonts.dmSans(color: AppTheme.textLight)),
                )),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () {
                    p.saveNote(widget.recipeId, ctrl.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                )),
              ]),
              const SizedBox(height: 16),
            ]),
      ),
    );
  }

  // ── Rating ─────────────────────────────────────────────────────────────────
  Widget _buildRatingSection(
      Recipe recipe, RecipeProvider provider, bool isDark, double fontScale) {
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Text('Rate this Recipe',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
          const Spacer(),
          if (recipe.rating > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.accent, size: 12),
                const SizedBox(width: 4),
                Text('${recipe.rating.toStringAsFixed(1)} avg',
                    style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent)),
              ]),
            ),
        ]),
        const SizedBox(height: 18),
        if (_submitted)
          GestureDetector(
            onTap: () => setState(() => _submitted = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.22),
                    width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.secondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'You rated this ${_userRating.toInt()} ★  •  Tap to change',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary))),
              ]),
            ),
          )
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = (i + 1).toDouble();
                return GestureDetector(
                  onTap: () => setState(() => _userRating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _userRating >= starValue
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: ValueKey(_userRating >= starValue),
                        color: _userRating >= starValue
                            ? AppTheme.accent
                            : AppTheme.textLight.withValues(alpha: 0.5),
                        size: 38,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
                child: Text(
              _userRating == 0
                  ? 'Tap a star to rate'
                  : _starLabel(_userRating.toInt()),
              style: GoogleFonts.lora(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color:
                      _userRating == 0 ? AppTheme.textLight : AppTheme.primary),
            )),
            if (_userRating > 0) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider.rateRecipe(recipe.id, _userRating);
                    if (mounted) {
                      setState(() => _submitted = true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 8),
                          Text('Rating submitted!',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.cream))
                        ]),
                        backgroundColor: AppTheme.secondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ));
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text('Submit Rating',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ]),
      ]),
    );
  }

  String _starLabel(int stars) => switch (stars) {
        1 => 'Not my favorite',
        2 => 'It was okay',
        3 => 'Pretty good!',
        4 => 'Really liked it!',
        5 => 'Absolutely loved it! 🔥',
        _ => '',
      };

  // ── Ingredients ───────────────────────────────────────────────────────────
  Widget _buildIngredients(Recipe recipe, double fontScale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_servingScale != 1.0)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                  'Scaled for ${(recipe.servings * _servingScale).round()} servings ($_servingScale×)',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      // Add all to shopping list button
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            final scaled = recipe.ingredients
                .map((i) => _scaleIngredient(i, _servingScale))
                .toList();
            context.read<LocalFeaturesProvider>().addItems(scaled);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${recipe.ingredients.length} items added to shopping list!',
                  style: GoogleFonts.dmSans(color: AppTheme.cream)),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ));
          },
          icon: const Icon(Icons.shopping_basket_outlined, size: 14),
          label: Text('Add all to list',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
        ),
      ),
      ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recipe.ingredients.length,
        separatorBuilder: (_, __) => Divider(
            color: (isDark ? AppTheme.divider : AppTheme.lightDivider),
            height: 1),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(children: [
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
                child: Text(
              _scaleIngredient(recipe.ingredients[i], _servingScale),
              style: GoogleFonts.lora(
                  fontSize: 14 * fontScale,
                  color: isDark ? AppTheme.textMid : AppTheme.lightTextMid,
                  height: 1.5),
            )),
          ]),
        ),
      ),
    ]);
  }

  // ── Steps ─────────────────────────────────────────────────────────────────
  Widget _buildSteps(Recipe recipe, bool isDark, double fontScale) =>
      ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recipe.steps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppTheme.border : AppTheme.lightBorder,
                width: 1),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${i + 1}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(recipe.steps[i],
                    style: GoogleFonts.lora(
                        fontSize: 14 * fontScale,
                        color:
                            isDark ? AppTheme.textMid : AppTheme.lightTextMid,
                        height: 1.6))),
          ]),
        ),
      );

  // ── Menu actions ──────────────────────────────────────────────────────────
  void _handleMenuAction(String action, BuildContext context,
      RecipeProvider provider, Recipe recipe) {
    switch (action) {
      case 'cook':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => CookModeScreen(recipe: recipe)));
        break;
      case 'shopping':
        context.read<LocalFeaturesProvider>().addItems(recipe.ingredients);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ingredients added to shopping list!',
              style: GoogleFonts.dmSans(color: AppTheme.cream)),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
        break;
      case 'collection':
        _showAddToCollectionDialog(context);
        break;
      case 'share':
        _shareRecipe(recipe);
        break;
      case 'edit':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddRecipeScreen(existingRecipe: recipe)));
        break;
      case 'duplicate':
        _duplicateRecipe(context, provider, recipe);
        break;
      case 'delete':
        _confirmDelete(context, provider);
        break;
    }
  }

  void _shareRecipe(Recipe recipe) {
    final text = StringBuffer();
    text.writeln('🍽 ${recipe.title}');
    text.writeln(
        'Category: ${recipe.category} | Difficulty: ${recipe.difficulty}');
    text.writeln(
        'Prep: ${_formatMin(recipe.prepTime)} | Cook: ${_formatMin(recipe.cookTime)} | Serves: ${recipe.servings}');
    text.writeln('\n${recipe.description}');
    text.writeln('\n📝 INGREDIENTS');
    for (final i in recipe.ingredients) {
      text.writeln('• $i');
    }
    text.writeln('\n👨‍🍳 INSTRUCTIONS');
    for (int i = 0; i < recipe.steps.length; i++) {
      text.writeln('${i + 1}. ${recipe.steps[i]}');
    }
    text.writeln('\nShared via Culinary Cookbook');
    Share.share(text.toString(), subject: recipe.title);
  }

  void _showAddToCollectionDialog(BuildContext context) {
    final p = context.read<LocalFeaturesProvider>();
    final cols = p.collections.values.toList();
    final inCols = p.collectionsForRecipe(widget.recipeId);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceAlt,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Add to Collection',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cream)),
            const SizedBox(height: 16),
            if (cols.isEmpty)
              Text('No collections yet. Create one in the Collections tab.',
                  style: GoogleFonts.lora(
                      fontSize: 13,
                      color: AppTheme.textMid,
                      fontStyle: FontStyle.italic))
            else
              ...cols.map((col) {
                final inCol = inCols.contains(col.id);
                return ListTile(
                  leading: Icon(
                      inCol ? Icons.folder_rounded : Icons.folder_outlined,
                      color: inCol ? AppTheme.primary : AppTheme.textLight),
                  title: Text(col.name,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppTheme.cream)),
                  trailing: inCol
                      ? const Icon(Icons.check_rounded,
                          color: AppTheme.secondary, size: 18)
                      : null,
                  onTap: () async {
                    if (inCol) {
                      await p.removeRecipeFromCollection(
                          col.id, widget.recipeId);
                    } else {
                      await p.addRecipeToCollection(col.id, widget.recipeId);
                    }
                    setS(() {});
                  },
                );
              }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final ctrl = TextEditingController();
                await showDialog(
                    context: context,
                    builder: (_) => _NewColDialog(
                        ctrl: ctrl,
                        onSubmit: (name) => p.createCollection(name)));
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Collection'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _duplicateRecipe(
      BuildContext context, RecipeProvider provider, Recipe recipe) async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final dup = Recipe(
      id: 'dup_$now',
      title: '${recipe.title} (Copy)',
      description: recipe.description,
      imageUrl: recipe.imageUrl,
      category: recipe.category,
      prepTime: recipe.prepTime,
      cookTime: recipe.cookTime,
      servings: recipe.servings,
      difficulty: recipe.difficulty,
      ingredients: List.from(recipe.ingredients),
      steps: List.from(recipe.steps),
      tags: List.from(recipe.tags),
      rating: 0,
      isUserAdded: true,
      createdBy: context.read<AuthProvider>().firebaseUser?.uid,
    );
    await provider.addRecipe(dup);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Recipe duplicated!',
            style: GoogleFonts.dmSans(color: AppTheme.cream)),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _confirmDelete(BuildContext context, RecipeProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Recipe?',
            style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w600,
                color: AppTheme.cream,
                fontSize: 20)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.lora(color: AppTheme.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: AppTheme.textLight))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteRecipe(widget.recipeId);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.dmSans(
                    color: AppTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── New Collection Dialog ─────────────────────────────────────────────────────
class _NewColDialog extends StatelessWidget {
  final TextEditingController ctrl;
  final Future<void> Function(String) onSubmit;
  const _NewColDialog({required this.ctrl, required this.onSubmit});

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Collection',
            style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w600,
                color: AppTheme.cream,
                fontSize: 20)),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.lora(color: AppTheme.cream, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Collection name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: AppTheme.textLight))),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await onSubmit(ctrl.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Create',
                style: GoogleFonts.dmSans(
                    color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _CuisinePill extends StatelessWidget {
  final String label;
  const _CuisinePill(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3)),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _Stat(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: AppTheme.primary),
      const SizedBox(height: 6),
      FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor ??
                      (isDark ? AppTheme.cream : AppTheme.lightTextDark)))),
      Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
          overflow: TextOverflow.ellipsis),
    ]);
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: isDark ? AppTheme.border : AppTheme.lightBorder);
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip(this.tag);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.25), width: 1),
        ),
        child: Text('#$tag',
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary)),
      );
}
