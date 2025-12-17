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
8. [高级：构建复杂交互小组件](#高级构建复杂交互小组件)
   - [陷阱 5：数量与列表数据不一致](#陷阱-5数量与列表数据不一致--重要) ⭐ 重要
9. [高级：小组件主题配置](#高级小组件主题配置) ⭐ 新增
   - [使用 WidgetConfigEditor 组件](#使用-widgetconfigeditor-组件)
   - [Android 端读取颜色配置](#android-端读取颜色配置)

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
4. RemoteViews（小组件）不支持直接使用 <View> 标签。RemoteViews 只支持有限的视图类型。

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

**原因**: SharedPreferences 文件名或键名不一致

**⚠️ 关键规则**:
1. **SharedPreferences 文件名**: 必须使用 `HomeWidgetPreferences`，不能使用 `FlutterSharedPreferences`
2. **键名前缀**: `HomeWidget.saveWidgetData()` **不会**自动添加 `flutter.` 前缀，Android 端读取时也不要加

**检查清单**:

```kotlin
// Android 端
// ✅ 正确：使用 PREFS_NAME（值为 "HomeWidgetPreferences"）
val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
val data = prefs.getString("habits_weekly_data_$widgetId", null)  // ✅ 无 flutter. 前缀

// ❌ 错误：使用 FlutterSharedPreferences
val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
val data = prefs.getString("flutter.habits_weekly_data_$widgetId", null)  // ❌ 有 flutter. 前缀
```

```dart
// Flutter 端
await HomeWidget.saveWidgetData<String>('habits_weekly_data_$widgetId', value);
// ✅ 自动保存到 HomeWidgetPreferences，键名就是 'habits_weekly_data_$widgetId'
```

**验证方法**:

```bash
# 查看 SharedPreferences 内容
adb shell run-as github.hunmer.memento cat /data/data/github.hunmer.memento/shared_prefs/HomeWidgetPreferences.xml
```

**常见错误示例**:

| 问题 | 错误写法 | 正确写法 |
|------|---------|---------|
| 文件名错误 | `FlutterSharedPreferences` | `HomeWidgetPreferences` (或使用 `PREFS_NAME`) |
| 键名多余前缀 | `flutter.xxx_data_$id` | `xxx_data_$id` |
| 继承基类但使用错误常量 | 自定义 `PREFS_NAME` | 使用 `BasePluginWidgetProvider.PREFS_NAME` |

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

---

## 高级：构建复杂交互小组件

本节基于"待办列表小组件"(TodoListWidget)的开发经验，详细说明如何实现一个**支持后台交互、可滚动列表**的复杂小组件。

### 功能需求

- **可滚动列表**: 支持无限任务显示，不限制数量
- **多区域点击**: 不同区域触发不同操作
  - 点击 checkbox → 后台完成任务（不打开应用）
  - 点击任务标题 → 打开任务详情页
  - 点击标题栏 → 跳转到任务列表
- **后台数据更新**: 不打开应用的情况下更新数据
- **双向同步**: 小组件操作同步到应用，应用操作同步到小组件

### 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                       Android 端                                │
├─────────────────────────────────────────────────────────────────┤
│  1. WidgetProvider (处理广播和整体更新)                          │
│     - onReceive() 处理点击广播                                   │
│     - updateAppWidget() 设置 RemoteViews                        │
│     - 后台更新 SharedPreferences 数据                            │
│     - 显示 Toast 提示                                           │
│                                                                 │
│  2. RemoteViewsService (提供列表数据)                           │
│     - 继承 RemoteViewsService                                   │
│     - 返回 RemoteViewsFactory 实例                              │
│                                                                 │
│  3. RemoteViewsFactory (创建列表项)                             │
│     - 实现 getViewAt() 创建每个列表项                            │
│     - 设置 setOnClickFillInIntent() 填充点击数据                 │
│                                                                 │
│  4. 布局文件                                                    │
│     - widget_xxx.xml (主布局，包含 ListView)                     │
│     - widget_xxx_item.xml (列表项布局)                          │
└─────────────────────────────────────────────────────────────────┘
                            ↕ (SharedPreferences + 待处理变更)
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter 端                                │
├─────────────────────────────────────────────────────────────────┤
│  1. 数据同步 (PluginWidgetSyncHelper)                           │
│     - syncXxxWidget() 同步数据到小组件                          │
│     - syncPendingChangesOnStartup() 同步待处理变更               │
│                                                                 │
│  2. 生命周期监听 (main.dart)                                    │
│     - WidgetsBindingObserver 监听应用恢复                       │
│     - 恢复时同步待处理变更                                       │
│                                                                 │
│  3. 数据变更监听 (TaskController)                               │
│     - 任务增删改时调用 _syncWidget()                             │
│     - 同时同步标准小组件和列表小组件                             │
└─────────────────────────────────────────────────────────────────┘
```

### 实现步骤

#### 1. 创建 RemoteViewsService

**路径**: `memento_widgets/android/src/main/kotlin/.../TodoListWidgetService.kt`

```kotlin
class TodoListWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoListRemoteViewsFactory(applicationContext, intent)
    }
}
```

#### 2. 创建 RemoteViewsFactory

**路径**: `memento_widgets/android/src/main/kotlin/.../TodoListRemoteViewsFactory.kt`

```kotlin
class TodoListRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private var tasks: List<TaskItem> = emptyList()

    data class TaskItem(
        val id: String,
        val title: String,
        val completed: Boolean
    )

    override fun onDataSetChanged() {
        // 从 SharedPreferences 加载数据
        tasks = loadTasks()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list_item)

        views.setTextViewText(R.id.task_title, task.title)

        // ⚠️ 关键：使用 setOnClickFillInIntent 填充点击数据
        // checkbox 点击 - 触发任务完成
        val checkboxFillIntent = Intent().apply {
            putExtra("action", "toggle_task")
            putExtra("task_id", task.id)
            putExtra("task_completed", task.completed)
        }
        views.setOnClickFillInIntent(R.id.task_checkbox, checkboxFillIntent)

        // 标题点击 - 打开详情
        val detailFillIntent = Intent().apply {
            putExtra("action", "open_detail")
            putExtra("task_id", task.id)
        }
        views.setOnClickFillInIntent(R.id.task_title_container, detailFillIntent)

        return views
    }

    // ... 其他必要方法
}
```

#### 3. 更新 WidgetProvider 支持 ListView

```kotlin
class TodoListWidgetProvider : BasePluginWidgetProvider() {

    companion object {
        const val ACTION_TASK_CLICK = "github.hunmer.memento.widgets.TODO_LIST_TASK_CLICK"
        const val PREF_KEY_PENDING_CHANGES = "todo_list_pending_changes"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_TASK_CLICK -> handleTaskClick(context, intent)
        }
    }

    private fun setupConfiguredWidget(views: RemoteViews, context: Context, appWidgetId: Int) {
        // ⚠️ 设置 ListView 的 RemoteViewsService
        val serviceIntent = Intent(context, TodoListWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.task_list_view, serviceIntent)

        // ⚠️ 设置 PendingIntent 模板（必须使用 FLAG_MUTABLE）
        val clickIntent = Intent(context, TodoListWidgetProvider::class.java).apply {
            action = ACTION_TASK_CLICK
        }
        val clickPendingIntent = PendingIntent.getBroadcast(
            context,
            appWidgetId,
            clickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE  // ⚠️ 必须 MUTABLE
        )
        views.setPendingIntentTemplate(R.id.task_list_view, clickPendingIntent)
    }
}
```

#### 4. 后台处理点击事件（不打开应用）

```kotlin
private fun handleTaskClick(context: Context, intent: Intent) {
    val action = intent.getStringExtra("action") ?: return
    val taskId = intent.getStringExtra("task_id") ?: return

    when (action) {
        "toggle_task" -> {
            val currentCompleted = intent.getBooleanExtra("task_completed", false)

            // 1. 直接更新 SharedPreferences 数据（不打开应用）
            val taskTitle = updateTaskInPrefs(context, taskId, !currentCompleted)

            // 2. 记录待同步变更（应用启动时处理）
            recordPendingChange(context, taskId, !currentCompleted)

            // 3. 显示 Toast 提示
            Toast.makeText(context, "✓ 已完成「$taskTitle」", Toast.LENGTH_SHORT).show()

            // 4. 刷新小组件
            refreshAllWidgets(context)
        }
        "open_detail" -> {
            // 打开应用的任务详情页
            val detailIntent = Intent(Intent.ACTION_VIEW)
            detailIntent.data = Uri.parse("memento://widget/todo_list/detail?taskId=$taskId")
            detailIntent.setPackage("github.hunmer.memento")
            detailIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(detailIntent)
        }
    }
}

// ⚠️ 记录待同步变更，应用启动时读取并同步到实际数据
private fun recordPendingChange(context: Context, taskId: String, completed: Boolean) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val pendingJson = prefs.getString(PREF_KEY_PENDING_CHANGES, "{}") ?: "{}"
    val pending = JSONObject(pendingJson)
    pending.put(taskId, completed)
    prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()
}
```

#### 5. 注册 Service（AndroidManifest.xml）

```xml
<!-- 注册 RemoteViewsService -->
<service
    android:name="github.hunmer.memento.widgets.providers.TodoListWidgetService"
    android:exported="false"
    android:permission="android.permission.BIND_REMOTEVIEWS" />

<!-- 注册 Provider，添加自定义 Action -->
<receiver
    android:name="github.hunmer.memento.widgets.providers.TodoListWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="github.hunmer.memento.widgets.TODO_LIST_TASK_CLICK" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_todo_list_info" />
</receiver>
```

#### 6. Flutter 端：应用恢复时同步待处理变更

**在 main.dart 添加生命周期监听**:

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ⚠️ 应用恢复到前台时同步待处理变更
    if (state == AppLifecycleState.resumed) {
      PluginWidgetSyncHelper.instance.syncPendingTaskChangesOnStartup();
    }
  }
}
```

**在 PluginWidgetSyncHelper 添加同步方法**:

```dart
// ⚠️ 防止重复同步的标志（避免循环调用）
bool _isSyncingPendingChanges = false;

Future<void> syncPendingTaskChangesOnStartup() async {
  final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
  if (plugin == null) return;
  await _syncPendingTaskChanges(plugin);
}

Future<void> _syncPendingTaskChanges(TodoPlugin plugin) async {
  // ⚠️ 防止循环调用
  if (_isSyncingPendingChanges) return;

  try {
    final pendingJson = await MyWidgetManager().getData<String>('todo_list_pending_changes');
    if (pendingJson == null || pendingJson == '{}') return;

    final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
    if (pending.isEmpty) return;

    // ⚠️ 先清除再处理（防止循环调用时重复处理）
    await MyWidgetManager().saveString('todo_list_pending_changes', '{}');

    _isSyncingPendingChanges = true;

    for (final entry in pending.entries) {
      final taskId = entry.key;
      final completed = entry.value as bool;

      if (completed) {
        await plugin.taskController.updateTaskStatus(taskId, TaskStatus.done);
      } else {
        await plugin.taskController.updateTaskStatus(taskId, TaskStatus.todo);
      }
    }
  } finally {
    _isSyncingPendingChanges = false;
  }
}
```

#### 7. 数据控制器：任务变更时同步小组件

```dart
class TaskController extends ChangeNotifier {
  Future<void> _syncWidget() async {
    // 同步标准小组件
    await PluginWidgetSyncHelper.instance.syncTodo();
    // ⚠️ 同时同步列表小组件
    await PluginWidgetSyncHelper.instance.syncTodoListWidget();
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    await _saveTasks();
    await _syncWidget();  // ⚠️ 同步小组件
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    // ... 更新逻辑
    await _saveTasks();
    await _syncWidget();  // ⚠️ 同步小组件
  }
}
```

### 常见陷阱与解决方案

#### 陷阱 1：PendingIntent 使用 FLAG_IMMUTABLE 导致 FillInIntent 无效

**问题**: ListView 项点击无响应

**原因**: `PendingIntent.FLAG_IMMUTABLE` 会阻止 FillInIntent 的数据填充

**解决**:
```kotlin
// ❌ 错误
PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

// ✅ 正确
PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
```

#### 陷阱 2：循环调用导致无限递归

**问题**: 控制台一直打印同步日志，应用卡死

**原因**: `syncTodoListWidget()` 内部调用 `_syncPendingTaskChanges()`，而 `_syncPendingTaskChanges()` 更新任务状态后触发 `_syncWidget()`，又调用 `syncTodoListWidget()`

**解决**:
1. 使用标志变量防止重复调用
2. 先清除待处理变更再处理
3. 将 pending 同步逻辑与 widget 数据同步逻辑分离

```dart
bool _isSyncingPendingChanges = false;

Future<void> _syncPendingTaskChanges(TodoPlugin plugin) async {
  if (_isSyncingPendingChanges) return;  // ⚠️ 防止重复调用

  // 先清除再处理
  await MyWidgetManager().saveString('todo_list_pending_changes', '{}');

  _isSyncingPendingChanges = true;
  try {
    // ... 处理逻辑
  } finally {
    _isSyncingPendingChanges = false;
  }
}
```

#### 陷阱 3：应用在后台时恢复不触发同步

**问题**: 小组件完成任务后，切换到应用发现任务状态未更新

**原因**: 应用在后台时 `main()` 不会重新执行

**解决**: 使用 `WidgetsBindingObserver` 监听 `AppLifecycleState.resumed`

#### 陷阱 4：应用内操作不同步到小组件

**问题**: 在应用内添加/完成任务，小组件不更新

**原因**: 只同步了标准小组件，没有同步列表小组件

**解决**: 在 `_syncWidget()` 中同时调用两个同步方法

#### 陷阱 5：数量与列表数据不一致 ⭐ 重要

**问题**:
1. 首次配置小组件后，显示的数量与列表任务数量不一致
2. 应用内完成任务后小组件数量更新，但列表不刷新
3. 小组件操作后才正常显示

**根本原因**:
1. **数量计算未过滤**: `getTaskCount()` 计算所有未完成任务，但 `RemoteViewsFactory.loadTasks()` 按时间范围过滤
2. **首次配置数据不完整**: 配置界面只同步部分任务（如4个），且缺少日期字段
3. **ListView 未刷新**: Flutter 端更新小组件时，`onUpdate()` 没有通知 ListView 数据变化

**完整解决方案**:

**1. 统一过滤逻辑（数量计算与列表加载必须一致）**

```kotlin
// TodoListWidgetProvider.kt

/**
 * 获取任务数量（按时间范围过滤）
 */
private fun getTaskCount(context: Context, timeRange: String): Int {
    return try {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val jsonString = prefs.getString("todo_list_widget_data", null) ?: return 0
        val json = JSONObject(jsonString)
        val tasks = json.optJSONArray("tasks") ?: return 0

        var count = 0
        for (i in 0 until tasks.length()) {
            val task = tasks.getJSONObject(i)
            if (!task.optBoolean("completed", false)) {
                // ⚠️ 关键：按时间范围过滤（与 RemoteViewsFactory 保持一致）
                if (shouldIncludeTask(task, timeRange)) {
                    count++
                }
            }
        }
        count
    } catch (e: Exception) {
        Log.e(TAG, "Failed to get task count", e)
        0
    }
}

/**
 * 根据时间范围判断是否包含任务
 * ⚠️ 必须与 RemoteViewsFactory 中的过滤逻辑完全一致
 */
private fun shouldIncludeTask(task: JSONObject, timeRange: String): Boolean {
    if (timeRange == RANGE_ALL) return true

    val startDateStr = task.optString("startDate", null)
    val dueDateStr = task.optString("dueDate", null)

    if (startDateStr.isNullOrEmpty() && dueDateStr.isNullOrEmpty()) return true

    val todayStart = getTodayStart()
    val todayEnd = todayStart + 24 * 60 * 60 * 1000
    val taskStart = parseDate(startDateStr)
    val taskDue = parseDate(dueDateStr)

    return when (timeRange) {
        RANGE_TODAY -> {
            // 今天的任务：开始日期<=今天 且 截止日期>=今天
            val startOk = taskStart == null || taskStart <= todayEnd
            val dueOk = taskDue == null || taskDue >= todayStart
            startOk && dueOk
        }
        RANGE_WEEK -> {
            val weekStart = getWeekStart()
            val weekEnd = weekStart + 7 * 24 * 60 * 60 * 1000
            val startOk = taskStart == null || taskStart <= weekEnd
            val dueOk = taskDue == null || taskDue >= weekStart
            startOk && dueOk
        }
        RANGE_MONTH -> {
            val monthStart = getMonthStart()
            val monthEnd = getMonthEnd()
            val startOk = taskStart == null || taskStart <= monthEnd
            val dueOk = taskDue == null || taskDue >= monthStart
            startOk && dueOk
        }
        else -> true
    }
}
```

**2. 完整数据同步（包含日期字段）**

```dart
// todo_list_selector_screen.dart

Future<void> _syncTasksToWidget() async {
  try {
    // ⚠️ 同步所有未完成任务（不按时间范围过滤，让 Android 端过滤）
    final allTasks = _todoPlugin.taskController.tasks
        .where((task) => task.status != TaskStatus.done)
        .toList();

    // ⚠️ 必须包含日期字段，供 Android 端过滤使用
    final taskList = allTasks.map((task) {
      return {
        'id': task.id,
        'title': task.title,
        'completed': task.status == TaskStatus.done,
        'startDate': task.startDate?.toIso8601String(),  // ⚠️ 关键：包含日期
        'dueDate': task.dueDate?.toIso8601String(),      // ⚠️ 关键：包含日期
      };
    }).toList();

    final widgetData = jsonEncode({
      'tasks': taskList,
      'total': taskList.length,
    });

    await HomeWidget.saveWidgetData<String>('todo_list_widget_data', widgetData);
  } catch (e) {
    debugPrint('同步待办列表数据失败: $e');
  }
}
```

**3. 通知 ListView 刷新数据**

```kotlin
// TodoListWidgetProvider.kt

/**
 * 重写 onUpdate 方法，确保 ListView 数据也被刷新
 */
override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray
) {
    // 调用父类方法更新小组件 UI（数量等静态内容）
    super.onUpdate(context, appWidgetManager, appWidgetIds)

    // ⚠️ 关键：通知 ListView 数据已更改，触发 RemoteViewsFactory.onDataSetChanged()
    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.task_list_view)

    Log.d(TAG, "onUpdate: notified ListView data changed for ${appWidgetIds.size} widgets")
}
```

**问题分析**:

| 问题 | 根源 | 症状 |
|------|------|------|
| 数量与列表不一致 | `getTaskCount()` 未过滤 | 显示"10个任务"，但列表只有3个 |
| 首次配置数据不完整 | 只同步4个任务 | Android 端读不到完整数据，列表为空 |
| ListView 不刷新 | 缺少 `notifyAppWidgetViewDataChanged()` | 数量更新但列表不变 |

**验证方法**:

```bash
# 1. 查看 SharedPreferences 数据
adb shell run-as github.hunmer.memento cat /data/data/github.hunmer.memento/shared_prefs/HomeWidgetPreferences.xml

# 2. 查看 Logcat 日志
adb logcat | grep -E "TodoListWidget|RemoteViewsFactory"

# 3. 检查数据字段完整性
# 确保 JSON 中包含 startDate 和 dueDate 字段
```

**最佳实践**:

1. ✅ **数量统计与列表加载必须使用相同的过滤逻辑**
2. ✅ **同步完整数据（包含所有过滤所需的字段）**
3. ✅ **重写 `onUpdate()` 添加 `notifyAppWidgetViewDataChanged()`**
4. ✅ **在 Android 端进行过滤，而不是 Flutter 端预过滤**
5. ✅ **使用 Log 输出调试数量计算和列表加载的过程**

### 数据流总结

```
┌─────────────────────────────────────────────────────────────────┐
│                    完整数据流                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  【应用内操作】                                                  │
│  添加/完成任务 → TaskController._syncWidget()                   │
│       ↓                                                         │
│  syncTodo() + syncTodoListWidget()                              │
│       ↓                                                         │
│  更新 SharedPreferences → 刷新小组件 ✓                          │
│                                                                 │
│  ═══════════════════════════════════════════════════════════    │
│                                                                 │
│  【小组件操作】                                                  │
│  点击 checkbox → Provider.handleTaskClick()                     │
│       ↓                                                         │
│  updateTaskInPrefs() + recordPendingChange()                    │
│       ↓                                                         │
│  Toast 提示 → 刷新小组件 ✓                                       │
│                                                                 │
│  ═══════════════════════════════════════════════════════════    │
│                                                                 │
│  【应用恢复】                                                    │
│  AppLifecycleState.resumed → syncPendingChangesOnStartup()      │
│       ↓                                                         │
│  读取 pending → 清除 pending → 设置标志                          │
│       ↓                                                         │
│  updateTaskStatus() → _syncWidget()                             │
│       ↓                                                         │
│  syncTodoListWidget() (跳过 pending 同步)                       │
│       ↓                                                         │
│  清除标志 → 完成 ✓                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
示例同步更新：
[用户切换回 App]
           ↓
  main.dart: didChangeAppLifecycleState(resumed) 触发
           ↓
  PluginWidgetSyncHelper: syncPendingCalendarEventsOnStartup()
           ↓
  CalendarSyncer: 读取队列并执行 controller.completeEvent()
           ↓
  日历 UI 更新 ✓

  现在无论 App 是首次启动还是从后台恢复，都会同步小组件上完成的日历事件。
```

### 完整示例代码位置

以待办列表小组件为例:

- **Android 端**:
  - Provider: `memento_widgets/android/src/main/kotlin/.../providers/TodoListWidgetProvider.kt`
  - Service: `memento_widgets/android/src/main/kotlin/.../providers/TodoListWidgetService.kt`
  - Factory: `memento_widgets/android/src/main/kotlin/.../providers/TodoListRemoteViewsFactory.kt`
  - 主布局: `memento_widgets/android/src/main/res/layout/widget_todo_list.xml`
  - 列表项布局: `memento_widgets/android/src/main/res/layout/widget_todo_list_item.xml`

- **Flutter 端**:
  - 配置界面: `lib/plugins/todo/screens/todo_list_selector_screen.dart`
  - 数据同步: `lib/core/services/plugin_widget_sync_helper.dart`
  - 生命周期监听: `lib/main.dart` (_MyAppState with WidgetsBindingObserver)
  - 数据控制器: `lib/plugins/todo/controllers/task_controller.dart`

---

## 高级：小组件主题配置

本节详细说明如何为小组件添加**主题可配置**功能，包括背景颜色、强调色和透明度的自定义，以及如何使用 `WidgetConfigEditor` 组件实现实时预览。

### 功能概述

- **背景色配置**: 用户可自定义小组件背景颜色
- **强调色配置**: 用户可自定义标题、文字等强调元素颜色
- **透明度配置**: 用户可调整背景透明度
- **实时预览**: 配置界面实时显示效果预览
- **持久化保存**: 配置数据保存到 SharedPreferences，小组件重启后保持配置

### 架构示意图

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter 端 - 配置界面                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  WidgetConfigEditor 组件                                        │
│  ├── 颜色选择器 (ColorConfig 列表)                               │
│  │   ├── 主色调 (背景色)                                         │
│  │   └── 强调色 (标题色)                                         │
│  ├── 透明度滑块                                                  │
│  └── 实时预览组件 (previewBuilder)                               │
│                                                                 │
│  保存配置                                                        │
│  ├── HomeWidget.saveWidgetData<String>('xxx_primary_color_$id') │
│  ├── HomeWidget.saveWidgetData<String>('xxx_accent_color_$id')  │
│  └── HomeWidget.saveWidgetData<String>('xxx_opacity_$id')       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↕ (SharedPreferences - String 类型)
┌─────────────────────────────────────────────────────────────────┐
│                    Android 端 - WidgetProvider                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  读取配置                                                        │
│  ├── getString("xxx_primary_color_$id")?.toLongOrNull()?.toInt()│
│  ├── getString("xxx_accent_color_$id")?.toLongOrNull()?.toInt() │
│  └── getString("xxx_opacity_$id")?.toFloatOrNull()              │
│                                                                 │
│  应用颜色                                                        │
│  ├── setColorStateList(..., "setBackgroundTintList", ...)       │
│  │   └── 保持圆角效果的背景色设置方式                             │
│  └── setTextColor(R.id.xxx, accentColor)                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 使用 WidgetConfigEditor 组件

#### 1. 数据模型

首先了解配置相关的数据模型：

**路径**: `lib/widgets/widget_config_editor/models/`

```dart
/// 单个颜色配置项
class ColorConfig {
  final String key;           // 唯一标识，如 'primary', 'accent'
  final String label;         // 显示标签，如 '背景色', '标题色'
  final Color defaultValue;   // 默认颜色
  Color currentValue;         // 当前选中的颜色

  ColorConfig({
    required this.key,
    required this.label,
    required this.defaultValue,
    Color? currentValue,
  }) : currentValue = currentValue ?? defaultValue;
}

/// 小组件完整配置
class WidgetConfig {
  final List<ColorConfig> colors;  // 颜色配置列表
  double opacity;                   // 透明度 (0.0 - 1.0)

  WidgetConfig({
    required this.colors,
    this.opacity = 1.0,
  });

  /// 根据 key 获取颜色配置
  ColorConfig? getColor(String key) {
    return colors.where((c) => c.key == key).firstOrNull;
  }
}
```

#### 2. 在配置界面中使用

**路径**: `lib/plugins/xxx/screens/xxx_selector_screen.dart`

```dart
import 'package:Memento/widgets/widget_config_editor/widget_config_editor.dart';
import 'package:Memento/widgets/widget_config_editor/models/color_config.dart';
import 'package:Memento/widgets/widget_config_editor/models/widget_config.dart';

class _XxxSelectorScreenState extends State<XxxSelectorScreen> {
  late WidgetConfig _widgetConfig;

  @override
  void initState() {
    super.initState();
    _initWidgetConfig();
  }

  void _initWidgetConfig() {
    // ⚠️ 初始化配置，可配置多个颜色
    _widgetConfig = WidgetConfig(
      colors: [
        ColorConfig(
          key: 'primary',
          label: '背景色',
          defaultValue: const Color(0xFF5A9E9A),  // 默认绿色
          currentValue: const Color(0xFF5A9E9A),
        ),
        ColorConfig(
          key: 'accent',
          label: '标题色',
          defaultValue: Colors.white,
          currentValue: Colors.white,
        ),
      ],
      opacity: 0.95,  // 默认透明度
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配置小组件')),
      body: Column(
        children: [
          // 其他配置界面（如项目选择列表）...

          // ⚠️ 主题配置编辑器
          WidgetConfigEditor(
            config: _widgetConfig,
            onConfigChanged: (newConfig) {
              setState(() {
                _widgetConfig = newConfig;
              });
            },
            // ⚠️ 实时预览组件
            previewBuilder: (config) => _buildPreview(config),
          ),

          // 保存按钮
          ElevatedButton(
            onPressed: _saveAndFinish,
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  /// 构建实时预览组件
  Widget _buildPreview(WidgetConfig config) {
    final primaryColor = config.getColor('primary')?.currentValue ?? Colors.green;
    final accentColor = config.getColor('accent')?.currentValue ?? Colors.white;
    final opacity = config.opacity;

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(opacity),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedItemName ?? '示例标题',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '预览内容',
            style: TextStyle(color: accentColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
```

#### 3. 保存颜色配置

**⚠️ 关键：必须使用 `String` 类型保存颜色值**

HomeWidget 的 `saveWidgetData` 方法**不支持** Dart 的 `int` 类型，只支持 `Boolean, Float, String, Double, Long`。

```dart
Future<void> _saveAndFinish() async {
  if (_selectedItemId == null || widget.widgetId == null) return;

  try {
    // 1. 获取配置值
    final primaryColor = _widgetConfig.getColor('primary')?.currentValue ?? Colors.green;
    final accentColor = _widgetConfig.getColor('accent')?.currentValue ?? Colors.white;
    final opacity = _widgetConfig.opacity;

    // ⚠️ 2. 保存颜色配置（必须使用 String 类型！）
    await HomeWidget.saveWidgetData<String>(
      'xxx_widget_primary_color_${widget.widgetId}',
      primaryColor.value.toString(),  // Color.value 转为字符串
    );

    await HomeWidget.saveWidgetData<String>(
      'xxx_widget_accent_color_${widget.widgetId}',
      accentColor.value.toString(),
    );

    await HomeWidget.saveWidgetData<String>(
      'xxx_widget_opacity_${widget.widgetId}',
      opacity.toString(),  // double 转为字符串
    );

    // 3. 保存选中项目 ID
    await HomeWidget.saveWidgetData<String>(
      'xxx_item_id_${widget.widgetId}',
      _selectedItemId!,
    );

    // 4. 同步数据并更新小组件
    await _syncDataToWidget();
    await HomeWidget.updateWidget(
      name: 'XxxWidgetProvider',
      iOSName: 'XxxWidgetProvider',
      qualifiedAndroidName: 'github.hunmer.memento.widgets.providers.XxxWidgetProvider',
    );

    if (mounted) Navigator.of(context).pop();
  } catch (e) {
    debugPrint('保存配置失败: $e');
  }
}
```

#### 4. 加载已保存的配置

```dart
Future<void> _loadSavedConfig() async {
  if (widget.widgetId == null) return;

  try {
    // 加载颜色配置
    final primaryColorStr = await HomeWidget.getWidgetData<String>(
      'xxx_widget_primary_color_${widget.widgetId}',
    );
    final accentColorStr = await HomeWidget.getWidgetData<String>(
      'xxx_widget_accent_color_${widget.widgetId}',
    );
    final opacityStr = await HomeWidget.getWidgetData<String>(
      'xxx_widget_opacity_${widget.widgetId}',
    );

    setState(() {
      // 解析颜色值
      if (primaryColorStr != null) {
        final colorValue = int.tryParse(primaryColorStr);
        if (colorValue != null) {
          _widgetConfig.getColor('primary')?.currentValue = Color(colorValue);
        }
      }

      if (accentColorStr != null) {
        final colorValue = int.tryParse(accentColorStr);
        if (colorValue != null) {
          _widgetConfig.getColor('accent')?.currentValue = Color(colorValue);
        }
      }

      if (opacityStr != null) {
        _widgetConfig.opacity = double.tryParse(opacityStr) ?? 0.95;
      }
    });
  } catch (e) {
    debugPrint('加载配置失败: $e');
  }
}
```

### Android 端读取颜色配置

#### 1. 定义配置常量

```kotlin
class XxxWidgetProvider : BasePluginWidgetProvider() {
    override val pluginId: String = "xxx"
    override val widgetSize: WidgetSize = WidgetSize.SIZE_2X2

    companion object {
        private const val PREF_KEY_PREFIX = "xxx_item_id_"
        private const val PREF_KEY_PRIMARY_COLOR = "xxx_widget_primary_color_"
        private const val PREF_KEY_ACCENT_COLOR = "xxx_widget_accent_color_"
        private const val PREF_KEY_OPACITY = "xxx_widget_opacity_"

        // 默认颜色值（ARGB 格式）
        private const val DEFAULT_PRIMARY_COLOR = 0xFF5A9E9A.toInt()
        private const val DEFAULT_ACCENT_COLOR = 0xFFFFFFFF.toInt()
        private const val DEFAULT_OPACITY = 0.95f
    }
}
```

#### 2. 读取配置方法

**⚠️ 关键：从 String 转换为对应类型**

```kotlin
/**
 * 获取背景色（主色调）
 * ⚠️ Flutter 使用 String 存储，需要转换
 */
private fun getConfiguredPrimaryColor(context: Context, appWidgetId: Int): Int {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val colorStr = prefs.getString("$PREF_KEY_PRIMARY_COLOR$appWidgetId", null)
    // ⚠️ 先转 Long 再转 Int（因为颜色值可能超过 Int.MAX_VALUE）
    return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_PRIMARY_COLOR
}

/**
 * 获取标题色（强调色）
 */
private fun getConfiguredAccentColor(context: Context, appWidgetId: Int): Int {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val colorStr = prefs.getString("$PREF_KEY_ACCENT_COLOR$appWidgetId", null)
    return colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_ACCENT_COLOR
}

/**
 * 获取透明度
 */
private fun getConfiguredOpacity(context: Context, appWidgetId: Int): Float {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val opacityStr = prefs.getString("$PREF_KEY_OPACITY$appWidgetId", null)
    return opacityStr?.toFloatOrNull() ?: DEFAULT_OPACITY
}

/**
 * 调整颜色的透明度
 */
private fun adjustColorAlpha(color: Int, alphaFactor: Float): Int {
    val alpha = (alphaFactor * 255).toInt()
    val red = (color shr 16) and 0xFF
    val green = (color shr 8) and 0xFF
    val blue = color and 0xFF
    return (alpha shl 24) or (red shl 16) or (green shl 8) or blue
}
```

#### 3. 应用颜色到小组件

**⚠️ 使用 `setColorStateList` + `backgroundTintList` 保持圆角效果**

```kotlin
import android.content.res.ColorStateList  // ⚠️ 别忘了导入

override fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val views = RemoteViews(context.packageName, R.layout.widget_xxx)

    // 1. 读取颜色和透明度配置
    val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
    val accentColor = getConfiguredAccentColor(context, appWidgetId)
    val opacity = getConfiguredOpacity(context, appWidgetId)

    // 2. ⚠️ 应用背景颜色（使用 backgroundTintList 保持圆角效果）
    val bgColor = adjustColorAlpha(primaryColor, opacity)
    views.setColorStateList(
        R.id.widget_container,
        "setBackgroundTintList",
        ColorStateList.valueOf(bgColor)
    )

    // 3. 应用标题颜色（强调色）
    views.setTextColor(R.id.widget_title, accentColor)

    // 4. 如果有多个标题，分别设置
    // views.setTextColor(R.id.widget_subtitle, accentColor)

    Log.d("XxxWidget", "应用颜色: bg=${Integer.toHexString(primaryColor)}, " +
        "accent=${Integer.toHexString(accentColor)}, opacity=$opacity")

    // ... 其他设置

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
```

#### 4. 修改背景 Drawable

**⚠️ 背景 Drawable 必须使用纯色，以便 `backgroundTintList` 生效**

**路径**: `memento_widgets/android/src/main/res/drawable/widget_xxx_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <!-- ⚠️ 使用纯色背景（白色），颜色通过 backgroundTintList 动态设置 -->
    <solid android:color="#FFFFFF" />
    <!-- 保持圆角效果 -->
    <corners android:radius="16dp" />
</shape>
```

**❌ 不要使用渐变色**:

```xml
<!-- ❌ 错误：渐变色会导致 backgroundTintList 无法正确应用 -->
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#68A9A4"
        android:endColor="#457C78"
        android:angle="135" />
</shape>
```

#### 5. 删除小组件时清理配置

```kotlin
override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    super.onDeleted(context, appWidgetIds)
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val editor = prefs.edit()
    for (appWidgetId in appWidgetIds) {
        // 清理所有相关配置
        editor.remove("$PREF_KEY_PREFIX$appWidgetId")
        editor.remove("$PREF_KEY_PRIMARY_COLOR$appWidgetId")
        editor.remove("$PREF_KEY_ACCENT_COLOR$appWidgetId")
        editor.remove("$PREF_KEY_OPACITY$appWidgetId")
    }
    editor.apply()
}
```

### 常见问题与解决方案

#### 问题 1：PlatformException - Invalid Type

**错误信息**:
```
PlatformException(-10, Invalid Type Long. Supported types are Boolean, Float, String, Double, Long
```

**原因**: Dart 的 `int` 类型不被 HomeWidget 支持

**解决方案**:
```dart
// ❌ 错误
await HomeWidget.saveWidgetData<int>('key', color.value);

// ✅ 正确
await HomeWidget.saveWidgetData<String>('key', color.value.toString());
```

#### 问题 2：背景颜色不生效（仍显示原色）

**原因**:
1. 背景 Drawable 使用了渐变色
2. 使用了 `setBackgroundColor` 而不是 `setColorStateList`

**解决方案**:
1. 修改 Drawable 为纯色：
   ```xml
   <solid android:color="#FFFFFF" />
   ```
2. 使用正确的方法：
   ```kotlin
   views.setColorStateList(R.id.container, "setBackgroundTintList", ColorStateList.valueOf(color))
   ```

#### 问题 3：颜色值解析失败

**原因**: 颜色值（如 `0xFFFFFFFF`）超过 `Int.MAX_VALUE`

**解决方案**:
```kotlin
// ❌ 错误
val color = colorStr?.toIntOrNull() ?: DEFAULT_COLOR

// ✅ 正确：先转 Long 再转 Int
val color = colorStr?.toLongOrNull()?.toInt() ?: DEFAULT_COLOR
```

### 完整示例：签到月历小组件

以 `CheckinMonthWidgetProvider` 为例，展示双颜色配置的完整实现：

**需求**:
- 主色调 → 背景色
- 强调色 → 左上角项目名称 + 右上角月份

**Flutter 端配置初始化**:
```dart
_widgetConfig = WidgetConfig(
  colors: [
    ColorConfig(
      key: 'primary',
      label: '背景色',
      defaultValue: Colors.purple,
      currentValue: Colors.purple,
    ),
    ColorConfig(
      key: 'accent',
      label: '标题色',
      defaultValue: Colors.white,
      currentValue: Colors.white,
    ),
  ],
  opacity: 0.95,
);
```

**Android 端应用颜色**:
```kotlin
override fun updateAppWidget(...) {
    val views = RemoteViews(context.packageName, R.layout.widget_checkin_month)

    val primaryColor = getConfiguredPrimaryColor(context, appWidgetId)
    val accentColor = getConfiguredAccentColor(context, appWidgetId)
    val opacity = getConfiguredOpacity(context, appWidgetId)

    // 背景色（主色调 + 透明度）
    val bgColor = adjustColorAlpha(primaryColor, opacity)
    views.setColorStateList(
        R.id.month_widget_container,
        "setBackgroundTintList",
        ColorStateList.valueOf(bgColor)
    )

    // 标题色（强调色）应用到多个元素
    views.setTextColor(R.id.month_widget_title, accentColor)  // 左上角项目名
    views.setTextColor(R.id.month_widget_month, accentColor)  // 右上角月份

    // ...
}
```

### 总结

实现小组件主题配置的**核心要点**:

1. ✅ **使用 `WidgetConfigEditor`**: 提供统一的颜色和透明度配置 UI
2. ✅ **数据类型转换**: Flutter 保存为 `String`，Android 读取后转换类型
3. ✅ **使用 `backgroundTintList`**: 动态设置背景色同时保持圆角效果
4. ✅ **纯色 Drawable**: 背景 Drawable 必须使用 `<solid>` 而非 `<gradient>`
5. ✅ **配置清理**: `onDeleted()` 中清理所有相关配置项
6. ✅ **实时预览**: 使用 `previewBuilder` 提供配置效果即时反馈

遵循本节指南，可以为任何小组件添加完整的主题配置功能！
