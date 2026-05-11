# ProGuard rules for Recipe Book
# Week 12 — Required by build.gradle (minifyEnabled + shrinkResources)

# Flutter — keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase — keep Firebase classes from being stripped
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# OkHttp / HTTP (used by http package)
-dontwarn okhttp3.**
-dontwarn okio.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep model classes (Firestore serialization)
-keep class com.example.recipe_book.** { *; }

# Suppress warnings for missing classes in dependencies
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Flutter Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }