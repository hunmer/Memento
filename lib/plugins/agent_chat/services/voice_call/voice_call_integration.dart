/// 语音通话集成示例
///
/// 这个文件展示了如何在 ChatScreen 中集成语音通话功能
/// 将以下代码添加到 ChatScreen 中

// ========== 1. 添加导入 ==========
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_manager.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_config_dialog.dart';
import 'package:Memento/plugins/agent_chat/screens/chat_screen/components/voice_call_screen.dart';
import 'package:Memento/plugins/agent_chat/services/speech/tencent_asr_service.dart';
import 'package:memento_foreground_service/memento_foreground_service.dart';

// ========== 2. 在 _ChatScreenState 中添加状态变量 ==========

// 语音通话管理器
VoiceCallManager? _voiceCallManager;

// 语音通话配置
VoiceCallConfig _voiceCallConfig = const VoiceCallConfig();

// AI消息流控制器（用于监听AI回复）
final StreamController<String> _aiMessageStreamController = StreamController<String>.broadcast();

// ========== 3. 在 initState 中初始化（添加在 _initializeController 调用后） ==========

Future<void> _initializeVoiceCall() async {
  try {
    // 创建语音识别服务（使用腾讯云ASR）
    final recognitionService = TencentASRService(
      // 从配置中获取ASR配置
      secretId: '',  // 从设置中获取
      secretKey: '', // 从设置中获取
      appId: '',     // 从设置中获取
    );

    // 创建语音通话管理器
    _voiceCallManager = VoiceCallManager(
      recognitionService: recognitionService,
      onUserMessage: (text) async {
        // 发送消息给AI
        await _controller.sendMessage(text);
      },
      aiMessageStream: _aiMessageStreamController.stream,
      onStateChanged: (state) {
        debugPrint('语音通话状态变更: $state');
      },
      onPhaseChanged: (phase) {
        debugPrint('语音通话阶段: $phase');
      },
      onError: (error) {
        toastService.showToast('语音通话错误: $error');
      },
    );

    await _voiceCallManager!.initialize();
    debugPrint('✅ 语音通话管理器初始化完成');
  } catch (e) {
    debugPrint('❌ 语音通话管理器初始化失败: $e');
  }
}

// ========== 4. 在 dispose 中释放资源 ==========

@override
void dispose() {
  _voiceCallManager?.dispose();
  _aiMessageStreamController.close();
  _controller.removeListener(_onControllerChanged);
  _controller.messageService.removeListener(_onControllerChanged);
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}

// ========== 5. 在 _onControllerChanged 中监听AI消息 ==========

void _onControllerChanged() {
  if (mounted) {
    final currentMessageCount = _controller.messages.length;
    final hasNewMessage = currentMessageCount > _lastMessageCount;
    final wasEmpty = _lastMessageCount == 0;
    _lastMessageCount = currentMessageCount;

    // 使用 addPostFrameCallback 避免在构建过程中调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });

    // 在以下情况自动滚动到底部：
    // 1. 有新消息添加时
    // 2. 从空消息列表变为有消息时（首次进入或清空后）
    if (hasNewMessage || wasEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    // 检查是否有新的AI消息完成，如果开启了自动朗读则进行朗读
    if (_autoReadEnabled) {
      _checkAndReadNewAIMessage();
    }

    // ===== 新增：语音通话功能 =====
    // 如果正在语音通话中，发送AI消息到管理器
    if (_voiceCallManager != null && _voiceCallManager!.isCallActive) {
      _checkAndSendAIMessageToVoiceCall();
    }
  }
}

/// 检查并发送AI消息到语音通话管理器
void _checkAndSendAIMessageToVoiceCall() {
  try {
    final messages = _controller.messages;
    if (messages.isEmpty) return;

    // 获取最新的AI消息
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];

      // 只处理AI消息，且消息已完成(非生成中)
      if (!message.isUser && !message.isGenerating) {
        // 检查是否是新消息（避免重复处理）
        // 可以通过检查消息ID或其他方式来判断
        _voiceCallManager?.handleAIMessage(message.content);
        break;
      }
    }
  } catch (e) {
    debugPrint('发送AI消息到语音通话管理器失败: $e');
  }
}

// ========== 6. 添加打开语音通话界面的方法 ==========

/// 打开语音通话界面
Future<void> _openVoiceCall() async {
  if (_voiceCallManager == null) {
    toastService.showToast('语音通话功能未初始化');
    return;
  }

  // 启动前台服务（支持熄屏后继续运行）
  await _startVoiceCallForegroundService();

  // 打开语音通话全屏界面
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => VoiceCallScreen(
        manager: _voiceCallManager!,
        onExit: () {
          // 退出时停止前台服务
          _stopVoiceCallForegroundService();
          Navigator.of(context).pop();
        },
      ),
    ),
  );
}

/// 启动语音通话前台服务
Future<void> _startVoiceCallForegroundService() async {
  if (!UniversalPlatform.isAndroid) return;

  try {
    final isRunning = await FlutterForegroundTask.isRunningService;

    if (!isRunning) {
      await FlutterForegroundTask.startService(
        serviceId: 258, // 使用不同的ID避免与聊天前台服务冲突
        notificationTitle: 'AI 语音通话',
        notificationText: '正在通话中...',
        notificationButtons: [
          const ServiceNotificationButton(key: 'pause', label: '暂停'),
          const ServiceNotificationButton(key: 'end', label: '结束'),
        ],
        callback: startVoiceCallTaskCallback,
      );
      debugPrint('✅ 语音通话前台服务已启动');
    }
  } catch (e) {
    debugPrint('❌ 启动语音通话前台服务失败: $e');
  }
}

/// 停止语音通话前台服务
Future<void> _stopVoiceCallForegroundService() async {
  if (!UniversalPlatform.isAndroid) return;

  try {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      debugPrint('✅ 语音通话前台服务已停止');
    }
  } catch (e) {
    debugPrint('❌ 停止语音通话前台服务失败: $e');
  }
}

/// 打开语音通话配置对话框
Future<void> _openVoiceCallConfig() async {
  final result = await showVoiceCallConfigDialog(
    context,
    initialConfig: _voiceCallConfig,
  );

  if (result != null) {
    setState(() {
      _voiceCallConfig = result;
    });
    _voiceCallManager?.updateConfig(result);
    toastService.showToast('配置已保存');
  }
}

// ========== 7. 在 AppBar 的 actions 中添加语音通话按钮 ==========

// 在现有按钮后添加：
IconButton(
  icon: const Icon(Icons.phone_in_talk),
  onPressed: _openVoiceCall,
  tooltip: '语音通话',
),

// ========== 8. 在 PopupMenuButton 中添加配置选项 ==========

PopupMenuItem(
  value: 'voice_call_config',
  child: Row(
    children: [
      const Icon(Icons.settings_voice),
      const SizedBox(width: 12),
      Text('语音通话设置'),
    ],
  ),
),

// 然后在 onSelected 中处理：
case 'voice_call_config':
  _openVoiceCallConfig();
  break;

// ========== 9. 创建前台服务回调（添加到 chat_task_handler.dart 或新建文件） ==========

/// 语音通话前台服务回调
@pragma('vm:entry-point')
void startVoiceCallTaskCallback() {
  FlutterForegroundTask.setTaskHandler(VoiceCallTaskHandler());
}

/// 语音通话任务处理器
class VoiceCallTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // 服务启动时的初始化
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // 定期更新通知等
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // 服务销毁时的清理
  }

  @override
  void onButtonPressed(String id) {
    switch (id) {
      case 'pause':
        // 发送暂停事件到主应用
        FlutterForegroundTask.sendDataToTask({'event': 'pause_call'});
        break;
      case 'resume':
        // 发送继续事件到主应用
        FlutterForegroundTask.sendDataToTask({'event': 'resume_call'});
        break;
      case 'end':
        // 发送结束事件到主应用
        FlutterForegroundTask.sendDataToTask({'event': 'end_call'});
        break;
    }
  }

  @override
  void onDataReceived(Object data) {
    // 接收来自主应用的数据，用于更新通知等
    if (data is Map<String, dynamic>) {
      final action = data['action'];

      switch (action) {
        case 'update_notification':
          // 更新通知内容
          FlutterForegroundTask.updateService(
            notificationTitle: data['title'] ?? 'AI 语音通话',
            notificationText: data['content'] ?? '正在通话中...',
          );
          break;
      }
    }
  }
}

// ========== 10. 在 VoiceCallScreen 中添加对前台服务事件的监听 ==========

// 在 _VoiceCallScreenState 中添加：

StreamSubscription? _foregroundDataSubscription;

@override
void initState() {
  super.initState();
  _initializeAnimation();
  _initializeManager();
  _listenToForegroundService();

  // 自动开始通话
  WidgetsBinding.instance.addPostFrameCallback((_) {
    widget.manager.startCall();
  });
}

@override
void dispose() {
  _foregroundDataSubscription?.cancel();
  _pulseController.dispose();
  super.dispose();
}

/// 监听前台服务事件
void _listenToForegroundService() {
  if (!UniversalPlatform.isAndroid) return;

  _foregroundDataSubscription = FlutterForegroundTask.getDataStream.listen((data) {
    if (data is Map<String, dynamic>) {
      final event = data['event'];

      switch (event) {
        case 'pause_call':
          widget.manager.pauseCall();
          break;
        case 'resume_call':
          widget.manager.resumeCall();
          break;
        case 'end_call':
          widget.manager.endCall();
          widget.onExit?.call();
          break;
      }
    }
  });
}

// ========== 11. 创建语音通话配置对话框 ==========

/// 显示语音通话配置对话框
Future<VoiceCallConfig?> showVoiceCallConfigDialog(
  BuildContext context, {
  required VoiceCallConfig initialConfig,
}) {
  return showDialog<VoiceCallConfig>(
    context: context,
    builder: (context) => VoiceCallConfigDialog(initialConfig: initialConfig),
  );
}
