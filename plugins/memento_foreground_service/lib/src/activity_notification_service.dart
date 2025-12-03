import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 活动通知前台服务
///
/// 提供活动提醒的前台服务管理，包括启动、更新和停止活动通知服务。
class MementoActivityNotificationService {
  static final MementoActivityNotificationService _instance =
      MementoActivityNotificationService._internal();

  /// 单例实例
  static MementoActivityNotificationService get instance => _instance;

  MementoActivityNotificationService._internal();

  /// MethodChannel 名称
  static const String _channelName =
      'com.memento.foreground_service/activity_notification';

  /// MethodChannel 实例
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// 通知点击事件回调
  Function(Map<String, dynamic>)? _onNotificationClicked;

  /// 设置通知点击事件回调
  void setOnNotificationClicked(Function(Map<String, dynamic>)? callback) {
    _onNotificationClicked = callback;

    // 设置 MethodChannel 回调处理
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onActivityNotificationClicked') {
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null && _onNotificationClicked != null) {
          _onNotificationClicked!(Map<String, dynamic>.from(args));
        }
      }
    });
  }

  /// 启动活动通知服务
  Future<void> startService() async {
    if (!Platform.isAndroid) {
      debugPrint('[MementoActivityNotificationService] 仅支持 Android 平台');
      return;
    }

    try {
      await _channel.invokeMethod('startActivityNotificationService');
      debugPrint('[MementoActivityNotificationService] 活动通知服务已启动');
    } catch (e) {
      debugPrint('[MementoActivityNotificationService] 启动活动通知服务失败: $e');
      rethrow;
    }
  }

  /// 停止活动通知服务
  Future<void> stopService() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopActivityNotificationService');
      debugPrint('[MementoActivityNotificationService] 活动通知服务已停止');
    } catch (e) {
      debugPrint('[MementoActivityNotificationService] 停止活动通知服务失败: $e');
      rethrow;
    }
  }

  /// 更新活动通知内容
  ///
  /// [title] 通知标题
  /// [content] 通知内容
  Future<void> updateNotification({
    required String title,
    required String content,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('updateActivityNotification', {
        'title': title,
        'content': content,
      });
      debugPrint('[MementoActivityNotificationService] 通知已更新: $title');
    } catch (e) {
      debugPrint('[MementoActivityNotificationService] 更新通知失败: $e');
      rethrow;
    }
  }
}
