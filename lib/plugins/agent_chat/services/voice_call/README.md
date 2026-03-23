# AI 语音通话功能

## 功能概述

这是一个完整的 AI 语音通话功能，支持与 AI 进行自然的语音对话，并在熄屏后继续运行。

## 核心特性

### ✅ 已实现的功能

1. **完整的对话流程**
   - 🎤 用户录音 → 语音识别 → 发送给 AI → TTS 播报 → 下一轮对话
   - 自动循环，无需手动操作

2. **后台运行支持**（Android）
   - 熄屏后继续通话
   - 持续通知显示通话状态
   - 通知栏按钮控制（暂停/继续/结束）

3. **状态管理**
   - 7 种通话状态：空闲、录音中、识别完成、AI 处理中、TTS 播报中、暂停、错误
   - 实时状态指示器
   - 动画效果反馈

4. **可配置选项**
   - TTS 服务选择
   - 自动继续对话
   - 播报后自动录音
   - 最大对话轮数限制
   - 录音超时设置
   - 欢迎语配置

## 文件结构

```
voice_call/
├── voice_call_manager.dart          # 核心管理器
├── voice_call_config.dart           # 配置数据模型
├── voice_call_config_dialog.dart    # 配置对话框
├── voice_call_screen.dart           # 全屏通话界面
├── voice_call_task_handler.dart     # 前台服务处理器
└── voice_call_integration.dart      # 集成示例代码
```

## 快速开始

### 1. 初始化管理器

在 `ChatScreen` 的 `initState` 中：

```dart
Future<void> _initializeVoiceCall() async {
  final recognitionService = TencentASRService(
    secretId: 'your_secret_id',
    secretKey: 'your_secret_key',
    appId: 'your_app_id',
  );

  _voiceCallManager = VoiceCallManager(
    recognitionService: recognitionService,
    onUserMessage: (text) async {
      await _controller.sendMessage(text);
    },
    aiMessageStream: _aiMessageStreamController.stream,
    onStateChanged: (state) {
      debugPrint('状态变更: $state');
    },
    onPhaseChanged: (phase) {
      debugPrint('阶段变更: $phase');
    },
    onError: (error) {
      toastService.showToast('错误: $error');
    },
  );

  await _voiceCallManager!.initialize();
}
```

### 2. 添加通话按钮

在 `AppBar` 的 `actions` 中：

```dart
IconButton(
  icon: const Icon(Icons.phone_in_talk),
  onPressed: _openVoiceCall,
  tooltip: '语音通话',
),
```

### 3. 打开通话界面

```dart
Future<void> _openVoiceCall() async {
  await _startVoiceCallForegroundService();

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => VoiceCallScreen(
        manager: _voiceCallManager!,
        onExit: () {
          _stopVoiceCallForegroundService();
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}
```

### 4. 监听 AI 消息

在 `_onControllerChanged` 中：

```dart
if (_voiceCallManager != null && _voiceCallManager!.isCallActive) {
  _checkAndSendAIMessageToVoiceCall();
}

void _checkAndSendAIMessageToVoiceCall() {
  final messages = _controller.messages;
  if (messages.isEmpty) return;

  for (int i = messages.length - 1; i >= 0; i--) {
    final message = messages[i];
    if (!message.isUser && !message.isGenerating) {
      _voiceCallManager?.handleAIMessage(message.content);
      break;
    }
  }
}
```

## 使用流程

```
用户点击通话按钮
      ↓
打开全屏通话界面
      ↓
自动开始录音（或播报欢迎语）
      ↓
用户说话 → 实时识别显示
      ↓
自动停止 → 发送给 AI
      ↓
显示"AI正在思考..."
      ↓
收到回复 → TTS 播报
      ↓
播报完成 → 自动开始下一轮
      ↓
（循环...）
```

## 配置选项说明

### VoiceCallConfig

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `ttsServiceId` | String? | null | TTS 服务 ID，null 使用默认服务 |
| `autoContinue` | bool | true | 是否自动继续下一轮对话 |
| `autoRecordAfterSpeaking` | bool | true | TTS 播报完成后是否自动开始录音 |
| `maxTurns` | int | 0 | 最大对话轮数，0 表示无限制 |
| `recordingTimeout` | int | 30 | 录音超时时间（秒） |
| `enableWelcomeMessage` | bool | false | 是否播报欢迎语 |
| `welcomeMessage` | String | "您好..." | 欢迎语文本 |

## 通话状态

| 状态 | 说明 | UI 显示 |
|------|------|---------|
| `idle` | 空闲 | 准备就绪 |
| `recording` | 录音中 | 请开始说话... |
| `recognized` | 识别完成 | 识别完成 |
| `processing` | AI 处理中 | AI 正在思考... |
| `speaking` | TTS 播报中 | AI 正在回复... |
| `paused` | 已暂停 | 已暂停 |
| `error` | 错误 | 发生错误 |

## 前台服务（Android）

前台服务确保在熄屏后继续运行：

### 通知栏功能

- 显示通话状态
- 显示当前阶段
- 提供控制按钮（暂停/继续/结束/跳过）

### 通知按钮

```
[暂停] [结束]  // 录音中
[继续] [结束]  // 已暂停
[结束]         // AI 处理中
[跳过] [结束]  // TTS 播报中
```

## 权限要求

### Android

```xml
<!-- 录音权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- 前台服务权限 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />

<!-- 通知权限 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风进行语音通话</string>
```

## 注意事项

### 1. ASR 配置

需要配置腾讯云 ASR 服务：
- Secret ID
- Secret Key
- App ID

从 [腾讯云控制台](https://console.cloud.tencent.com/asr) 获取。

### 2. TTS 配置

需要在 TTS 插件中至少配置一个 TTS 服务。

### 3. 网络要求

- 语音识别需要网络连接
- AI 对话需要网络连接
- HTTP TTS 服务需要网络连接

### 4. 电池优化

长时间通话会消耗较多电量：
- 建议在充电时使用
- 可以设置 `maxTurns` 限制对话轮数

### 5. 隐私

- 录音数据会上传到 ASR 服务
- 对话内容会发送给 AI 服务
- 请确保用户知晓并同意

## 扩展功能

### 添加语音活动检测（VAD）

自动检测用户说话结束：

```dart
await recognitionService.startRecording(enableVAD: true);
```

### 添加打断功能

用户可以在 TTS 播报时打断：

```dart
if (_state == VoiceCallState.speaking) {
  await _voiceCallManager.skipSpeaking();
  await _voiceCallManager.startRecording();
}
```

### 添加对话历史

保存和显示对话历史：

```dart
List<Map<String, dynamic>> conversationHistory = [];

conversationHistory.add({
  'isUser': true,
  'text': _lastRecognizedText,
  'timestamp': DateTime.now(),
});
```

## 故障排查

### 问题：录音失败

**原因**：麦克风权限未授予
**解决**：在设置中授予麦克风权限

### 问题：识别无结果

**原因**：ASR 服务配置错误
**解决**：检查腾讯云 ASR 配置

### 问题：TTS 不播报

**原因**：TTS 服务未配置
**解决**：在 TTS 插件中添加服务

### 问题：熄屏后停止

**原因**：前台服务未启动
**解决**：检查 Android 权限和服务启动

## 更新日志

### v1.0.0 (2026-03-23)

- ✅ 完整的语音通话流程
- ✅ 前台服务支持（Android）
- ✅ 状态管理和动画
- ✅ 配置对话框
- ✅ 通话界面

## 待实现功能

- [ ] 语音活动检测（VAD）
- [ ] 打断功能
- [ ] 对话历史显示
- [ ] 通话记录
- [ ] 更多 TTS 服务
- [ ] iOS 后台运行支持
- [ ] 蓝牙耳机支持
