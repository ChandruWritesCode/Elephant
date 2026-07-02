# 1. RETAIN CORE METADATA (Required for debugging and stack traces)
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations

# 2. PROTECT YOUR DATA MODELS (Strictly restricted to your package)
# Only keep classes inside your own 'models' package. 
# Do not keep everything globally (which was insecure).
-keep class in.commandlinecoding.elephant.models.** { *; }

# Safely handle JSON conversion methods
-keepclassmembers class in.commandlinecoding.elephant.models.** {
    public static *** fromJson(...);
    public *** toJson(...);
}

# 3. NETWORK FRAMEWORK PROTECTION
# Dio requires internal fields to handle interceptors/requests correctly
-keep class dio.** { *; }
-dontwarn dio.**

# WebSockets require keeping the internal message stream/channel logic
-keep class web_socket_channel.** { *; }
-dontwarn web_socket_channel.**
-keep class com.google.gson.** { *; }

# 4. FLUTTER ENGINE INTEGRATION (Minimized scope)
# Keep only the specific plugin/embedding classes required for initialization
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# 5. PLAY CORE SILENCING (Keeps the build stable)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# 6. SECURITY: Remove unnecessary logging in release builds
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}