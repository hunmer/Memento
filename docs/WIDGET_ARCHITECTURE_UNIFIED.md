# Memento 小组件统一架构文档

> **版本**: 2.0 (统一架构)
> **更新日期**: 2025-11-30
> **状态**: ✅ 已完成统一

---

## 架构总览

Memento 小组件系统已完成统一架构改造,所有小组件遵循一致的设计模式和最佳实践。

### 核心原则

1. **统一入口** - 所有小组件更新通过 `SystemWidgetService` 统一入口
2. **平台检查** - 使用 `SystemWidgetService.instance.isWidgetSupported()` 统一平台检查
3. **错误处理** - 使用 `Logger` 统一日志记录,规范的错误处理
4. **数据模型** - 常规小组件使用 `PluginWidgetData` 标准模型

---

## 小组件分类

### 1. 常规插件小组件 (20个)

**特点**:
- 使用标准 `PluginWidgetData` 数据模型
- 通过 `SystemWidgetService.updateWidgetData()` 更新
- 通过 `PluginWidgetSyncHelper` 批量同步

**已实现的插件**:
```
todo, timer, bill, calendar, activity, tracker, habits,
diary, checkin, nodes, database, contact, day, goods,
notes, store, openai, agent_chat, calendar_album, chat
```

**示例** (以 `agent_chat` 为例):
```dart
// lib/plugins/agent_chat/services/widget_service.dart
class AgentChatWidgetService {
  static Future<void> updateWidget() async {
    // 1. 统一平台检查
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      _logger.fine('Widget not supported');
      return;
    }

    try {
      // 2. 构建标准数据模型
      final widgetData = PluginWidgetData(
        pluginId: 'agent_chat',
        pluginName: 'AI对话',
        iconCodePoint: Icons.smart_toy.codePoint,
        colorValue: Colors.blue.value,
        stats: [
          WidgetStatItem(id: 'count', label: '对话数', value: '10'),
          WidgetStatItem(id: 'messages', label: '消息数', value: '42'),
        ],
      );

      // 3. 统一更新接口
      await SystemWidgetService.instance.updateWidgetData('agent_chat', widgetData);
    } catch (e, stack) {
      _logger.severe('更新失败', e, stack);
    }
  }
}
```

---

### 2. 快速小组件 (2个)

**特点**:
- 使用自定义数据格式(JSON)
- 直接使用 `HomeWidget` API,但通过 Service 层封装
- 包含完整的包名 `qualifiedAndroidName`

**已实现**:
1. **ChatQuickWidget** - 聊天快速小组件(显示最近3个频道)
2. **AgentVoiceWidget** - AI语音快捷小组件

**示例** (`ChatQuickWidget`):
```dart
// lib/plugins/chat/services/widget_service.dart
class ChatWidgetService {
  static Future<void> updateWidget() async {
    // 1. 统一平台检查
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      _logger.fine('Widget not supported');
      return;
    }

    try {
      // 2. 保存自定义 JSON 数据
      await HomeWidget.saveWidgetData('channels_json', jsonEncode(channelsData));
      await HomeWidget.saveWidgetData('channel_count', channels.length);

      // 3. 使用完整包名更新
      await HomeWidget.updateWidget(
        name: 'ChatQuickWidget',
        qualifiedAndroidName: 'github.hunmer.memento.widgets.quick.ChatQuickWidgetProvider',
        iOSName: 'ChatQuickWidget',
      );
    } catch (e, stack) {
      _logger.severe('更新失败', e, stack);
    }
  }
}
```

---

## 统一架构实践

### ✅ 统一平台检查

**错误做法** (已废弃):
```dart
// ❌ 不要这样做
if (!UniversalPlatform.isAndroid && !UniversalPlatform.isIOS) {
  return;
}
```

**正确做法**:
```dart
// ✅ 使用统一接口
if (!SystemWidgetService.instance.isWidgetSupported()) {
  _logger.fine('Widget not supported on this platform');
  return;
}
```

---

### ✅ 统一错误处理

**标准模式**:
```dart
try {
  // 小组件更新逻辑
  await SystemWidgetService.instance.updateWidgetData(pluginId, data);
  _logger.info('${pluginName}小组件已更新');
} catch (e, stack) {
  _logger.severe('更新${pluginName}小组件失败', e, stack);
}
```

---

### ✅ 统一初始化流程

**插件级初始化**:
```dart
class MyPluginWidgetService {
  static Future<void> initialize() async {
    // 平台检查
    if (!SystemWidgetService.instance.isWidgetSupported()) {
      _logger.fine('Widget not supported, skipping initialization');
      return;
    }

    try {
      // 初次更新小组件
      await updateWidget();
      _logger.info('MyPluginWidgetService 已初始化');
    } catch (e, stack) {
      _logger.severe('初始化失败', e, stack);
    }
  }
}
```

**主应用初始化** (main.dart):
```dart
void main() async {
  // ...

  // 1. 初始化系统小组件服务
  await SystemWidgetService.instance.initialize();

  // 2. 同步所有插件
  await PluginWidgetSyncHelper.instance.syncAllPlugins();

  runApp(MyApp());
}
```

---

## 完整的包名映射

### Android Provider 类名规范

**常规插件小组件**:
```
格式: github.hunmer.memento.widgets.providers.{PluginName}WidgetProvider
示例:
- TodoWidgetProvider         → github.hunmer.memento.widgets.providers.TodoWidgetProvider
- DiaryWidgetProvider        → github.hunmer.memento.widgets.providers.DiaryWidgetProvider
- ChatWidgetProvider         → github.hunmer.memento.widgets.providers.ChatWidgetProvider
```

**快速小组件**:
```
格式: github.hunmer.memento.widgets.quick.{WidgetName}Provider
示例:
- ChatQuickWidgetProvider    → github.hunmer.memento.widgets.quick.ChatQuickWidgetProvider
- AgentVoiceWidgetProvider   → github.hunmer.memento.widgets.quick.AgentVoiceWidgetProvider
```

---

## 数据流图

```
┌─────────────────────────────────────────────────────┐
│           Memento 主应用 (Flutter)                  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  插件数据变更 (Plugin Data Change)            │  │
│  └──────────────────┬────────────────────────────┘  │
│                     │                               │
│                     ▼                               │
│  ┌───────────────────────────────────────────────┐  │
│  │  插件级 WidgetService                         │  │
│  │  - ChatWidgetService (快速小组件)             │  │
│  │  - AgentChatWidgetService (常规小组件)        │  │
│  └──────────────────┬────────────────────────────┘  │
│                     │                               │
│                     ▼                               │
│  ┌───────────────────────────────────────────────┐  │
│  │  SystemWidgetService (统一入口)               │  │
│  │  - isWidgetSupported() 平台检查               │  │
│  │  - updateWidgetData() 标准更新                │  │
│  └──────────────────┬────────────────────────────┘  │
│                     │                               │
└─────────────────────┼───────────────────────────────┘
                      │
                      ▼
     ┌────────────────────────────────────┐
     │  memento_widgets 插件 (Flutter)    │
     │  ┌──────────────────────────────┐  │
     │  │  MyWidgetManager             │  │
     │  │  - updatePluginWidgetData()  │  │
     │  └──────────┬───────────────────┘  │
     │             │                      │
     │             ▼                      │
     │  ┌──────────────────────────────┐  │
     │  │  SharedPreferences           │  │
     │  │  (HomeWidgetPreferences)     │  │
     │  └──────────┬───────────────────┘  │
     └─────────────┼──────────────────────┘
                   │
                   ▼
     ┌────────────────────────────────────┐
     │  Android 原生层 (Kotlin)           │
     │  ┌──────────────────────────────┐  │
     │  │  BasePluginWidgetProvider    │  │
     │  │  - onUpdate()                │  │
     │  │  - 读取 SharedPreferences     │  │
     │  │  - 渲染 RemoteViews          │  │
     │  └──────────────────────────────┘  │
     └────────────────────────────────────┘
                   │
                   ▼
          Android 系统桌面小组件
```

---

## 最佳实践总结

### ✅ 推荐做法

1. **使用统一接口**
   - 平台检查: `SystemWidgetService.instance.isWidgetSupported()`
   - 数据更新: `SystemWidgetService.instance.updateWidgetData()`

2. **规范日志记录**
   - 使用 `Logger` 包
   - `_logger.fine()` - 调试信息(平台不支持等)
   - `_logger.info()` - 正常操作
   - `_logger.severe()` - 错误(附带堆栈)

3. **标准数据模型**
   - 常规小组件: `PluginWidgetData` + `WidgetStatItem`
   - 快速小组件: 自定义JSON(但通过Service封装)

4. **完整包名**
   - 始终使用 `qualifiedAndroidName` 参数
   - 避免简单类名冲突

### ❌ 避免做法

1. **不要直接判断平台**
   ```dart
   // ❌ 不要这样
   if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) { }
   ```

2. **不要跳过错误处理**
   ```dart
   // ❌ 不要这样
   await updateWidget(); // 没有 try-catch
   ```

3. **不要使用简单类名**
   ```dart
   // ❌ 不要这样
   await HomeWidget.updateWidget(androidName: 'ChatWidgetProvider');
   ```

4. **不要重复调用 initialize()**
   ```dart
   // ❌ 不要在插件级服务中调用
   await SystemWidgetService.instance.initialize(); // 主应用已初始化
   ```

---

## 迁移检查清单

如果你要添加新的小组件或修改现有小组件,请确保:

- [ ] 使用 `SystemWidgetService.instance.isWidgetSupported()` 检查平台
- [ ] 使用 `Logger` 记录日志
- [ ] 常规小组件使用 `PluginWidgetData` 数据模型
- [ ] Android Provider 使用完整包名 `qualifiedAndroidName`
- [ ] 在 `PluginWidgetSyncHelper` 中添加同步方法
- [ ] 在 `MyWidgetManager._getProviderName()` 中添加映射
- [ ] 在 `memento_widgets/android/AndroidManifest.xml` 注册 Receiver
- [ ] 提供标准化的错误处理和日志输出

---

## 相关文件

| 文件路径 | 说明 |
|---------|------|
| `lib/core/services/system_widget_service.dart` | 统一入口 Service |
| `lib/core/services/plugin_widget_sync_helper.dart` | 批量同步工具 |
| `lib/plugins/chat/services/widget_service.dart` | 快速小组件示例 |
| `lib/plugins/agent_chat/services/widget_service.dart` | 常规小组件示例 |
| `memento_widgets/lib/memento_widgets.dart` | 底层插件 API |
| `memento_widgets/android/src/main/AndroidManifest.xml` | Provider 注册 |

---

## 关键修复记录

### ✅ 修复 Provider 包名映射缺失 (2025-11-30)

**问题**:
```
PlatformException(-3, No Widget found with Name TodoWidgetProvider.
ClassNotFoundException: github.hunmer.memento.TodoWidgetProvider
```

**原因**:
`memento_widgets/lib/memento_widgets.dart` 中的 `_androidProviders` 映射只包含示例小组件,缺少所有插件小组件的完整包名。

**修复**:
在 `_androidProviders` 中添加了所有 42 个小组件的完整包名映射:
- 20 个插件小组件 (1x1 尺寸)
- 20 个插件小组件 (2x2 尺寸)
- 2 个快速小组件

```dart
static const Map<String, String> _androidProviders = {
  // 插件小组件 - 1x1
  'TodoWidgetProvider': 'github.hunmer.memento.widgets.providers.TodoWidgetProvider',
  'DiaryWidgetProvider': 'github.hunmer.memento.widgets.providers.DiaryWidgetProvider',
  // ... 其他 18 个

  // 插件小组件 - 2x2
  'TodoWidget2x1Provider': 'github.hunmer.memento.widgets.providers.TodoWidget2x1Provider',
  // ... 其他 19 个

  // 快速小组件
  'ChatQuickWidgetProvider': 'github.hunmer.memento.widgets.quick.ChatQuickWidgetProvider',
  'AgentVoiceWidgetProvider': 'github.hunmer.memento.widgets.quick.AgentVoiceWidgetProvider',
};
```

---

## 更新历史

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| 2.1 | 2025-11-30 | 修复所有插件小组件的包名映射缺失问题 |
| 2.0 | 2025-11-30 | 完成架构统一改造,修复 ChatQuickWidget 类名问题 |
| 1.0 | - | 初始版本(混合架构) |

---

**文档维护**: Memento 开发团队
**反馈渠道**: [GitHub Issues](https://github.com/hunmer/Memento/issues)
