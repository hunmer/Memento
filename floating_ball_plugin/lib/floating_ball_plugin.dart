import 'dart:async';
import 'package:flutter/services.dart';

class FloatingBallPlugin {
  static const MethodChannel _channel = MethodChannel('floating_ball_plugin');

  /// 启动悬浮球
  static Future<String?> startFloatingBall() async {
    try {
      final String? result = await _channel.invokeMethod('startFloatingBall');
      return result;
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
}
