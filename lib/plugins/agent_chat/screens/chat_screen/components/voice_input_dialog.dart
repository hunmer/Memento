import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/speech/speech_recognition_service.dart';
import '../../../services/speech/speech_recognition_state.dart';

/// 语音输入对话框
///
/// 功能：
/// - 长按录音按钮开始录音，松开结束
/// - 实时显示识别文本
/// - 显示识别状态
/// - 支持文本编辑
/// - 确定发送，取消关闭
class VoiceInputDialog extends StatefulWidget {
  /// 语音识别服务
  final SpeechRecognitionService recognitionService;

  /// 识别完成回调
  final Function(String text) onRecognitionComplete;

  const VoiceInputDialog({
    super.key,
    required this.recognitionService,
    required this.onRecognitionComplete,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SpeechRecognitionState _currentState = SpeechRecognitionState.idle;

  StreamSubscription<String>? _recognitionSubscription;
  StreamSubscription<SpeechRecognitionState>? _stateSubscription;
  StreamSubscription<String>? _errorSubscription;

  bool _isRecording = false;

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
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      await widget.recognitionService.initialize();

      // 监听识别结果
      _recognitionSubscription =
          widget.recognitionService.recognitionStream.listen((text) {
            setState(() {
          _textController.text = text;
        });
      });

      // 监听状态变化
      _stateSubscription =
          widget.recognitionService.stateStream.listen((state) {
        setState(() {
          _currentState = state;
          if (state == SpeechRecognitionState.idle && _isRecording) {
            _isRecording = false;
          }
        });
      });

      // 监听错误
      _errorSubscription = widget.recognitionService.errorStream.listen((error) {
        setState(() {
        });
        _showErrorSnackBar(error);
      });
    } catch (e) {
      _showErrorSnackBar('初始化失败: $e');
    }
  }

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
      });

      final success = await widget.recognitionService.startRecording();
      if (!success) {
        setState(() {
          _isRecording = false;
        });
        _showErrorSnackBar('开始录音失败');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _showErrorSnackBar('开始录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      await widget.recognitionService.stopRecording();
    } catch (e) {
      _showErrorSnackBar('停止录音失败: $e');
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// 取消录音
  Future<void> _cancelRecording() async {
    try {
      await widget.recognitionService.cancelRecording();
    } catch (e) {
      _showErrorSnackBar('取消录音失败: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _textController.clear();
      });
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 确认发送
  void _confirmSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackBar('请先录音或输入文本');
      return;
    }

    widget.onRecognitionComplete(text);
    Navigator.of(context).pop();
  }

  /// 取消并关闭
  void _cancel() {
    if (_isRecording) {
      _cancelRecording();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '语音识别',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // 状态显示
            _buildStateIndicator(),
            const SizedBox(height: 16),

            // 文本显示区
            _buildTextDisplay(),
            const SizedBox(height: 20),

            // 录音按钮
            _buildRecordButton(),
            const SizedBox(height: 20),

            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStateIndicator() {
    Color stateColor;
    IconData stateIcon;

    switch (_currentState) {
      case SpeechRecognitionState.idle:
        stateColor = Colors.grey;
        stateIcon = Icons.mic_none;
        break;
      case SpeechRecognitionState.connecting:
        stateColor = Colors.orange;
        stateIcon = Icons.sync;
        break;
      case SpeechRecognitionState.recording:
        stateColor = Colors.red;
        stateIcon = Icons.mic;
        break;
      case SpeechRecognitionState.processing:
        stateColor = Colors.blue;
        stateIcon = Icons.hourglass_empty;
        break;
      case SpeechRecognitionState.error:
        stateColor = Colors.red;
        stateIcon = Icons.error_outline;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          stateIcon,
          color: stateColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          _currentState.description,
          style: TextStyle(
            color: stateColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建文本显示区
  Widget _buildTextDisplay() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 120,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          hintText: '识别的文本将显示在这里，您也可以编辑...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  /// 构建录音按钮
  Widget _buildRecordButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
          boxShadow: _isRecording
              ? [
                  BoxShadow(
                    color: Colors.red.withAlpha(102),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ]
              : [],
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _cancel,
          child: const Text('取消'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _currentState == SpeechRecognitionState.recording
              ? null
              : _confirmSend,
          child: const Text('发送'),
        ),
      ],
    );
  }
}
