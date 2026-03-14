import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// WebSocket 连接信息
class WebSocketConnection {
  final String userId;
  final String deviceId;
  final WebSocket socket;
  final DateTime connectedAt;

  WebSocketConnection({
    required this.userId,
    required this.deviceId,
    required this.socket,
    required this.connectedAt,
  });
}

/// 文件更新通知消息
class FileUpdateNotification {
  final String filePath;
  final String md5;
  final DateTime modifiedAt;
  final String sourceDeviceId;

  FileUpdateNotification({
    required this.filePath,
    required this.md5,
    required this.modifiedAt,
    required this.sourceDeviceId,
  });

  Map<String, dynamic> toJson() => {
    'type': 'file_updated',
    'data': {
      'file_path': filePath,
      'md5': md5,
      'modified_at': modifiedAt.toUtc().toIso8601String(),
      'source_device_id': sourceDeviceId,
    },
  };

  String toJsonString() => jsonEncode(toJson());
}

/// WebSocket 连接管理器
///
/// 负责:
/// - 管理客户端 WebSocket 连接
/// - 广播文件更新通知
/// - 连接生命周期管理
class WebSocketManager {
  // 单例模式
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  /// userId -> deviceId -> WebSocketConnection
  final Map<String, Map<String, WebSocketConnection>> _connections = {};

  /// 是否启用日志
  bool _enableLog = true;

  /// 获取连接数量
  int get connectionCount {
    int count = 0;
    for (final userConnections in _connections.values) {
      count += userConnections.length;
    }
    return count;
  }

  /// 获取用户连接数
  int getUserConnectionCount(String userId) {
    return _connections[userId]?.length ?? 0;
  }

  /// 注册 WebSocket 连接
  void register(String userId, String deviceId, WebSocket socket) {
    final connection = WebSocketConnection(
      userId: userId,
      deviceId: deviceId,
      socket: socket,
      connectedAt: DateTime.now(),
    );

    _connections.putIfAbsent(userId, () => {});
    _connections[userId]![deviceId] = connection;

    _log('注册连接: userId=$userId, deviceId=$deviceId, 当前连接数: $connectionCount');

    // 监听连接关闭
    socket.done.then((_) {
      unregister(userId, deviceId);
    });

    // 监听消息（用于心跳和确认）
    socket.listen(
      (message) {
        _handleMessage(connection, message);
      },
      onError: (error) {
        _log('WebSocket 错误: userId=$userId, deviceId=$deviceId, error=$error');
        unregister(userId, deviceId);
      },
      onDone: () {
        unregister(userId, deviceId);
      },
    );
  }

  /// 注销 WebSocket 连接
  void unregister(String userId, String deviceId) {
    final userConnections = _connections[userId];
    if (userConnections == null) return;

    final connection = userConnections.remove(deviceId);
    if (connection != null) {
      _log('注销连接: userId=$userId, deviceId=$deviceId, 当前连接数: $connectionCount');
    }

    // 如果用户没有连接了，移除用户条目
    if (userConnections.isEmpty) {
      _connections.remove(userId);
    }
  }

  /// 处理客户端消息
  void _handleMessage(WebSocketConnection connection, dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'ping':
          // 心跳响应
          _sendMessage(connection.socket, {'type': 'pong'});
          break;
        case 'ack':
          // 确认消息，记录日志
          _log('收到确认: userId=${connection.userId}, deviceId=${connection.deviceId}');
          break;
        default:
          _log('未知消息类型: $type');
      }
    } catch (e) {
      _log('处理消息错误: $e');
    }
  }

  /// 发送消息
  void _sendMessage(WebSocket socket, Map<String, dynamic> message) {
    try {
      socket.add(jsonEncode(message));
    } catch (e) {
      _log('发送消息失败: $e');
    }
  }

  /// 广播文件更新通知
  ///
  /// [userId] 用户ID
  /// [filePath] 文件路径
  /// [md5] 文件 MD5
  /// [modifiedAt] 修改时间
  /// [sourceDeviceId] 触发更新的设备ID（不会被通知）
  void broadcastFileUpdate(
    String userId,
    String filePath,
    String md5,
    DateTime modifiedAt,
    String sourceDeviceId,
  ) {
    final userConnections = _connections[userId];
    if (userConnections == null || userConnections.isEmpty) {
      _log('用户无在线连接，跳过广播: userId=$userId');
      return;
    }

    final notification = FileUpdateNotification(
      filePath: filePath,
      md5: md5,
      modifiedAt: modifiedAt,
      sourceDeviceId: sourceDeviceId,
    );

    final message = notification.toJsonString();
    int sentCount = 0;

    for (final entry in userConnections.entries) {
      final deviceId = entry.key;
      final connection = entry.value;

      // 排除源设备（不回发给触发更新的设备）
      if (deviceId == sourceDeviceId) {
        continue;
      }

      try {
        connection.socket.add(message);
        sentCount++;
      } catch (e) {
        _log('广播失败: userId=$userId, deviceId=$deviceId, error=$e');
        // 发送失败，移除连接
        unregister(userId, deviceId);
      }
    }

    _log('广播文件更新: filePath=$filePath, 发送给 $sentCount 个设备');
  }

  /// 广播给用户所有设备（包括源设备）
  void broadcastToAllDevices(
    String userId,
    Map<String, dynamic> message,
  ) {
    final userConnections = _connections[userId];
    if (userConnections == null || userConnections.isEmpty) return;

    final messageStr = jsonEncode(message);

    for (final connection in userConnections.values) {
      try {
        connection.socket.add(messageStr);
      } catch (e) {
        _log('广播失败: userId=$userId, deviceId=${connection.deviceId}, error=$e');
        unregister(userId, connection.deviceId);
      }
    }
  }

  /// 检查用户是否有在线连接
  bool isUserOnline(String userId) {
    final userConnections = _connections[userId];
    return userConnections != null && userConnections.isNotEmpty;
  }

  /// 检查用户特定设备是否在线
  bool isDeviceOnline(String userId, String deviceId) {
    return _connections[userId]?.containsKey(deviceId) ?? false;
  }

  /// 获取用户所有在线设备
  List<String> getOnlineDevices(String userId) {
    return _connections[userId]?.keys.toList() ?? [];
  }

  /// 关闭所有连接
  Future<void> closeAll() async {
    _log('关闭所有 WebSocket 连接...');

    for (final userConnections in _connections.values) {
      for (final connection in userConnections.values) {
        try {
          await connection.socket.close();
        } catch (e) {
          // 忽略关闭错误
        }
      }
    }

    _connections.clear();
    _log('所有连接已关闭');
  }

  /// 输出日志
  void _log(String message) {
    if (_enableLog) {
      print('[WebSocketManager] $message');
    }
  }

  /// 设置日志开关
  void setLogEnabled(bool enabled) {
    _enableLog = enabled;
  }
}
