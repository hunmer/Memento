import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'models/floating_ball_gesture.dart';

/// Overlay窗口主应用
///
/// 在系统overlay中运行的悬浮球应用
class OverlayWindowApp extends StatefulWidget {
  const OverlayWindowApp({super.key});

  @override
  State<OverlayWindowApp> createState() => _OverlayWindowAppState();
}

class _OverlayWindowAppState extends State<OverlayWindowApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 监听overlay窗口消息
      FlutterOverlayWindow.overlayListener.listen(_handleMainAppMessage);

      // 加载配置
      await _loadConfiguration();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 通知主应用overlay窗口已准备好
        await _sendMessageToMainApp('ready', null);
      }
    } catch (e) {
      debugPrint('Error initializing overlay window app: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    // TODO: 加载overlay窗口特定的配置
    // 暂时使用默认配置
  }

  /// 处理从主应用收到的消息
  void _handleMainAppMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final action = data['action'] as String?;
        
        switch (action) {
          case 'show':
            debugPrint('Overlay window received show command');
            break;
          case 'update_config':
            debugPrint('Overlay window received config update');
            // TODO: 更新配置
            break;
          default:
            debugPrint('Unknown main app message: $action');
        }
      }
    } catch (e) {
      debugPrint('Error handling main app message: $e');
    }
  }

  /// 发送消息到主应用
  Future<void> _sendMessageToMainApp(String action, Map<String, dynamic>? data) async {
    try {
      await FlutterOverlayWindow.shareData({
        'action': action,
        'data': data ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'overlay_window',
      });
    } catch (e) {
      debugPrint('Failed to send message to main app: $e');
    }
  }

  /// 发送手势消息到主应用
  Future<void> _sendGestureMessage(FloatingBallGesture gesture) async {
    await _sendMessageToMainApp('gesture', {
      'gesture': _getGestureName(gesture),
    });
  }

  /// 发送位置变化消息到主应用
  Future<void> _sendPositionMessage(Offset position) async {
    await _sendMessageToMainApp('position_changed', {
      'x': position.dx,
      'y': position.dy,
    });
  }

  /// 发送大小变化消息到主应用
  Future<void> _sendSizeMessage(double scale) async {
    await _sendMessageToMainApp('size_changed', {
      'scale': scale,
    });
  }

  /// 获取手势名称
  String _getGestureName(FloatingBallGesture gesture) {
    switch (gesture) {
      case FloatingBallGesture.tap:
        return 'tap';
      case FloatingBallGesture.swipeUp:
        return 'swipeUp';
      case FloatingBallGesture.swipeDown:
        return 'swipeDown';
      case FloatingBallGesture.swipeLeft:
        return 'swipeLeft';
      case FloatingBallGesture.swipeRight:
        return 'swipeRight';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: OverlayDemoWidget(
            onGesture: _sendGestureMessage,
            onPositionChanged: _sendPositionMessage,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 清理资源
    super.dispose();
  }
}

/// 模仿 doc/overlay_demo 的 TrueCallerOverlay，用于验证 overlay UI
class OverlayDemoWidget extends StatefulWidget {
  final ValueChanged<FloatingBallGesture>? onGesture;
  final ValueChanged<Offset>? onPositionChanged;

  const OverlayDemoWidget({
    super.key,
    this.onGesture,
    this.onPositionChanged,
  });

  @override
  State<OverlayDemoWidget> createState() => _OverlayDemoWidgetState();
}

class _OverlayDemoWidgetState extends State<OverlayDemoWidget> {
  bool _isGold = true;

  static const _goldColors = [
    Color(0xFFa2790d),
    Color(0xFFebd197),
    Color(0xFFa2790d),
  ];

  static const _silverColors = [
    Color(0xFFAEB2B8),
    Color(0xFFC7C9CB),
    Color(0xFFD7D7D8),
    Color(0xFFAEB2B8),
  ];

  Offset _position = const Offset(0, 0);

  void _toggleTheme() {
    setState(() {
      _isGold = !_isGold;
    });
    widget.onGesture?.call(FloatingBallGesture.tap);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final childWidth = size.width.clamp(0, 360);
    final childHeight = size.height * 0.4;
    final newPosition = Offset(
      (_position.dx + details.delta.dx).clamp(0, size.width - childWidth),
      (_position.dy + details.delta.dy).clamp(0, size.height - childHeight),
    );

    setState(() {
      _position = newPosition;
    });
    widget.onPositionChanged?.call(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = width;
        final cardHeight = height.clamp(180.0, 400.0);

        return Stack(
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              right: (width - cardWidth - _position.dx).clamp(0, width),
              child: GestureDetector(
                onPanUpdate: _handlePanUpdate,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: cardHeight,
                    width: cardWidth,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isGold ? _goldColors : _silverColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(2, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            ListTile(
                              leading: Container(
                                height: 64,
                                width: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black45),
                                  image: const DecorationImage(
                                    image: NetworkImage('https://api.multiavatar.com/x-slayer.png'),
                                  ),
                                ),
                              ),
                              title: const Text(
                                'X-SLAYER',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Sousse, Tunisia'),
                            ),
                            const Spacer(),
                            const Divider(color: Colors.black54),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('+216 21065826'),
                                      Text('Last call - 1 min ago'),
                                    ],
                                  ),
                                  Text(
                                    'Flutter Overlay',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.color_lens_outlined, color: Colors.black),
                                onPressed: _toggleTheme,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.black),
                                onPressed: () => FlutterOverlayWindow.closeOverlay(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
