// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x50000000) : const Color(0x18000000),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(isDark),
            _buildContent(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    final isValidUrl = recipe.imageUrl.contains('unsplash.com') ||
        recipe.imageUrl.contains('cloudinary.com') ||
        recipe.imageUrl.contains('res.cloudinary');

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.cardRadius)),
          child: isValidUrl
              ? Image.network(
                  recipe.imageUrl,
                  height: 195,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return _placeholder(isDark);
                  },
                  errorBuilder: (_, __, ___) => _placeholder(isDark),
                )
              : _placeholder(isDark),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.cardRadius)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55)
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Builder(builder: (context) {
            final mealCategories =
                AppConstants.categories.map((c) => c.toLowerCase()).toSet();
            final cuisineTag = recipe.tags.firstWhere(
                (t) => !mealCategories.contains(t.toLowerCase()),
                orElse: () => '');
            return _CuisinePill(
                cuisineTag.isNotEmpty ? cuisineTag : recipe.category);
          }),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Consumer<RecipeProvider>(
            builder: (context, provider, _) => GestureDetector(
              onTap: () => provider.toggleFavorite(recipe.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
                child: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite ? AppTheme.primary : Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 12,
          child: Row(children: [
            _DifficultyPill(recipe.difficulty),
            if (recipe.isUserAdded) ...[
              const SizedBox(width: 6),
              const _SmallPill('Mine', AppTheme.secondary)
            ],
          ]),
        ),
        Positioned(
          bottom: 10,
          right: 12,
          child: Row(children: [
            const Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(_formatTime(recipe.totalTime),
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70)),
          ]),
        ),
      ],
    );
  }

  Widget _placeholder(bool isDark) => Container(
        height: 195,
        width: double.infinity,
        color: isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.restaurant_menu_rounded,
                size: 34,
                color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
            const SizedBox(height: 6),
            Text('No image',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color:
                        isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
          ]),
        ),
      );

  Widget _buildContent(BuildContext context, bool isDark) {
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final descColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final statColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final divColor = isDark ? AppTheme.divider : AppTheme.lightDivider;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(recipe.title,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: titleColor,
                height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Text(recipe.description,
            style: GoogleFonts.lora(
                fontSize: 12.5, color: descColor, height: 1.55),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 0.5, color: divColor),
        const SizedBox(height: 12),
        Row(children: [
          _FooterStat(
              icon: Icons.people_outline_rounded,
              label: '${recipe.servings} srv',
              color: statColor),
          const SizedBox(width: 14),
          _FooterStat(
              icon: Icons.tag_rounded,
              label: recipe.category,
              color: statColor),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: AppTheme.accent, size: 13),
              const SizedBox(width: 4),
              Text(recipe.rating > 0 ? recipe.rating.toStringAsFixed(1) : 'New',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent)),
            ]),
          ),
        ]),
      ]),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _CuisinePill extends StatelessWidget {
  final String label;
  const _CuisinePill(this.label);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3)),
      );
}

class _DifficultyPill extends StatelessWidget {
  final String difficulty;
  const _DifficultyPill(this.difficulty);
  Color get _color => switch (difficulty) {
        'Easy' => const Color(0xFF4A9B6F),
        'Medium' => const Color(0xFFD4831F),
        'Hard' => const Color(0xFFCF5A50),
        _ => AppTheme.textLight,
      };
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: _color.withValues(alpha: 0.45), width: 1)),
        child: Text(difficulty,
            style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: _color)),
      );
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallPill(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.40), width: 1)),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FooterStat(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]);
}
