// lib/providers/auth_provider.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AppAuthState {
  loading,
  needsFirebaseAuth,
  needsEmailVerification, // new — waiting for user to verify email
  needsPin,
  ready,
}

class AuthProvider extends ChangeNotifier {
  AppAuthState _state = AppAuthState.loading;
  String? _errorMessage;
  int _failedPinAttempts = 0;
  bool _verificationSent = false;
  static const int _maxPinAttempts = 5;

  // ── Session timeout (30 minutes of inactivity → re-prompt PIN) ────────────
  static const Duration _sessionTimeout = Duration(minutes: 30);
  Timer? _sessionTimer;

  /// Call this on any user interaction to reset the inactivity timer.
  void resetSessionTimer() {
    _sessionTimer?.cancel();
    if (_state == AppAuthState.ready) {
      _sessionTimer = Timer(_sessionTimeout, _onSessionExpired);
    }
  }

  void _onSessionExpired() async {
    final hasPin = await StorageService.instance.hasPin();
    if (hasPin) {
      _setState(AppAuthState.needsPin);
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  AppAuthState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isReady => _state == AppAuthState.ready;
  bool get isPinLocked => _failedPinAttempts >= _maxPinAttempts;
  bool get verificationSent => _verificationSent;
  User? get firebaseUser => AuthService.instance.currentUser;

  String get displayName {
    final user = firebaseUser;
    if (user == null) return '';
    if (user.isAnonymous) return 'Guest';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email?.split('@').first ?? 'User';
  }

  Future<void> initialize() async {
    _setState(AppAuthState.loading);
    final user = AuthService.instance.currentUser;
    if (user == null) {
      _setState(AppAuthState.needsFirebaseAuth);
    } else if (!user.isAnonymous && !user.emailVerified) {
      // Signed in but email not verified yet
      _setState(AppAuthState.needsEmailVerification);
    } else {
      final hasPin = await StorageService.instance.hasPin();
      _setState(hasPin ? AppAuthState.needsPin : AppAuthState.ready);
    }
  }

  // Sign up — send verification email immediately after account creation
  Future<void> signUp(String email, String password,
      {String? displayName}) async {
    clearError();
    try {
      final cred =
          await AuthService.instance.signUp(email: email, password: password);
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
        await cred.user?.reload();
      }
      // Send verification email
      await AuthService.instance.sendVerificationEmail();
      _verificationSent = true;
      _setState(AppAuthState.needsEmailVerification);
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      notifyListeners();
    }
  }

  // Sign in — block unverified accounts
  Future<void> signIn(String email, String password) async {
    clearError();
    try {
      await AuthService.instance.signIn(email: email, password: password);
      // Reload to get latest emailVerified status from Firebase
      await AuthService.instance.reloadUser();
      if (!AuthService.instance.isEmailVerified) {
        _verificationSent = false;
        _setState(AppAuthState.needsEmailVerification);
        return;
      }
      final hasPin = await StorageService.instance.hasPin();
      _setState(hasPin ? AppAuthState.needsPin : AppAuthState.ready);
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> signInAsGuest() async {
    clearError();
    try {
      await AuthService.instance.signInAnonymously();
      _setState(AppAuthState.ready);
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      notifyListeners();
    }
  }

  // Re-check if user has clicked the verification link
  Future<void> checkEmailVerified() async {
    clearError();
    await AuthService.instance.reloadUser();
    if (AuthService.instance.isEmailVerified) {
      _verificationSent = false;
      final hasPin = await StorageService.instance.hasPin();
      _setState(hasPin ? AppAuthState.needsPin : AppAuthState.ready);
    } else {
      _errorMessage = 'Email not verified yet. Please check your inbox.';
      notifyListeners();
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    clearError();
    try {
      await AuthService.instance.sendVerificationEmail();
      _verificationSent = true;
      _errorMessage = null;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthService.friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> setPin(String pin) async {
    await StorageService.instance.savePin(pin);
    _failedPinAttempts = 0;
    clearError();
    _setState(AppAuthState.ready);
  }

  void skipPin() {
    clearError();
    _setState(AppAuthState.ready);
  }

  Future<bool> verifyPin(String input) async {
    if (isPinLocked) {
      _errorMessage = 'Too many failed attempts. Restart the app.';
      notifyListeners();
      return false;
    }
    final stored = await StorageService.instance.readPin();
    if (input == stored) {
      _failedPinAttempts = 0;
      clearError();
      _setState(AppAuthState.ready);
      return true;
    }
    _failedPinAttempts++;
    final left = _maxPinAttempts - _failedPinAttempts;
    _errorMessage = left > 0
        ? 'Incorrect PIN. $left attempt${left == 1 ? '' : 's'} remaining.'
        : 'Too many failed attempts. Restart the app.';
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    await StorageService.instance.clearSecureData();
    _failedPinAttempts = 0;
    _verificationSent = false;
    clearError();
    _setState(AppAuthState.needsFirebaseAuth);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AppAuthState s) {
    _state = s;
    if (s == AppAuthState.ready) {
      resetSessionTimer();
    } else {
      _sessionTimer?.cancel();
    }
    notifyListeners();
  }
}
