# 活动周视图小组件 - 全部修复总结

## 问题与解决方案总览

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 1. BroadcastReceiver 注册失败 | Android 14+ 要求指定 RECEIVER_EXPORTED 标志 | 在 `MementoWidgetsPlugin.kt` 中添加版本检查 |
| 2. 热力图布局错误 | 错误的 7×24 布局 | 重写为正确的 24×7 布局 |
| 3. 小组件未注册 | 配置保存时未添加到列表 | 在配置屏幕中添加 `_registerWidgetId()` |
| 4. 小组件删除未清理 | 未从列表中移除 | 添加清理广播机制 |

## 详细修复内容

### 1. 修复 BroadcastReceiver 注册失败

**错误信息**：
```
java.lang.SecurityException: github.hunmer.memento: One of RECEIVER_EXPORTED or RECEIVER_NOT_EXPORTED should be specified
```

**修改文件**：`memento_widgets/android/src/main/kotlin/github/hunmer/memento_widgets/MementoWidgetsPlugin.kt`

**修复内容**：
```kotlin
// 注册广播接收器
if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
    context.registerReceiver(
        widgetBroadcastReceiver,
        filter,
        android.content.Context.RECEIVER_EXPORTED
    )
} else {
    context.registerReceiver(widgetBroadcastReceiver, filter)
}
```

**说明**：Android 14（API 34）及以上版本需要明确指定广播接收器是否导出

---

### 2. 修复热力图布局

**问题**：热力图是 7行24列，应该是 24行7列

**修改文件**：
- `memento_widgets/android/src/main/res/layout/widget_heatmap_grid.xml` - 完全重写
- `memento_widgets/android/src/main/res/layout/widget_activity_weekly.xml` - 调整标签位置
- `memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/ActivityWeeklyWidgetProvider.kt` - 更新索引计算

**布局结构**：
- **24行**：每小时一行（0点-23点）
- **7列**：每天一列（周一到周日）
- **索引公式**：`index = hour * 7 + day`

**顶部标签**：7个星期标签（周一到周日）
**左侧标签**：5个时间标签（0, 6, 12, 18, 24小时）

---

### 3. 修复小组件未注册问题

**问题**：配置保存后，Flutter 同步器找不到已配置的小组件
```
No configured activity weekly widgets found
```

**修改文件**：`lib/plugins/activity/screens/activity_weekly_config_screen.dart`

**新增方法**：`_registerWidgetId()`
```dart
Future<void> _registerWidgetId(int widgetId) async {
  // 获取现有列表
  final existingIdsJson = await HomeWidget.getWidgetData<String>(
    'activity_weekly_widget_ids',
  );

  List<int> widgetIds = [];
  if (existingIdsJson != null && existingIdsJson.isNotEmpty) {
    try {
      widgetIds = List<int>.from(jsonDecode(existingIdsJson) as List);
    } catch (e) {
      debugPrint('Failed to parse existing widget IDs, creating new list: $e');
    }
  }

  // 添加新 widgetId（如果不存在）
  if (!widgetIds.contains(widgetId)) {
    widgetIds.add(widgetId);
    debugPrint('ActivityWeeklyConfig: Registered widgetId $widgetId (total: ${widgetIds.length})');
  }

  // 保存更新后的列表
  await HomeWidget.saveWidgetData<String>(
    'activity_weekly_widget_ids',
    jsonEncode(widgetIds),
  );
}
```

**调用位置**：在 `_saveAndFinish()` 中保存配置后调用

---

### 4. 修复小组件删除未清理问题

**问题**：删除小组件后，widgetId 仍在列表中，导致同步失败

**修改文件**：
- `memento_widgets/android/src/main/kotlin/github/hunmer/memento/widgets/providers/ActivityWeeklyWidgetProvider.kt` - 发送清理广播
- `memento_widgets/android/src/main/AndroidManifest.xml` - 添加清理广播权限
- `lib/core/app_widgets/home_widget_service.dart` - 添加清理广播处理

**Android Provider 修复**：
```kotlin
override fun onDeleted(context: Context, appWidgetIds: IntArray) {
    // 清理数据...
    editor.apply()

    // 通知 Flutter 端清理已删除的 widgetId
    val intent = Intent("github.hunmer.memento.CLEANUP_WIDGET_IDS").apply {
        putExtra("deletedWidgetIds", appWidgetIds)
        putExtra("widgetType", "activity_weekly")
    }
    context.sendBroadcast(intent)
}
```

**Flutter 端新增**：`_cleanupWidgetIds()` 方法
```dart
Future<void> _cleanupWidgetIds(String listKey, List<int> deletedWidgetIds) async {
  final existingIdsJson = await HomeWidget.getWidgetData<String>(listKey);
  final widgetIds = List<int>.from(jsonDecode(existingIdsJson) as List);

  // 移除已删除的 widgetId
  widgetIds.removeWhere((id) => deletedWidgetIds.contains(id));

  // 保存更新后的列表
  if (widgetIds.isEmpty) {
    await HomeWidget.saveWidgetData<String>(listKey, '');
  } else {
    await HomeWidget.saveWidgetData<String>(
      listKey,
      jsonEncode(widgetIds),
    );
  }
}
```

**广播处理**：
```dart
else if (action == 'github.hunmer.memento.CLEANUP_WIDGET_IDS') {
  final widgetType = data?['widgetType'] as String?;
  final deletedWidgetIds = data?['deletedWidgetIds'] as List?;

  if (widgetType == 'activity_weekly' && deletedWidgetIds != null) {
    await _cleanupWidgetIds('activity_weekly_widget_ids', deletedWidgetIds.cast<int>());
  }
}
```

---

## 数据流程

### 周切换按钮工作流程

1. **用户点击上一周/下一周按钮**
   - Android Provider 接收点击事件
   - 更新 weekOffset
   - 发送广播 `REFRESH_ACTIVITY_WEEKLY_WIDGET`

2. **Flutter 端接收广播**
   - memento_widgets 插件转发广播到 Flutter
   - home_widget_service.dart 处理广播

3. **数据同步**
   - 更新 SharedPreferences 中的 weekOffset
   - 调用 `syncActivityWeeklyWidget()` 重新计算数据
   - 调用 `updateWidget()` 通知 Android 刷新

4. **Android 端刷新界面**
   - ActivityWeeklyWidgetProvider 重新渲染
   - 显示新的周数据

### 配置保存工作流程

1. **用户配置小组件**
   - 选择颜色、透明度等
   - 点击"完成"按钮

2. **保存配置**（`_saveAndFinish()`）
   - 保存颜色配置
   - 生成初始数据
   - 同步数据到小组件
   - **注册 widgetId 到列表**（新增）
   - 更新小组件界面

3. **后续使用**
   - 同步器可以找到已配置的小组件
   - 周切换按钮可以正常工作

### 小组件删除清理流程

1. **用户删除小组件**
   - 系统调用 `onDeleted()`
   - Android Provider 清理数据

2. **发送清理广播**
   - 广播包含 deletedWidgetIds 和 widgetType
   - memento_widgets 插件转发到 Flutter

3. **Flutter 端清理列表**
   - 从 `activity_weekly_widget_ids` 中移除已删除的 widgetId
   - 保持列表同步

---

## 完整文件清单

### 新增文件
1. `memento_widgets/android/src/main/res/layout/widget_heatmap_grid.xml` - 24×7 热力图网格

### 修改文件

| 类型 | 文件 | 修改内容 |
|------|------|----------|
| **Android** | `MementoWidgetsPlugin.kt` | 添加 RECEIVER_EXPORTED 标志支持 |
| **Android** | `ActivityWeeklyWidgetProvider.kt` | 更新索引计算、添加清理广播 |
| **Android** | `AndroidManifest.xml` | 添加清理广播权限 |
| **Android** | `widget_activity_weekly.xml` | 调整标签位置 |
| **Flutter** | `activity_weekly_config_screen.dart` | 添加 _registerWidgetId() 方法 |
| **Flutter** | `home_widget_service.dart` | 添加广播监听和 _cleanupWidgetIds() |

### 文档文件
1. `ACTIVITY_WIDGET_UPDATE_SUMMARY.md` - 初始修改总结
2. `HEATMAP_LAYOUT_FIX_SUMMARY.md` - 热力图布局修复总结
3. `ALL_FIXES_SUMMARY.md` - 全部修复总结（本文件）

---

## 测试验证

### 1. 显示测试
- ✅ 热力图显示 24行7列
- ✅ 顶部有星期标签
- ✅ 左侧有时间标签
- ✅ 热力图清晰不模糊

### 2. 功能测试
- ✅ 配置保存后，周切换按钮正常工作
- ✅ 点击上一周/下一周，界面刷新并显示正确数据
- ✅ 删除小组件后，列表正确清理

### 3. 日志验证

**成功日志示例**：
```
ActivityWeeklyWidget: onReceive: action=github.hunmer.memento.widget.ACTIVITY_PREV_WEEK
ActivityWeeklyWidget: Week changed: widgetId=69, newOffset=-2
flutter: 收到小组件广播: github.hunmer.memento.REFRESH_ACTIVITY_WEEKLY_WIDGET
flutter: 活动周视图小组件刷新请求: widgetId=69, weekOffset=-2
flutter: 已更新 weekOffset 为 -2
flutter: ActivityWeeklyConfig: Registered widgetId 69 (total: 1)
flutter: 活动周视图小组件刷新完成
```

### 4. 错误处理
- ✅ Android 14+ 广播注册成功
- ✅ 配置保存成功
- ✅ 小组件删除清理成功

---

## 关键代码片段

### 索引计算（24行7列）
```kotlin
for (hour in 0..23) {
    for (day in 0..6) {
        val index = hour * 7 + day
        val cellId = R.id.heatmap_cell_0 + index
        views.setInt(cellId, "setBackgroundColor", color)
    }
}
```

### 数据访问（heatmap[day][hour]）
```kotlin
val count = if (day < heatmap.size && hour < heatmap[day].size) {
    heatmap[day][hour]
} else {
    0
}
```

### 配置注册
```dart
await _registerWidgetId(widget.widgetId);
```

### 清理逻辑
```dart
widgetIds.removeWhere((id) => deletedWidgetIds.contains(id));
```

---

## 兼容性

- **Android 13 及以下**：使用旧方法注册 BroadcastReceiver
- **Android 14 及以上**：使用 RECEIVER_EXPORTED 标志
- **Flutter**：支持所有版本
- **iOS**：小组件功能不受影响

---

## 总结

所有问题已完全修复：
1. ✅ BroadcastReceiver 注册问题
2. ✅ 热力图显示布局问题
3. ✅ 小组件配置注册问题
4. ✅ 小组件删除清理问题

现在活动周视图小组件可以正常工作，包括：
- 清晰的热力图显示（24×7 网格）
- 正确的星期和时间标签
- 正常的周切换功能
- 完整的配置和清理流程
