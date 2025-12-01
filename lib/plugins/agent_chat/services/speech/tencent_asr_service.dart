import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'speech_recognition_config.dart';
import 'speech_recognition_service.dart';
import 'speech_recognition_state.dart';

/// 腾讯云实时语音识别服务实现
class TencentASRService implements SpeechRecognitionService {
  final TencentASRConfig config;

  // 音频录制器
  final AudioRecorder _recorder = AudioRecorder();

  // WebSocket 连接
  WebSocketChannel? _webSocketChannel;

  // 流控制器
  final _recognitionController = StreamController<String>.broadcast();
  final _stateController = StreamController<SpeechRecognitionState>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // 当前状态
  SpeechRecognitionState _currentState = SpeechRecognitionState.idle;

  // 音频流订阅
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  // 语音唯一标识
  String? _voiceId;

  // 累积的识别结果
  String _accumulatedText = '';

  // 是否已完成握手
  bool _handshakeCompleted = false;

  TencentASRService({required this.config});

  @override
  Stream<String> get recognitionStream => _recognitionController.stream;

  @override
  Stream<SpeechRecognitionState> get stateStream => _stateController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  SpeechRecognitionState get currentState => _currentState;

  @override
  Future<void> initialize() async {
    // 验证配置
    if (!config.isValid()) {
      throw Exception('腾讯云 ASR 配置无效');
    }

    // 检查麦克风权限
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('没有麦克风权限');
    }
  }

  @override
  Future<bool> startRecording() async {
    if (_currentState != SpeechRecognitionState.idle) {
      debugPrint('语音识别服务当前状态不是空闲: $_currentState');
      return false;
    }

    try {
      // 生成语音 ID
      _voiceId = const Uuid().v4();
      _accumulatedText = '';
      _handshakeCompleted = false;

      // 更新状态为连接中
      _updateState(SpeechRecognitionState.connecting);

      // 建立 WebSocket 连接
      await _connectWebSocket();

      // 等待握手完成（最多等待 10 秒）
      final handshakeTimeout = DateTime.now().add(const Duration(seconds: 10));
      while (!_handshakeCompleted &&
          DateTime.now().isBefore(handshakeTimeout)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_handshakeCompleted) {
        throw Exception('WebSocket 握手超时');
      }

      // 更新状态为录音中
      _updateState(SpeechRecognitionState.recording);

      // 开始录音
      await _startAudioRecording();

      return true;
    } catch (e) {
      debugPrint('开始录音失败: $e');
      _handleError('开始录音失败: $e');
      await _cleanup();
      return false;
    }
  }

  @override
  Future<void> stopRecording() async {
    if (_currentState != SpeechRecognitionState.recording) {
      return;
    }

    // 立即更新状态为处理中（优先更新 UI）
    _updateState(SpeechRecognitionState.processing);

    try {
      // 停止音频录制
      await _stopAudioRecording();

      // 发送结束标记
      await _sendEndMessage();

      // 等待最终结果（最多等待 2 秒）
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('停止录音失败: $e');
      _handleError('停止录音失败: $e');
    } finally {
      // 无论成功或失败，都要清理资源并更新状态
      await _closeWebSocket();
      _updateState(SpeechRecognitionState.idle);
    }
  }

  @override
  Future<void> cancelRecording() async {
    await _cleanup();
    _accumulatedText = '';
    _updateState(SpeechRecognitionState.idle);
  }

  @override
  void dispose() {
    _cleanup();
    _recognitionController.close();
    _stateController.close();
    _errorController.close();
    _recorder.dispose();
  }

  // ==================== 私有方法 ====================

  /// 更新状态
  void _updateState(SpeechRecognitionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// 处理错误
  void _handleError(String error) {
    _updateState(SpeechRecognitionState.error);
    _errorController.add(error);
  }

  /// 连接 WebSocket
  Future<void> _connectWebSocket() async {
    try {
      final url = config.generateWebSocketUrl(voiceId: _voiceId!);
      debugPrint('WebSocket URL: $url');

      _webSocketChannel = WebSocketChannel.connect(Uri.parse(url));

      // 监听 WebSocket 消息
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: (error) {
          debugPrint('WebSocket 错误: $error');
          _handleError('连接错误: $error');
        },
        onDone: () {
          debugPrint('WebSocket 连接关闭');
        },
        cancelOnError: true,
      );
    } catch (e) {
      throw Exception('WebSocket 连接失败: $e');
    }
  }

  /// 关闭 WebSocket
  Future<void> _closeWebSocket() async {
    try {
      await _webSocketChannel?.sink.close();
      _webSocketChannel = null;
    } catch (e) {
      debugPrint('关闭 WebSocket 失败: $e');
    }
  }

  /// 处理 WebSocket 消息
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final code = data['code'] as int?;
      final messageText = data['message'] as String?;

      // 检查错误码
      if (code != null && code != 0) {
        _handleError('识别失败 (错误码: $code): $messageText');
        return;
      }

      // 握手响应
      if (code == 0 && !_handshakeCompleted) {
        _handshakeCompleted = true;
        debugPrint('WebSocket 握手成功');
        return;
      }

      // 识别结果
      final result = data['result'] as Map<String, dynamic>?;
      if (result != null) {
        final voiceTextStr = result['voice_text_str'] as String?;
        final sliceType = result['slice_type'] as int?;

        if (voiceTextStr != null && voiceTextStr.isNotEmpty) {
          // 更新累积文本
          if (sliceType == 0) {
            // 开始
            _accumulatedText = voiceTextStr;
          } else if (sliceType == 1) {
            // 进行中
            _accumulatedText = voiceTextStr;
          } else if (sliceType == 2) {
            // 结束
            _accumulatedText = voiceTextStr;
          }

          // 推送识别结果
          _recognitionController.add(_accumulatedText);
          debugPrint('识别结果: $_accumulatedText');
        }
      }

      // 检查是否为最终结果
      final final_ = data['final'] as int?;
      if (final_ == 1) {
        debugPrint('收到最终识别结果');
      }
    } catch (e) {
      debugPrint('解析 WebSocket 消息失败: $e');
    }
  }

  /// 开始音频录制
  Future<void> _startAudioRecording() async {
    try {
      // 配置录音参数
      const recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1, // 单声道
        bitRate: 128000,
      );

      // 检查权限
      if (!await _recorder.hasPermission()) {
        throw Exception('没有麦克风权限');
      }

      // 开始流式录音
      final audioStream = await _recorder.startStream(recordConfig);

      // 监听音频数据并发送
      _audioStreamSubscription = audioStream.listen(
        _handleAudioData,
        onError: (error) {
          debugPrint('音频流错误: $error');
          _handleError('录音错误: $error');
        },
        onDone: () {
          debugPrint('音频流结束');
        },
        cancelOnError: true,
      );

      debugPrint('开始流式录音');
    } catch (e) {
      throw Exception('启动录音失败: $e');
    }
  }

  /// 停止音频录制
  Future<void> _stopAudioRecording() async {
    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      await _recorder.stop();
      debugPrint('停止录音');
    } catch (e) {
      debugPrint('停止录音失败: $e');
    }
  }

  /// 处理音频数据
  void _handleAudioData(Uint8List audioData) {
    try {
      // 发送音频数据到 WebSocket
      if (_webSocketChannel != null && _handshakeCompleted) {
        _webSocketChannel!.sink.add(audioData);
      }
    } catch (e) {
      debugPrint('发送音频数据失败: $e');
    }
  }

  /// 发送结束消息
  Future<void> _sendEndMessage() async {
    try {
      if (_webSocketChannel != null) {
        final endMessage = jsonEncode({'type': 'end'});
        _webSocketChannel!.sink.add(endMessage);
        debugPrint('发送结束消息');
      }
    } catch (e) {
      debugPrint('发送结束消息失败: $e');
    }
  }

  /// 清理资源
  Future<void> _cleanup() async {
    await _stopAudioRecording();
    await _closeWebSocket();
    _handshakeCompleted = false;
    _voiceId = null;
  }
}
