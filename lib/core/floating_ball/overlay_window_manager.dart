import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'renderers/overlay_window_floating_ball_renderer.dart';
import 'floating_ball_manager.dart';
import 'config/floating_ball_config.dart';
import 'models/floating_ball_gesture.dart';

/// Overlay窗口管理器
///
/// 负责管理overlay窗口悬浮球的显示和隐藏
class OverlayWindowManager {
  static final OverlayWindowManager _instance = OverlayWindowManager._internal();
  factory OverlayWindowManager() => _instance;
  OverlayWindowManager._internal();

  OverlayWindowFloatingBallRenderer? _renderer;
  bool _isInitialized = false;
  bool _hasPermissions = false;
  StreamSubscription? _overlaySubscription;

  /// 初始化overlay窗口管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _prepareRenderer();

      if (_renderer == null) {
        // 没有权限时不重复注册监听器
        return;
      }

      _overlaySubscription ??=
          FlutterOverlayWindow.overlayListener.listen(_handleOverlayMessage);

      _isInitialized = true;
      debugPrint('OverlayWindowManager initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OverlayWindowManager: $e');
      rethrow;
    }
  }

  Future<void> _prepareRenderer() async {
    _hasPermissions = await _checkPermissions();

    if (!_hasPermissions) {
      debugPrint('OverlayWindowManager: No overlay permissions');
      return;
    }

    if (_renderer == null) {
      _renderer = OverlayWindowFloatingBallRenderer();
      await _renderer!.initialize();
    }
  }

  /// 检查权限
  Future<bool> _checkPermissions() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('Error checking overlay permissions: $e');
      return false;
    }
  }

  /// 请求权限
  Future<bool> requestPermissions() async {
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      debugPrint('Overlay permission granted: $granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
      return false;
    }
  }

  /// 显示overlay窗口悬浮球
  Future<void> showFloatingBall(BuildContext context) async {
    debugPrint('=== 开始显示悬浮球 ===');

    if (!_isInitialized) {
      debugPrint('初始化 OverlayWindowManager...');
      await initialize();
    }

    if (!_hasPermissions) {
      debugPrint('没有权限，请求权限中...');
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('权限被拒绝');
        _showPermissionDialog(context);
        return;
      }
      _hasPermissions = true;
      debugPrint('权限获取成功，重新初始化...');
      await initialize();
    }

    try {
      if (_renderer == null) {
        debugPrint('准备渲染器...');
        await _prepareRenderer();
      }

      if (_renderer == null) {
        debugPrint('错误：渲染器不可用');
        _showErrorDialog(context, '全局悬浮球渲染器不可用');
        return;
      }

      debugPrint('调用渲染器显示悬浮球...');
      await _renderer!.show(context);
      debugPrint('✅ 悬浮球显示成功');
    } catch (e) {
      debugPrint('❌ 显示悬浮球失败: $e');
      _showErrorDialog(context, 'Failed to show overlay window: $e');
    }
  }

  /// 隐藏overlay窗口悬浮球
  Future<void> hideFloatingBall() async {
    if (_renderer != null && _renderer!.isVisible()) {
      try {
        await _renderer!.hide();
        debugPrint('Overlay window floating ball hidden');
      } catch (e) {
        debugPrint('Failed to hide overlay window floating ball: $e');
      }
    }
  }

  /// 更新悬浮球配置
  Future<void> updateConfig(FloatingBallConfig config) async {
    if (_renderer != null) {
      await _renderer!.updateConfig(config);
    }
  }

  /// 检查是否正在显示
  bool isVisible() {
    return _renderer?.isVisible() ?? false;
  }

  /// 处理从overlay窗口收到的消息
  void _handleOverlayMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final action = data['action'] as String?;
        debugPrint('OverlayWindowManager received message: $action');

        // 先转发给渲染器处理
        _renderer?.handleOverlayMessage(data);

        // 管理器只处理特定消息
        switch (action) {
          case 'ready':
            debugPrint('Overlay window is ready');
            break;
          case 'gesture':
            _handleGestureMessage(data['data'] as Map<String, dynamic>?);
            break;
          case 'position_changed':
            _handlePositionChangedMessage(data['data'] as Map<String, dynamic>?);
            break;
          case 'size_changed':
            _handleSizeChangedMessage(data['data'] as Map<String, dynamic>?);
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling overlay message: $e');
    }
  }

  /// 处理手势消息
  void _handleGestureMessage(Map<String, dynamic>? data) {
    if (data != null) {
      final manager = FloatingBallManager();
      final gestureName = data['gesture'] as String?;
      if (gestureName != null) {
        final gesture = _parseGestureName(gestureName);
        if (gesture != null) {
          final action = manager.getAction(gesture);
          if (action != null) {
            action();
          }
        }
      }
    }
  }

  /// 处理位置变化消息
  void _handlePositionChangedMessage(Map<String, dynamic>? data) {
    if (data != null) {
      final x = (data['x'] as num?)?.toDouble() ?? 0.0;
      final y = (data['y'] as num?)?.toDouble() ?? 0.0;
      final position = Offset(x, y);

      final manager = FloatingBallManager();
      manager.savePosition(position);

      // TODO: 通知FloatingBallService
      // FloatingBallService().updatePosition(position);
    }
  }

  /// 处理大小变化消息
  void _handleSizeChangedMessage(Map<String, dynamic>? data) {
    if (data != null) {
      final scale = (data['scale'] as num?)?.toDouble() ?? 1.0;

      final manager = FloatingBallManager();
      manager.saveSizeScale(scale);

      // TODO: 通知FloatingBallService
      // FloatingBallService().notifySizeChange(scale);
    }
  }

  /// 解析手势名称
  FloatingBallGesture? _parseGestureName(String gestureName) {
    switch (gestureName) {
      case 'tap':
        return FloatingBallGesture.tap;
      case 'swipeUp':
        return FloatingBallGesture.swipeUp;
      case 'swipeDown':
        return FloatingBallGesture.swipeDown;
      case 'swipeLeft':
        return FloatingBallGesture.swipeLeft;
      case 'swipeRight':
        return FloatingBallGesture.swipeRight;
      default:
        return null;
    }
  }

  /// 显示权限对话框
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('需要权限'),
          content: Text('请开启"显示在其他应用上层"权限以使用全局悬浮球功能。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 打开系统设置页面
              },
              child: Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('错误'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 销毁管理器
  Future<void> dispose() async {
    // 取消流订阅
    await _overlaySubscription?.cancel();
    _overlaySubscription = null;

    if (_renderer != null) {
      await _renderer!.dispose();
      _renderer = null;
    }
    _isInitialized = false;
    debugPrint('OverlayWindowManager disposed');
  }
}
