# Keep Flutter’s JNI bridge and plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep AndroidX basics and metadata often used by plugins
-keep class androidx.** { *; }
-keep class kotlin.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.metadata.** { *; }

# ML/Camera/location related (used in your app via plugins)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.** { *; }
-keep class com.google.android.material.** { *; }
-keep class com.google.zxing.** { *; }
-keep class org.tensorflow.lite.** { *; }

# Prevent removal of needed annotations
-keepattributes *Annotation*