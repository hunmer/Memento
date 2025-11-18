import 'dart:async';
import 'package:flutter/material.dart';
import '../services/speech/speech_recognition_service.dart';
import '../services/speech/speech_recognition_state.dart';

/// 长按录音按钮组件
///
/// 功能：
/// - 长按开始录音，松手停止录音
/// - 实时将识别结果输出到目标输入框
/// - 显示录音状态视觉反馈
/// - 可自定义图标、颜色、大小
///
/// 使用示例：
/// ```dart
/// PressToRecordButton(
///   textController: _textController,
///   recognitionService: myRecognitionService,
///   icon: Icon(Icons.mic),
/// )
/// ```
class PressToRecordButton extends StatefulWidget {
  /// 目标输入框控制器（识别结果将添加到此输入框）
  final TextEditingController textController;

  /// 语音识别服务
  final SpeechRecognitionService recognitionService;

  /// 自定义图标（默认为 Icons.mic）
  final Widget? icon;

  /// 按钮大小（默认为标准 IconButton 大小）
  final double? size;

  /// 按钮颜色（默认为主题色）
  final Color? color;

  /// 录音时的颜色（默认为红色）
  final Color? recordingColor;

  /// 是否禁用按钮
  final bool enabled;

  /// 工具提示文本
  final String? tooltip;

  /// 录音完成回调（可选）
  final Function(String text)? onRecognitionComplete;

  /// 录音失败回调（可选）
  final Function(String error)? onError;

  const PressToRecordButton({
    super.key,
    required this.textController,
    required this.recognitionService,
    this.icon,
    this.size,
    this.color,
    this.recordingColor,
    this.enabled = true,
    this.tooltip,
    this.onRecognitionComplete,
    this.onError,
  });

  @override
  State<PressToRecordButton> createState() => _PressToRecordButtonState();
}

class _PressToRecordButtonState extends State<PressToRecordButton> {
  String _recognizedText = '';
  bool _isRecording = false;
  bool _isInitialized = false;

  StreamSubscription<String>? _recognitionSubscription;
  StreamSubscription<SpeechRecognitionState>? _stateSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _stateSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  /// 初始化语音识别服务
  Future<void> _initializeService() async {
    try {
      await widget.recognitionService.initialize();

      // 监听识别结果
      _recognitionSubscription =
          widget.recognitionService.recognitionStream.listen((text) {
        setState(() {
          _recognizedText = text;
        });
      });

      // 监听状态变化
      _stateSubscription =
          widget.recognitionService.stateStream.listen((state) {
        if (state == SpeechRecognitionState.idle && _isRecording) {
          setState(() {
            _isRecording = false;
          });
          _onRecordingComplete();
        }
      });

      // 监听错误
      _errorSubscription = widget.recognitionService.errorStream.listen((error) {
        _handleError(error);
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('初始化语音识别服务失败: $e');
      _handleError('初始化失败: $e');
    }
  }

  /// 开始录音
  Future<void> _startRecording() async {
    if (!widget.enabled || !_isInitialized || _isRecording) return;

    try {
      setState(() {
        _isRecording = true;
        _recognizedText = '';
      });

      final success = await widget.recognitionService.startRecording();
      if (!success) {
        setState(() {
          _isRecording = false;
        });
        _handleError('开始录音失败');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _handleError('开始录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await widget.recognitionService.stopRecording();
    } catch (e) {
      _handleError('停止录音失败: $e');
    }
  }

  /// 录音完成时的处理
  void _onRecordingComplete() {
    if (_recognizedText.isNotEmpty) {
      // 将识别结果添加到输入框
      final currentText = widget.textController.text;
      final newText = currentText.isEmpty
          ? _recognizedText
          : '$currentText\n$_recognizedText';
      widget.textController.text = newText;

      // 触发回调
      widget.onRecognitionComplete?.call(_recognizedText);

      // 清空识别文本
      setState(() {
        _recognizedText = '';
      });
    }
  }

  /// 处理错误
  void _handleError(String error) {
    debugPrint('语音识别错误: $error');
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = widget.icon ?? const Icon(Icons.mic);
    final buttonColor = _isRecording
        ? (widget.recordingColor ?? Colors.red)
        : (widget.color ?? Theme.of(context).iconTheme.color);

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          icon: AnimatedScale(
            scale: _isRecording ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IconTheme(
              data: IconThemeData(
                color: buttonColor,
                size: widget.size,
              ),
              child: iconWidget,
            ),
          ),
          onPressed: widget.enabled && _isInitialized ? null : null,
          tooltip: widget.tooltip ?? (_isRecording ? '松开停止录音' : '长按开始录音'),
        ),
      ),
    );
  }
}
