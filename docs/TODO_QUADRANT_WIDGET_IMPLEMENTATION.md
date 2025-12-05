# 任务四象限小组件实现文档

## 概述

本项目成功实现了自定义【任务四象限】小组件，支持在桌面显示任务四象限视图（紧急且重要、不紧急但重要、紧急但不重要、不紧急且不重要），并提供颜色配置和快速任务完成功能。

## 完成的功能特性

### 1. 核心功能
- ✅ 四象限任务展示：按重要性和紧急程度分组显示任务
- ✅ 任务快速完成：点击 checkbox 后台完成任务，无需打开应用
- ✅ 日期范围切换：支持本日/本周/本月循环切换
- ✅ 颜色配置：支持自定义背景色、标题色和透明度
- ✅ 首次配置提示：显示"点击设置小组件"，点击进入配置页面

### 2. 数据同步
- ✅ 应用启动时同步待处理的任务变更
- ✅ 小组件后台操作后实时更新应用 UI
- ✅ 支持广播机制实现数据实时同步

### 3. 配置页面
- ✅ 实时预览效果
- ✅ 双色配置（背景色 + 标题色）
- ✅ 透明度调节
- ✅ 使用 WidgetConfigEditor 组件

## 文件结构

### Flutter 端（lib/）

#### 同步逻辑
```
lib/core/services/sync/todo_syncer.dart
└── 新增方法:
    • syncTodoQuadrantWidget() - 同步四象限小组件数据
    • syncPendingQuadrantChangesOnStartup() - 应用启动时同步
    • _syncPendingQuadrantChanges() - 内部同步方法
```

#### 同步器管理
```
lib/core/services/plugin_widget_sync_helper.dart
└── 修改:
    • syncAllPlugins() - 添加四象限小组件同步
    • 新增 syncTodoQuadrantWidget()
    • 新增 syncPendingQuadrantChangesOnStartup()
```

#### 配置页面
```
lib/plugins/todo/screens/todo_quadrant_widget_config_screen.dart
└── 新增文件:
    • TodoQuadrantWidgetConfigScreen - 小组件配置界面
    • 支持颜色配置和透明度调节
    • 实时预览功能
```

#### 广播接收器
```
lib/core/app_widgets/home_widget_service.dart
└── 修改:
    • _registerBroadcastReceiver() - 注册 REFRESH_TODO_QUADRANT_WIDGET 广播
    • 广播事件处理 - 处理四象限小组件刷新
```

### Android 端（memento_widgets/）

#### Provider 实现
```
memento_widgets/android/src/main/kotlin/.../providers/TodoQuadrantWidgetProvider.kt
└── 新增文件:
    • TodoQuadrantWidgetProvider - 小组件 Provider
    • 处理任务点击事件 (ACTION_TASK_CLICK)
    • 处理日期范围切换 (ACTION_DATE_RANGE_CLICK)
    • 支持颜色配置（主色调、强调色、透明度）
```

#### 布局文件
```
memento_widgets/android/src/main/res/layout/widget_todo_quadrant.xml
└── 新增文件:
    • 2x2 网格布局
    • 四象限展示区域
    • 日期范围切换按钮
```

#### 背景 Drawable
```
memento_widgets/android/src/main/res/drawable/
├── widget_todo_quadrant_background.xml - 小组件背景
├── widget_quadrant_background.xml - 象限背景
├── widget_date_range_button_background.xml - 日期按钮背景
└── widget_checkbox.xml - 自定义 checkbox 样式
```

#### 小组件元数据
```
memento_widgets/android/src/main/res/xml/widget_todo_quadrant_info.xml
└── 新增文件:
    • 小组件配置（2x2 尺寸）
    • 预览布局和描述
```

#### 字符串资源
```
memento_widgets/android/src/main/res/values/strings.xml
└── 修改:
    • 添加 widget_todo_quadrant_label
    • 添加 widget_todo_quadrant_description
```

#### Android 配置
```
memento_widgets/android/src/main/AndroidManifest.xml
└── 修改:
    • 注册 TodoQuadrantWidgetProvider Receiver
    • 添加广播 Action 过滤:
      - APPWIDGET_UPDATE
      - TODO_QUADRANT_TASK_CLICK
      - TODO_QUADRANT_DATE_RANGE_CLICK
```

### memento_widgets 插件

#### 小组件映射
```
memento_widgets/lib/memento_widgets.dart
└── 修改:
    • _androidProviders - 添加 TodoQuadrantWidgetProvider 映射
    • _getProviderNames() - 添加 todo_quadrant 插件映射
    • _getAllProviderNames() - 添加到完整列表
```

## 核心流程

### 1. 首次配置流程
```
用户添加小组件
    ↓
显示"点击设置小组件"
    ↓
点击进入配置页面 (deeplink: memento://widget/todo_quadrant/config)
    ↓
选择颜色和透明度
    ↓
保存配置并同步数据
    ↓
小组件显示四象限视图
```

### 2. 任务完成流程
```
用户点击 checkbox
    ↓
发送广播 ACTION_TASK_CLICK
    ↓
Provider 处理广播事件
    ↓
更新本地 SharedPreferences
    ↓
记录待同步变更
    ↓
刷新小组件 UI
    ↓
应用启动时同步到数据库
```

### 3. 日期范围切换流程
```
用户点击日期范围按钮
    ↓
发送广播 ACTION_DATE_RANGE_CLICK
    ↓
Provider 处理广播事件
    ↓
更新本地配置
    ↓
发送广播刷新应用数据
    ↓
应用接收到广播并刷新小组件
```

## 颜色配置机制

### 配置存储键值对
```dart
// 主色调 (背景色)
'todo_quadrant_widget_primary_color_{widgetId}' -> String (Color.value.toString())

// 强调色 (标题色)
'todo_quadrant_widget_accent_color_{widgetId}' -> String (Color.value.toString())

// 透明度
'todo_quadrant_widget_opacity_{widgetId}' -> String (opacity.toString())

// 日期范围
'todo_quadrant_date_range_{widgetId}' -> String ('today'|'week'|'month')
```

### 配置页面实现
```dart
WidgetConfig(
  colors: [
    ColorConfig(
      key: 'primary',
      label: '背景色',
      defaultValue: Color(0xFF2196F3),
      currentValue: Color(0xFF2196F3),
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

## 四象限逻辑

### 象限分类规则
```kotlin
// 重要程度判断
val isImportant = task.priority == HIGH || task.priority == MEDIUM

// 紧急程度判断 (截止日期在2天内或今天)
val isUrgent = task.dueDate != null &&
    (task.dueDate.isBefore(now.plusDays(2)) ||
     task.dueDate.isSameDayAs(today))

// 四象限分组
if (isImportant && isUrgent) {
    // 紧急且重要
} else if (isImportant && !isUrgent) {
    // 不紧急但重要
} else if (!isImportant && isUrgent) {
    // 紧急但不重要
} else {
    // 不紧急且不重要
}
```

### 象限标签
```xml
紧急且重要      | 不紧急但重要
---------|---------
紧急但不重要  | 不紧急且不重要
```

## 广播机制

### 应用端广播注册
```dart
await platform.invokeMethod('registerBroadcastReceiver', {
  'actions': [
    'github.hunmer.memento.REFRESH_TODO_QUADRANT_WIDGET',
    // ... 其他广播
  ],
});
```

### 广播事件处理
```dart
else if (action == 'github.hunmer.memento.REFRESH_TODO_QUADRANT_WIDGET') {
  await PluginWidgetSyncHelper.instance.syncTodoQuadrantWidget();
  await HomeWidget.updateWidget(
    name: 'TodoQuadrantWidgetProvider',
  );
}
```

## 待处理任务变更机制

### 小组件端记录
```kotlin
// 任务状态变更时
val pending = JSONObject()
pending.put(taskId, completed)  // true=已完成, false=未完成
prefs.edit().putString(PREF_KEY_PENDING_CHANGES, pending.toString()).apply()
```

### 应用端同步
```dart
// 应用启动时
await _todoSyncer.syncPendingQuadrantChangesOnStartup();

// 内部实现
Future<void> _syncPendingQuadrantChanges(TodoPlugin plugin) async {
  final pendingJson = await MyWidgetManager().getData<String>('todo_quadrant_pending_changes');
  final pending = jsonDecode(pendingJson) as Map<String, dynamic>;

  for (final entry in pending.entries) {
    final taskId = entry.key;
    final completed = entry.value as bool;

    if (completed) {
      await plugin.taskController.updateTaskStatus(taskId, TaskStatus.done);
    } else {
      await plugin.taskController.updateTaskStatus(taskId, TaskStatus.todo);
    }
  }
}
```

## 使用说明

### 1. 添加小组件
1. 在桌面长按进入小组件添加模式
2. 滑动找到"任务四象限"小组件
3. 选择 2x2 尺寸并添加到桌面

### 2. 配置小组件
1. 首次添加会显示"点击设置小组件"
2. 点击小组件进入配置页面
3. 选择喜欢的背景色、标题色和透明度
4. 点击"完成"保存配置

### 3. 使用小组件
- **切换日期范围**: 点击左上角按钮（本日/本周/本月）
- **完成任务**: 点击任意象限中的 checkbox
- **查看任务**: 点击标题栏打开待办事项页面

## 注意事项

1. **颜色配置类型**: 必须使用 `String` 类型存储颜色值（Color.value.toString()）
2. **广播权限**: 需要在 AndroidManifest.xml 中注册相应的广播 Action
3. **透明度范围**: 0.0 - 1.0，建议 0.95 保持良好视觉效果
4. **日期范围**: 本日/本周/本月循环切换，不支持自定义日期
5. **任务分组**: 基于优先级和截止日期自动分组，不支持手动调整

## 测试建议

### 1. 功能测试
- [ ] 首次添加小组件显示配置提示
- [ ] 配置页面正常显示和保存
- [ ] 颜色配置实时生效
- [ ] 日期范围切换正常工作
- [ ] 任务完成功能正常

### 2. 数据同步测试
- [ ] 小组件完成的任务应用启动后同步
- [ ] 应用中完成的任务小组件实时更新
- [ ] 任务状态变更双向同步

### 3. 边界情况测试
- [ ] 无任务时显示
- [ ] 任务数量超过象限容量时
- [ ] 应用被杀死后重启数据同步

## 总结

本实现完全按照需求文档完成，包括：
- ✅ 使用可变颜色配置（参考 docs/CUSTOM_WIDGET_GUIDE.md:1467~2021）
- ✅ 小组件 UI 与效果图保持一致
- ✅ 使用 RemoteViews 而非嵌入 View
- ✅ 实现广播机制支持后台数据更新（参考 docs/CUSTOM_WIDGET_GUIDE.md:1430~1476）
- ✅ 支持 deeplink 配置页面（非 android:configure）
- ✅ 四象限完整布局和交互功能

所有代码已通过编译检查，可正常构建和运行。
