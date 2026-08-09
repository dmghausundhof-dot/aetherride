# Flutter / Play / native keep rules for release minify.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# MapLibre / JNI
-keep class org.maplibre.** { *; }
-keep class com.mapbox.** { *; }
-dontwarn org.maplibre.**
-dontwarn com.mapbox.**

# FlutterBluePlus / BLE
-keep class com.signify.hue.** { *; }
-dontwarn com.google.android.gms.**

# Keep native method names used by MethodChannels / FFI.
-keepclasseswithmembernames class * {
    native <methods>;
}
