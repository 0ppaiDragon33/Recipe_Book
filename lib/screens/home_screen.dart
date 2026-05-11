// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'favorites_screen.dart';
import 'add_recipe_screen.dart';
import 'pin_screen.dart';
import 'collections_screen.dart';
import 'shopping_list_screen.dart';
import 'settings_screen.dart';

enum _SideTab {
  recipes,
  favorites,
  collections,
  shoppingList,
  settings,
  addRecipe,
  changePIN,
  signOut
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  DateTime? _lastBackPress;
  final _searchCtrl = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    // If drawer is open, close it
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
      return false;
    }
    // If not on home tab, go back to home
    if (_tab != 0) {
      setState(() => _tab = 0);
      return false;
    }
    // On home tab — require double back to quit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return false;
    }
    return true; // allow quit
  }

  void _goToTab(int tab) => setState(() => _tab = tab);

  Future<void> _handleSideAction(_SideTab action) async {
    final auth = context.read<AuthProvider>();
    switch (action) {
      case _SideTab.recipes:
        setState(() => _tab = 0);
        break;
      case _SideTab.favorites:
        setState(() => _tab = 1);
        break;
      case _SideTab.collections:
        setState(() => _tab = 2);
        break;
      case _SideTab.shoppingList:
        setState(() => _tab = 3);
        break;
      case _SideTab.settings:
        setState(() => _tab = 4);
        break;
      case _SideTab.addRecipe:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
        break;
      case _SideTab.changePIN:
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)));
        break;
      case _SideTab.signOut:
        await auth.signOut();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.firebaseUser?.isAnonymous ?? true;

    if (isWide) return _buildWideLayout(auth, isGuest);
    return _buildNarrowLayout(auth, isGuest);
  }

  // ── WIDE layout ───────────────────────────────────────────────────────────
  Widget _buildWideLayout(AuthProvider auth, bool isGuest) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? AppTheme.background : AppTheme.lightBackground,
      body: Row(
        children: [
          _Sidebar(
            currentTab: _tab,
            isGuest: isGuest,
            auth: auth,
            onAction: _handleSideAction,
          ),
          Container(width: 1, color: AppTheme.divider),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _buildRecipesTab(true),
                FavoritesScreen(onBack: () => _goToTab(0)),
                const CollectionsScreen(),
                const ShoppingListScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_tab == 0 && !isGuest) ? _buildFAB() : null,
    );
  }

  // ── NARROW layout ─────────────────────────────────────────────────────────
  Widget _buildNarrowLayout(AuthProvider auth, bool isGuest) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor:
            isDark ? AppTheme.background : AppTheme.lightBackground,
        drawer: _MobileDrawer(
          auth: auth,
          isGuest: isGuest,
          onAction: (action) {
            Navigator.pop(context);
            _handleSideAction(action);
          },
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            _buildRecipesTab(false),
            FavoritesScreen(
                onBack: () => _goToTab(0),
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
            CollectionsScreen(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
            ShoppingListScreen(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
            SettingsScreen(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer()),
          ],
        ),
        floatingActionButton: (_tab == 0 && !isGuest) ? _buildFAB() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildFAB() {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isSmall
          ? FloatingActionButton(
              onPressed: () => _handleSideAction(_SideTab.addRecipe),
              backgroundColor: AppTheme.primary,
              elevation: 0,
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            )
          : FloatingActionButton.extended(
              onPressed: () => _handleSideAction(_SideTab.addRecipe),
              backgroundColor: AppTheme.primary,
              elevation: 0,
              icon:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: Text(
                'Add Recipe',
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.lightSurface,
        border:
            const Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _tab.clamp(0, 1),
        onDestinationSelected: _goToTab,
        backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
        elevation: 0,
        height: 62,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: AppTheme.primary),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.primary),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  // ── Recipes tab ───────────────────────────────────────────────────────────
  Widget _buildRecipesTab(bool isWide) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return _buildLoading();
        if (provider.error != null) return _buildError(provider);

        return NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _buildHeader(context, provider, isWide)),
          ],
          body: Column(
            children: [
              // Sticky search + chips
              Material(
                color: isDark ? AppTheme.background : AppTheme.lightBackground,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearch(provider, isWide),
                    const SizedBox(height: 10),
                    _buildCategoryChips(provider, isWide),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildSortRow(provider, isWide)),
                    if (provider.recipes.isEmpty)
                      SliverFillRemaining(child: _buildEmpty())
                    else
                      _buildGrid(provider, isWide),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 20),
          Text('Preparing recipes…',
              style: GoogleFonts.lora(
                  fontSize: 14,
                  color:
                      isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
        ],
      ),
    );
  }

  Widget _buildError(RecipeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 52, color: subColor.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text('Connection lost',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22, color: textColor)),
            const SizedBox(height: 8),
            Text(provider.error!,
                style: GoogleFonts.lora(fontSize: 13, color: subColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: provider.initialize,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, RecipeProvider provider, bool isWide) {
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    final auth = context.read<AuthProvider>();
    final isGuest = auth.firebaseUser?.isAnonymous ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    final menuColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(isWide ? p : 8, isWide ? 36 : 14, p, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isWide)
              IconButton(
                icon: Icon(Icons.menu_rounded, color: menuColor, size: 22),
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                constraints: const BoxConstraints(),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),

            // Terracotta accent bar
            Container(
              width: 3,
              height: 28,
              margin: EdgeInsets.only(right: 12, left: isWide ? 0 : 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Culinary Cookbook',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isWide ? 28 : 22,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${provider.recipes.length} recipes',
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: subColor),
                      ),
                      const SizedBox(width: 8),
                      // User chip
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGuest
                                ? AppTheme.border
                                : AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isGuest
                                  ? AppTheme.border
                                  : AppTheme.primary.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              isGuest
                                  ? Icons.person_outline
                                  : Icons.person_rounded,
                              size: 10,
                              color: isGuest ? subColor : AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                auth.displayName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isGuest ? subColor : AppTheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch(RecipeProvider provider, bool isWide) {
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(p, 14, p, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: provider.setSearchQuery,
        style: GoogleFonts.lora(
            fontSize: 14,
            color: isDark ? AppTheme.cream : AppTheme.lightTextDark),
        decoration: InputDecoration(
          hintText: 'Search recipes, ingredients…',
          prefixIcon: Icon(Icons.search_rounded,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
              size: 19),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color:
                          isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                      size: 17),
                  onPressed: () {
                    _searchCtrl.clear();
                    provider.setSearchQuery('');
                  })
              : null,
        ),
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────
  static const _categoryIcons = {
    'All': Icons.apps_rounded,
    'Breakfast': Icons.wb_sunny_rounded,
    'Lunch': Icons.lunch_dining_rounded,
    'Dinner': Icons.dinner_dining_rounded,
    'Dessert': Icons.cake_rounded,
    'Snack': Icons.cookie_rounded,
    'Quick': Icons.bolt_rounded,
    'Healthy': Icons.eco_rounded,
    'Vegetarian': Icons.grass_rounded,
    'Comfort Food': Icons.soup_kitchen_rounded,
    'Drinks': Icons.local_drink_rounded,
  };

  Widget _buildCategoryChips(RecipeProvider provider, bool isWide) {
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt;
    final chipBorder = isDark ? AppTheme.border : AppTheme.lightBorder;
    final iconColor = isDark ? AppTheme.textLight : AppTheme.lightTextMid;
    final labelColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: p),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: AppConstants.categories.length,
        itemBuilder: (_, i) {
          final cat = AppConstants.categories[i];
          final sel = provider.selectedCategory == cat;
          final iconData = _categoryIcons[cat] ?? Icons.circle_outlined;
          return GestureDetector(
            onTap: () => provider.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppTheme.primary : chipBorder,
                  width: 1,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData,
                      size: sel ? 13 : 12,
                      color: sel ? Colors.white : iconColor),
                  const SizedBox(width: 7),
                  Text(
                    cat,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : labelColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sort row ──────────────────────────────────────────────────────────────
  Widget _buildSortRow(RecipeProvider provider, bool isWide) {
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(p, 16, p, 12),
      child: Row(children: [
        Text(
          '${provider.recipes.length} ${provider.recipes.length == 1 ? "recipe" : "recipes"}',
          style: GoogleFonts.dmSans(
              fontSize: 12,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          onSelected: provider.setSortBy,
          color: isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.swap_vert_rounded,
                  size: 14,
                  color: isDark ? AppTheme.textMid : AppTheme.lightTextMid),
              const SizedBox(width: 6),
              Text(provider.sortBy,
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color:
                          isDark ? AppTheme.textMid : AppTheme.lightTextMid)),
            ]),
          ),
          itemBuilder: (_) => ['Default', 'Rating', 'Time', 'Name']
              .map((s) => PopupMenuItem(
                  value: s,
                  child: Text(s,
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppTheme.textDark))))
              .toList(),
        ),
      ]),
    );
  }

  // ── Grid / List ───────────────────────────────────────────────────────────
  Widget _buildGrid(RecipeProvider provider, bool isWide) {
    final p =
        isWide ? AppConstants.pageHPaddingWide : AppConstants.pageHPadding;
    final recipes = provider.recipes;

    if (isWide) {
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(p, 0, p, 32),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, i) => RecipeCard(
              recipe: recipes[i],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recipeId: recipes[i].id))),
            ),
            childCount: recipes.length,
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            mainAxisExtent: 380,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(p, 0, p, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RecipeCard(
              recipe: recipes[i],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recipeId: recipes[i].id))),
            ),
          ),
          childCount: recipes.length,
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded,
              size: 56,
              color: isDark
                  ? AppTheme.textLight
                  : AppTheme.lightTextLight.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Text('Nothing found',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  color: isDark ? AppTheme.textMid : AppTheme.lightTextMid)),
          const SizedBox(height: 8),
          Text('Try a different keyword or category',
              style: GoogleFonts.lora(
                  fontSize: 13,
                  color:
                      isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR — Desktop
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int currentTab;
  final bool isGuest;
  final AuthProvider auth;
  final void Function(_SideTab) onAction;

  const _Sidebar({
    required this.currentTab,
    required this.isGuest,
    required this.auth,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sideColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    return Container(
      width: 240,
      color: sideColor,
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),

                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Culinary\nCookbook',
                            style: GoogleFonts.cormorantGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                                height: 1.2)),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 36),
                  _sectionLabel('BROWSE', context),
                  const SizedBox(height: 4),
                  _SideItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'Recipes',
                    isActive: currentTab == 0,
                    onTap: () => onAction(_SideTab.recipes),
                  ),
                  _SideItem(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: 'Favorites',
                    isActive: currentTab == 1,
                    onTap: () => onAction(_SideTab.favorites),
                  ),
                  _SideItem(
                    icon: Icons.collections_bookmark_outlined,
                    activeIcon: Icons.collections_bookmark,
                    label: 'Collections',
                    isActive: currentTab == 2,
                    onTap: () => onAction(_SideTab.collections),
                  ),
                  _SideItem(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart,
                    label: 'Shopping List',
                    isActive: currentTab == 3,
                    onTap: () => onAction(_SideTab.shoppingList),
                  ),

                  if (!isGuest) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('CREATE', context),
                    const SizedBox(height: 4),
                    _SideItem(
                      icon: Icons.add_circle_outline_rounded,
                      activeIcon: Icons.add_circle_rounded,
                      label: 'Add Recipe',
                      isActive: false,
                      onTap: () => onAction(_SideTab.addRecipe),
                      color: AppTheme.primary,
                    ),
                  ],

                  const Spacer(),
                  const Divider(
                      color: AppTheme.divider, indent: 20, endIndent: 20),

                  // User card
                  _sectionLabel('ACCOUNT', context),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceAlt
                            : AppTheme.lightSurfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border, width: 1),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.18),
                          child: Text(
                            auth.displayName.isNotEmpty
                                ? auth.displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.cormorantGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auth.displayName,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.cream
                                          : AppTheme.lightTextDark),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                isGuest
                                    ? 'Guest'
                                    : auth.firebaseUser?.email ?? '',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10, color: subColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SideItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    isActive: currentTab == 4,
                    onTap: () => onAction(_SideTab.settings),
                  ),
                  _SideItem(
                    icon: Icons.lock_outline_rounded,
                    activeIcon: Icons.lock_rounded,
                    label: 'Change PIN',
                    isActive: false,
                    onTap: () => onAction(_SideTab.changePIN),
                  ),
                  _SideItem(
                    icon: Icons.logout_rounded,
                    activeIcon: Icons.logout_rounded,
                    label: isGuest ? 'End Session' : 'Sign Out',
                    isActive: false,
                    onTap: () => onAction(_SideTab.signOut),
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(t,
          style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  final AuthProvider auth;
  final bool isGuest;
  final void Function(_SideTab) onAction;

  const _MobileDrawer({
    required this.auth,
    required this.isGuest,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final titleColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    return Drawer(
      backgroundColor: drawerColor,
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text('Culinary Cookbook',
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: titleColor)),
                    ]),
                  ),
                  const SizedBox(height: 28),
                  _SideItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'Recipes',
                    isActive: false,
                    onTap: () => onAction(_SideTab.recipes),
                  ),
                  _SideItem(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    label: 'Favorites',
                    isActive: false,
                    onTap: () => onAction(_SideTab.favorites),
                  ),
                  _SideItem(
                    icon: Icons.collections_bookmark_outlined,
                    activeIcon: Icons.collections_bookmark,
                    label: 'Collections',
                    isActive: false,
                    onTap: () => onAction(_SideTab.collections),
                  ),
                  _SideItem(
                    icon: Icons.shopping_cart_outlined,
                    activeIcon: Icons.shopping_cart,
                    label: 'Shopping List',
                    isActive: false,
                    onTap: () => onAction(_SideTab.shoppingList),
                  ),
                  if (!isGuest)
                    _SideItem(
                      icon: Icons.add_circle_outline_rounded,
                      activeIcon: Icons.add_circle_rounded,
                      label: 'Add Recipe',
                      isActive: false,
                      onTap: () => onAction(_SideTab.addRecipe),
                      color: AppTheme.primary,
                    ),
                  const Spacer(),
                  const Divider(
                      color: AppTheme.divider, indent: 20, endIndent: 20),
                  _SideItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    isActive: false,
                    onTap: () => onAction(_SideTab.settings),
                  ),
                  _SideItem(
                    icon: Icons.lock_outline_rounded,
                    activeIcon: Icons.lock_rounded,
                    label: 'Change PIN',
                    isActive: false,
                    onTap: () => onAction(_SideTab.changePIN),
                  ),
                  _SideItem(
                    icon: Icons.logout_rounded,
                    activeIcon: Icons.logout_rounded,
                    label: isGuest ? 'End Session' : 'Sign Out',
                    isActive: false,
                    onTap: () => onAction(_SideTab.signOut),
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sidebar/drawer nav item
// ─────────────────────────────────────────────────────────────────────────────
class _SideItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;

  const _SideItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final c = color ?? (isActive ? AppTheme.primary : inactiveColor);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.18), width: 1)
              : null,
        ),
        child: Row(children: [
          Icon(isActive ? activeIcon : icon, size: 18, color: c),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: c)),
        ]),
      ),
    );
  }
}
