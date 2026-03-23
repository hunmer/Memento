import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_service.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_state.dart';
import 'package:Memento/plugins/tts/tts_plugin.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 语音通话状态
enum VoiceCallState {
  /// 空闲（未开始或已结束）
  idle,

  /// 录音中（等待用户说话）
  recording,

  /// 识别完成，准备发送给AI
  recognized,

  /// AI处理中（生成回复）
  processing,

  /// TTS播报中（朗读AI回复）
  speaking,

  /// 暂停
  paused,

  /// 错误
  error,
}

/// 语音通话阶段
enum VoiceCallPhase {
  /// 用户说话
  userSpeaking,

  /// AI回复
  aiResponding,
}

/// 语音通话配置
class VoiceCallConfig {
  /// TTS服务ID（null表示使用默认服务）
  final String? ttsServiceId;

  /// 自动开始下一轮对话
  final bool autoContinue;

  /// TTS播报完成后自动开始录音
  final bool autoRecordAfterSpeaking;

  /// 最大连续对话轮数（0表示无限制）
  final int maxTurns;

  /// 录音超时时间（秒）
  final int recordingTimeout;

  /// 是否播报欢迎语
  final bool enableWelcomeMessage;

  /// 欢迎语
  final String welcomeMessage;

  const VoiceCallConfig({
    this.ttsServiceId,
    this.autoContinue = true,
    this.autoRecordAfterSpeaking = true,
    this.maxTurns = 0,
    this.recordingTimeout = 30,
    this.enableWelcomeMessage = false,
    this.welcomeMessage = '您好，我是AI助手，请开始说话',
  });

  VoiceCallConfig copyWith({
    String? ttsServiceId,
    bool? autoContinue,
    bool? autoRecordAfterSpeaking,
    int? maxTurns,
    int? recordingTimeout,
    bool? enableWelcomeMessage,
    String? welcomeMessage,
  }) {
    return VoiceCallConfig(
      ttsServiceId: ttsServiceId ?? this.ttsServiceId,
      autoContinue: autoContinue ?? this.autoContinue,
      autoRecordAfterSpeaking: autoRecordAfterSpeaking ?? this.autoRecordAfterSpeaking,
      maxTurns: maxTurns ?? this.maxTurns,
      recordingTimeout: recordingTimeout ?? this.recordingTimeout,
      enableWelcomeMessage: enableWelcomeMessage ?? this.enableWelcomeMessage,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
    );
  }
}

/// 语音通话管理器
///
/// 负责管理AI语音通话的完整流程：
/// 1. 录音（用户说话）
/// 2. 语音识别（转文字）
/// 3. 发送给AI（获取回复）
/// 4. TTS播报（朗读回复）
/// 5. 循环下一轮
class VoiceCallManager {
  final SpeechRecognitionService recognitionService;
  final Function(String text) onUserMessage;
  final Stream<String> aiMessageStream;

  // 配置
  VoiceCallConfig _config = const VoiceCallConfig();

  // 状态
  VoiceCallState _state = VoiceCallState.idle;
  int _currentTurn = 0;
  String? _lastRecognizedText;
  String? _lastAIMessage;

  // 订阅
  StreamSubscription<String>? _recognitionSubscription;
  StreamSubscription<String>? _aiMessageSubscription;
  StreamSubscription<SpeechRecognitionState>? _stateSubscription;

  // TTS控制
  bool _isTTSPlaying = false;

  // 定时器
  Timer? _recordingTimeoutTimer;

  // 回调
  final Function(VoiceCallState)? onStateChanged;
  final Function(String phase)? onPhaseChanged;
  final Function(String error)? onError;

  VoiceCallManager({
    required this.recognitionService,
    required this.onUserMessage,
    required this.aiMessageStream,
    this.onStateChanged,
    this.onPhaseChanged,
    this.onError,
  });

  /// 获取当前状态
  VoiceCallState get state => _state;

  /// 获取当前配置
  VoiceCallConfig get config => _config;

  /// 获取当前对话轮数
  int get currentTurn => _currentTurn;

  /// 是否正在通话
  bool get isCallActive => _state != VoiceCallState.idle;

  /// 是否正在录音
  bool get isRecording => _state == VoiceCallState.recording;

  /// 是否AI处理中
  bool get isProcessing => _state == VoiceCallState.processing;

  /// 是否正在播报
  bool get isSpeaking => _state == VoiceCallState.speaking;

  /// 更新配置
  void updateConfig(VoiceCallConfig config) {
    _config = config;
  }

  /// 初始化
  Future<void> initialize() async {
    await recognitionService.initialize();

    // 监听识别结果
    _recognitionSubscription = recognitionService.recognitionStream.listen((text) {
      if (_state == VoiceCallState.recording) {
        _onRecognized(text);
      }
    });

    // 监听识别状态
    _stateSubscription = recognitionService.stateStream.listen((speechState) {
      if (speechState == SpeechRecognitionState.idle && _state == VoiceCallState.recording) {
        // 录音自动停止（超时或静音）
        _stopRecording();
      }
    });

    debugPrint('✅ VoiceCallManager 初始化完成');
  }

  /// 开始语音通话
  Future<void> startCall() async {
    if (isCallActive) {
      debugPrint('⚠️ 通话已在进行中');
      return;
    }

    _setState(VoiceCallState.recording);
    _currentTurn = 0;

    // 播报欢迎语
    if (_config.enableWelcomeMessage && _config.welcomeMessage.isNotEmpty) {
      await _speak(_config.welcomeMessage);
    }

    // 开始录音
    await _startRecording();
  }

  /// 暂停通话
  Future<void> pauseCall() async {
    if (_state == VoiceCallState.idle || _state == VoiceCallState.paused) return;

    // 停止录音
    if (_state == VoiceCallState.recording) {
      await recognitionService.stopRecording();
      _recordingTimeoutTimer?.cancel();
    }

    // 停止TTS
    if (_state == VoiceCallState.speaking) {
      await TTSPlugin.instance.stop();
    }

    _setState(VoiceCallState.paused);
    debugPrint('⏸️ 通话已暂停');
  }

  /// 继续通话
  Future<void> resumeCall() async {
    if (_state != VoiceCallState.paused) return;

    _setState(VoiceCallState.recording);
    await _startRecording();
    debugPrint('▶️ 通话已继续');
  }

  /// 结束通话
  Future<void> endCall() async {
    _recordingTimeoutTimer?.cancel();

    // 停止录音
    if (_state == VoiceCallState.recording) {
      await recognitionService.stopRecording();
    }

    // 停止TTS
    await TTSPlugin.instance.stop();

    _setState(VoiceCallState.idle);
    _currentTurn = 0;
    debugPrint('📞 通话已结束');
  }

  /// 手动开始录音
  Future<void> startRecording() async {
    if (!isCallActive || _state == VoiceCallState.recording) return;

    _setState(VoiceCallState.recording);
    await _startRecording();
  }

  /// 手动停止录音
  Future<void> stopRecording() async {
    if (_state != VoiceCallState.recording) return;

    await recognitionService.stopRecording();
    _recordingTimeoutTimer?.cancel();
  }

  /// 跳过当前TTS播报
  Future<void> skipSpeaking() async {
    if (_state != VoiceCallState.speaking) return;

    await TTSPlugin.instance.stop();
    debugPrint('⏭️ 已跳过播报');
  }

  // ========== 私有方法 ==========

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      _setPhase(VoiceCallPhase.userSpeaking);

      final success = await recognitionService.startRecording();
      if (!success) {
        _setError('开始录音失败');
        return;
      }

      // 设置录音超时
      _recordingTimeoutTimer?.cancel();
      _recordingTimeoutTimer = Timer(
        Duration(seconds: _config.recordingTimeout),
        () => _stopRecording(),
      );

      debugPrint('🎤 开始录音');
    } catch (e) {
      _setError('开始录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    _recordingTimeoutTimer?.cancel();

    if (_state != VoiceCallState.recording) return;

    await recognitionService.stopRecording();
  }

  /// 识别完成处理
  void _onRecognized(String text) {
    if (text.trim().isEmpty) return;

    _lastRecognizedText = text;
    _setState(VoiceCallState.recognized);
    debugPrint('📝 识别完成: $text');

    // 停止录音
    _stopRecording();

    // 发送给AI
    _sendToAI(text);
  }

  /// 发送给AI
  void _sendToAI(String text) {
    _setState(VoiceCallState.processing);
    _setPhase(VoiceCallPhase.aiResponding);
    _currentTurn++;

    debugPrint('🤖 发送给AI (第$_currentTurn轮)');

    // 调用回调发送消息
    onUserMessage(text);
  }

  /// AI回复完成处理（需要外部调用）
  void handleAIMessage(String message) {
    _lastAIMessage = message;

    if (!isCallActive) return;

    // 检查是否达到最大轮数
    if (_config.maxTurns > 0 && _currentTurn >= _config.maxTurns) {
      debugPrint('✅ 已达到最大对话轮数 (${_config.maxTurns})');
      endCall();
      return;
    }

    // TTS播报
    _speakAndContinue(message);
  }

  /// TTS播报并继续下一轮
  Future<void> _speakAndContinue(String text) async {
    _setState(VoiceCallState.speaking);

    await _speak(text);

    // 播报完成后，决定是否继续
    if (_config.autoContinue && _config.autoRecordAfterSpeaking) {
      _setState(VoiceCallState.recording);
      await _startRecording();
    } else {
      _setState(VoiceCallState.idle);
    }
  }

  /// TTS播报
  Future<void> _speak(String text) async {
    try {
      _isTTSPlaying = true;
      debugPrint('🔊 开始播报: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      await TTSPlugin.instance.speak(
        text,
        serviceId: _config.ttsServiceId,
        onStart: () {
          debugPrint('🔊 TTS开始');
        },
        onComplete: () {
          debugPrint('✅ TTS完成');
          _isTTSPlaying = false;
        },
        onError: (error) {
          debugPrint('❌ TTS错误: $error');
          _isTTSPlaying = false;
        },
      );
    } catch (e) {
      _setError('TTS播报失败: $e');
      _isTTSPlaying = false;
    }
  }

  /// 设置状态
  void _setState(VoiceCallState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(newState);
      debugPrint('🔄 状态变更: $newState');
    }
  }

  /// 设置阶段
  void _setPhase(VoiceCallPhase phase) {
    onPhaseChanged?.call(phase == VoiceCallPhase.userSpeaking ? 'user' : 'ai');
  }

  /// 设置错误
  void _setError(String error) {
    _setState(VoiceCallState.error);
    onError?.call(error);
    debugPrint('❌ 错误: $error');
  }

  /// 释放资源
  void dispose() {
    _recordingTimeoutTimer?.cancel();
    _recognitionSubscription?.cancel();
    _aiMessageSubscription?.cancel();
    _stateSubscription?.cancel();

    // 停止所有服务
    recognitionService.dispose();
    TTSPlugin.instance.stop();

    debugPrint('🗑️ VoiceCallManager 已释放');
  }
}
