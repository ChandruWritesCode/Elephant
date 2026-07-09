# 1. RETAIN CORE METADATA (Required for clean crash logs, stack traces, and reflection)
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable
-keepattributes RuntimeVisibleAnnotations

# 2. PROTECT DATA MODELS & SERIALIZATION SCHEMA (Restricted precisely to your package)
# Keeps data models intact to prevent broken chats or missing message properties in release packages
-keep class in.commandlinecoding.elephant.models.** { *; }

# Safely preserve custom JSON serialization methods used by incoming/outgoing pipelines
-keepclassmembers class in.commandlinecoding.elephant.models.** {
    public static *** fromJson(...);
    public *** toJson(...);
}

# 3. NETWORK FRAMEWORK PROTECTION (Preserves HTTP & Persistent WebSocket Engines)
# Dio requires internal fields to handle interceptors, token rotations, and request configurations correctly
-keep class dio.** { *; }
-dontwarn dio.**

# WebSockets require keeping the internal message stream/channel logic
-keep class web_socket_channel.** { *; }
-dontwarn web_socket_channel.**

# Retain Gson serialization references if used by native plugin drivers
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# 4. FLUTTER ENGINE & NATIVE PLUGINS INTEGRATION (Minimized optimization scope)
# Keep the core embedding engine classes required for application initialization
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# 5. FOSS COMPLIANCE: PLAY CORE HOOKS SILENCING
# Tells R8 to safely ignore missing Google Play binary symbols without packing non-free SDKs
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# 6. APP SECURITY & PERFORMANCE: Remove debugging logs from the release binary
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
}