import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_manager.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_config_dialog.dart';
import 'package:Memento/plugins/openai/models/ai_agent.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 语音通话界面
///
/// 全屏界面，支持与AI进行语音对话
/// 支持熄屏后继续运行（Android前台服务）
class VoiceCallScreen extends StatefulWidget {
  final VoiceCallManager manager;
  final VoidCallback? onExit;
  final AIAgent? agent;

  const VoiceCallScreen({
    super.key,
    required this.manager,
    this.onExit,
    this.agent,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  VoiceCallState _currentState = VoiceCallState.idle;
  int _currentTurn = 0;
  StreamSubscription<VoiceCallState>? _stateSubscription;
  StreamSubscription<String>? _recognizedTextSubscription;
  StreamSubscription<int>? _countdownSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 文本编辑控制器
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 自动发送相关
  int _countdownSeconds = 0;
  bool _autoSendCancelled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _listenToManager();

    // 自动开始通话
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.manager.startCall();
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _recognizedTextSubscription?.cancel();
    _countdownSubscription?.cancel();
    _pulseController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 初始化动画
  void _initializeAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// 监听管理器状态变化
  void _listenToManager() {
    _currentState = widget.manager.state;
    _currentTurn = widget.manager.currentTurn;

    // 监听状态变化
    _stateSubscription = widget.manager.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _currentTurn = widget.manager.currentTurn;
          _autoSendCancelled = widget.manager.autoSendCancelled;
          _updateAnimation();

          // 进入 processing 状态时清空文本框（消息已发送）
          if (state == VoiceCallState.processing) {
            _textController.clear();
            _countdownSeconds = 0;
          }
        });
      }
    });

    // 监听识别文本（实时更新）
    _recognizedTextSubscription = widget.manager.recognizedTextStream.listen((text) {
      if (mounted) {
        setState(() {
          _textController.text = text;
          // 保持光标在末尾
          if (_textController.selection.baseOffset == -1) {
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          }
        });
      }
    });

    // 监听倒计时
    _countdownSubscription = widget.manager.countdownStream.listen((seconds) {
      if (mounted) {
        setState(() {
          _countdownSeconds = seconds;
        });
      }
    });
  }

  /// 更新动画状态
  void _updateAnimation() {
    switch (_currentState) {
      case VoiceCallState.recording:
      case VoiceCallState.processing:
      case VoiceCallState.speaking:
        _pulseController.repeat(reverse: true);
        break;
      default:
        _pulseController.stop();
        _pulseController.reset();
    }
  }

  /// 更新前台服务通知
  Future<void> _updateForegroundNotification() async {
    if (!UniversalPlatform.isAndroid) return;

    String title = 'AI 语音通话';
    String content = _getStatusText();
    List<NotificationButton> buttons = [];

    switch (_currentState) {
      case VoiceCallState.recording:
        buttons = [
          NotificationButton(text: '暂停', id: 'pause'),
          NotificationButton(text: '结束', id: 'end'),
        ];
        break;
      case VoiceCallState.paused:
        buttons = [
          NotificationButton(text: '继续', id: 'resume'),
          NotificationButton(text: '结束', id: 'end'),
        ];
        break;
      case VoiceCallState.idle:
        break;
      default:
        buttons = [
          NotificationButton(text: '结束', id: 'end'),
        ];
    }

    try {
      FlutterForegroundTask.sendDataToTask({
        'action': 'update_notification',
        'title': title,
        'content': content,
        'buttons': buttons.map((b) => b.text).toList(),
      });
    } catch (e) {
      debugPrint('更新前台通知失败: $e');
    }
  }

  /// 获取状态文本
  String _getStatusText() {
    switch (_currentState) {
      case VoiceCallState.idle:
        return '准备就绪';
      case VoiceCallState.recording:
        return '请开始说话...';
      case VoiceCallState.recognized:
        return '识别完成';
      case VoiceCallState.processing:
        return 'AI正在思考...';
      case VoiceCallState.speaking:
        return 'AI正在回复...';
      case VoiceCallState.paused:
        return '已暂停';
      case VoiceCallState.error:
        return '发生错误';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (_currentState) {
      case VoiceCallState.recording:
        return Colors.red;
      case VoiceCallState.processing:
      case VoiceCallState.recognized:
        return Colors.blue;
      case VoiceCallState.speaking:
        return Colors.green;
      case VoiceCallState.paused:
        return Colors.orange;
      case VoiceCallState.error:
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  /// 获取状态图标
  IconData _getStatusIcon() {
    switch (_currentState) {
      case VoiceCallState.recording:
        return Icons.mic;
      case VoiceCallState.processing:
      case VoiceCallState.recognized:
        return Icons.psychology;
      case VoiceCallState.speaking:
        return Icons.volume_up;
      case VoiceCallState.paused:
        return Icons.pause;
      case VoiceCallState.error:
        return Icons.error;
      default:
        return Icons.phone_disabled;
    }
  }

  /// 暂停/继续
  Future<void> _togglePause() async {
    if (_currentState == VoiceCallState.paused) {
      await widget.manager.resumeCall();
    } else {
      await widget.manager.pauseCall();
    }
  }

  /// 退出
  Future<void> _exit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束通话'),
        content: const Text('确定要结束当前通话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('结束'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.manager.endCall();
      widget.onExit?.call();
    }
  }

  /// 打开设置
  Future<void> _openSettings() async {
    final result = await showDialog<VoiceCallConfig>(
      context: context,
      builder: (context) => VoiceCallConfigDialog(
        initialConfig: widget.manager.config,
      ),
    );

    if (result != null) {
      // 更新管理器的配置
      widget.manager.updateConfig(result);
      // 刷新界面以应用背景图
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 更新前台通知
    _updateForegroundNotification();

    final backgroundImage = widget.manager.config.backgroundImagePath;
    final hasBackgroundImage = backgroundImage != null && File(backgroundImage).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: hasBackgroundImage
            ? BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(backgroundImage)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Container(
          // 添加半透明遮罩以提高可读性
          decoration: hasBackgroundImage
              ? BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                )
              : null,
          child: SafeArea(
            child: Column(
              children: [
                // 顶部栏（包含状态指示器在右上角）
                _buildTopBar(),

                // 主要内容区 - 中间显示 Agent 头像/图标
                Expanded(
                  child: Center(
                    child: _buildAgentAvatar(),
                  ),
                ),

                // 录音输入区（在底部控制区上方）
                if (_currentState == VoiceCallState.recording)
                  _buildRecordingInputCompact(),

                // 底部控制区
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 退出按钮
          IconButton(
            onPressed: _exit,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
          ),
          const SizedBox(width: 16),
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.agent?.name ?? 'AI 语音通话',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '第 $_currentTurn 轮',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 右上角状态指示器（小标）
          _buildStatusIndicatorSmall(),
          const SizedBox(width: 8),
          // 设置按钮
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
          ),
        ],
      ),
    );
  }

  /// 构建右上角小型状态指示器
  Widget _buildStatusIndicatorSmall() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 Agent 头像/图标
  Widget _buildAgentAvatar() {
    final agent = widget.agent;
    final statusColor = _getStatusColor();

    // 构建头像内容
    Widget avatarContent;
    if (agent?.avatarUrl != null && agent!.avatarUrl!.isNotEmpty) {
      // 如果有头像URL，显示网络图片
      avatarContent = ClipOval(
        child: Image.network(
          agent.avatarUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildDefaultAvatarIcon(agent),
        ),
      );
    } else {
      avatarContent = _buildDefaultAvatarIcon(agent);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: statusColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: avatarContent,
    );
  }

  /// 构建默认头像图标
  Widget _buildDefaultAvatarIcon(AIAgent? agent) {
    final icon = agent?.icon ?? Icons.smart_toy;
    final iconColor = agent?.iconColor ?? Colors.white;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 56,
      ),
    );
  }

  /// 构建精简版录音输入区域（底部控制区上方）
  Widget _buildRecordingInputCompact() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 100),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文本输入区 + 倒计时
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 麦克风图标
                    Icon(Icons.mic, color: _getStatusColor(), size: 18),
                    const SizedBox(width: 10),
                    // 文本输入
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '正在识别...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    // 倒计时
                    if (!_autoSendCancelled && _countdownSeconds > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_countdownSeconds s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 底部操作按钮（精简版）
            if (_textController.text.isNotEmpty || _autoSendCancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 编辑按钮
                    if (!_autoSendCancelled)
                      _buildCompactActionButton(
                        icon: Icons.edit,
                        label: '编辑',
                        color: Colors.orange,
                        onTap: () {
                          widget.manager.cancelAutoSend();
                          _focusNode.requestFocus();
                        },
                      ),
                    const SizedBox(width: 8),
                    // 发送按钮
                    _buildCompactActionButton(
                      icon: Icons.send,
                      label: '发送',
                      color: Colors.green,
                      onTap: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          widget.manager.manualSend(text);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // 删除按钮
                    _buildCompactActionButton(
                      icon: Icons.close,
                      label: '清除',
                      color: Colors.red,
                      onTap: () {
                        setState(() {
                          _textController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建精简版操作按钮
  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部控制区
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: _buildMainControlButton(),
    );
  }

  /// 构建主控制按钮（带脉冲动画）
  Widget _buildMainControlButton() {
    IconData icon;
    Color color;
    VoidCallback? onTap;

    switch (_currentState) {
      case VoiceCallState.recording:
        icon = Icons.pause;
        color = Colors.orange;
        onTap = _togglePause;
        break;
      case VoiceCallState.paused:
        icon = Icons.play_arrow;
        color = Colors.green;
        onTap = _togglePause;
        break;
      case VoiceCallState.speaking:
        icon = Icons.skip_next;
        color = Colors.blue;
        onTap = () => widget.manager.skipSpeaking();
        break;
      default:
        icon = Icons.call_end;
        color = Colors.red;
        onTap = _exit;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4 * _pulseAnimation.value),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 5 * _pulseAnimation.value,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
