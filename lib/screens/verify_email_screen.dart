// lib/screens/verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.firebaseUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.38),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined,
                        size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Verify Your Email',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.cream,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to:',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Click the link in the email, then tap the button below.',
                    style: GoogleFonts.lora(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Error banner
                  if (auth.errorMessage != null) ...[
                    _Banner(
                      icon: Icons.error_outline_rounded,
                      text: auth.errorMessage!,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Success banner
                  if (auth.verificationSent) ...[
                    const _Banner(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Verification email sent!',
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.read<AuthProvider>().checkEmailVerified(),
                      icon: const Icon(Icons.verified_outlined,
                          color: Colors.white, size: 17),
                      label: Text(
                        "I've Verified My Email",
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Resend
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .read<AuthProvider>()
                          .resendVerificationEmail(),
                      icon: const Icon(Icons.send_outlined, size: 15),
                      label: Text('Resend Email',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMid,
                        side:
                            const BorderSide(color: AppTheme.border, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor: AppTheme.surfaceAlt,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    child: Text('Back to Sign In',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppTheme.textLight)),
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

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _Banner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.dmSans(fontSize: 12, color: color)),
          ),
        ]),
      );
}
