import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:Memento/core/js_bridge/js_bridge_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'api_forwarding_config.dart';

/// API 转发服务
///
/// 通过 WebSocket 连接到转发服务器，接收前端发来的 API 请求，
/// 调用本地插件方法后返回结果
class ApiForwardingService {
  static ApiForwardingService? _instance;
  static ApiForwardingService get instance {
    _instance ??= ApiForwardingService._();
    return _instance!;
  }

  ApiForwardingService._();

  WebSocketChannel? _channel;
  ApiForwardingConfig? _config;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _isWaitingForPeer = false;  // 新增：等待对端连接
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _baseReconnectDelay = 1000;

  // 事件流
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  /// 连接状态流
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  /// 是否已连接（包括等待对端）
  bool get isConnected => _isConnected;

  /// 是否已完全认证（两端都已配对）
  bool get isAuthenticated => _isAuthenticated;

  /// 是否正在等待对端
  bool get isWaitingForPeer => _isWaitingForPeer;

  /// 初始化服务
  Future<void> initialize() async {
    final config = await ApiForwardingConfig.load();
    if (config.enabled && config.isValid) {
      await start(config);
    }
  }

  /// 启动转发服务
  Future<void> start(ApiForwardingConfig config) async {
    if (_isConnected) {
      await stop();
    }

    _config = config;

    try {
      // 规范化服务器 URL
      final serverUrl = _normalizeServerUrl(config.serverUrl);
      debugPrint('[API转发] 正在连接到 $serverUrl...');

      // 连接 WebSocket 服务器
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      // 连接建立
      _isConnected = true;
      _isWaitingForPeer = false;
      _isAuthenticated = false;
      _emitEvent({'type': 'connecting', 'message': '正在连接...'});

      // 监听消息
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('[API转发] 错误: $error');
          _emitEvent({'type': 'error', 'message': error.toString()});
        },
        onDone: () {
          debugPrint('[API转发] 连接已关闭');
          _isConnected = false;
          _isWaitingForPeer = false;
          _isAuthenticated = false;
          _emitEvent({'type': 'disconnected'});

          // 自动重连
          if (_config?.enabled == true) {
            _startReconnect();
          }
        },
        cancelOnError: false,
      );

      // 等待连接建立后发送认证
      await Future.delayed(const Duration(milliseconds: 100));
      await _sendAuthMessage();

      // 启动心跳
      _startHeartbeat();
    } catch (e) {
      _isConnected = false;
      _isWaitingForPeer = false;
      _isAuthenticated = false;
      debugPrint('[API转发] 启动失败: $e');
      _emitEvent({'type': 'error', 'message': e.toString()});
      rethrow;
    }
  }

  /// 规范化服务器 URL
  String _normalizeServerUrl(String url) {
    String normalized = url.trim();

    // 移除末尾的 # 或其他无效字符
    normalized = normalized.split('#')[0];

    // 如果没有协议前缀，默认使用 ws://
    if (!normalized.startsWith('ws://') && !normalized.startsWith('wss://')) {
      if (normalized.startsWith('http://')) {
        normalized = normalized.replaceFirst('http://', 'ws://');
      } else if (normalized.startsWith('https://')) {
        normalized = normalized.replaceFirst('https://', 'wss://');
      } else {
        normalized = 'ws://$normalized';
      }
    }

    // 移除末尾的斜杠
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');

    return normalized;
  }

  /// 停止转发服务
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _isWaitingForPeer = false;
    _isAuthenticated = false;
    _reconnectAttempts = 0;
    _emitEvent({'type': 'stopped'});
  }

  /// 发送认证消息
  Future<void> _sendAuthMessage() async {
    final authMessage = {
      'type': 'auth',
      'id': _generateId(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'role': 'client',
      'pairingKey': _config!.pairingKey,
      'clientInfo': {
        'platform': _getPlatform(),
        'version': '2.0.7',
        'deviceId': await _getDeviceId(),
        'deviceName': _config!.deviceName,
      }
    };

    _channel!.sink.add(jsonEncode(authMessage));
  }

  /// 处理收到的消息
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      debugPrint('[API转发] 收到消息: $type, 数据: $data');

      switch (type) {
        case 'response':
          _handleResponse(data);
          break;

        case 'request':
          _handleApiRequest(data);
          break;

        case 'error':
          debugPrint('[API转发] 收到错误: ${data['message']}');
          break;

        case 'ping':
          _sendPong();
          break;

        case 'pong':
          // 心跳响应
          break;
      }
    } catch (e) {
      debugPrint('[API转发] 处理消息失败: $e');
    }
  }

  /// 处理响应消息
  void _handleResponse(Map<String, dynamic> data) {
    final success = data['success'] as bool?;
    final message = data['message'] as String?;

    if (success == true) {
      if (data.containsKey('matchedPeer')) {
        // 配对成功
        debugPrint('[API转发] 认证成功，已匹配对端');
        _isConnected = true;
        _isAuthenticated = true;
        _isWaitingForPeer = false;
        _reconnectAttempts = 0;
        _emitEvent({
          'type': 'connected',
          'pairingKey': _config!.pairingKey,
          'message': '已连接到前端',
        });
      } else if (message?.contains('等待') == true) {
        // 等待对端连接
        debugPrint('[API转发] 等待对端连接...');
        _isConnected = true;
        _isWaitingForPeer = true;
        _isAuthenticated = false;
        _emitEvent({
          'type': 'waiting',
          'message': '等待前端连接...',
        });
      }
    }
  }

  /// 处理 API 请求
  Future<void> _handleApiRequest(Map<String, dynamic> request) async {
    final requestId = request['requestId'] as String;
    final pluginId = request['pluginId'] as String;
    final methodName = request['methodName'] as String;
    final params = request['params'] as Map<String, dynamic>?;

    debugPrint('[API转发] 调用: $pluginId.$methodName');

    try {
      // 获取插件
      final jsBridge = JSBridgeManager.instance;
      final plugin = jsBridge.getPlugin(pluginId);

      if (plugin == null) {
        throw Exception('插件不存在: $pluginId');
      }

      // 检查插件是否混入了 JSBridgePlugin
      Map<String, Function>? apis;
      if (plugin is JSBridgePlugin) {
        apis = plugin.defineJSAPI();
      }

      if (apis == null || !apis.containsKey(methodName)) {
        throw Exception('方法不存在: $pluginId.$methodName');
      }

      // 调用方法
      final method = apis[methodName]!;
      final result = await Function.apply(method, [params]);

      debugPrint('[API转发] 调用成功，结果: $result');

      // 返回成功响应
      _sendResponse(requestId, true, result);
      debugPrint('[API转发] 响应已发送');
    } catch (e) {
      debugPrint('[API转发] 调用失败: $e');
      _sendResponse(
        requestId,
        false,
        null,
        error: {
          'code': 'METHOD_ERROR',
          'message': e.toString(),
        },
      );
    }
  }

  /// 发送响应
  void _sendResponse(
    String requestId,
    bool success,
    dynamic result, {
    Map<String, dynamic>? error,
  }) {
    final response = {
      'type': 'response',
      'id': _generateId(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'requestId': requestId,
      'success': success,
      if (success) 'result': result,
      if (!success) 'error': error,
    };

    debugPrint('[API转发] 发送响应: ${jsonEncode(response)}');
    _channel!.sink.add(jsonEncode(response));
  }

  /// 发送 Pong
  void _sendPong() {
    final pong = {
      'type': 'pong',
      'id': _generateId(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _channel!.sink.add(jsonEncode(pong));
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        final ping = {
          'type': 'ping',
          'id': _generateId(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        _channel!.sink.add(jsonEncode(ping));
      }
    });
  }

  /// 启动重连
  void _startReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[API转发] 达到最大重连次数');
      _emitEvent({
        'type': 'error',
        'message': '达到最大重连次数',
      });
      return;
    }

    // 指数退避
    final delay = _baseReconnectDelay * (1 << _reconnectAttempts);

    debugPrint('[API转发] ${delay}ms 后重连 (尝试 $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      _reconnectAttempts++;
      if (_config?.enabled == true) {
        try {
          await start(_config!);
        } catch (e) {
          // 继续重连
          _startReconnect();
        }
      }
    });
  }

  /// 发送事件
  void _emitEvent(Map<String, dynamic> event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// 生成消息 ID
  String _generateId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 获取平台名称
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 获取设备 ID
  Future<String> _getDeviceId() async {
    // 简化处理，实际可以使用 device_info_plus
    return 'client_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}
