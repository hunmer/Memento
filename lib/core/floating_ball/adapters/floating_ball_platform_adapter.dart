import 'package:flutter/material.dart';
import '../models/floating_ball_gesture.dart';

/// 悬浮球平台适配器抽象基类
abstract class FloatingBallPlatformAdapter {
  /// 获取屏幕尺寸
  Size getScreenSize(BuildContext context);

  /// 判断是否应该处理特定手势
  bool shouldHandleGesture(FloatingBallGesture gesture);

  /// 适配子Widget（处理平台特定的显示逻辑）
  Widget adaptChildWidget(Widget child);

  /// 处理平台特定的初始化
  Future<void> initialize();

  /// 清理资源
  Future<void> dispose();

  /// 获取适配器名称（用于调试）
  String get adapterName;

  /// 检查是否支持拖拽功能
  bool get supportsDragging;
}

/// 适配器创建工厂
class FloatingBallAdapterFactory {
  static FloatingBallPlatformAdapter create({required bool isInOverlay}) {
    return FloatingBallAdapter();
  }
}

/// 悬浮球适配器实现
class FloatingBallAdapter extends FloatingBallPlatformAdapter {
  @override
  Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  @override
  bool shouldHandleGesture(FloatingBallGesture gesture) {
    // 支持所有手势
    return true;
  }

  @override
  Widget adaptChildWidget(Widget child) {
    return child;
  }

  @override
  Future<void> initialize() async {
    debugPrint('FloatingBallAdapter initialized');
  }

  @override
  Future<void> dispose() async {
    debugPrint('FloatingBallAdapter disposed');
  }

  @override
  String get adapterName => 'FloatingBallAdapter';

  @override
  bool get supportsDragging => true;
}