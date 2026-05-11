// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const SettingsScreen({super.key, this.onMenuTap});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final name = context.read<SettingsProvider>().displayName ?? '';
    _nameCtrl = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final isGuest = auth.firebaseUser?.isAnonymous ?? true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.cream : AppTheme.lightTextDark;
    final subColor = isDark ? AppTheme.textMid : AppTheme.lightTextMid;
    final cardColor = isDark ? AppTheme.surface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.border : AppTheme.lightBorder;

    final isWide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        leading: (!isWide && widget.onMenuTap != null)
            ? IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AppTheme.textMid, size: 22),
                onPressed: widget.onMenuTap,
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text('Settings',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Profile ──────────────────────────────────────────────────────
          _SectionHeader('Profile', isDark),
          _Card(
              color: cardColor,
              border: borderColor,
              child: Column(children: [
                if (isGuest) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Guest',
                                style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                            const SizedBox(height: 2),
                            Text('Sign in to set a display name and email.',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: subColor)),
                          ])),
                      const Icon(Icons.lock_outline_rounded,
                          size: 16, color: AppTheme.primary),
                    ]),
                  ),
                ] else ...[
                  _LabeledRow(
                    label: 'Display Name',
                    subColor: subColor,
                    textColor: textColor,
                    child: SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _nameCtrl,
                        style:
                            GoogleFonts.dmSans(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText:
                              auth.firebaseUser?.email?.split('@').first ??
                                  'Your name',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        onFieldSubmitted: (v) =>
                            context.read<SettingsProvider>().setDisplayName(v),
                      ),
                    ),
                  ),
                  _Divider(isDark),
                  ListTile(
                    dense: true,
                    title: Text('Email',
                        style:
                            GoogleFonts.dmSans(fontSize: 13, color: subColor)),
                    trailing: Text(
                      auth.firebaseUser?.email ?? '—',
                      style: GoogleFonts.dmSans(fontSize: 13, color: textColor),
                    ),
                  ),
                ],
              ])),

          const SizedBox(height: 24),

          // ── Appearance ───────────────────────────────────────────────────
          _SectionHeader('Appearance', isDark),
          _Card(
              color: cardColor,
              border: borderColor,
              child: Column(children: [
                // Theme toggle
                _LabeledRow(
                  label: 'Theme',
                  subColor: subColor,
                  textColor: textColor,
                  child: _ThemeToggle(
                      current: s.themeMode,
                      onChanged: (v) => s.setThemeMode(v)),
                ),
                _Divider(isDark),
                // Font size
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Font Size',
                            style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        const Spacer(),
                        Text(_fontLabel(s.fontScale),
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor:
                              isDark ? AppTheme.border : AppTheme.lightBorder,
                          thumbColor: AppTheme.primary,
                          overlayColor:
                              AppTheme.primary.withValues(alpha: 0.15),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: s.fontScale,
                          min: 0.8,
                          max: 1.4,
                          divisions: 6,
                          onChanged: (v) => s.setFontScale(v),
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Small',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.textLight
                                        : AppTheme.lightTextLight)),
                            Text('Large',
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppTheme.textLight
                                        : AppTheme.lightTextLight)),
                          ]),
                      const SizedBox(height: 8),
                      // Preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.surfaceAlt
                              : AppTheme.lightSurfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'The quick brown fox jumped over the lazy dog.',
                          style: GoogleFonts.lora(
                              fontSize: 14 * s.fontScale,
                              color: subColor,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ])),

          const SizedBox(height: 32),

          // Save display name button
          ElevatedButton.icon(
            onPressed: () {
              context.read<SettingsProvider>().setDisplayName(_nameCtrl.text);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Settings saved!',
                    style: GoogleFonts.dmSans(color: AppTheme.cream)),
                backgroundColor: AppTheme.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
              ));
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fontLabel(double scale) {
    if (scale <= 0.8) return 'Extra Small';
    if (scale <= 0.9) return 'Small';
    if (scale <= 1.0) return 'Normal';
    if (scale <= 1.1) return 'Medium';
    if (scale <= 1.2) return 'Large';
    if (scale <= 1.3) return 'X-Large';
    return 'XX-Large';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader(this.title, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(title.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppTheme.primary)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color border;
  const _Card({required this.child, required this.color, required this.border});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1),
        ),
        child: child,
      );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, color: isDark ? AppTheme.divider : AppTheme.lightDivider);
}

class _LabeledRow extends StatelessWidget {
  final String label;
  final Color subColor;
  final Color textColor;
  final Widget child;
  const _LabeledRow(
      {required this.label,
      required this.subColor,
      required this.textColor,
      required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
          const Spacer(),
          child,
        ]),
      );
}

class _ThemeToggle extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _ThemeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('dark', Icons.dark_mode_rounded, 'Dark'),
      ('light', Icons.light_mode_rounded, 'Light'),
      ('auto', Icons.brightness_auto_rounded, 'Auto'),
    ];
    return Row(
      children: options.map((o) {
        final active = current == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: active ? AppTheme.primary : AppTheme.border, width: 1),
            ),
            child: Row(children: [
              Icon(o.$2,
                  size: 14, color: active ? Colors.white : AppTheme.textLight),
              const SizedBox(width: 4),
              Text(o.$3,
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppTheme.textLight)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
