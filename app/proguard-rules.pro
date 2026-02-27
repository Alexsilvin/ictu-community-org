# ProGuard rules for ICTU Community

# Keep application classes
-keep class com.ictu.community.** { *; }

# Keep Retrofit classes
-keep class retrofit2.** { *; }
-keepattributes Signature

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*

# Keep Hilt classes
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Keep Room classes
-keep class androidx.room.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclasseswithmembernames class * {
    native <methods>;
}
