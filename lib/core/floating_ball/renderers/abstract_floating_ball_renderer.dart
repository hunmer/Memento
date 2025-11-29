import 'package:Memento/core/floating_ball/models/floating_ball_gesture.dart';
import 'package:flutter/material.dart';
import '../config/floating_ball_config.dart';
import '../floating_ball_manager.dart';

/// 悬浮球渲染器抽象基类
///
/// 定义了不同悬浮球实现方式的统一接口
abstract class AbstractFloatingBallRenderer {
  /// 渲染器类型标识
  String get rendererType;

  /// 初始化渲染器
  Future<void> initialize();

  /// 显示悬浮球
  Future<void> show(BuildContext context);

  /// 隐藏悬浮球
  Future<void> hide();

  /// 更新悬浮球配置
  Future<void> updateConfig(FloatingBallConfig config);

  /// 检查悬浮球是否可见
  bool isVisible();

  /// 销毁渲染器并清理资源
  Future<void> dispose();

  /// 处理手势动作
  void handleGesture(FloatingBallGesture gesture);

  /// 设置手势动作回调
  void setGestureCallback(FloatingBallGesture gesture, VoidCallback callback);

  /// 设置位置变化回调
  void setPositionChangedCallback(Function(Offset) callback);

  /// 设置大小变化回调
  void setSizeChangedCallback(Function(double) callback);

  /// 获取当前悬浮球位置
  Offset? getPosition();

  /// 获取当前悬浮球大小比例
  double getSizeScale();
}

/// 基础渲染器实现
///
/// 提供通用的渲染器功能，子类可以继承并重写特定方法
abstract class BaseFloatingBallRenderer extends AbstractFloatingBallRenderer {
  FloatingBallConfig _config = FloatingBallConfig.defaultConfig;
  final Map<FloatingBallGesture, VoidCallback> _gestureCallbacks = {};
  Function(Offset)? _positionChangedCallback;
  Function(double)? _sizeChangedCallback;
  bool _isVisible = false;

  final FloatingBallManager _manager = FloatingBallManager();

  /// 获取当前配置
  FloatingBallConfig get config => _config;

  @override
  bool isVisible() => _isVisible;

  /// 设置可见性状态（供子类使用）
  @protected
  void setVisible(bool visible) {
    _isVisible = visible;
  }

  @override
  void handleGesture(FloatingBallGesture gesture) {
    final callback = _gestureCallbacks[gesture];
    if (callback != null) {
      callback();
    } else {
      // 使用管理器中的默认动作
      final action = _manager.getAction(gesture);
      if (action != null) {
        action();
      }
    }
  }

  @override
  void setGestureCallback(FloatingBallGesture gesture, VoidCallback callback) {
    _gestureCallbacks[gesture] = callback;
  }

  @override
  void setPositionChangedCallback(Function(Offset) callback) {
    _positionChangedCallback = callback;
  }

  @override
  void setSizeChangedCallback(Function(double) callback) {
    _sizeChangedCallback = callback;
  }

  @override
  Offset? getPosition() {
    return _config.position;
  }

  @override
  double getSizeScale() {
    return _config.sizeScale;
  }

  @override
  Future<void> updateConfig(FloatingBallConfig config) async {
    _config = config;
    await _saveConfig();
    await _applyConfig();
  }

  /// 保存配置到持久化存储
  Future<void> _saveConfig() async {
    // TODO: 实现配置保存逻辑
    debugPrint('Saving config for $rendererType: $_config');
  }

  /// 应用配置变更
  Future<void> _applyConfig() async {
    // 子类可以重写此方法来应用特定的配置变更
  }

  /// 通知位置变化
  void notifyPositionChanged(Offset position) {
    _positionChangedCallback?.call(position);
    // 保存到管理器
    _manager.savePosition(position);
  }

  /// 通知大小变化
  void notifySizeChanged(double scale) {
    _sizeChangedCallback?.call(scale);
    // 保存到管理器
    _manager.saveSizeScale(scale);
  }

  @override
  Future<void> dispose() async {
    _gestureCallbacks.clear();
    _positionChangedCallback = null;
    _sizeChangedCallback = null;
    _isVisible = false;
  }
}
