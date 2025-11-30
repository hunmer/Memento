import 'package:flutter/material.dart';
import 'dart:async';
import 'floating_ball_widget.dart';
import 'floating_ball_manager.dart';
import 'models/floating_ball_gesture.dart';

/// 悬浮球服务
class FloatingBallService {
  static final FloatingBallService _instance = FloatingBallService._internal();
  factory FloatingBallService() => _instance;
  FloatingBallService._internal();

  OverlayEntry? _overlayEntry;
  final FloatingBallManager _manager = FloatingBallManager();
  bool _isInitialized = false;
  BuildContext? lastContext;

  // 添加流控制器用于通知悬浮球变化
  final StreamController<double> _sizeChangeController =
      StreamController<double>.broadcast();
  final StreamController<Offset> _positionChangeController =
      StreamController<Offset>.broadcast();
  Stream<double> get sizeChangeStream => _sizeChangeController.stream;
  Stream<Offset> get positionChangeStream => _positionChangeController.stream;

  /// 初始化悬浮球
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _manager.setActionContext(context);
    _isInitialized = true;
  }

  // 更新上下文
  void updateContext(BuildContext context) {
    _manager.setActionContext(context);
  }

  /// 显示悬浮球
  Future<void> show(BuildContext? context) async {
    try {
      if (_overlayEntry != null || context == null) return;
      if (!context.mounted) return; // 检查上下文是否有效

      // 检查悬浮球是否启用
      final isEnabled = await _manager.isEnabled();
      if (!isEnabled) return;

      lastContext = context;
      initialize(context);

      _overlayEntry = OverlayEntry(
        builder:
            (context) => const FloatingBallWidget(
              baseSize: 60,
              iconPath: 'assets/icon/icon.png',
            ),
      );

      final overlayState = Overlay.of(context);
      if (overlayState != null && overlayState.mounted) {
        overlayState.insert(_overlayEntry!);
      }
    } catch (e) {
      debugPrint('Error showing floating ball: $e');
    }
  }

  /// 隐藏悬浮球
  void hide() {
    try {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    } catch (e) {
      debugPrint('Error hiding floating ball: $e');
    }
  }

  /// 设置悬浮球动作
  void setAction(
    FloatingBallGesture gesture,
    String title,
    Function() callback,
  ) {
    _manager.setAction(gesture, title, callback);
  }

  /// 获取悬浮球管理器
  FloatingBallManager get manager => _manager;

  /// 通知悬浮球大小变化
  void notifySizeChange(double scale) {
    _sizeChangeController.add(scale);

    // 强制重新构建悬浮球
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// 更新悬浮球位置
  void updatePosition(Offset newPosition) {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      _positionChangeController.add(newPosition);
    }
  }

  /// 释放资源
  void dispose() {
    _sizeChangeController.close();
    _positionChangeController.close();
  }
}
