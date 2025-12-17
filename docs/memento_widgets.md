# Android 小组件开发指南

本指南说明如何在 Memento 项目中为插件添加 Android 桌面小组件支持。

## 概述

Memento 支持为各插件添加 Android 桌面小组件（1x1 和 2x2 尺寸），可实时展示插件统计数据。小组件通过 Flutter 的 `home_widget` 插件实现。

## 实现步骤

### 1. 添加依赖

在 `android/app/build.gradle` 中添加 home_widget 依赖：

```gradle
dependencies {
    implementation 'dev.fluttercommunity.plus:home_widget:0.4.0'
}
```

### 2. 创建小组件 Provider

在 `android/app/src/main/kotlin/` 目录下创建小组件 Provider 类：

```kotlin
package github.hunmer.memento

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import io.flutter.plugins.homewidget.HomeWidgetPlugin

class PluginWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.plugin_widget_layout)
        // 从 SharedPreferences 读取数据并更新 UI
        val data = HomeWidgetPlugin.getData(context)
        // 根据插件类型设置不同的数据
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
```

### 3. 注册小组件

在 `android/app/src/main/AndroidManifest.xml` 中注册小组件：

```xml
<receiver android:name=".PluginWidgetProvider">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/plugin_widget_info" />
</receiver>
```

### 4. 创建小组件布局

在 `android/app/src/main/res/layout/` 创建 `plugin_widget_layout.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="8dp"
    android:orientation="vertical">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="插件数据"
        android:textSize="12sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/widget_content"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="0"
        android:textSize="16sp" />

</LinearLayout>
```

### 5. 创建小组件信息文件

在 `android/app/src/main/res/xml/` 创建 `plugin_widget_info.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="1"
    android:updatePeriodMillis="0"
    android:previewImage="@drawable/widget_preview"
    android:initialLayout="@layout/plugin_widget_layout"
    android:configure="com.example.memento.WidgetConfigureActivity"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
```

## 数据同步

小组件数据通过 SharedPreferences 与 Flutter 应用同步：

```dart
// Flutter 端更新小组件数据
await HomeWidget.saveWidgetData('title', '今日活动');
await HomeWidget.saveWidgetData('content', '5项活动');
await HomeWidget.updateWidget(
    name: 'PluginWidgetProvider',
    iOSName: 'PluginWidget',
);
```

## 最佳实践

1. **定期更新**：小组件更新频率不宜过高，建议 30 分钟以上
2. **数据缓存**：使用 SharedPreferences 缓存数据，减少读取次数
3. **错误处理**：添加异常处理，避免小组件崩溃
4. **资源优化**：合理控制小组件布局复杂度

## 常见问题

**Q: 小组件不显示数据？**
A: 检查 SharedPreferences 数据是否正确保存，确保 key 名称一致。

**Q: 如何支持多种尺寸？**
A: 在 res/xml/ 目录下创建不同的 widget_info 文件，并在 Provider 中区分处理。

**Q: 小组件点击无响应？**
A: 需要在 AndroidManifest.xml 中配置点击事件，并在 Provider 中处理 onClick。

## 相关资源

- [home_widget 插件文档](https://pub.dev/packages/home_widget)
- [Android App Widgets 指南](https://developer.android.com/guide/topics/appwidgets)
