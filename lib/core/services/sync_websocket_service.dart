import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../route/route_refresh_manager.dart';
import 'sync_client_service.dart';
import 'sync_record_service.dart';

/// 文件更新通知
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

  factory FileUpdateNotification.fromJson(Map<String, dynamic> json) {
    return FileUpdateNotification(
      filePath: json['file_path'] as String,
      md5: json['md5'] as String,
      modifiedAt: DateTime.parse(json['modified_at'] as String),
      sourceDeviceId: json['source_device_id'] as String,
    );
  }
}

/// 同步 WebSocket 服务
///
/// 负责:
/// - 与服务器建立 WebSocket 连接
/// - 接收文件更新通知
/// - 触发文件拉取和路由刷新
/// - 防循环更新机制
class SyncWebSocketService {
  static final SyncWebSocketService _instance = SyncWebSocketService._internal();
  factory SyncWebSocketService() => _instance;
  SyncWebSocketService._internal();

  static const String _tag = 'SyncWebSocketService';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  SyncClientService? _syncClientService;
  SyncRecordService? _recordService;
  RouteRefreshManager? _routeRefreshManager;

  String? _serverUrl;
  String? _token;
  String? _deviceId;

  bool _isConnecting = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  /// 重连间隔（秒）
  static const int _reconnectIntervalSeconds = 5;

  /// 心跳间隔（秒）
  static const int _pingIntervalSeconds = 30;

  /// 是否已连接
  bool get isConnected => _channel != null && _subscription != null;

  /// 配置服务
  void configure({
    required SyncClientService syncClientService,
    required SyncRecordService recordService,
    RouteRefreshManager? routeRefreshManager,
  }) {
    _syncClientService = syncClientService;
    _recordService = recordService;
    _routeRefreshManager = routeRefreshManager;
  }

  /// 连接到服务器
  Future<void> connect({
    required String serverUrl,
    required String token,
    required String deviceId,
  }) async {
    if (_isConnecting || isConnected) {
      _log('已连接或正在连接中，跳过');
      return;
    }

    _serverUrl = serverUrl;
    _token = token;
    _deviceId = deviceId;
    _shouldReconnect = true;

    await _doConnect();
  }

  /// 执行连接
  Future<void> _doConnect() async {
    if (_serverUrl == null || _token == null || _deviceId == null) {
      _log('服务器 URL、Token 或 DeviceId 为空，无法连接');
      return;
    }

    _isConnecting = true;

    try {
      // 将 HTTP URL 转换为 WebSocket URL
      final wsUrl = _serverUrl!
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      final uri = Uri.parse('$wsUrl/api/v1/sync/ws');

      _log('正在连接 WebSocket: $uri');
      _channel = IOWebSocketChannel.connect(uri);

      // 等待连接建立
      await _channel!.ready;

      _log('WebSocket 连接成功，发送认证消息');

      // 发送认证消息
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'token': _token,
        'device_id': _deviceId,
      }));

      // 订阅消息
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // 启动心跳
      _startPingTimer();

      _isConnecting = false;
    } catch (e) {
      _log('WebSocket 连接失败: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'auth_success':
          _log('WebSocket 认证成功: userId=${data['user_id']}');
          break;
        case 'auth_error':
          _log('WebSocket 认证失败: ${data['error']}');
          // 认证失败，断开连接
          disconnect();
          break;
        case 'file_updated':
          _handleFileUpdated(data['data'] as Map<String, dynamic>);
          break;
        case 'pong':
          // 心跳响应，忽略
          break;
        default:
          _log('未知消息类型: $type');
      }
    } catch (e) {
      _log('处理消息错误: $e');
    }
  }

  /// 处理文件更新通知
  Future<void> _handleFileUpdated(Map<String, dynamic> data) async {
    try {
      final notification = FileUpdateNotification.fromJson(data);

      _log('收到文件更新通知: ${notification.filePath}, 来源: ${notification.sourceDeviceId}');

      // 防护1: 忽略来自本设备的更新
      // 只有当 sourceDeviceId 非空且等于本设备 ID 时才忽略
      if (notification.sourceDeviceId.isNotEmpty &&
          notification.sourceDeviceId == _deviceId) {
        _log('忽略来自本设备的更新');
        return;
      }

      // 防护2: 检查是否最近上传过
      if (_recordService?.wasRecentlyUploaded(notification.filePath) == true) {
        _log('最近上传过，跳过: ${notification.filePath}');
        return;
      }

      // 防护3: MD5 比对（如果本地有记录）
      final localMd5 = await _getLocalMd5(notification.filePath);
      if (localMd5 != null && localMd5 == notification.md5) {
        _log('MD5 相同，跳过拉取: ${notification.filePath}');
        return;
      }

      // 拉取更新
      if (_syncClientService != null && _syncClientService!.isLoggedIn) {
        _log('开始拉取文件: ${notification.filePath}');
        final result = await _syncClientService!.pullFile(notification.filePath);

        if (result.isSuccess) {
          _log('文件拉取成功: ${notification.filePath}');

          // 触发路由刷新
          _routeRefreshManager?.onFileSynced(notification.filePath);
        } else {
          _log('文件拉取失败: ${result.message}');
        }
      }
    } catch (e) {
      _log('处理文件更新错误: $e');
    }
  }

  /// 获取本地文件的 MD5
  Future<String?> _getLocalMd5(String filePath) async {
    // 委托给 SyncClientService 的内部方法
    // 这里简化处理，直接返回 null（实际实现需要访问存储）
    return null;
  }

  /// 处理连接错误
  void _handleError(dynamic error) {
    _log('WebSocket 错误: $error');
    _cleanup();
    _scheduleReconnect();
  }

  /// 处理连接关闭
  void _handleDone() {
    _log('WebSocket 连接已关闭');
    _cleanup();
    _scheduleReconnect();
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (!_shouldReconnect) {
      _log('不重连');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectIntervalSeconds),
      () {
        _log('尝试重连...');
        _doConnect();
      },
    );
  }

  /// 启动心跳定时器
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(seconds: _pingIntervalSeconds),
      (_) => _sendPing(),
    );
  }

  /// 发送心跳
  void _sendPing() {
    if (!isConnected) return;

    try {
      _channel!.sink.add(jsonEncode({'type': 'ping'}));
      _log('发送心跳');
    } catch (e) {
      _log('发送心跳失败: $e');
    }
  }

  /// 清理资源
  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 断开连接
  void disconnect() {
    _log('断开 WebSocket 连接');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
  }

  /// 输出日志
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag: $message');
    }
  }
}
