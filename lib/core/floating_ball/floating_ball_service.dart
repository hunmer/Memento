import 'package:flutter/material.dart';
import 'dart:async';
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
  
  // 添加一个流控制器用于通知悬浮球大小变化
  final StreamController<double> _sizeChangeController = StreamController<double>.broadcast();
  Stream<double> get sizeChangeStream => _sizeChangeController.stream;

  /// 初始化悬浮球
  void initialize(BuildContext context) {
    if (_isInitialized) return;
    
    _manager.initDefaultActions(context);
    _manager.setActionContext(context);
    _isInitialized = true;
  }

  // 更新上下文
  void updateContext(BuildContext context) {
    _manager.setActionContext(context);
  }

  /// 显示悬浮球
  void show(BuildContext context) {
    if (_overlayEntry != null) return;
    
    initialize(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => const FloatingBallWidget(
        baseSize: 60,
        iconPath: 'assets/icon/icon.png',
      ),
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
  
  /// 通知悬浮球大小变化
  void notifySizeChange(double scale) {
    _sizeChangeController.add(scale);
  }
  
  /// 释放资源
  void dispose() {
    _sizeChangeController.close();
  }
}