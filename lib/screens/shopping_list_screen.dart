// lib/screens/shopping_list_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/local_features_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ShoppingListScreen({super.key, this.onMenuTap});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  void _addItem(LocalFeaturesProvider p) {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    p.addItems([text]);
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<LocalFeaturesProvider>();
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.firebaseUser?.isAnonymous ?? true;
    final items = p.shoppingList;
    final unchecked = items.where((e) => !e.checked).toList();
    final checked = items.where((e) => e.checked).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;

    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: (!isWide && widget.onMenuTap != null)
            ? IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AppTheme.textMid, size: 22),
                onPressed: widget.onMenuTap,
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text('Shopping List',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
        actions: [
          if (!isGuest && checked.isNotEmpty)
            TextButton.icon(
              onPressed: () => p.clearChecked(),
              icon: const Icon(Icons.cleaning_services_rounded, size: 16),
              label: Text('Clear done',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textLight)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.textLight),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add item input — hidden for guests
          if (isGuest)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign in to add items to your shopping list.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: subColor),
                  ),
                ),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    style: GoogleFonts.lora(fontSize: 14, color: textColor),
                    decoration: const InputDecoration(
                      hintText: 'Add an ingredient…',
                      prefixIcon: Icon(Icons.add_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    onSubmitted: (_) =>
                        _addItem(context.read<LocalFeaturesProvider>()),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () =>
                      _addItem(context.read<LocalFeaturesProvider>()),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.check_rounded, size: 20),
                ),
              ]),
            ),

          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 56,
                          color: isDark
                              ? AppTheme.textLight
                              : AppTheme.lightTextLight),
                      const SizedBox(height: 16),
                      Text(
                          isGuest
                              ? 'Sign in to use Shopping List'
                              : 'Your shopping list is empty',
                          style: GoogleFonts.lora(
                              fontSize: 16,
                              color: subColor,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      Text(
                          isGuest
                              ? 'Guests can browse recipes but cannot add items.'
                              : 'Add ingredients above or from a recipe',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.textLight
                                  : AppTheme.lightTextLight),
                          textAlign: TextAlign.center),
                    ]),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (unchecked.isNotEmpty) ...[
                    _sectionLabel(
                        '${unchecked.length} item${unchecked.length == 1 ? '' : 's'}',
                        subColor),
                    ...unchecked.map((item) => _ShoppingTile(
                          item: item,
                          cardColor: cardColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          onToggle: () => p.toggleItem(item.id),
                          onDelete: () => p.removeItem(item.id),
                        )),
                  ],
                  if (checked.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('Done (${checked.length})',
                        isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                    ...checked.map((item) => _ShoppingTile(
                          item: item,
                          cardColor: cardColor,
                          textColor: subColor,
                          borderColor: borderColor,
                          onToggle: () => p.toggleItem(item.id),
                          onDelete: () => p.removeItem(item.id),
                          strikethrough: true,
                        )),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
        child: Text(text.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: color)),
      );
}

class _ShoppingTile extends StatelessWidget {
  final dynamic item; // ShoppingItem
  final Color cardColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool strikethrough;

  const _ShoppingTile({
    required this.item,
    required this.cardColor,
    required this.textColor,
    required this.borderColor,
    required this.onToggle,
    required this.onDelete,
    this.strikethrough = false,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppTheme.error, size: 22),
        ),
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.checked ? AppTheme.secondary : Colors.transparent,
                  border: Border.all(
                    color:
                        item.checked ? AppTheme.secondary : AppTheme.textLight,
                    width: 1.5,
                  ),
                ),
                child: item.checked
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.text,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    color: textColor,
                    decoration:
                        strikethrough ? TextDecoration.lineThrough : null,
                    decorationColor: AppTheme.textLight,
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
