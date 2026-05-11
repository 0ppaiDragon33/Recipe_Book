// lib/services/storage_service.dart
// Week 8 — Secure local storage.
//   • FlutterSecureStorage → PIN (encrypted at rest)
//   • SharedPreferences   → onboarding flag (non-sensitive)
// Favorites are now stored in Firestore, not locally.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── PIN (encrypted) ───────────────────────────────────────────────────────
  Future<void> savePin(String pin) =>
      _secure.write(key: AppConstants.keyUserPin, value: pin);

  Future<String?> readPin() =>
      _secure.read(key: AppConstants.keyUserPin);

  Future<void> deletePin() =>
      _secure.delete(key: AppConstants.keyUserPin);

  Future<bool> hasPin() async {
    final pin = await readPin();
    return pin != null && pin.isNotEmpty;
  }

  // ── Onboarding flag (non-sensitive) ──────────────────────────────────────
  Future<bool> isOnboarded() async {
    final onboarded = await _secure.read(key: AppConstants.keyOnboarded);
    return onboarded == 'true';
  }

  Future<void> setOnboarded() async {
    await _secure.write(key: AppConstants.keyOnboarded, value: 'true');
  }

  // ── Clear secure data on logout ───────────────────────────────────────────
  Future<void> clearSecureData() => deletePin();
}
