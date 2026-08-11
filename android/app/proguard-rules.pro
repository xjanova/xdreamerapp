# Flutter's own classes are kept by the Flutter Gradle plugin's consumer rules.
# These cover plugins that reach for their classes reflectively.

# video_player (ExoPlayer / media3)
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Play Core is referenced by Flutter's deferred-components support, which this
# app does not use. Without this, R8 fails the release build on missing classes.
-dontwarn com.google.android.play.core.**
