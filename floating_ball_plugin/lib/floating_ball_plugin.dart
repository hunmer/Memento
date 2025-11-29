import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';

/// 悬浮球配置类
class FloatingBallConfig {
  /// 图标资源名称（放在 android/app/src/main/res/drawable/ 目录）
  final String? iconName;
  /// 悬浮球大小（dp）
  final double? size;
  /// 起始位置 X 坐标（px）
  final int? startX;
  /// 起始位置 Y 坐标（px）
  final int? startY;
  /// 靠近边缘的阈值（px），小于此值会吸附
  final int? snapThreshold;
  /// 子按钮数量（最多10个）
  final int? subButtonCount;

  const FloatingBallConfig({
    this.iconName,
    this.size,
    this.startX,
    this.startY,
    this.snapThreshold,
    this.subButtonCount,
  });

  /// 转换为 Map 传递给原生端
  Map<String, dynamic> toMap() {
    return {
      'iconName': iconName,
      'size': size,
      'startX': startX,
      'startY': startY,
      'snapThreshold': snapThreshold,
      'subButtonCount': subButtonCount,
    };
  }
}

/// 悬浮球位置信息
class FloatingBallPosition {
  final int x;
  final int y;

  const FloatingBallPosition(this.x, this.y);

  factory FloatingBallPosition.fromMap(Map<String, dynamic> map) {
    return FloatingBallPosition(
      map['x']?.toInt() ?? 0,
      map['y']?.toInt() ?? 0,
    );
  }
}

typedef FloatingBallPositionCallback = void Function(FloatingBallPosition position);

class FloatingBallPlugin {
  static const MethodChannel _channel = MethodChannel('floating_ball_plugin');
  static const EventChannel _eventChannel = EventChannel('floating_ball_plugin/events');

  /// 启动悬浮球
  static Future<String?> startFloatingBall({
    FloatingBallConfig? config,
  }) async {
    try {
      final result = await _channel.invokeMethod(
        'startFloatingBall',
        config?.toMap() ?? {},
      );
      return result as String?;
    } on PlatformException {
      return 'Failed to start floating ball';
    }
  }

  /// 停止悬浮球
  static Future<String?> stopFloatingBall() async {
    try {
      final String? result = await _channel.invokeMethod('stopFloatingBall');
      return result;
    } on PlatformException {
      return 'Failed to stop floating ball';
    }
  }

  /// 检查悬浮球状态
  static Future<bool> isRunning() async {
    try {
      final bool? result = await _channel.invokeMethod('isRunning');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 监听位置变更
  static Stream<FloatingBallPosition> listenPositionChanges() {
    return _eventChannel.receiveBroadcastStream().map(
      (dynamic data) {
        final map = data as Map<dynamic, dynamic>;
        return FloatingBallPosition.fromMap(
          map.map((key, value) => MapEntry(key.toString(), value)),
        );
      },
    );
  }

  /// 实时更新悬浮球配置（无需重启）
  static Future<String?> updateConfig(FloatingBallConfig config) async {
    try {
      final String? result = await _channel.invokeMethod(
        'updateFloatingBallConfig',
        config.toMap(),
      );
      return result;
    } on PlatformException {
      return 'Failed to update config';
    }
  }

  /// 设置悬浮球图片（从字节数据）
  static Future<String?> setFloatingBallImage(Uint8List imageBytes) async {
    try {
      final String? result = await _channel.invokeMethod(
        'setFloatingBallImage',
        {'imageBytes': imageBytes},
      );
      return result;
    } on PlatformException {
      return 'Failed to set image';
    }
  }
}
