import 'package:flutter/material.dart';
import 'floating_ball_widget.dart';
import 'floating_ball_manager.dart';

/// 悬浮球服务
class FloatingBallService {
  static final FloatingBallService _instance = FloatingBallService._internal();
  factory FloatingBallService() => _instance;
  FloatingBallService._internal();

  OverlayEntry? _overlayEntry;
  final FloatingBallManager _manager = FloatingBallManager();
  bool _isInitialized = false;

  /// 初始化悬浮球
  void initialize(BuildContext context) {
    if (_isInitialized) return;
    
    _manager.initDefaultActions(context);
    _isInitialized = true;
  }

  /// 显示悬浮球
  void show(BuildContext context) {
    if (_overlayEntry != null) return;
    
    initialize(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingBallWidget(),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏悬浮球
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 注册悬浮球动作
  void registerAction(FloatingBallGesture gesture, String title, Function callback) {
    _manager.registerAction(gesture, title, callback);
  }

  /// 获取悬浮球管理器
  FloatingBallManager get manager => _manager;
}