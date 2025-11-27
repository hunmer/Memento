import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'abstract_floating_ball_renderer.dart';
import '../config/floating_ball_config.dart';
import '../adapters/floating_ball_platform_adapter.dart';
import '../models/floating_ball_gesture.dart';

/// OverlayWindow悬浮球渲染器
///
/// 使用flutter_overlay_window在应用外部显示悬浮球
class OverlayWindowFloatingBallRenderer extends BaseFloatingBallRenderer {
  bool _isInitialized = false;

  @override
  String get rendererType => 'OverlayWindow';

  @override
  bool get isInOverlay => true;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查权限
      final adapter = OverlayWindowPlatformAdapter();
      if (!await adapter.checkPermissions()) {
        await adapter.requestPermissions();
      }

      // 注意：不在这里监听流，由OverlayWindowManager统一管理

      _isInitialized = true;
      debugPrint('OverlayWindowFloatingBallRenderer initialized');
    } catch (e) {
      debugPrint('Failed to initialize OverlayWindowFloatingBallRenderer: $e');
      rethrow;
    }
  }

  @override
  Future<void> show(BuildContext context) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (isVisible()) return;

    try {
      // 显示overlay窗口，使用较大的初始尺寸以容纳悬浮球和可能的展开选项
      await FlutterOverlayWindow.showOverlay(
        height: 300, // 足够大的初始尺寸
        width: 300,
        alignment: OverlayAlignment.topRight,
        enableDrag: true,
        overlayContent: "overlayMain", // 对应 @pragma("vm:entry-point") 的函数名
      );

      // 发送显示消息到overlay
      await _sendOverlayMessage('show', {
        'config': config.toJson(),
        'rendererType': rendererType,
      });

      setVisible(true);
      debugPrint('Overlay window floating ball shown');
    } catch (e) {
      debugPrint('Failed to show overlay window floating ball: $e');
      rethrow;
    }
  }

  @override
  Future<void> hide() async {
    if (!isVisible()) return;

    try {
      // 隐藏overlay窗口
      await FlutterOverlayWindow.closeOverlay();
      setVisible(false);
      debugPrint('Overlay window floating ball hidden');
    } catch (e) {
      debugPrint('Failed to hide overlay window floating ball: $e');
    }
  }

  @override
  Future<void> updateConfig(FloatingBallConfig config) async {
    await super.updateConfig(config);

    if (isVisible()) {
      // 发送配置更新消息到overlay
      await _sendOverlayMessage('update_config', {
        'config': this.config.toJson(),
      });
    }
  }

  /// 发送消息到overlay窗口
  Future<void> _sendOverlayMessage(
    String action,
    Map<String, dynamic> data,
  ) async {
    try {
      await FlutterOverlayWindow.shareData({
        'action': action,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'source': 'main_app',
      });
    } catch (e) {
      debugPrint('Failed to send overlay message: $e');
    }
  }

  /// 处理从overlay窗口收到的消息
  void _handleOverlayMessage(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final action = data['action'] as String?;
        final messageData = data['data'] as Map<String, dynamic>?;

        switch (action) {
          case 'gesture':
            _handleOverlayGesture(messageData);
            break;
          case 'position_changed':
            _handleOverlayPositionChanged(messageData);
            break;
          case 'size_changed':
            _handleOverlaySizeChanged(messageData);
            break;
          case 'ready':
            debugPrint('Overlay window is ready');
            break;
          default:
            debugPrint('Unknown overlay message action: $action');
        }
      }
    } catch (e) {
      debugPrint('Error handling overlay message: $e');
    }
  }

  /// 处理overlay窗口的手势消息
  void _handleOverlayGesture(Map<String, dynamic>? data) {
    if (data != null) {
      final gestureName = data['gesture'] as String?;
      if (gestureName != null) {
        final gesture = _parseGestureName(gestureName);
        if (gesture != null) {
          handleGesture(gesture);
        }
      }
    }
  }

  /// 处理overlay窗口的位置变化消息
  void _handleOverlayPositionChanged(Map<String, dynamic>? data) {
    if (data != null) {
      final x = (data['x'] as num?)?.toDouble() ?? 0.0;
      final y = (data['y'] as num?)?.toDouble() ?? 0.0;
      final position = Offset(x, y);
      notifyPositionChanged(position);
    }
  }

  /// 处理overlay窗口的大小变化消息
  void _handleOverlaySizeChanged(Map<String, dynamic>? data) {
    if (data != null) {
      final scale = (data['scale'] as num?)?.toDouble() ?? 1.0;
      notifySizeChanged(scale);
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

  /// 处理从OverlayWindowManager转发的消息
  void handleOverlayMessage(dynamic data) {
    _handleOverlayMessage(data);
  }

  @override
  Future<void> dispose() async {
    await hide();
    await super.dispose();
    _isInitialized = false;
    debugPrint('OverlayWindowFloatingBallRenderer disposed');
  }
}
