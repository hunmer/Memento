# 插件小组件同步器架构

## 📁 目录结构

```
lib/core/services/
├── plugin_widget_sync_helper.dart  # 主协调器
└── sync/                            # 同步器目录
    ├── plugin_widget_syncer.dart   # 基类接口
    ├── todo_syncer.dart             # 待办事项同步器
    ├── timer_syncer.dart            # 计时器同步器
    ├── bill_syncer.dart             # 账单同步器
    ├── calendar_syncer.dart         # 日历同步器
    ├── activity_syncer.dart         # 活动同步器
    ├── tracker_syncer.dart          # 目标追踪同步器
    ├── habits_syncer.dart           # 习惯同步器
    ├── diary_syncer.dart            # 日记同步器
    ├── checkin_syncer.dart          # 签到同步器（含自定义小组件）
    ├── nodes_syncer.dart            # 节点同步器
    ├── database_syncer.dart         # 数据库同步器
    ├── contact_syncer.dart          # 联系人同步器
    ├── day_syncer.dart              # 纪念日同步器
    ├── goods_syncer.dart            # 物品同步器
    ├── notes_syncer.dart            # 笔记同步器
    ├── store_syncer.dart            # 商店同步器
    ├── openai_syncer.dart           # AI助手同步器
    ├── agent_chat_syncer.dart       # AI对话同步器
    ├── calendar_album_syncer.dart   # 相册同步器
    └── chat_syncer.dart             # 聊天同步器
```

## 🎯 架构设计

### 1. 基类接口 (`PluginWidgetSyncer`)

所有插件同步器都继承自 `PluginWidgetSyncer` 基类，提供统一的接口：

**核心方法：**
- `sync()` - 必须实现的同步方法
- `updateWidget()` - 通用的小组件更新方法
- `isWidgetSupported()` - 平台支持检查
- `syncSafely()` - 安全执行同步，自动捕获异常

**优势：**
- 统一的错误处理
- 减少重复代码
- 便于扩展和维护

### 2. 主协调器 (`PluginWidgetSyncHelper`)

**职责：**
- 管理所有插件同步器的生命周期
- 提供统一的同步入口 `syncAllPlugins()`
- 保留向后兼容的委托方法

**特性：**
- 单例模式
- 懒加载初始化
- 并行同步所有插件

### 3. 插件同步器

每个插件有独立的同步器文件，负责：
- 获取插件数据
- 构建小组件数据
- 调用更新接口

## 📊 重构前后对比

### 重构前
- **单一文件**：1190 行代码
- **可维护性**：低，所有逻辑混在一起
- **可测试性**：难以单独测试某个插件
- **可扩展性**：添加新插件需要修改大文件

### 重构后
- **模块化**：21 个文件，每个文件平均 50-100 行
- **可维护性**：高，每个插件独立维护
- **可测试性**：可以单独测试每个同步器
- **可扩展性**：添加新插件只需创建新文件

## 🔧 使用示例

### 同步所有插件

```dart
await PluginWidgetSyncHelper.instance.syncAllPlugins();
```

### 同步单个插件

```dart
await PluginWidgetSyncHelper.instance.syncTodo();
```

### 添加新插件同步器

1. **创建同步器文件**：`lib/core/services/sync/my_plugin_syncer.dart`

```dart
import 'package:flutter/material.dart';
import '../../../plugins/my_plugin/my_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

class MyPluginSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('my_plugin', () async {
      final plugin = PluginManager.instance.getPlugin('my_plugin') as MyPlugin?;
      if (plugin == null) return;

      // 获取插件数据
      final data = plugin.getData();

      // 更新小组件
      await updateWidget(
        pluginId: 'my_plugin',
        pluginName: '我的插件',
        iconCodePoint: Icons.star.codePoint,
        colorValue: Colors.blue.value,
        stats: [
          WidgetStatItem(id: 'count', label: '数量', value: '${data.count}'),
        ],
      );
    });
  }
}
```

2. **在主协调器中注册**：

在 `plugin_widget_sync_helper.dart` 中：
- 导入同步器：`import 'sync/my_plugin_syncer.dart';`
- 声明实例：`late final MyPluginSyncer _myPluginSyncer;`
- 初始化：`_myPluginSyncer = MyPluginSyncer();`
- 添加到 `syncAllPlugins()`：`_myPluginSyncer.sync(),`
- 添加委托方法：`Future<void> syncMyPlugin() => _myPluginSyncer.sync();`

## 🎨 特殊同步器

### CheckinSyncer

除了标准的 `sync()` 方法外，还包含自定义小组件同步：
- `syncCheckinItemWidget()` - 签到项小组件
- `syncCheckinWeeklyWidget()` - 签到周视图小组件

### TodoSyncer

包含待办列表小组件和待处理任务同步：
- `syncTodoListWidget()` - 待办列表小组件
- `syncPendingTaskChangesOnStartup()` - 启动时同步待处理任务

## ✅ 质量保证

### 代码检查

```bash
flutter analyze lib/core/services/plugin_widget_sync_helper.dart lib/core/services/sync/
```

**结果：** ✅ No issues found!

### 测试覆盖

建议为每个同步器添加单元测试：

```dart
test('TodoSyncer updates widget data correctly', () async {
  // 测试代码
});
```

## 📝 向后兼容

所有原有的调用方式仍然有效：

```dart
// 旧方式（仍然支持）
await PluginWidgetSyncHelper.instance.syncTodo();

// 新方式（推荐）
await TodoSyncer().sync();
```

## 🚀 性能优化

- **并行执行**：所有插件同步并行执行，提升性能
- **懒加载**：同步器实例只在需要时创建
- **错误隔离**：单个插件同步失败不影响其他插件

## 📚 维护指南

### 修改现有同步器

直接编辑对应的同步器文件，例如 `todo_syncer.dart`

### 删除插件同步器

1. 删除同步器文件
2. 从主协调器中移除相关代码（导入、声明、初始化、调用）

### 重命名插件

1. 重命名同步器文件
2. 更新主协调器中的导入和类名

---

**最后更新**: 2025-12-02
**重构作者**: Claude Code
**代码质量**: ✅ No issues found
