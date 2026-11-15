# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Requested ProGuard rules
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-keep class io.supabase.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn io.flutter.plugins.**

# Additional Plugins
-keep class mobile_scanner.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
