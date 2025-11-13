[根目录](../../CLAUDE.md) > **core**

---

# 核心层 (Core Layer) - 模块文档

## 模块职责

核心层提供 Memento 应用的基础设施，包括：

- **插件管理系统**：动态注册、生命周期管理、插件间通信
- **存储抽象层**：跨平台文件存储（移动端 + Web）
- **配置管理**：应用级与插件级配置持久化
- **事件系统**：全局事件总线，支持插件间松耦合通信
- **插件基类**：定义插件标准接口与生命周期钩子

---

## 入口与启动

### 核心服务初始化流程

在 `main.dart` 中按以下顺序初始化：

```dart
// 1. 存储管理器
globalStorage = StorageManager();
await globalStorage.initialize();

// 2. 配置管理器
globalConfigManager = ConfigManager(globalStorage);
await globalConfigManager.initialize();

// 3. 插件管理器
globalPluginManager = PluginManager();
await globalPluginManager.setStorageManager(globalStorage);

// 4. 注册所有插件
for (final plugin in plugins) {
    await globalPluginManager.registerPlugin(plugin);
}
```

**全局单例访问**：
- `globalStorage`: StorageManager 实例
- `globalConfigManager`: ConfigManager 实例
- `globalPluginManager`: PluginManager 实例
- `eventManager`: 事件管理器（从 event.dart 导出）

---

## 对外接口

### 插件管理器 (PluginManager)

**路径**: `lib/core/plugin_manager.dart`

#### 核心方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `registerPlugin` | `Future<void> registerPlugin(PluginBase plugin)` | 注册插件到系统 |
| `getPlugin` | `PluginBase? getPlugin(String id)` | 根据 ID 获取插件实例 |
| `getAllPlugins` | `List<PluginBase> getAllPlugins({bool sortByRecentlyOpened})` | 获取所有插件列表 |
| `openPlugin` | `void openPlugin(BuildContext context, PluginBase plugin)` | 打开插件界面 |
| `getLastOpenedPlugin` | `PluginBase? getLastOpenedPlugin({String? excludePluginId})` | 获取最近打开的插件 |
| `getCurrentPlugin` | `PluginBase? getCurrentPlugin()` | 获取当前打开的插件 |

#### 特性
- **单例模式**：全局唯一实例
- **访问时间追踪**：记录每个插件的最后访问时间
- **持久化配置**：`autoOpenLastPlugin` 设置

---

### 存储管理器 (StorageManager)

**路径**: `lib/core/storage/storage_manager.dart`

#### 核心方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `write` | `Future<void> write(String key, dynamic value)` | 写入数据（自动序列化 JSON） |
| `read` | `Future<dynamic> read(String key, [dynamic defaultValue])` | 读取数据（自动反序列化） |
| `readFile` | `Future<String> readFile(String path, [String defaultValue])` | 读取文件内容（纯文本） |
| `writeFile` | `Future<void> writeFile(String path, String content)` | 写入文件内容 |
| `delete` | `Future<void> delete(String key)` | 删除数据 |
| `exists` | `Future<bool> exists(String key)` | 检查数据是否存在 |
| `getPluginStoragePath` | `String getPluginStoragePath(String id)` | 获取插件专属存储路径 |

#### 平台适配
- **移动端 (Android/iOS/Desktop)**: 使用 `MobileStorage`，基于文件系统
- **Web**: 使用 `WebStorage`，基于 IndexedDB
- **自动切换**: 通过 `kIsWeb` 判断平台

#### 存储路径结构
```
<appDocuments>/
├── configs/                    # 配置文件
│   ├── app_config.json         # 应用配置
│   └── plugin_access_times     # 插件访问记录
├── chat/                       # 聊天插件数据
│   ├── channels/
│   └── messages/
├── diary/                      # 日记插件数据
└── ...                         # 其他插件
```

---

### 配置管理器 (ConfigManager)

**路径**: `lib/core/config_manager.dart`

#### 核心方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `getLocale` | `Locale getLocale()` | 获取应用语言设置 |
| `setLocale` | `Future<void> setLocale(Locale locale)` | 设置应用语言 |
| `saveAppConfig` | `Future<void> saveAppConfig()` | 保存应用配置 |
| `getPluginConfig` | `Future<Map<String, dynamic>?> getPluginConfig(String pluginId)` | 获取插件配置 |
| `savePluginConfig` | `Future<void> savePluginConfig(String pluginId, Map<String, dynamic> config)` | 保存插件配置 |

#### 配置键
- **应用级配置**: `configs/app_config.json`
  - `themeMode`: 'system' / 'light' / 'dark'
  - `locale`: 'zh_CN' / 'en_US'
- **插件级配置**: `configs/<pluginId>/settings.json`

---

### 插件基类 (PluginBase)

**路径**: `lib/core/plugin_base.dart`

#### 必须实现的属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `id` | `String` | 插件唯一标识符（小写字母+下划线） |
| `icon` | `IconData?` | 插件图标（Material Icons） |
| `color` | `Color?` | 插件主题色 |

#### 必须实现的方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `initialize` | `Future<void> initialize()` | 初始化插件（加载数据、设置监听器） |
| `buildMainView` | `Widget buildMainView(BuildContext context)` | 构建插件主界面 |

#### 可选方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `buildCardView` | `Widget? buildCardView(BuildContext context)` | 构建插件卡片视图（主屏幕显示） |
| `buildSettingsView` | `Widget buildSettingsView(BuildContext context)` | 构建插件设置界面 |
| `registerToApp` | `Future<void> registerToApp(PluginManager, ConfigManager)` | 注册到应用（设置全局监听器等） |
| `getPluginName` | `String? getPluginName(context)` | 获取本地化插件名称 |

#### 插件生命周期

```dart
class MyPlugin extends PluginBase {
    @override
    String get id => 'my_plugin';

    @override
    Future<void> initialize() async {
        // 1. 加载插件配置
        await loadSettings(defaultSettings);

        // 2. 初始化服务层
        await myService.initialize();

        // 3. 恢复状态
        await restoreState();
    }

    @override
    Widget buildMainView(BuildContext context) {
        return MyPluginScreen();
    }
}
```

---

### 事件系统

**路径**: `lib/core/event/`

#### 核心组件

- **Event**: 事件基类
- **EventArgs**: 事件参数基类
- **eventManager**: 全局事件管理器

#### 使用示例

```dart
// 发布事件
eventManager.broadcast('data_updated', EventArgs('user_data'));

// 订阅事件
eventManager.subscribe('data_updated', (args) {
    print('数据已更新: ${args.data}');
});

// 取消订阅
eventManager.unsubscribe('data_updated', handler);
```

#### 内置事件

| 事件名 | 触发时机 | 参数 |
|--------|---------|------|
| `plugins_initialized` | 所有插件注册完成 | EventArgs('plugins_initialized') |
| `data_updated` | 数据更新时（插件自定义） | 自定义 |

---

## 关键依赖与配置

### 外部依赖

- `path_provider`: 获取应用文档目录
- `flutter/foundation.dart`: 平台判断 (`kIsWeb`)
- `shared_preferences`: Web 平台持久化（通过 WebStorage）

### 内部依赖

- `storage/storage_interface.dart`: 存储接口定义
- `storage/mobile_storage.dart`: 移动端实现
- `storage/web_storage.dart`: Web 端实现

---

## 数据模型

### 插件访问记录

```json
{
  "chat": 1731473170123,
  "diary": 1731472890456,
  "activity": 1731471234789
}
```

### 应用配置

```json
{
  "themeMode": "system",
  "locale": "zh_CN"
}
```

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **代码覆盖率**: 未测量

### 测试建议（优先级）

1. **高优先级**：
   - `PluginManager` 的注册、查找、访问时间追踪
   - `StorageManager` 的读写、序列化、平台切换
   - `ConfigManager` 的配置持久化

2. **中优先级**：
   - 事件系统的订阅、发布、取消订阅
   - 插件生命周期钩子调用顺序

3. **低优先级**：
   - 边界条件测试（空值、大数据量）

---

## 常见问题 (FAQ)

### Q1: 如何在插件中访问存储？

```dart
class MyPlugin extends PluginBase {
    Future<void> saveData() async {
        // 方式1：使用插件专属路径
        await storage.write('${storageDir}/my_data.json', data);

        // 方式2：使用辅助方法
        await storage.writePluginFile(id, 'my_data.json', jsonEncode(data));
    }
}
```

### Q2: 如何注册插件间事件监听？

```dart
@override
Future<void> registerToApp(PluginManager pm, ConfigManager cm) async {
    await initialize();

    // 监听其他插件的事件
    eventManager.subscribe('other_plugin_event', (args) {
        handleExternalEvent(args);
    });
}
```

### Q3: 如何调试存储问题？

1. 检查平台类型：`print('Is Web: $kIsWeb')`
2. 打印存储路径：`print(storage.getPluginStoragePath('my_plugin'))`
3. 验证数据写入：`await storage.exists(key)`

### Q4: Web 平台的存储限制是什么？

- IndexedDB 通常有 50MB+ 的配额
- 超出配额时会抛出异常
- 建议大文件使用外部存储（WebDAV 同步）

---

## 相关文件清单

### 核心文件
- `plugin_manager.dart` (253 行) - 插件管理器
- `storage/storage_manager.dart` (242 行) - 存储管理器
- `config_manager.dart` (123 行) - 配置管理器
- `plugin_base.dart` (120 行) - 插件基类
- `storage_service.dart` - 存储服务抽象

### 存储实现
- `storage/storage_interface.dart` - 存储接口
- `storage/mobile_storage.dart` - 移动端存储
- `storage/web_storage.dart` - Web 端存储
- `storage/native_storage_stub.dart` - 平台桩文件
- `storage/web_io_stub.dart` - Web IO 桩文件

### 事件系统
- `event/event.dart` - 事件基类
- `event/event_args.dart` - 事件参数
- `event/item_event_args.dart` - 项目事件参数

### 其他
- `notification_manager.dart` - 通知管理器
- `theme_controller.dart` - 主题控制器
- `floating_ball/floating_ball.dart` - 悬浮球组件

---

## 变更记录 (Changelog)

- **2025-11-13T04:06:10+00:00**: 初始化核心层文档，识别 6 个核心文件与 3 个存储实现

---

**上级目录**: [返回根文档](../../CLAUDE.md)
