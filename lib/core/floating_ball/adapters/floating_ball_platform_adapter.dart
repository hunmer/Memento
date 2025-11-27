import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:math' as math;
import '../models/floating_ball_gesture.dart';

/// 悬浮球平台适配器抽象基类
///
/// 为不同运行环境（Overlay vs OverlayWindow）提供统一的接口抽象
/// 处理平台特定的差异和限制
abstract class FloatingBallPlatformAdapter {
  /// 获取屏幕尺寸
  Size getScreenSize(BuildContext context);

  /// 检查必要权限
  Future<bool> checkPermissions();

  /// 请求必要权限
  Future<bool> requestPermissions();

  /// 判断是否应该处理特定手势
  bool shouldHandleGesture(FloatingBallGesture gesture);

  /// 判断是否可以导航到特定页面
  bool canNavigateToScreen(String screenId);

  /// 适配子Widget（处理平台特定的显示逻辑）
  Widget adaptChildWidget(Widget child);

  /// 获取平台特定的配置
  Map<String, dynamic> getPlatformSpecificConfig();

  /// 处理平台特定的初始化
  Future<void> initialize();

  /// 清理资源
  Future<void> dispose();

  /// 获取适配器名称（用于调试）
  String get adapterName;

  /// 检查是否支持拖拽功能
  bool get supportsDragging;

  /// 检查是否支持调整大小
  bool get supportsResizing;

  /// 获取最小窗口尺寸
  Size get minimumWindowSize;

  /// 获取最大窗口尺寸
  Size get maximumWindowSize;
}

/// 适配器创建工厂
class FloatingBallAdapterFactory {
  static FloatingBallPlatformAdapter create({required bool isInOverlay}) {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported for overlay windows');
    }

    if (isInOverlay) {
      return OverlayPlatformAdapter();
    } else {
      return OverlayWindowPlatformAdapter();
    }
  }
}

/// Overlay环境适配器（现有功能）
class OverlayPlatformAdapter extends FloatingBallPlatformAdapter {
  @override
  Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  @override
  Future<bool> checkPermissions() async {
    // Overlay实现不需要特殊权限
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    // Overlay实现不需要特殊权限
    return true;
  }

  @override
  bool shouldHandleGesture(FloatingBallGesture gesture) {
    // Overlay环境支持所有手势
    return true;
  }

  @override
  bool canNavigateToScreen(String screenId) {
    // Overlay环境可以直接导航
    return true;
  }

  @override
  Widget adaptChildWidget(Widget child) {
    // Overlay环境不需要特殊适配
    return child;
  }

  @override
  Map<String, dynamic> getPlatformSpecificConfig() {
    return {
      'supportsMultiTouch': true,
      'supportsComplexAnimations': true,
      'maxConcurrentGestures': 5,
      'supportsBackdrop': false,
    };
  }

  @override
  Future<void> initialize() async {
    // Overlay环境初始化逻辑
    debugPrint('OverlayPlatformAdapter initialized');
  }

  @override
  Future<void> dispose() async {
    // Overlay环境清理逻辑
    debugPrint('OverlayPlatformAdapter disposed');
  }

  @override
  String get adapterName => 'OverlayPlatformAdapter';

  @override
  bool get supportsDragging => true;

  @override
  bool get supportsResizing => true;

  @override
  Size get minimumWindowSize => const Size(30, 30);  // 最小悬浮球尺寸

  @override
  Size get maximumWindowSize => const Size(150, 150); // 最大悬浮球尺寸
}

/// OverlayWindow环境适配器（新功能）
class OverlayWindowPlatformAdapter extends FloatingBallPlatformAdapter {
  @override
  Size getScreenSize(BuildContext context) {
    // 在overlay环境中，返回overlay窗口的实际可用尺寸
    // 使用MediaQuery获取真实尺寸，如果没有context则返回默认尺寸
    try {
      if (context.mounted) {
        final size = MediaQuery.of(context).size;
        debugPrint('🎯 Overlay窗口实际尺寸: ${size.width}x${size.height}');
        return size;
      }
    } catch (e) {
      debugPrint('无法获取overlay窗口尺寸，使用默认值: $e');
    }

    // 如果无法获取真实尺寸，返回基于屏幕尺寸的合理默认值
    final screenSize = WidgetsBinding.instance.window;
    final screenWidth = screenSize.physicalSize.width / screenSize.devicePixelRatio;
    final screenHeight = screenSize.physicalSize.height / screenSize.devicePixelRatio;

    // 返回一个合理的overlay窗口尺寸（约屏幕的40%）
    final overlaySize = math.min(screenWidth, screenHeight) * 0.4;
    debugPrint('🎯 使用计算的overlay窗口尺寸: ${overlaySize}x$overlaySize');
    return Size(overlaySize, overlaySize);
  }

  @override
  Future<bool> checkPermissions() async {
    try {
      // 检查overlay权限
      // 这里需要使用flutter_overlay_window的权限检查API
      // 目前flutter_overlay_window没有直接的权限检查API，需要通过异常来判断
      return true; // 暂时返回true，实际使用时会通过异常检测
    } catch (e) {
      debugPrint('Permission check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // 请求overlay权限
      // 这里需要引导用户到系统设置页面开启权限
      debugPrint('Requesting overlay permissions...');
      return true;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  @override
  bool shouldHandleGesture(FloatingBallGesture gesture) {
    // OverlayWindow环境可能对手势有限制
    switch (gesture) {
      case FloatingBallGesture.tap:
      case FloatingBallGesture.swipeUp:
      case FloatingBallGesture.swipeDown:
        return true;
      case FloatingBallGesture.swipeLeft:
      case FloatingBallGesture.swipeRight:
        return false; // 横滑可能与系统手势冲突
    }
  }

  @override
  bool canNavigateToScreen(String screenId) {
    // OverlayWindow环境不能直接导航，需要通过消息通信
    return false;
  }

  @override
  Widget adaptChildWidget(Widget child) {
    // OverlayWindow环境可能需要特殊适配
    return Material(
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  Map<String, dynamic> getPlatformSpecificConfig() {
    return {
      'supportsMultiTouch': false,
      'supportsComplexAnimations': true,
      'maxConcurrentGestures': 1,
      'supportsBackdrop': true,
      'requiresPermission': true,
      'windowAlignment': 'topRight',
      'windowFlag': 'notFocusable',
    };
  }

  @override
  Future<void> initialize() async {
    debugPrint('OverlayWindowPlatformAdapter initialized');
    // OverlayWindow环境初始化逻辑
    // 注册消息监听器等
  }

  @override
  Future<void> dispose() async {
    debugPrint('OverlayWindowPlatformAdapter disposed');
    // OverlayWindow环境清理逻辑
  }

  @override
  String get adapterName => 'OverlayWindowPlatformAdapter';

  @override
  bool get supportsDragging => true;

  @override
  bool get supportsResizing => false; // OverlayWindow不支持动态调整大小

  @override
  Size get minimumWindowSize => const Size(60, 60);  // 最小窗口尺寸

  @override
  Size get maximumWindowSize => const Size(120, 120); // 最大窗口尺寸
}
