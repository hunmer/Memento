
# Flutter 保留规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保留所有带有@Keep注解的类
-keep @androidx.annotation.Keep class * {*;}

# 保留Flutter native绑定
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }

# 保留插件类
-keep class * implements io.flutter.plugin.common.PluginRegistry.Plugin { *; }

# 保留资源
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 保留JSON模型类
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 保留Play Core Split相关类
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class * implements com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }