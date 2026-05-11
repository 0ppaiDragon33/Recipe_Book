// lib/screens/cook_mode_screen.dart
// Fullscreen step-by-step cook mode. Keeps screen awake, big text, tap to advance.
// Each step has an optional countdown timer.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';

class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _currentStep = 0;
  int? _timerSeconds; // null = not running
  int _timerRemaining = 0;
  Timer? _timer;
  bool _timerPaused = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _timerSeconds = seconds;
      _timerRemaining = seconds;
      _timerPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_timerPaused) {
        setState(() {
          if (_timerRemaining > 0) {
            _timerRemaining--;
          } else {
            _timer?.cancel();
            // Done — show indicator
          }
        });
      }
    });
  }

  void _pauseResumeTimer() {
    setState(() => _timerPaused = !_timerPaused);
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = null;
      _timerRemaining = 0;
      _timerPaused = false;
    });
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.steps.length - 1) {
      _cancelTimer();
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _cancelTimer();
      setState(() => _currentStep--);
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    final step = steps[_currentStep];
    final isLast = _currentStep == steps.length - 1;
    final isFirst = _currentStep == 0;
    final timerDone = _timerSeconds != null && _timerRemaining == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(children: [
                    Text(widget.recipe.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Step ${_currentStep + 1} of ${steps.length}',
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: Colors.white38)),
                  ]),
                ),
                // Timer button
                IconButton(
                  icon: Icon(
                    _timerSeconds != null
                        ? Icons.timer_rounded
                        : Icons.timer_outlined,
                    color: _timerSeconds != null
                        ? AppTheme.accent
                        : Colors.white70,
                  ),
                  onPressed: () => _showTimerPicker(context),
                  tooltip: 'Set timer',
                ),
              ]),
            ),

            // ── Progress bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final active = i == _currentStep;
                  final done = i < _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: done
                            ? AppTheme.secondary
                            : active
                                ? AppTheme.primary
                                : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Timer display ─────────────────────────────────────────────
            if (_timerSeconds != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: timerDone
                      ? AppTheme.primary.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: timerDone ? AppTheme.primary : Colors.white12,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      timerDone
                          ? Icons.notifications_active_rounded
                          : Icons.timer_rounded,
                      color: timerDone ? AppTheme.primary : AppTheme.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timerDone ? 'Timer done!' : _formatTime(_timerRemaining),
                      style: GoogleFonts.dmSans(
                        fontSize: timerDone ? 18 : 28,
                        fontWeight: FontWeight.w700,
                        color: timerDone ? AppTheme.primary : Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    if (!timerDone) ...[
                      IconButton(
                        icon: Icon(
                            _timerPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white70,
                            size: 22),
                        onPressed: _pauseResumeTimer,
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white38, size: 18),
                      onPressed: _cancelTimer,
                    ),
                  ],
                ),
              ),

            // ── Step content ──────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if (d.primaryVelocity != null) {
                    if (d.primaryVelocity! < -300) _nextStep();
                    if (d.primaryVelocity! > 300) _prevStep();
                  }
                },
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Step number circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${_currentStep + 1}',
                            style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 28),
                      // Step text
                      Text(
                        step,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontSize: 22,
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Swipe hint
                      Text('Swipe or tap arrows to navigate',
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: Colors.white24)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Navigation ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(children: [
                // Prev
                _NavButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Prev',
                  enabled: !isFirst,
                  onTap: _prevStep,
                ),
                const Spacer(),
                // Done / Next
                if (isLast)
                  _FinishButton(onTap: () => Navigator.pop(context))
                else
                  _NavButton(
                    icon: Icons.arrow_forward_rounded,
                    label: 'Next',
                    enabled: true,
                    primary: true,
                    onTap: _nextStep,
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimerPicker(BuildContext context) {
    int minutes = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Set Timer',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 20),
            // Quick presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 2, 3, 5, 10, 15, 20, 30]
                  .map((m) => GestureDetector(
                        onTap: () {
                          setS(() => minutes = m);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: minutes == m
                                ? AppTheme.primary
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${m}m',
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: minutes == m
                                      ? Colors.white
                                      : Colors.white60)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startTimer(minutes * 60);
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              child: Text('Start $minutes-Minute Timer',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;
  const _NavButton(
      {required this.icon,
      required this.label,
      required this.enabled,
      this.primary = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.25,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: primary
                  ? AppTheme.primary
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              if (!primary) Icon(icon, size: 18, color: Colors.white70),
              if (!primary) const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              if (primary) const SizedBox(width: 8),
              if (primary) Icon(icon, size: 18, color: Colors.white),
            ]),
          ),
        ),
      );
}

class _FinishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FinishButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded,
                size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text('Done!',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
        ),
      );
}
