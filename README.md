# Culinary Cookbook

A secure Flutter recipe book app with Firebase backend, PIN lock, cloud sync, and local-first features.

---

## Description

Culinary Cookbook lets users discover, save, and create their own recipes. Recipes are stored in Firebase Firestore and synced in real time across sessions. Users can sign in with email/password or browse anonymously as a guest. An optional PIN lock adds a local security layer on top of Firebase Authentication. New features include Cook Mode, recipe collections, a shopping list, serving scaler, personal notes, and dark/light/auto theming — all stored locally with no Firebase changes required.

---

## Features

- Browse a curated library of recipes across multiple categories
- Search and filter by category, name, or tag
- Filter by maximum total cook time
- Sort by rating, cook time, or name
- Add your own recipes with photo upload (Cloudinary)
- Mark recipes as favorites (synced per user in Firestore)
- **Cook Mode** — fullscreen step-by-step with screen always on, swipe to advance, and per-step countdown timers
- **Serving size scaler** — tap +/− on the detail screen to scale all ingredients automatically
- **Recipe collections** — create named folders and organize recipes locally
- **Personal notes** — write private notes on any recipe, stored on-device
- **Shopping list** — add ingredients from any recipe, check off items, swipe to delete
- **Recently viewed** — horizontal strip of the last 6 recipes you opened
- **Random recipe** button — tap the dice icon for a surprise pick
- **Dark / Light / Auto theme** toggle (persisted across sessions)
- **Font size control** — 7 steps from Extra Small to XX-Large
- **Default category & cuisine** preferences saved in Settings
- **Display name** editing (local, shown in the sidebar/header)
- Firebase Authentication — email/password, email verification, guest mode
- Optional 4–6 digit PIN lock with lockout after 5 failed attempts and 30-minute session timeout
- Responsive layout — sidebar on desktop (> 800 px), bottom nav + drawer on mobile
- Full form validation with XSS input sanitization
- Duplicate any recipe you own with one tap

---

## Screenshots
- Home Screen ![Home Screen](https://github.com/0ppaiDragon33/Recipe_Book/blob/74489868cfa3c4d460c75a11adbdaf9984d0017e/Homescreen.png)
- Favorites ![Favorites](https://github.com/0ppaiDragon33/Recipe_Book/blob/ed013414f8fad2d557ca40e650eef24deaf46f34/Favorites.png)

---

## Security Features (Course Goal 1)

- [x] **HTTPS for all API calls** — Firebase SDK and Cloudinary both use HTTPS/TLS
- [x] **Encrypted storage for sensitive data** — PIN stored via `FlutterSecureStorage` with `encryptedSharedPreferences: true` on Android
- [x] **No sensitive data in SharedPreferences** — PIN/tokens stay in `FlutterSecureStorage`; only non-sensitive local data (collections, notes, shopping list) uses `SharedPreferences`
- [x] **Input validation** — email format, password length, recipe name length (3–80 chars), PIN digits-only
- [x] **Input sanitization (XSS prevention)** — `<script>`, `javascript:`, `onerror=`, `onload=` patterns rejected; `<` and `>` escaped on display
- [x] **Secure authentication** — Firebase Auth with JWT tokens managed entirely by the Firebase SDK
- [x] **Logout clears all sensitive data** — `signOut()` deletes PIN from secure storage
- [x] **Session timeout implemented** — 30-minute inactivity timer re-prompts PIN lock
- [x] **PIN lockout** — locked after 5 consecutive wrong attempts
- [x] **User-friendly error messages** — Firebase errors mapped to safe messages; raw codes only logged via `debugPrint`
- [x] **No hardcoded API secrets** — Cloudinary uses an unsigned upload preset (public by design; no API secret in code)
- [x] **Firebase security rules** — Firestore enforces auth-required reads, creator-only writes, and per-user favorites (not in test mode)
- [x] **Debug banner removed** — `debugShowCheckedModeBanner: false`
- [x] **No print() statements** — only `debugPrint()` used (stripped in release builds)

---

## Why Flutter? (Course Goal 2)

- **Cross-platform** — one codebase runs on Android and iOS
- **Hot reload** — sped up UI iteration significantly during development
- **Widget system** — composable widgets made the recipe card, cook mode, and shopping list easy to build and reuse across screens
- **Provider** — minimal boilerplate for state management; `AuthProvider`, `RecipeProvider`, `SettingsProvider`, and `LocalFeaturesProvider` integrate cleanly with `MultiProvider`
- **FlutterFire** — official Firebase plugins (`firebase_auth`, `cloud_firestore`) are maintained by the same team, reducing compatibility issues
- **Built-in async/await** — Dart's async model made Firestore real-time streams and image uploads straightforward
- **ThemeData / ThemeMode** — switching between dark, light, and system themes is a single property change, no custom logic needed
- **WakelockPlus** — keeping the screen on during Cook Mode required one line of Dart vs complex native code on each platform

---

## Setup Instructions

### Prerequisites
- Flutter SDK 3.x
- Android Studio / Xcode
- A Firebase project with **Authentication** and **Firestore** enabled

### Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd recipe_book
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Email/Password and Anonymous sign-in under Authentication
   - Create a Firestore database (start in **production mode**, not test mode)
   - Download `google-services.json` → place in `android/app/`
   - The `lib/services/firebase_options.dart` file already contains platform options (update with your own values if needed)

4. **Deploy Firestore security rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

6. **Run tests**
   ```bash
   flutter test
   ```

### Building a release APK (Week 12)

1. Generate a keystore (one-time):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (already in `.gitignore`):
   ```
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=/Users/yourname/upload-keystore.jks
   ```

3. Build:
   ```bash
   flutter build apk --release
   # or for Play Store:
   flutter build appbundle --release
   ```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | State management |
| `firebase_core` | ^3.1.0 | Firebase initialization |
| `firebase_auth` | ^5.1.0 | Authentication |
| `cloud_firestore` | ^5.1.0 | Cloud database |
| `flutter_secure_storage` | ^9.0.0 | Encrypted local storage (PIN) |
| `shared_preferences` | ^2.3.0 | Local storage (settings, collections, notes, shopping list) |
| `cached_network_image` | ^3.3.0 | Image caching |
| `image_picker` | ^1.1.2 | Photo selection |
| `http` | ^1.2.0 | Cloudinary image upload |
| `google_fonts` | ^6.1.0 | Typography |
| `flutter_animate` | ^4.5.0 | UI animations |
| `uuid` | ^4.4.0 | Recipe ID generation |
| `wakelock_plus` | ^1.2.8 | Keep screen on during Cook Mode |
| `share_plus` | ^10.0.0 | Export/share recipe as text |

---

## Project Structure

```
lib/
├── main.dart                        # App entry, providers, theme routing
├── models/
│   └── recipe.dart                  # Recipe data model
├── providers/
│   ├── auth_provider.dart           # Firebase auth + PIN state
│   ├── recipe_provider.dart         # Recipe list, favorites, filters
│   ├── settings_provider.dart       # Theme, font scale, display name, defaults
│   └── local_features_provider.dart # Collections, notes, shopping list, recently viewed
├── screens/
│   ├── login_screen.dart
│   ├── pin_screen.dart
│   ├── verify_email_screen.dart
│   ├── home_screen.dart             # Recipes tab, drawer, random recipe, time filter
│   ├── recipe_detail_screen.dart    # Serving scaler, cook mode, notes, shopping, share
│   ├── add_recipe_screen.dart
│   ├── favorites_screen.dart
│   ├── cook_mode_screen.dart        # Fullscreen step-by-step, wakelock, timers
│   ├── collections_screen.dart      # Folder management + detail view
│   ├── shopping_list_screen.dart    # Swipe-to-delete, check off items
│   └── settings_screen.dart         # Theme, font size, display name, defaults
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── recipe_service.dart
│   ├── storage_service.dart
│   ├── cloudinary_service.dart
│   ├── local_storage_service.dart   # SharedPreferences wrapper for local features
│   └── firebase_options.dart
├── utils/
│   ├── app_theme.dart               # Dark + light themes, font scaling
│   ├── constants.dart
│   └── validators.dart
└── widgets/
    └── recipe_card.dart

test/
├── models/recipe_test.dart          # 7 unit tests
├── services/validators_test.dart    # 15 unit tests
└── widgets/recipe_card_test.dart    # 9 widget tests
```

---

## Author

Karl Joshua Vargas — karljoshuavargas@gmail.com
