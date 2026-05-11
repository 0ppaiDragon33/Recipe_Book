// lib/screens/collections_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/local_features_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'recipe_detail_screen.dart';

class CollectionsScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const CollectionsScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LocalFeaturesProvider>();
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.firebaseUser?.isAnonymous ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final cols = p.collections.values.toList();

    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: (!isWide && onMenuTap != null)
            ? IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AppTheme.textMid, size: 22),
                onPressed: onMenuTap,
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text('Collections',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
              onPressed: () => _showCreateDialog(context, p),
              tooltip: 'New collection',
            ),
        ],
      ),
      body: cols.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 56,
                        color: isDark
                            ? AppTheme.textLight
                            : AppTheme.lightTextLight),
                    const SizedBox(height: 16),
                    Text('No collections yet',
                        style: GoogleFonts.lora(
                            fontSize: 16,
                            color: subColor,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Sign in to create and manage collections.',
                          style:
                              GoogleFonts.dmSans(fontSize: 13, color: subColor),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showCreateDialog(context, p),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Create your first collection'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary),
                      ),
                  ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cols.length,
              itemBuilder: (context, i) {
                final col = cols[i];
                return _CollectionTile(
                  collection: col,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CollectionDetailScreen(collectionId: col.id)),
                  ),
                  onRename: isGuest
                      ? null
                      : () => _showRenameDialog(context, p, col.id, col.name),
                  onDelete: isGuest
                      ? null
                      : () => _confirmDelete(context, p, col.id, col.name),
                );
              },
            ),
    );
  }

  void _showCreateDialog(BuildContext context, LocalFeaturesProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _NameDialog(
        title: 'New Collection',
        hint: 'e.g. Weeknight Dinners',
        ctrl: ctrl,
        onSubmit: (name) => p.createCollection(name),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, LocalFeaturesProvider p,
      String id, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Rename Collection',
        hint: current,
        ctrl: ctrl,
        onSubmit: (name) => p.renameCollection(id, name),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, LocalFeaturesProvider p, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "$name"?',
            style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w600,
                color: AppTheme.cream,
                fontSize: 20)),
        content: Text(
            'The recipes won\'t be deleted, just removed from this collection.',
            style: GoogleFonts.lora(color: AppTheme.textMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: AppTheme.textLight))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              p.deleteCollection(id);
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

class _CollectionTile extends StatelessWidget {
  final dynamic collection;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  const _CollectionTile(
      {required this.collection,
      required this.isDark,
      required this.onTap,
      this.onRename,
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;
    final count = (collection.recipeIds as List).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_rounded,
              color: AppTheme.primary, size: 22),
        ),
        title: Text(collection.name,
            style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text('$count recipe${count == 1 ? '' : 's'}',
            style: GoogleFonts.dmSans(fontSize: 12, color: subColor)),
        trailing: (onRename != null || onDelete != null)
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18,
                    color:
                        isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                color: isDark ? AppTheme.surfaceAlt : AppTheme.lightSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'rename') {
                    onRename?.call();
                  } else {
                    onDelete?.call();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'rename',
                      child: Text('Rename',
                          style: GoogleFonts.dmSans(color: textColor))),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: GoogleFonts.dmSans(color: AppTheme.error))),
                ],
              )
            : null,
      ),
    );
  }
}

// ── Collection Detail ─────────────────────────────────────────────────────────
class CollectionDetailScreen extends StatelessWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LocalFeaturesProvider>();
    final recipes = context.watch<RecipeProvider>();
    final col = p.collections[collectionId];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;

    if (col == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Collection not found')),
      );
    }

    final colRecipes = col.recipeIds
        .map((id) => recipes.getRecipeById(id))
        .where((r) => r != null)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(col.name,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
      ),
      body: colRecipes.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu_outlined,
                        size: 56,
                        color: isDark
                            ? AppTheme.textLight
                            : AppTheme.lightTextLight),
                    const SizedBox(height: 16),
                    Text('No recipes in this collection yet',
                        style: GoogleFonts.lora(
                            fontSize: 15,
                            color: subColor,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Text('Add recipes from the recipe detail page',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textLight
                                : AppTheme.lightTextLight)),
                  ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: colRecipes.length,
              itemBuilder: (context, i) {
                final recipe = colRecipes[i]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailScreen(recipeId: recipe.id))),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(recipe.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: isDark
                                  ? AppTheme.surfaceAlt
                                  : AppTheme.lightSurfaceAlt,
                              child: const Icon(Icons.restaurant_menu_rounded,
                                  color: AppTheme.textLight, size: 20))),
                    ),
                    title: Text(recipe.title,
                        style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    subtitle: Text(recipe.category,
                        style:
                            GoogleFonts.dmSans(fontSize: 12, color: subColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppTheme.error, size: 20),
                      onPressed: () =>
                          p.removeRecipeFromCollection(collectionId, recipe.id),
                      tooltip: 'Remove from collection',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Name Dialog ───────────────────────────────────────────────────────────────
class _NameDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController ctrl;
  final Future<void> Function(String) onSubmit;
  const _NameDialog(
      {required this.title,
      required this.hint,
      required this.ctrl,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final bgColor = isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: GoogleFonts.cormorantGaramond(
              fontWeight: FontWeight.w600, color: textColor, fontSize: 20)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: GoogleFonts.lora(color: textColor, fontSize: 14),
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) async {
          if (v.trim().isNotEmpty) {
            await onSubmit(v.trim());
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppTheme.textLight))),
        TextButton(
          onPressed: () async {
            final v = ctrl.text.trim();
            if (v.isNotEmpty) {
              await onSubmit(v);
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: Text('Save',
              style: GoogleFonts.dmSans(
                  color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
