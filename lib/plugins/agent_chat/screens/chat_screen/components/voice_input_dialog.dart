import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_service.dart';
import 'package:Memento/plugins/agent_chat/services/speech/speech_recognition_state.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../../../core/services/toast_service.dart';
import '../../../../../../core/services/speech_recognition_config_service.dart';
import '../../../../../../plugins/openai/services/request_service.dart';
import '../../../../../../plugins/openai/models/ai_agent.dart';

/// 语音输入对话框
///
/// 功能：
/// - 点击或长按录音按钮开始录音
/// - 点击停止，长按松开结束
/// - 连续录音自动追加文本
/// - 标点符号替换功能（替换为空文本）
/// - AI智能纠错（占位）
/// - 实时显示识别文本
/// - 显示识别状态
/// - 支持文本编辑
/// - 输入框内置清空按钮
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

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  SpeechRecognitionState _currentState = SpeechRecognitionState.idle;

  StreamSubscription<String>? _recognitionSubscription;
  StreamSubscription<SpeechRecognitionState>? _stateSubscription;
  StreamSubscription<String>? _errorSubscription;

  bool _isRecording = false;
  bool _isAppendMode = false; // 是否处于追加模式
  String? _savedText; // 保存的文本用于追加
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 标点符号替换设置
  bool _enablePunctuationReplacement = false;

  // AI纠错状态
  bool _isCorrecting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeService();
  }

  /// 初始化动画
  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 注意：不在这里启动动画，而是在开始录音时启动
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _stateSubscription?.cancel();
    _errorSubscription?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 初始化服务
  Future<void> _initializeService() async {
    try {
      await widget.recognitionService.initialize();

      // 监听识别结果（仅在录音状态下更新文本）
      _recognitionSubscription = widget.recognitionService.recognitionStream
          .listen((text) {
            if (!mounted) return;

            // 只有在录音状态下才更新文本，停止录音后不再更新
            if (!_isRecording) return;

            // 应用标点符号替换
            final processedText = _applyPunctuationReplacement(text);

            setState(() {
              if (_isAppendMode && _savedText != null && _savedText!.isNotEmpty) {
                // 追加模式：在保存的文本后添加新识别的文本
                _textController.text = _savedText! + processedText;
                // 注意：不清空 _savedText，这样每次识别结果都会追加到原始文本后
              } else {
                // 普通模式：直接替换文本
                _textController.text = processedText;
              }
            });
            // 自动滚动到底部
            _scrollToBottom();
          });

      // 监听状态变化
      _stateSubscription = widget.recognitionService.stateStream.listen((
        state,
      ) {
        setState(() {
          _currentState = state;
          if (state == SpeechRecognitionState.idle && _isRecording) {
            _isRecording = false;
          }
        });
      });

      // 监听错误
      _errorSubscription = widget.recognitionService.errorStream.listen((
        error,
      ) {
        setState(() {});
        _showErrorSnackBar(error);
      });
    } catch (e) {
      _showErrorSnackBar('初始化失败: $e');
    }
  }

  /// 开始录音
  Future<void> _startRecording({bool isFromTap = false}) async {
    try {
      // 重置追加模式
      _isAppendMode = false;
      _savedText = null;

      // 如果是点击触发的录音且已有文本，保存当前文本用于追加
      if (isFromTap && _textController.text.isNotEmpty) {
        _savedText = _textController.text;
        _isAppendMode = true;
      }

      setState(() {
        _isRecording = true;
      });

      // 启动循环缩放动画
      _animationController.repeat(reverse: true);

      // 播放录音开始音效
      try {
        await _audioPlayer.play(AssetSource('audio/start_record.mp3'));
      } catch (e) {
        // 音效播放失败不影响录音功能
      }

      final success = await widget.recognitionService.startRecording();
      if (!success) {
        setState(() {
          _isRecording = false;
          _isAppendMode = false;
          _savedText = null;
        });
        // 停止动画
        _animationController.stop();
        _showErrorSnackBar('开始录音失败');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isAppendMode = false;
        _savedText = null;
      });
      // 停止动画
      _animationController.stop();
      _showErrorSnackBar('开始录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // 立即更新 UI 状态并停止动画
    setState(() {
      _isRecording = false;
      _isAppendMode = false;
      _savedText = null;
    });
    _animationController.stop();
    _animationController.reset();

    try {
      // 停止录音
      await widget.recognitionService.stopRecording();
    } catch (e) {
      _showErrorSnackBar('停止录音失败: $e');
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
      // 停止并重置动画
      _animationController.stop();
      _animationController.reset();
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    // 延迟执行，确保文本已更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    toastService.showToast(message);
  }

  /// 应用标点符号替换
  String _applyPunctuationReplacement(String text) {
    if (!_enablePunctuationReplacement) return text;

    // 替换中文标点
    text = text.replaceAll(
      RegExp(r'[，。！？；：""''（）【】「」『』、]'),
      '',
    );
    // 替换英文标点
    text = text.replaceAll(
      RegExp(r"[,.!?;:'''()\[\]{}<>]"),
      '',
    );
    return text;
  }

  /// 执行AI智能纠错
  Future<void> _performAICorrection() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackBar('请先输入或录音获取文本');
      return;
    }

    // 检查是否配置了AI纠错Agent
    final configService = SpeechRecognitionConfigService.instance;
    final agent = configService.correctionAgent;

    if (agent == null) {
      // 未配置，提示用户跳转到设置界面
      final shouldGoToSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high),
              SizedBox(width: 8),
              Text('AI智能纠错'),
            ],
          ),
          content: const Text(
            '您还未配置AI纠错助手。是否跳转到设置界面进行配置？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('去设置'),
            ),
          ],
        ),
      );

      if (shouldGoToSettings == true && mounted) {
        // 关闭当前对话框
        Navigator.of(context).pop();
        // 打开设置界面
        // 注意：这里需要根据实际的设置界面路由来调整
        _showErrorSnackBar('请在设置中配置AI纠错Agent');
      }
      return;
    }

    // 已配置，执行AI纠错
    setState(() {
      _isCorrecting = true;
    });

    try {
      // 构建纠错请求
      final correctionPrompt = '请纠正以下文本中的识别错误，只输出纠正后的文本：\n\n$text';

      // 调用OpenAI服务进行纠错
      final correctedText = await RequestService.chat(
        correctionPrompt,
        agent,
      );

      if (correctedText.startsWith('Error:')) {
        _showErrorSnackBar('AI纠错失败：${correctedText.substring(7)}');
      } else {
        // 应用纠错结果
        setState(() {
          _textController.text = correctedText.trim();
        });
        _showErrorSnackBar('AI纠错完成');
      }
    } catch (e) {
      _showErrorSnackBar('AI纠错失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isCorrecting = false;
        });
      }
    }
  }

  /// 确认发送
  void _confirmSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorSnackBar('请先录音或输入文本');
      return;
    }

    widget.onRecognitionComplete(text);
    Navigator.of(context).pop(true); // 返回 true 表示确认
  }

  /// 取消并关闭
  void _cancel() {
    if (_isRecording) {
      _cancelRecording();
    }
    Navigator.of(context).pop(false); // 返回 false 表示取消
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '语音识别',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 状态显示
            _buildStateIndicator(),
            const SizedBox(height: 16),

            // 文本显示区
            _buildTextDisplay(),
            const SizedBox(height: 20),

            // 录音按钮区域
            _buildRecordButtons(),
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
        Icon(stateIcon, color: stateColor, size: 20),
        const SizedBox(width: 8),
        Text(
          _currentState.description,
          style: TextStyle(color: stateColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// 构建文本显示区
  Widget _buildTextDisplay() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(51),
        ),
      ),
      child: Stack(
        children: [
          // 文本输入框
          Scrollbar(
            controller: _scrollController,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              scrollController: _scrollController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '识别的文本将显示在这里，您也可以编辑...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          // 清空按钮（右下角）
          Positioned(
            bottom: 8,
            right: 8,
            child: AnimatedBuilder(
              animation: Listenable.merge([_textController]),
              builder: (context, child) {
                final hasText = _textController.text.isNotEmpty;
                if (!hasText) return const SizedBox.shrink();
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _textController.clear();
                      setState(() {
                        _savedText = null;
                        _isAppendMode = false;
                      });
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.clear,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建录音按钮区域
  Widget _buildRecordButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 标点符号替换按钮（左侧）
        _buildIconButton(
          icon: Icons.text_fields,
          tooltip: '标点符号替换',
          isActive: _enablePunctuationReplacement,
          onPressed: () {
            setState(() {
              _enablePunctuationReplacement = !_enablePunctuationReplacement;
              // 开启时立即应用替换到当前文本
              if (_enablePunctuationReplacement && _textController.text.isNotEmpty) {
                _textController.text = _applyPunctuationReplacement(_textController.text);
              }
            });
          },
        ),
        const SizedBox(width: 16),

        // 录音按钮（中间）
        _buildRecordButton(),

        const SizedBox(width: 16),

        // AI智能纠错按钮（右侧）
        _buildIconButton(
          icon: Icons.auto_fix_high,
          tooltip: 'AI智能纠错',
          isActive: _isCorrecting,
          onPressed: _isCorrecting
              ? () {}
              : () => _performAICorrection(),
        ),
      ],
    );
  }

  /// 构建录音按钮
  Widget _buildRecordButton() {
    return GestureDetector(
      // 点击触发：开始或停止录音
      onTap: () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording(isFromTap: true);
        }
      },
      // 长按触发：开始录音，松开结束
      onLongPressStart: (_) => _startRecording(isFromTap: false),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = _isRecording ? _scaleAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                boxShadow:
                    _isRecording
                        ? [
                          BoxShadow(
                            color: Colors.red.withAlpha(102),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
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
        },
      ),
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: _cancel, child: Text('agent_chat_cancel'.tr)),
        const SizedBox(width: 12),
        FilledButton(
          onPressed:
              _currentState == SpeechRecognitionState.recording
                  ? null
                  : _confirmSend,
          child: Text('agent_chat_send'.tr),
        ),
      ],
    );
  }
}
