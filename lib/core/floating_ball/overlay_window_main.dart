import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'models/floating_ball_gesture.dart';
import 'widgets/shared_floating_ball_widget.dart';
import 'config/floating_ball_config.dart';
import 'adapters/floating_ball_platform_adapter.dart';

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
  FloatingBallConfig _config = FloatingBallConfig.overlayWindowDefaultConfig;
  final GlobalKey _floatingBallKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('🚀 OverlayWindowApp 初始化开始');
    try {
      // 监听overlay窗口消息
      debugPrint('设置消息监听器...');
      FlutterOverlayWindow.overlayListener.listen(_handleMainAppMessage);

      // 加载配置
      debugPrint('加载配置...');
      await _loadConfiguration();

      if (mounted) {
        debugPrint('设置加载状态为 false');
        setState(() {
          _isLoading = false;
        });

        // 通知主应用overlay窗口已准备好
        debugPrint('发送 ready 消息到主应用...');
        await _sendMessageToMainApp('ready', null);
      }
    } catch (e) {
      debugPrint('❌ Error initializing overlay window app: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      // 加载overlay窗口特定的配置
      final config = await FloatingBallConfigManager.loadConfig(isInOverlay: true);
      if (mounted) {
        setState(() {
          _config = config;
        });
      }
      debugPrint('✅ 悬浮球配置加载成功: ${config.color}');
    } catch (e) {
      debugPrint('❌ 加载悬浮球配置失败，使用默认配置: $e');
      // 继续使用默认配置
    }
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
            _updateConfigFromMessage(data['data'] as Map<String, dynamic>?);
            break;
          case 'reset_position':
            debugPrint('Overlay window received reset position command');
            _resetPosition();
            _clearPersistentPosition();
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

  /// 更新配置
  Future<void> _updateConfigFromMessage(Map<String, dynamic>? configData) async {
    if (configData != null) {
      try {
        final newConfig = FloatingBallConfig.fromJson(configData);
        if (mounted) {
          setState(() {
            _config = newConfig;
          });
          debugPrint('✅ 配置更新成功: ${newConfig.color}');
        }
      } catch (e) {
        debugPrint('❌ 配置更新失败: $e');
      }
    }
  }

  /// 重置悬浮球位置到中心
  void _resetPosition() {
    debugPrint('🔄 开始重置悬浮球位置到中心');
    // 通过消息机制让悬浮球重置位置
    // 由于无法直接访问widget的state，我们通过清除持久化位置并重建来实现重置
    if (mounted) {
      setState(() {
        // 强制重建会触发SharedFloatingBallWidget的重新初始化
        // 但不会清除持久化位置，所以我们需要在SharedFloatingBallWidget中处理重置逻辑
      });
      debugPrint('✅ 悬浮球位置重置完成');
    }
  }

  /// 清除全局持久化位置
  void _clearPersistentPosition() {
    debugPrint('清除全局悬浮球位置缓存');
    // 调用静态重置方法，标记需要重置位置
    SharedFloatingBallWidget.resetGlobalPosition();

    // 强制重建来应用重置
    if (mounted) {
      setState(() {});
    }
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
    debugPrint('🎨 OverlayWindowApp.build() called, _isLoading: $_isLoading');

    if (_isLoading) {
      debugPrint('显示加载中状态...');
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    debugPrint('显示悬浮球主内容...');
    debugPrint('悬浮球配置: 颜色=${_config.color}, 大小比例=${_config.sizeScale}, 位置=${_config.position}');
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent, // 确保容器透明
        child: Stack(
          children: [
            // 调试背景 - 临时添加半透明背景来确认窗口位置
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.1), // 半透明黑色背景
            ),
            // 使用统一的悬浮球组件
            SharedFloatingBallWidget(
              key: _floatingBallKey,
              isInOverlay: true, // 在OverlayWindow环境中
              baseSize: 80.0, // 增大悬浮球尺寸，使其更显眼
              color: Colors.red, // 临时使用红色确保可见性
              iconPath: _config.iconPath,
              platformAdapter: OverlayWindowPlatformAdapter(),
              onGesture: _sendGestureMessage,
              onPositionChanged: _sendPositionMessage,
              onConfigChanged: () {
                // 配置变更时可以重新加载
                debugPrint('🎯 悬浮球配置变更');
              },
            ),
          ],
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

