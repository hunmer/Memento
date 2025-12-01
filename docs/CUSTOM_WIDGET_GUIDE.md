# 自定义小组件开发指南

本文档基于 Memento 项目中"签到项小组件"(CheckinItemWidget)的开发经验总结，详细说明如何在 Memento 中实现一个**复杂的自定义小组件**。

> **适用场景**: 需要用户选择配置的小组件（如选择特定的签到项、待办任务等），与标准的插件统计小组件不同。

---

## 目录

1. [概述](#概述)
2. [完整实现清单](#完整实现清单)
3. [Android 端实现](#android-端实现)
4. [Flutter 端实现](#flutter-端实现)
5. [路由配置](#路由配置)
6. [常见问题与解决方案](#常见问题与解决方案)
7. [调试技巧](#调试技巧)

---

## 概述

### 什么是"复杂的自定义小组件"？

与标准插件小组件（直接显示插件统计数据）不同，复杂自定义小组件具有以下特点：

- **需要用户配置**: 用户添加小组件时需要选择具体展示哪个数据项
- **独立数据源**: 每个小组件实例展示不同的数据
- **独立 Provider**: 不复用标准的 `BasePluginWidgetProvider`，需要自定义布局和逻辑
- **持久化配置**: 需要保存每个小组件实例的配置（如选中的项目ID）

### 架构示意图

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter 端                             │
├─────────────────────────────────────────────────────────────┤
│  1. 配置界面 (XxxSelectorScreen)                             │
│     - 显示可选项列表                                          │
│     - 保存用户选择到 SharedPreferences                        │
│     - 同步数据到小组件                                        │
│     - 触发小组件更新                                          │
│                                                              │
│  2. 数据同步 (PluginWidgetSyncHelper)                        │
│     - syncXxxWidget() 方法                                   │
│     - 构建符合 Android 端期望的 JSON 数据                     │
│     - 保存到 HomeWidgetPreferences                           │
│                                                              │
│  3. 路由配置 (route.dart + main.dart)                        │
│     - 注册深链接路由 /xxx_selector                            │
│     - 解析 widgetId 参数                                     │
└─────────────────────────────────────────────────────────────┘
                            ↕ (SharedPreferences)
┌─────────────────────────────────────────────────────────────┐
│                      Android 端                              │
├─────────────────────────────────────────────────────────────┤
│  1. Provider (XxxWidgetProvider)                            │
│     - 读取小组件配置（itemId）                                │
│     - 读取共享数据（JSON）                                    │
│     - 渲染 RemoteViews                                       │
│     - 处理点击事件                                            │
│                                                              │
│  2. 布局文件 (widget_xxx.xml)                                │
│     - 所有视图必须有 layout_width 和 layout_height           │
│     - 不能使用 <bitmap> 引用 vector drawable                 │
│                                                              │
│  3. 资源文件                                                  │
│     - widget_xxx_info.xml (小组件配置)                       │
│     - widget_xxx_preview.xml (预览图，纯 drawable)           │
│     - strings.xml (小组件名称和描述)                          │
│                                                              │
│  4. AndroidManifest.xml                                     │
│     - 注册 <receiver> 标签                                   │
│     - 配置 intent-filter                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 完整实现清单

### 必须完成的步骤

- [ ] **Android 端**
  - [ ] 创建自定义 Provider 类
  - [ ] 创建自定义布局文件
  - [ ] 创建预览图（纯 drawable，不使用 bitmap 引用 vector）
  - [ ] 创建小组件配置 XML
  - [ ] 在 AndroidManifest.xml 注册 receiver
  - [ ] 在 strings.xml 添加小组件名称和描述

- [ ] **Flutter 端**
  - [ ] 创建配置界面（XxxSelectorScreen）
  - [ ] 实现数据同步方法（syncXxxWidget）
  - [ ] 注册深链接路由
  - [ ] 在 MyWidgetManager 添加 Provider 映射

- [ ] **集成测试**
  - [ ] 添加小组件到桌面
  - [ ] 配置小组件（选择项目）
  - [ ] 验证数据显示正确
  - [ ] 验证点击跳转正确
  - [ ] 验证数据更新同步

---

## Android 端实现

### 1. 创建自定义 Provider

**路径**: `memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/XxxWidgetProvider.kt`

**关键要点**:

```kotlin
class CheckinItemWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "checkin_item"  // ⚠️ 必须与 Flutter 端一致
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        // ⚠️ 关键：使用 PREFS_NAME 而不是自定义名称！
        // PREFS_NAME 定义在 BasePluginWidgetProvider 中，值为 "HomeWidgetPreferences"
        private const val PREF_KEY_PREFIX = "checkin_item_id_"
    }

    override fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_checkin_item)

        // 1. 读取此小组件实例的配置（用户选择的项目ID）
        val itemId = getConfiguredItemId(context, appWidgetId)

        if (itemId == null) {
            // 未配置：显示提示，引导用户点击配置
            setupUnconfiguredWidget(views, context, appWidgetId)
        } else {
            // 已配置：读取数据并显示
            val data = loadWidgetData(context)  // 从 HomeWidgetPreferences 读取
            if (data != null) {
                setupCustomWidget(views, data, itemId)
            } else {
                setupDefaultWidget(views)
            }
            setupClickIntent(context, views)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    // ⚠️ 使用统一的 PREFS_NAME（继承自 BasePluginWidgetProvider）
    private fun getConfiguredItemId(context: Context, appWidgetId: Int): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString("$PREF_KEY_PREFIX$appWidgetId", null)
    }

    private fun setupUnconfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        views.setTextViewText(R.id.widget_title, "打卡")
        views.setViewVisibility(R.id.widget_hint_text, View.VISIBLE)
        views.setViewVisibility(R.id.widget_checkin_count, View.GONE)

        // 设置点击跳转到配置界面
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("memento://widget/checkin_item/config?widgetId=$appWidgetId")
        intent.setPackage("github.hunmer.memento")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
    }

    private fun setupCustomWidget(views: RemoteViews, data: JSONObject, itemId: String): Boolean {
        return try {
            // 从 data 中查找对应 ID 的项目
            val items = data.optJSONArray("items")
            var targetItem: JSONObject? = null

            if (items != null) {
                for (i in 0 until items.length()) {
                    val item = items.getJSONObject(i)
                    if (item.optString("id") == itemId) {
                        targetItem = item
                        break
                    }
                }
            }

            if (targetItem == null) return false

            // 设置数据
            val itemName = targetItem.optString("name", "打卡")
            views.setTextViewText(R.id.widget_title, itemName)

            val weekChecks = targetItem.optString("weekChecks", "")
            val checks = weekChecks.split(",").map { it.trim() == "1" }
            val checkinCount = checks.count { it }
            views.setTextViewText(R.id.widget_checkin_count, checkinCount.toString())

            // 显示七日打卡状态
            val checkIds = listOf(
                R.id.week_checks_1, R.id.week_checks_2, R.id.week_checks_3,
                R.id.week_checks_4, R.id.week_checks_5, R.id.week_checks_6, R.id.week_checks_7
            )
            for (i in 0 until 7) {
                val isChecked = i < checks.size && checks[i]
                views.setViewVisibility(checkIds[i], if (isChecked) View.VISIBLE else View.INVISIBLE)
            }

            true
        } catch (e: Exception) {
            Log.e("CheckinItemWidget", "Failed to bind widget data", e)
            false
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("$PREF_KEY_PREFIX$appWidgetId")
        }
        editor.apply()
    }
}
```

**关键注意事项**:

1. ⚠️ **必须使用 `PREFS_NAME`**: 这是在 `BasePluginWidgetProvider` 中定义的常量，值为 `"HomeWidgetPreferences"`。**绝对不要**使用自定义的 SharedPreferences 文件名，否则 Flutter 端保存的数据读不到！

2. **配置键命名**: `${PREF_KEY_PREFIX}${appWidgetId}` 格式，每个小组件实例有独立的配置

3. **数据键命名**: `${pluginId}_widget_data` 格式（如 `checkin_item_widget_data`），所有小组件实例共享同一份数据

### 2. 创建布局文件

**路径**: `memento_widgets/android/src/main/res/layout/widget_xxx.xml`

**⚠️ 关键规则**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="@drawable/widget_checkin_background"
    android:padding="16dp">

    <!-- ⚠️ 所有子视图必须明确指定 layout_width 和 layout_height -->
    <TextView
        android:id="@+id/widget_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"  <!-- ⚠️ 必须！不能省略 -->
        android:text="打卡"
        android:textColor="@android:color/white"
        android:textSize="18sp"
        android:textStyle="bold" />

    <!-- ⚠️ ImageView 也必须指定高度 -->
    <ImageView
        android:id="@+id/week_checks_1"
        android:layout_width="0dp"
        android:layout_height="24dp"  <!-- ⚠️ 必须！ -->
        android:layout_weight="1"
        android:src="@drawable/ic_check" />

</LinearLayout>
```

**常见错误**:

- ❌ `<TextView android:layout_width="0dp" android:layout_weight="1" .../>`
- ✅ `<TextView android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" .../>`

**错误日志**:
```
android.view.InflateException: Binary XML file line #68: You must supply a layout_height attribute.
```

### 3. 创建预览图

**路径**: `memento_widgets/android/src/main/res/drawable/widget_xxx_preview.xml`

**⚠️ 禁止使用 `<bitmap>` 引用 vector drawable**:

```xml
<!-- ❌ 错误：会导致小组件无法加载 -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient
                android:startColor="#68A9A4"
                android:endColor="#457C78"
                android:angle="135" />
            <corners android:radius="16dp" />
        </shape>
    </item>
    <item android:gravity="center">
        <bitmap android:src="@drawable/ic_check" />  <!-- ❌ ic_check 是 vector drawable -->
    </item>
</layer-list>

<!-- ✅ 正确：使用纯 drawable 绘制 -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient
                android:startColor="#68A9A4"
                android:endColor="#457C78"
                android:angle="135" />
            <corners android:radius="16dp" />
        </shape>
    </item>
    <!-- 使用 shape 绘制简单图形 -->
    <item
        android:gravity="center"
        android:width="48dp"
        android:height="48dp">
        <shape android:shape="rectangle">
            <solid android:color="#FFFFFF" />
            <corners android:radius="24dp" />
        </shape>
    </item>
</layer-list>
```

**原因**: Android 的 `<bitmap>` 标签只能引用实际的位图文件（PNG/JPG），不能引用 XML vector drawable。

### 4. 小组件配置文件

**路径**: `memento_widgets/android/src/main/res/xml/widget_xxx_info.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/widget_checkin_item"
    android:resizeMode="none"
    android:widgetCategory="home_screen"
    android:previewLayout="@layout/widget_checkin_item"
    android:previewImage="@drawable/widget_checkin_item_preview"  <!-- ⚠️ 使用纯 drawable -->
    android:description="@string/widget_checkin_item_description" />
```

### 5. AndroidManifest.xml 注册

**路径**: `memento_widgets/android/src/main/AndroidManifest.xml`

```xml
<receiver
    android:name="github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_checkin_item_info" />
</receiver>
```

### 6. 字符串资源

**路径**: `memento_widgets/android/src/main/res/values/strings.xml`

```xml
<string name="widget_checkin_item_label">签到项</string>
<string name="widget_checkin_item_description">快速签到</string>
```

---

## Flutter 端实现

### 1. 创建配置界面

**路径**: `lib/plugins/xxx/screens/xxx_selector_screen.dart`

**核心功能**:

```dart
class CheckinItemSelectorScreen extends StatefulWidget {
  final int? widgetId;  // ⚠️ 从路由参数获取

  const CheckinItemSelectorScreen({super.key, this.widgetId});

  @override
  State<CheckinItemSelectorScreen> createState() => _CheckinItemSelectorScreenState();
}

class _CheckinItemSelectorScreenState extends State<CheckinItemSelectorScreen> {
  String? _selectedItemId;

  Future<void> _saveAndFinish() async {
    if (_selectedItemId == null || widget.widgetId == null) return;

    try {
      // 1. 保存小组件配置（哪个小组件选了哪个项目）
      await HomeWidget.saveWidgetData<String>(
        'checkin_item_id_${widget.widgetId}',  // ⚠️ 键名格式必须与 Android 端一致
        _selectedItemId!,
      );

      // 2. 同步数据到小组件
      final selectedItem = _plugin.items.firstWhere((item) => item.id == _selectedItemId);
      await _syncItemToWidget(selectedItem);

      // 3. ⚠️ 使用 qualifiedAndroidName！
      await HomeWidget.updateWidget(
        name: 'CheckinItemWidgetProvider',
        iOSName: 'CheckinItemWidgetProvider',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 错误处理
    }
  }

  Future<void> _syncItemToWidget(CheckinItem item) async {
    // 计算本周7天打卡状态
    final now = DateTime.now();
    final weekChecks = List<bool>.filled(7, false);
    final mondayOffset = (now.weekday - 1);

    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: mondayOffset - i));
      final records = item.getDateRecords(targetDate);
      weekChecks[i] = records.isNotEmpty;
    }

    final weekChecksString = weekChecks.map((e) => e ? '1' : '0').join(',');

    // ⚠️ 构建符合 Android 端期望的 JSON 格式
    final widgetData = jsonEncode({
      'items': [
        {
          'id': item.id,
          'name': item.name,
          'weekChecks': weekChecksString,
        }
      ],
    });

    // ⚠️ 保存到 HomeWidgetPreferences
    await HomeWidget.saveWidgetData<String>(
      'checkin_item_widget_data',  // ⚠️ 键名必须与 Android 端一致
      widgetData,
    );
  }
}
```

**⚠️ 关键要点**:

1. **SharedPreferences 键名一致性**:
   - 配置键: `${PREF_KEY_PREFIX}${widgetId}` (如 `checkin_item_id_123`)
   - 数据键: `${pluginId}_widget_data` (如 `checkin_item_widget_data`)

2. **使用 `qualifiedAndroidName`**:
   ```dart
   // ❌ 错误：会导致 ClassNotFoundException
   await HomeWidget.updateWidget(
     androidName: 'CheckinItemWidgetProvider',
   );

   // ✅ 正确
   await HomeWidget.updateWidget(
     name: 'CheckinItemWidgetProvider',
     iOSName: 'CheckinItemWidgetProvider',
     qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
   );
   ```

3. **数据格式**: 必须与 Android 端 `setupCustomWidget()` 中的解析逻辑匹配

### 2. 实现数据同步方法

**路径**: `lib/core/services/plugin_widget_sync_helper.dart`

```dart
// 添加必要的导入
import 'dart:convert';
import 'package:memento_widgets/memento_widgets.dart';

class PluginWidgetSyncHelper {
  Future<void> syncAllPlugins() async {
    await Future.wait([
      // ... 其他插件
      syncCheckinItemWidget(),  // ⚠️ 添加到列表
    ]);
  }

  Future<void> syncCheckinItemWidget() async {
    try {
      // 1. 获取插件数据
      final plugin = PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) {
        debugPrint('Checkin plugin not found, skipping checkin_item widget sync');
        return;
      }

      // 2. 构建所有签到项的数据
      final items = plugin.checkinItems.map((item) {
        // 计算本周7天的打卡状态
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final List<String> weekChecks = [];

        final mondayOffset = today.weekday - 1;
        final monday = today.subtract(Duration(days: mondayOffset));

        for (int i = 0; i < 7; i++) {
          final date = monday.add(Duration(days: i));
          final hasCheckin = item.getDateRecords(date).isNotEmpty;
          weekChecks.add(hasCheckin ? '1' : '0');
        }

        return {
          'id': item.id,
          'name': item.name,
          'weekChecks': weekChecks.join(','),
        };
      }).toList();

      // 3. ⚠️ 保存为 JSON 字符串
      final data = {'items': items};
      final jsonString = jsonEncode(data);
      await MyWidgetManager().saveString('checkin_item_widget_data', jsonString);

      // 4. 更新小组件
      await SystemWidgetService.instance.updateWidget('checkin_item');

      debugPrint('Synced checkin_item widget with ${items.length} items');
    } catch (e) {
      debugPrint('Failed to sync checkin_item widget: $e');
    }
  }
}
```

**数据流**:

```
Plugin Data → syncCheckinItemWidget()
             → JSON.encode({'items': [...]})
             → HomeWidget.saveWidgetData('checkin_item_widget_data', jsonString)
             → SharedPreferences (HomeWidgetPreferences)
             → Android WidgetProvider.loadWidgetData()
             → JSON.parse()
             → setupCustomWidget(data, itemId)
```

### 3. 注册 MyWidgetManager 映射

**路径**: `memento_widgets/lib/memento_widgets.dart`

```dart
class MyWidgetManager {
  static const Map<String, String> _androidProviders = {
    // ... 其他小组件
    'CheckinItemWidgetProvider': 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
  };

  List<String> _getProviderNames(String pluginId) {
    if (pluginId == 'checkin_item') {  // ⚠️ 特殊处理
      return ['CheckinItemWidgetProvider'];
    }
    // ... 标准插件处理
  }

  List<String> _getAllProviderNames() {
    return [
      // ... 其他小组件
      'CheckinItemWidgetProvider',  // ⚠️ 添加到列表
    ];
  }
}
```

---

## 路由配置

### 1. 注册路由 (route.dart)

```dart
import 'package:Memento/plugins/checkin/screens/checkin_item_selector_screen.dart';

class Routes {
  static const String checkinItemSelector = '/checkin_item_selector';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';
    final uri = Uri.parse(routeName);

    // ⚠️ 解析查询参数
    if (routeName.startsWith('/checkin_item_selector')) {
      final widgetId = uri.queryParameters['widgetId'];
      return MaterialPageRoute(
        builder: (_) => CheckinItemSelectorScreen(
          widgetId: widgetId != null ? int.tryParse(widgetId) : null,
        ),
      );
    }

    // ... 其他路由
  }
}
```

### 2. 深链接处理 (main.dart)

```dart
void _handleDeepLink(String? routePath) {
  if (routePath == null) return;

  // ⚠️ 转换深链接格式
  // 从 /checkin_item/config?widgetId=xxx 转换为 /checkin_item_selector?widgetId=xxx
  if (routePath.startsWith('/checkin_item/config')) {
    final uri = Uri.parse(routePath);
    final widgetId = uri.queryParameters['widgetId'];
    routePath = '/checkin_item_selector${widgetId != null ? '?widgetId=$widgetId' : ''}';
  }

  Navigator.of(context).pushNamed(routePath);
}
```

---

## 常见问题与解决方案

### 问题 1: 小组件显示 "can't load widget"

**原因**:

1. ✅ **布局文件缺少 layout_height**: 检查所有 TextView/ImageView 是否有 `android:layout_height`
2. ✅ **预览图使用 bitmap 引用 vector**: 改用纯 drawable 绘制
3. ✅ **资源文件缺失**: 确保所有引用的 drawable/layout/string 都存在

**调试方法**:

```bash
adb logcat -d | grep -i "widget\|appwidget\|remoteviews"
```

查找类似错误:
```
AppWidgetHostView: Error inflating RemoteViews
android.view.InflateException: Binary XML file line #68: You must supply a layout_height attribute.
```

### 问题 2: 配置后小组件不更新

**原因**: SharedPreferences 不一致

**检查清单**:

```kotlin
// Android 端
val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)  // ✅ 使用 PREFS_NAME

// ❌ 错误
val prefs = context.getSharedPreferences("my_custom_prefs", Context.MODE_PRIVATE)
```

```dart
// Flutter 端
await HomeWidget.saveWidgetData<String>('key', value);  // ✅ 自动保存到 HomeWidgetPreferences
```

**验证方法**:

```bash
# 查看 SharedPreferences 内容
adb shell run-as github.hunmer.memento cat /data/data/github.hunmer.memento/shared_prefs/HomeWidgetPreferences.xml
```

### 问题 3: ClassNotFoundException

**错误日志**:
```
java.lang.ClassNotFoundException: github.hunmer.memento.CheckinItemWidgetProvider
```

**原因**: 使用了 `androidName` 而不是 `qualifiedAndroidName`

**解决方案**:

```dart
// ❌ 错误
await HomeWidget.updateWidget(
  androidName: 'CheckinItemWidgetProvider',  // home_widget 会自动加上基础包名，导致错误
);

// ✅ 正确
await HomeWidget.updateWidget(
  name: 'CheckinItemWidgetProvider',
  iOSName: 'CheckinItemWidgetProvider',
  qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.CheckinItemWidgetProvider',
);
```

### 问题 4: 数据格式不匹配

**现象**: Android 端 `setupCustomWidget()` 返回 false，显示默认数据

**原因**: Flutter 端保存的 JSON 格式与 Android 端解析逻辑不匹配

**检查清单**:

```dart
// Flutter 端
final widgetData = jsonEncode({
  'items': [  // ⚠️ 必须是数组
    {
      'id': item.id,
      'name': item.name,
      'weekChecks': '1,1,0,1,0,0,0',  // ⚠️ 字段名必须匹配
    }
  ],
});
```

```kotlin
// Android 端
val items = data.optJSONArray("items")  // ⚠️ 必须匹配
val item = items.getJSONObject(i)
val itemName = item.optString("name")  // ⚠️ 必须匹配
val weekChecks = item.optString("weekChecks")  // ⚠️ 必须匹配
```

---

## 调试技巧

### 1. 查看 Logcat 日志

```bash
# 实时查看日志
adb logcat | grep -E "CheckinItemWidget|WidgetProvider|RemoteViews"

# 查看历史日志
adb logcat -d | grep -i widget | tail -50
```

### 2. 查看 SharedPreferences

```bash
# 查看所有 SharedPreferences 文件
adb shell run-as github.hunmer.memento ls /data/data/github.hunmer.memento/shared_prefs/

# 查看 HomeWidgetPreferences 内容
adb shell run-as github.hunmer.memento cat /data/data/github.hunmer.memento/shared_prefs/HomeWidgetPreferences.xml
```

### 3. 手动触发小组件更新

```dart
// 在 Flutter 代码中添加
debugPrint('=== Widget Data ===');
final data = await HomeWidget.getWidgetData<String>('checkin_item_widget_data');
debugPrint(data);

await SystemWidgetService.instance.updateWidget('checkin_item');
debugPrint('Widget updated');
```

### 4. 验证数据同步

```kotlin
// 在 Android Provider 中添加
override fun updateAppWidget(...) {
    val data = loadWidgetData(context)
    Log.d("CheckinItemWidget", "Widget data: $data")

    val itemId = getConfiguredCheckinItemId(context, appWidgetId)
    Log.d("CheckinItemWidget", "Configured item ID: $itemId")

    // ...
}
```

---

## 完整示例代码位置

以签到项小组件为例:

- **Android 端**:
  - Provider: `memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/CheckinItemWidgetProvider.kt`
  - 布局: `memento_widgets/android/src/main/res/layout/widget_checkin_item.xml`
  - 配置: `memento_widgets/android/src/main/res/xml/widget_checkin_item_info.xml`
  - 预览: `memento_widgets/android/src/main/res/drawable/widget_checkin_item_preview.xml`

- **Flutter 端**:
  - 配置界面: `lib/plugins/checkin/screens/checkin_item_selector_screen.dart`
  - 数据同步: `lib/core/services/plugin_widget_sync_helper.dart` (syncCheckinItemWidget 方法)
  - 路由配置: `lib/screens/route.dart` 和 `lib/main.dart`

---

## 总结

实现复杂自定义小组件的**核心要点**:

1. ✅ **SharedPreferences 一致性**: Android 端和 Flutter 端必须使用相同的文件名（`HomeWidgetPreferences`）
2. ✅ **布局规范**: 所有视图必须有 `layout_width` 和 `layout_height`
3. ✅ **预览图限制**: 不能使用 `<bitmap>` 引用 vector drawable
4. ✅ **数据格式匹配**: Flutter 端保存的 JSON 必须与 Android 端解析逻辑完全一致
5. ✅ **正确的更新调用**: 使用 `qualifiedAndroidName` 而不是 `androidName`
6. ✅ **深链接路由**: 正确解析 `widgetId` 参数并跳转到配置界面
7. ✅ **Provider 映射**: 在 `MyWidgetManager` 中注册完整类名

遵循本文档的步骤和注意事项，可以避免 90% 的常见错误！
