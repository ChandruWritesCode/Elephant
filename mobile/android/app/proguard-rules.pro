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

# 4. FLUTTER ENGINE & NATIVE PLUGINS INTEGRATION (Optimized optimization scope)
# REPLACED BROAD EMBEDDING KEEP RULE: Allows R8 to strip unused embedding classes (like SplitInstall) 
# while safely preserving the core infrastructure used during app startup.
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.loader.FlutterLoader { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragment { *; }
-keep class io.flutter.embedding.android.FlutterView { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# 5. FOSS COMPLIANCE & DEFERRED COMPONENTS REMOVAL
# Correct R8 syntax to mark the Play Store manager and listeners as entry points that CAN be shrunk/deleted
-keep,allowshrinking class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep,allowshrinking class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$FeatureInstallStateUpdatedListener { *; }

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
