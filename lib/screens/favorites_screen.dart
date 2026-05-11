// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onMenuTap;
  const FavoritesScreen({super.key, required this.onBack, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;

    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        final favorites = provider.favoriteRecipes;

        return CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(p, isWide ? 40 : 16, p, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (!isWide && onMenuTap != null) ...[
                          IconButton(
                            icon: const Icon(Icons.menu_rounded,
                                color: AppTheme.textMid, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onMenuTap,
                          ),
                          const SizedBox(width: 8),
                        ],
                        GestureDetector(
                          onTap: onBack,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.arrow_back_ios_new,
                                size: 12, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('All Recipes',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                    letterSpacing: 0.2)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 22),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: 3,
                                height: 28,
                                decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('Saved Recipes',
                                    style: GoogleFonts.cormorantGaramond(
                                        fontSize: isWide ? 34 : 26,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        height: 1.1),
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          favorites.isEmpty
                              ? 'Nothing saved yet'
                              : '${favorites.length} ${favorites.length == 1 ? "recipe" : "recipes"} bookmarked',
                          style:
                              GoogleFonts.dmSans(fontSize: 12, color: subColor),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
          if (favorites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceAlt
                            : AppTheme.lightSurfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                isDark ? AppTheme.border : AppTheme.lightBorder,
                            width: 1),
                      ),
                      child: Icon(Icons.favorite_border_rounded,
                          size: 32,
                          color: AppTheme.primary.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 22),
                    Text('No favorites yet',
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 8),
                    Text('Tap ♥ on any recipe to save it here.',
                        style: GoogleFonts.lora(
                            fontSize: 13,
                            color: subColor,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.menu_book_outlined, size: 16),
                        label: const Text('Browse Recipes')),
                  ]),
            )
          else if (isWide)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(p, 0, p, 40),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => RecipeCard(
                      recipe: favorites[i],
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                  recipeId: favorites[i].id)))),
                  childCount: favorites.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 380,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(p, 0, p, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RecipeCard(
                          recipe: favorites[i],
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RecipeDetailScreen(
                                      recipeId: favorites[i].id))))),
                  childCount: favorites.length,
                ),
              ),
            ),
        ]);
      },
    );
  }
}
