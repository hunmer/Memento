# TTS 插件 - AI 上下文文档

> **相对路径**: [根目录](../../../CLAUDE.md) > [plugins](../../) > **tts**

> **变更记录 (Changelog)**
> - **2025-12-17T04:05:34+08:00**: 初始化 TTS 插件文档，完成模块扫描与分析

## 模块职责

TTS (Text-to-Speech) 插件提供文本转语音功能，支持：
- **多服务支持**: 系统内置 TTS 和自定义 HTTP API 服务
- **队列管理**: 批量文本朗读、暂停/继续、跳过等队列控制
- **语音参数调整**: 音调、语速、音量、语音选择
- **多语言支持**: 中英文界面，支持多语言语音
- **跨平台兼容**: Android、iOS、Windows、Web

## 架构设计

### 分层结构
```
tts/
├── tts_plugin.dart              # 插件主类，实现 BasePlugin
├── models/                      # 数据模型层
│   ├── tts_service_config.dart  # TTS服务配置模型
│   ├── tts_service_type.dart    # 服务类型枚举
│   ├── tts_voice.dart           # 语音参数模型
│   └── tts_queue_item.dart      # 队列项模型
├── services/                    # 业务逻辑层
│   ├── tts_base_service.dart    # TTS服务抽象基类
│   ├── tts_manager_service.dart # 管理器服务（服务+队列管理）
│   ├── system_tts_service.dart  # 系统TTS实现（flutter_tts）
│   └── http_tts_service.dart    # HTTP TTS服务实现
├── screens/                     # 界面层
│   └── tts_services_screen.dart # 服务列表管理界面
├── widgets/                     # UI组件
│   └── service_editor_dialog.dart # 服务配置编辑对话框
└── l10n/                        # 国际化资源
    ├── tts_translations.dart    # 翻译接口
    ├── tts_translations_zh.dart # 中文翻译
    └── tts_translations_en.dart # 英文翻译
```

## 核心组件详解

### 1. TTSPlugin (插件主类)
- **继承**: `BasePlugin`
- **单例模式**: 通过 `TTSPlugin.instance` 访问
- **核心服务**: `managerService` - 负责所有 TTS 操作
- **对外API**:
  - `speak()` - 单次朗读
  - `addToQueue()` - 添加到队列
  - `addBatchToQueue()` - 批量添加
  - `pause/resume/stop()` - 播放控制
  - `queue` - 获取队列状态

### 2. TTSManagerService (管理器服务)
- **职责**: 服务配置管理 + 队列管理
- **关键功能**:
  - 服务的增删改查
  - 默认服务管理
  - 队列顺序播放
  - 错误处理与重试
- **存储**: 通过插件存储系统持久化服务配置

### 3. TTS服务实现
#### SystemTTSService (系统TTS)
- **依赖**: `flutter_tts` 包
- **平台适配**:
  - iOS: 音频类别配置、蓝牙支持
  - Android: TTS引擎检测、中文语音包识别
  - Windows: UWP语音支持
- **特性**: 自动语音匹配、降级策略

#### HttpTTSService (HTTP API)
- **依赖**: `dio` + `audioplayers`
- **支持特性**:
  - 自定义API端点
  - 请求模板（支持占位符）
  - 直接音频/JSON响应
  - Base64音频解码
- **配置示例**:
  ```json
  {
    "url": "https://api.example.com/tts",
    "requestBody": "{\"text\":\"{text}\",\"voice\":\"{voice}\"}",
    "responseType": "audio",
    "audioFormat": "mp3"
  }
  ```

## 数据模型

### TTSServiceConfig
```dart
class TTSServiceConfig {
  final String id;              // UUID
  String name;                  // 服务名称
  TTSServiceType type;          // system/http
  bool isDefault;               // 是否默认
  bool isEnabled;               // 是否启用

  // HTTP特有配置
  String? url;                  // API URL
  Map<String, String>? headers; // 请求头
  String? requestBody;          // 请求体模板
  String? audioFormat;          // 音频格式

  // 通用参数
  double pitch;                 // 音调 (0.5-2.0)
  double speed;                 // 语速 (0.5-2.0)
  double volume;                // 音量 (0.0-1.0)
  String? voice;                // 语音标识
}
```

### TTSQueueItem
```dart
class TTSQueueItem {
  final String id;              // UUID
  final String text;            // 朗读文本
  final String? serviceId;      // 指定服务ID
  TTSQueueItemStatus status;    // pending/playing/completed/error
  String? error;                // 错误信息
  final DateTime createdAt;      // 创建时间
}
```

## 关键接口

### 插件对外 API
```dart
// 单次朗读
Future<void> speak(
  String text, {
  String? serviceId,
  TTSCallback? onStart,
  TTSCallback? onComplete,
  TTSErrorCallback? onError,
})

// 队列管理
void addToQueue(String text, {String? serviceId});
void addBatchToQueue(List<String> texts, {String? serviceId});
Future<void> pauseQueue();
Future<void> resumeQueue();
Future<void> stopQueue();
Future<void> skipCurrent();
void clearQueue();

// 播放控制
Future<void> stop();
Future<void> pause();
Future<void> resume();

// 状态查询
List<dynamic> get queue;
bool get isProcessingQueue;
bool get isQueuePaused;
```

## 依赖关系

### 外部依赖
- `flutter_tts: ^3.8.0` - 系统TTS引擎
- `audioplayers: 6.5.0` - 音频播放（HTTP服务）
- `dio: ^5.4.1` - HTTP请求（已存在）
- `uuid: ^4.3.3` - UUID生成（已存在）

### 内部依赖
- `BasePlugin` - 插件基类
- `StorageManager` - 数据持久化
- `ToastService` - 消息提示

## 使用示例

### 1. 基础朗读
```dart
// 获取插件实例
final ttsPlugin = TTSPlugin.instance;

// 使用默认服务朗读
await ttsPlugin.speak('Hello World');

// 指定服务朗读
await ttsPlugin.speak(
  '你好，世界',
  serviceId: 'custom-service-id',
  onStart: () => print('开始朗读'),
  onComplete: () => print('朗读完成'),
  onError: (error) => print('错误: $error'),
);
```

### 2. 队列批量朗读
```dart
// 添加多个文本到队列
ttsPlugin.addBatchToQueue([
  '第一段文本',
  '第二段文本',
  '第三段文本',
]);

// 控制队列
await ttsPlugin.pauseQueue();
await ttsPlugin.resumeQueue();
await ttsPlugin.skipCurrent();
```

### 3. 服务管理
```dart
// 获取管理器
final manager = ttsPlugin.managerService;

// 获取所有服务
final services = await manager.getAllServices();

// 保存新服务
final newService = TTSServiceConfig(
  name: 'Azure TTS',
  type: TTSServiceType.http,
  url: 'https://your-region.tts.speech.microsoft.com/cognitiveservices/v1',
  // ... 其他配置
);
await manager.saveService(newService);
```

### 4. 添加新的 TTS 服务到其他插件
```dart
// 在其他插件中使用 TTS
class ChatPlugin extends BasePlugin {
  Future<void> readMessage(String message) async {
    try {
      final ttsPlugin = PluginManager.instance.getPlugin('tts') as TTSPlugin;
      await ttsPlugin.speak(message);
    } catch (e) {
      // 处理错误
    }
  }
}
```

## 实现细节与注意事项

### 1. 平台特定配置
- **Android**: 需要安装中文语音包
- **iOS**: 自动配置音频会话
- **Windows**: 依赖系统语音包
- **Web**: 通过浏览器 Web Speech API

### 2. 错误处理策略
- 服务降级：HTTP服务失败时回退到系统TTS
- 语音匹配失败：前缀匹配（zh-CN 匹配 zh-CN-*）
- 队列错误：单条失败不影响后续播放

### 3. 性能优化
- 音频临时文件自动清理
- 服务实例复用
- 队列处理异步化

### 4. 安全考虑
- HTTP服务的API密钥通过headers配置
- 临时文件隔离在应用缓存目录

## 扩展指南

### 1. 添加新的TTS服务类型
1. 在 `TTSServiceType` 枚举中添加新类型
2. 创建新服务类继承 `TTSBaseService`
3. 在 `TTSManagerService._createService()` 中添加创建逻辑
4. 更新服务配置模型（如需特有字段）

### 2. 自定义音频处理
- 继承 `HttpTTSService` 并重写 `_playAudioFromBytes()`
- 支持音频格式转换、效果处理等

### 3. 队列策略扩展
- 实现优先级队列
- 添加队列持久化
- 支持队列保存/恢复

## 测试建议

1. **单元测试覆盖**:
   - 服务配置的序列化/反序列化
   - 队列项状态转换
   - 占位符替换逻辑

2. **集成测试**:
   - 系统TTS各平台兼容性
   - HTTP服务连接测试
   - 队列批量播放

3. **性能测试**:
   - 大文本队列处理
   - 并发TTS请求
   - 内存占用监控

## 相关文件清单

### 核心文件（优先阅读）
- `tts_plugin.dart` - 插件入口和对外API
- `services/tts_manager_service.dart` - 核心业务逻辑
- `models/tts_service_config.dart` - 服务配置模型
- `services/system_tts_service.dart` - 系统TTS实现

### 实现文件
- `services/http_tts_service.dart` - HTTP API实现
- `models/tts_queue_item.dart` - 队列项模型
- `models/tts_voice.dart` - 语音模型
- `models/tts_service_type.dart` - 类型定义

### UI文件
- `screens/tts_services_screen.dart` - 服务管理界面
- `widgets/service_editor_dialog.dart` - 服务配置对话框

### 国际化文件
- `l10n/tts_translations_zh.dart` - 中文翻译
- `l10n/tts_translations_en.dart` - 英文翻译

## 扫描覆盖率

- **文件覆盖率**: 100% (15/15 文件已扫描)
- **代码行数采样**: 约 60% (关键部分已读取)
- **未覆盖部分**:
  - 服务编辑对话框的完整UI实现
  - HTTP TTS的占位符处理细节
  - 队列状态变化的UI更新逻辑

## 下一步深挖建议

1. **如果需要添加新功能**:
   - 查看队列管理的并发控制逻辑
   - 研究HTTP服务的自定义配置示例

2. **如果遇到问题**:
   - 检查平台特定的TTS初始化逻辑
   - 查看错误处理和日志记录

3. **性能优化方向**:
   - 音频流式播放实现
   - TTS服务池化管理

---

**最后更新**: 2025-12-17T04:05:34+08:00
**扫描时间**: 2025-12-17
**维护者**: AI Assistant