// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/local_features_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/firebase_options.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed, but the app can continue with limited functionality
  }
  final settings = SettingsProvider();
  await settings.initialize();
  final localFeatures = LocalFeaturesProvider();
  await localFeatures.initialize();
  runApp(RecipeBookApp(settings: settings, localFeatures: localFeatures));
}

class RecipeBookApp extends StatelessWidget {
  final SettingsProvider settings;
  final LocalFeaturesProvider localFeatures;
  const RecipeBookApp(
      {super.key, required this.settings, required this.localFeatures});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: localFeatures),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, s, __) => MaterialApp(
          title: 'Culinary Cookbook',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLight(s.fontScale),
          darkTheme: AppTheme.buildDark(s.fontScale),
          themeMode: s.flutterThemeMode,
          // ── Global keyboard lag fix ───────────────────────────────────────
          // Prevents every Scaffold from resizing when the keyboard opens.
          // Equivalent to resizeToAvoidBottomInset: false on every screen.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
            child: child!,
          ),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  AppAuthState? _prevState;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recipe = context.read<RecipeProvider>();
    if (_prevState == AppAuthState.ready && auth.state != AppAuthState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => recipe.reset());
    }
    _prevState = auth.state;
    return switch (auth.state) {
      AppAuthState.loading => const _SplashScreen(),
      AppAuthState.needsFirebaseAuth => const LoginScreen(),
      AppAuthState.needsEmailVerification => const VerifyEmailScreen(),
      AppAuthState.needsPin => const PinScreen(isSetup: false),
      AppAuthState.ready => const _RecipeLoader(),
    };
  }
}

class _RecipeLoader extends StatefulWidget {
  const _RecipeLoader();
  @override
  State<_RecipeLoader> createState() => _RecipeLoaderState();
}

class _RecipeLoaderState extends State<_RecipeLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.38),
                      blurRadius: 28,
                      offset: const Offset(0, 10))
                ],
              ),
              child: const Icon(Icons.menu_book_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text('Culinary Cookbook',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.cream)),
            const SizedBox(height: 6),
            Text('Your personal recipe collection',
                style: GoogleFonts.lora(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 36),
            SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15))),
          ]),
        ),
      );
}
