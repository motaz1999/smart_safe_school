# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep MainActivity - Critical for app launch
-keep class com.smartsafeschool.app.MainActivity { *; }
-keep class com.smartsafeschool.app.** { *; }

# Keep all activities and their methods
-keep public class * extends android.app.Activity
-keep public class * extends io.flutter.embedding.android.FlutterActivity

# Supabase specific rules
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Additional Flutter embedding rules
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# ---- R8/ProGuard Additions for Flutter + Supabase/Ktor/OkHttp/Kotlin Serialization ----

# Preserve important attributes often needed by reflection and serializers
-keepattributes RuntimeVisibleAnnotations,RuntimeInvisibleAnnotations,AnnotationDefault,Signature,EnclosingMethod,InnerClasses

# Flutter generated registrant (defensive)
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Kotlin serialization: keep serializers and @Serializable models
-keep class kotlinx.serialization.** { *; }
-keep @kotlinx.serialization.Serializable class ** { *; }
-keepclassmembers class **$$serializer { *; }
-dontwarn kotlinx.serialization.**

# Ktor + OkHttp + Okio networking stack (used by Supabase in many setups)
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Kotlin coroutines warnings are safe to ignore in shrinked builds
-dontwarn kotlinx.coroutines.**

# If WorkManager is used by any plugin (defensive)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Gson (defensive: in case any plugin or code path uses Gson)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class com.google.gson.reflect.TypeToken { *; }

# Keep your app package (defensive for reflection-based access)
-keep class com.smartsafeschool.** { *; }

# -------------------------------------------------------------------------------

# Play Core keep rules to satisfy Flutter deferred components references
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }