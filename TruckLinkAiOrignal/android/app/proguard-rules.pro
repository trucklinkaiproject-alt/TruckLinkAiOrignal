# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepclassmembers class * {
    @com.google.firebase.database.IgnoreExtraProperties *;
    @com.google.firebase.firestore.IgnoreExtraProperties *;
    @com.google.firebase.database.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Play Store split install suppression for Flutter embedding
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

