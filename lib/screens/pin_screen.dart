// lib/screens/pin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, required this.isSetup});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _shake;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shake, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _shake.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: GoogleFonts.dmSans(color: AppTheme.cream))),
      ]),
      backgroundColor:
          success ? AppTheme.secondary : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();

    if (widget.isSetup) {
      await auth.setPin(_pinCtrl.text.trim());
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar('PIN saved successfully!', success: true);
      }
    } else {
      final ok = await auth.verifyPin(_pinCtrl.text.trim());
      if (mounted) {
        setState(() => _loading = false);
        if (!ok) {
          _shake.forward(from: 0);
          _showSnackBar(
            auth.errorMessage ?? 'Incorrect PIN. Please try again.',
            success: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isSetup && auth.isReady
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textLight, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Change PIN',
                  style: GoogleFonts.cormorantGaramond(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.cream : AppTheme.lightTextDark)),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 28,
                vertical: 44,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ────────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.primary.withValues(alpha: 0.38),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isSetup
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    widget.isSetup ? 'Set Up PIN Lock' : 'Enter Your PIN',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.cream : AppTheme.lightTextDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isSetup
                        ? 'Protect your app with a 4–6 digit PIN'
                        : 'Enter your PIN to unlock the app',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // ── Form card with shake ─────────────────────────────
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final offset =
                          Curves.elasticOut.transform(_shake.value);
                      final dx = offset == 0
                          ? 0.0
                          : (8 *
                              (1 - offset) *
                              ((_shake.value * 4).round().isEven
                                  ? 1
                                  : -1));
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.border : AppTheme.lightBorder, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 28,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          // PIN field
                          TextFormField(
                            controller: _pinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: _obscure,
                            maxLength: 6,
                            style: GoogleFonts.dmSans(
                                fontSize: 22,
                                letterSpacing: 10,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.cream : AppTheme.lightTextDark),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textLight,
                                  size: 18,
                                ),
                                onPressed: () => setState(
                                    () => _obscure = !_obscure),
                              ),
                            ),
                            validator: Validators.pin,
                          ),

                          // Confirm PIN (setup only)
                          if (widget.isSetup) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmCtrl,
                              keyboardType: TextInputType.number,
                              obscureText: _obscure,
                              maxLength: 6,
                              style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  letterSpacing: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.cream : AppTheme.lightTextDark),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                labelText: 'Confirm PIN',
                                counterText: '',
                              ),
                              validator: (v) {
                                final err = Validators.pin(v);
                                if (err != null) return err;
                                if (v != _pinCtrl.text) {
                                  return 'PINs do not match.';
                                }
                                return null;
                              },
                            ),
                          ],

                          // Error banner
                          if (auth.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error
                                    .withValues(alpha: 0.10),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.error
                                        .withValues(alpha: 0.25),
                                    width: 1),
                              ),
                              child: Row(children: [
                                const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.error,
                                    size: 15),
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

                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  (auth.isPinLocked || _loading)
                                      ? null
                                      : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : Text(
                                      widget.isSetup
                                          ? 'Set PIN'
                                          : 'Unlock',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),

                          // Skip (setup only)
                          if (widget.isSetup) ...[
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () =>
                                  context.read<AuthProvider>().skipPin(),
                              child: Text('Skip for now',
                                  style: GoogleFonts.dmSans(
                                      color: AppTheme.textLight,
                                      fontSize: 12)),
                            ),
                          ],

                          // Lock message (verify only)
                          if (!widget.isSetup && auth.isPinLocked) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error
                                    .withValues(alpha: 0.07),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      color: AppTheme.error,
                                      size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Too many attempts. Try again later.',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
