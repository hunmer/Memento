import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';

/// 悬浮球按钮数据
class FloatingBallButtonData {
  /// 按钮标题
  final String title;
  /// 按钮图标资源名称（android R.drawable 中的图标名）
  final String icon;
  /// 自定义数据，会在点击时回传
  final Map<String, dynamic>? data;
  /// 按钮背景图片（base64 编码），有此字段时优先使用图片而非 icon
  final String? image;

  const FloatingBallButtonData({
    required this.title,
    required this.icon,
    this.data,
    this.image,
  });

  /// 转换为 Map 传递给原生端
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'data': data,
      'image': image,
    };
  }
}

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
  /// 子按钮数组（替代 subButtonCount）
  final List<FloatingBallButtonData>? buttonData;

  const FloatingBallConfig({
    this.iconName,
    this.size,
    this.startX,
    this.startY,
    this.snapThreshold,
    this.buttonData,
  });

  /// 转换为 Map 传递给原生端
  Map<String, dynamic> toMap() {
    return {
      'iconName': iconName,
      'size': size,
      'startX': startX,
      'startY': startY,
      'snapThreshold': snapThreshold,
      'buttonData': buttonData?.map((button) => button.toMap()).toList(),
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
      (map['x'] as num?)?.toInt() ?? 0,
      (map['y'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 悬浮球按钮点击事件数据
class FloatingBallButtonEvent {
  /// 按钮索引
  final int index;
  /// 按钮标题
  final String title;
  /// 按钮自定义数据
  final Map<String, dynamic>? data;

  const FloatingBallButtonEvent({
    required this.index,
    required this.title,
    this.data,
  });

  factory FloatingBallButtonEvent.fromMap(Map<String, dynamic> map) {
    // 安全地转换 data 字段，处理嵌套 Map 的类型问题
    Map<String, dynamic>? parsedData;
    final rawData = map['data'];
    if (rawData is Map) {
      parsedData = _deepConvertMap(rawData);
    }

    return FloatingBallButtonEvent(
      index: (map['index'] as num?)?.toInt() ?? 0,
      title: map['title']?.toString() ?? '',
      data: parsedData,
    );
  }

  /// 递归转换 Map 为 Map<String, dynamic>
  static Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map((key, value) {
      final stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(stringKey, _deepConvertList(value));
      }
      return MapEntry(stringKey, value);
    });
  }

  /// 递归转换 List 中的 Map
  static List<dynamic> _deepConvertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      }
      return item;
    }).toList();
  }
}

typedef FloatingBallPositionCallback = void Function(FloatingBallPosition position);
typedef FloatingBallButtonCallback = void Function(FloatingBallButtonEvent event);

class FloatingBallPlugin {
  static const MethodChannel _channel = MethodChannel('floating_ball_plugin');
  static const EventChannel _positionChannel = EventChannel('floating_ball_plugin/position');
  static const EventChannel _buttonChannel = EventChannel('floating_ball_plugin/button');

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
    return _positionChannel.receiveBroadcastStream().cast<Map>().map(
      (Map map) {
        return FloatingBallPosition.fromMap(
          map.map((key, value) => MapEntry(key.toString(), value as dynamic)),
        );
      },
    );
  }

  /// 监听按钮点击事件
  static Stream<FloatingBallButtonEvent> listenButtonEvents() {
    return _buttonChannel.receiveBroadcastStream().cast<Map>().map(
      (Map map) {
        return FloatingBallButtonEvent.fromMap(
          map.map((key, value) => MapEntry(key.toString(), value as dynamic)),
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

  /// 设置单个按钮的图片（分批次更新，避免 Binder 事务过大）
  /// [index] 按钮索引
  /// [imageBase64] 图片的 base64 编码字符串
  static Future<String?> setButtonImage(int index, String imageBase64) async {
    try {
      final String? result = await _channel.invokeMethod(
        'setButtonImage',
        {'index': index, 'imageBase64': imageBase64},
      );
      return result;
    } on PlatformException {
      return 'Failed to set button image';
    }
  }
}
