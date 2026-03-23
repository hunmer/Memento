import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/agent_chat/services/voice_call/voice_call_manager.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/models/notification_button.dart';

/// 语音通话界面
///
/// 全屏界面，支持与AI进行语音对话
/// 支持熄屏后继续运行（Android前台服务）
class VoiceCallScreen extends StatefulWidget {
  final VoiceCallManager manager;
  final VoidCallback? onExit;

  const VoiceCallScreen({
    super.key,
    required this.manager,
    this.onExit,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  VoiceCallState _currentState = VoiceCallState.idle;
  String _currentPhase = 'user';
  int _currentTurn = 0;
  String _lastRecognizedText = '';
  String _lastAIMessage = '';
  StreamSubscription<VoiceCallState>? _stateSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController.dispose();
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

    _stateSubscription = widget.manager.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _currentTurn = widget.manager.currentTurn;
          _updateAnimation();
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
        'buttons': buttons.map((b) => b.label).toList(),
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

  @override
  Widget build(BuildContext context) {
    // 更新前台通知
    _updateForegroundNotification();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            _buildTopBar(),

            // 主要内容区
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 状态指示器
                  _buildStatusIndicator(),

                  const SizedBox(height: 48),

                  // 动画圆圈
                  _buildPulsingCircle(),

                  const SizedBox(height: 48),

                  // 对话信息
                  _buildConversationInfo(),
                ],
              ),
            ),

            // 底部控制区
            _buildBottomControls(),
          ],
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
                  'AI 语音通话',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '第 $_currentTurn 轮',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 设置按钮
          IconButton(
            onPressed: () {
              // TODO: 打开设置
            },
            icon: const Icon(Icons.settings, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
          ),
        ],
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建脉冲圆圈
  Widget _buildPulsingCircle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor().withOpacity(0.3),
              border: Border.all(
                color: _getStatusColor(),
                width: 3,
              ),
            ),
            child: Icon(
              _getStatusIcon(),
              color: Colors.white,
              size: 48,
            ),
          ),
        );
      },
    );
  }

  /// 构建对话信息
  Widget _buildConversationInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // 用户说的话
          if (_lastRecognizedText.isNotEmpty)
            _buildMessageBubble(
              _lastRecognizedText,
              isUser: true,
            ),
          const SizedBox(height: 16),

          // AI的回复
          if (_lastAIMessage.isNotEmpty)
            _buildMessageBubble(
              _lastAIMessage,
              isUser: false,
            ),
        ],
      ),
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(String text, {required bool isUser}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUser ? Icons.person : Icons.smart_toy,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部控制区
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 静音按钮（预留）
          _buildControlButton(
            icon: Icons.mic_off,
            label: '静音',
            onTap: () {
              // TODO: 静音功能
            },
          ),

          // 主控制按钮
          _buildMainControlButton(),

          // 扬声器按钮（预留）
          _buildControlButton(
            icon: Icons.volume_up,
            label: '外放',
            onTap: () {
              // TODO: 切换扬声器
            },
          ),
        ],
      ),
    );
  }

  /// 构建主控制按钮
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
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
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
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
