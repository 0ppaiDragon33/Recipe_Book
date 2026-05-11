// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    if (_isSignUp) {
      await auth.signUp(_emailCtrl.text.trim(), _passCtrl.text,
          displayName: _nameCtrl.text.trim());
    } else {
      await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guest() async {
    setState(() => _loading = true);
    await context.read<AuthProvider>().signInAsGuest();
    if (mounted) setState(() => _loading = false);
  }

  void _toggleMode() {
    context.read<AuthProvider>().clearError();
    _anim
      ..reset()
      ..forward();
    setState(() => _isSignUp = !_isSignUp);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? AppTheme.background : AppTheme.lightBackground;
    final Color surface = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final Color surfaceAlt =
        isDark ? AppTheme.surfaceAlt : AppTheme.lightSurfaceAlt;
    final Color border = isDark ? AppTheme.border : AppTheme.lightBorder;
    final Color cream = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final Color textDark = isDark ? AppTheme.textDark : AppTheme.lightTextDark;
    final Color textMid = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final Color textLight =
        isDark ? AppTheme.textLight : AppTheme.lightTextLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Warm glow — top right
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Warm glow — bottom left
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 100 : 24,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Brand ─────────────────────────────────
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.38),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.menu_book_rounded,
                                      size: 32, color: Colors.white),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Culinary Cookbook',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: isWide ? 34 : 28,
                                    fontWeight: FontWeight.w600,
                                    color: cream,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isSignUp
                                      ? 'Create an account to begin'
                                      : 'Welcome back — sign in to continue',
                                  style: GoogleFonts.lora(
                                      fontSize: 13,
                                      color: textLight,
                                      fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── Form card ─────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: border, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x50000000),
                                  blurRadius: 32,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isSignUp ? 'Create Account' : 'Sign In',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: cream,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  if (_isSignUp) ...[
                                    _fieldLabel('Username', textLight),
                                    const SizedBox(height: 8),
                                    _buildField(
                                      controller: _nameCtrl,
                                      hint: 'e.g. Chef Marco',
                                      icon: Icons.person_outline_rounded,
                                      textColor: textDark,
                                      hintColor: textLight,
                                      fillColor: surfaceAlt,
                                      borderColor: border,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Username required.';
                                        }
                                        if (v.trim().length < 2) {
                                          return 'At least 2 characters.';
                                        }
                                        if (v.trim().length > 30) {
                                          return 'Max 30 characters.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _fieldLabel('Email', textLight),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _emailCtrl,
                                    hint: 'you@example.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textColor: textDark,
                                    hintColor: textLight,
                                    fillColor: surfaceAlt,
                                    borderColor: border,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email required.';
                                      }
                                      if (!RegExp(r'^[\w\-.]+@[\w\-.]+.\w+$')
                                          .hasMatch(v.trim())) {
                                        return 'Enter a valid email.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _fieldLabel('Password', textLight),
                                  const SizedBox(height: 8),
                                  _buildField(
                                    controller: _passCtrl,
                                    hint: _isSignUp
                                        ? 'Min 6 characters'
                                        : '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    textColor: textDark,
                                    hintColor: textLight,
                                    fillColor: surfaceAlt,
                                    borderColor: border,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: textLight,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password required.';
                                      }
                                      if (_isSignUp && v.length < 6) {
                                        return 'Minimum 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (auth.errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error
                                            .withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppTheme.error
                                                .withValues(alpha: 0.25),
                                            width: 1),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.error_outline_rounded,
                                            color: AppTheme.error, size: 15),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(auth.errorMessage!,
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 12,
                                                  color: AppTheme.error)),
                                        ),
                                      ]),
                                    ),
                                  ],
                                  const SizedBox(height: 26),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      onPressed: _loading ? null : _submit,
                                      child: _loading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
                                          : Text(
                                              _isSignUp
                                                  ? 'Create Account'
                                                  : 'Sign In',
                                              style: GoogleFonts.dmSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: TextButton(
                                      onPressed: _toggleMode,
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.dmSans(
                                              fontSize: 13, color: textLight),
                                          children: [
                                            TextSpan(
                                              text: _isSignUp
                                                  ? 'Already have an account? '
                                                  : "Don't have an account? ",
                                            ),
                                            TextSpan(
                                              text: _isSignUp
                                                  ? 'Sign in'
                                                  : 'Sign up',
                                              style: GoogleFonts.dmSans(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Divider ───────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            child: Row(children: [
                              Expanded(
                                  child: Divider(color: border, thickness: 1)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('or',
                                    style: GoogleFonts.dmSans(
                                        color: textLight,
                                        fontSize: 12,
                                        letterSpacing: 0.5)),
                              ),
                              Expanded(
                                  child: Divider(color: border, thickness: 1)),
                            ]),
                          ),

                          // ── Guest button ──────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _guest,
                              icon: Icon(Icons.person_outline_rounded,
                                  size: 17, color: textMid),
                              label: Text('Continue as Guest',
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: textMid)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textMid,
                                side: BorderSide(color: border, width: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                backgroundColor: surfaceAlt,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Guests can browse but cannot add recipes.',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: textLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) => Text(
        text,
        style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color textColor,
    required Color hintColor,
    required Color fillColor,
    required Color borderColor,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.lora(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.lora(color: hintColor, fontSize: 14),
        prefixIcon: Icon(icon, color: hintColor, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      validator: validator,
    );
  }
}
