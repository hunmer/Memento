# WebSocket 实时同步协议

## 概述

Memento 使用 WebSocket 实现多设备间的实时文件同步通知。当一台设备修改文件并推送到服务器后，服务器通过 WebSocket 通知其他在线设备拉取更新。

## 连接流程

```
┌─────────┐                    ┌─────────┐                    ┌─────────┐
│ Client  │                    │ Server  │                    │  Other  │
│ Device A│                    │         │                    │ Devices │
└────┬────┘                    └────┬────┘                    └────┬────┘
     │                              │                              │
     │  1. WebSocket Handshake      │                              │
     │  WS: /api/v1/sync/ws         │                              │
     │ ─────────────────────────────>│                              │
     │                              │                              │
     │  2. Auth Message             │                              │
     │  {"type":"auth",...}         │                              │
     │ ─────────────────────────────>│                              │
     │                              │                              │
     │  3. Auth Success             │                              │
     │  {"type":"auth_success",...} │                              │
     │ <─────────────────────────────│                              │
     │                              │                              │
     │  4. File Update              │                              │
     │  HTTP POST /api/v1/sync/push │                              │
     │ ─────────────────────────────>│                              │
     │                              │  5. Broadcast Notification   │
     │                              │  {"type":"file_updated",...}  │
     │                              │ ──────────────────────────────>│
     │                              │                              │
     │  6. Heartbeat (ping/pong)    │                              │
     │  <──────────────────────────>│                              │
     │                              │                              │
```

## 客户端实现

### 连接地址

```
ws://{server}/api/v1/sync/ws
```

- 开发环境: `ws://127.0.0.1:8874/api/v1/sync/ws`
- 生产环境: `wss://your-server.com/api/v1/sync/ws`

### 认证消息

连接建立后，客户端必须在 **5 秒内** 发送认证消息：

```json
{
  "type": "auth",
  "token": "<JWT_TOKEN>",
  "device_id": "<DEVICE_ID>"
}
```

### 认证成功响应

```json
{
  "type": "auth_success",
  "user_id": "<USER_ID>"
}
```

### 认证失败响应

```json
{
  "type": "auth_error",
  "error": "<ERROR_MESSAGE>"
}
```

认证失败后，服务器会关闭连接。

### 心跳机制

客户端每 30 秒发送心跳：

```json
{
  "type": "ping"
}
```

服务器响应：

```json
{
  "type": "pong"
}
```

### 文件更新通知

当其他设备推送文件更新时，服务器广播：

```json
{
  "type": "file_updated",
  "data": {
    "file_path": "diary/2024/01/15.json",
    "md5": "abc123...",
    "modified_at": "2024-01-15T10:30:00.000Z",
    "source_device_id": "device_123"
  }
}
```

### Dart 客户端代码示例

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SyncWebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  Future<void> connect({
    required String serverUrl,
    required String token,
    required String deviceId,
  }) async {
    // 转换 HTTP URL 为 WebSocket URL
    final wsUrl = serverUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final uri = Uri.parse('$wsUrl/api/v1/sync/ws');

    _channel = IOWebSocketChannel.connect(uri);
    await _channel!.ready;

    // 发送认证消息
    _channel!.sink.add(jsonEncode({
      'type': 'auth',
      'token': token,
      'device_id': deviceId,
    }));

    // 订阅消息
    _subscription = _channel!.stream.listen(_handleMessage);

    // 启动心跳
    _startPingTimer();
  }

  void _handleMessage(dynamic message) {
    final data = jsonDecode(message as String) as Map<String, dynamic>;
    final type = data['type'] as String?;

    switch (type) {
      case 'auth_success':
        print('认证成功: ${data['user_id']}');
        break;
      case 'auth_error':
        print('认证失败: ${data['error']}');
        disconnect();
        break;
      case 'file_updated':
        _handleFileUpdated(data['data']);
        break;
      case 'pong':
        // 心跳响应
        break;
    }
  }

  void _handleFileUpdated(Map<String, dynamic> data) {
    final filePath = data['file_path'] as String;
    final sourceDeviceId = data['source_device_id'] as String;

    // 忽略来自本设备的更新
    if (sourceDeviceId == _deviceId) return;

    // 拉取更新
    _pullFile(filePath);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'type': 'ping'}));
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
  }
}
```

## 服务端实现

### 路由配置

```dart
// bin/server.dart

// 创建 WebSocket handler
final wsHandler = _createAuthenticatedWebSocketHandler(
  authService: authService,
  webSocketManager: webSocketManager,
  logger: logger,
);

// 挂载路由
router.get('/api/v1/sync/ws', wsHandler);
```

### 认证处理

```dart
Handler _createAuthenticatedWebSocketHandler({
  required AuthService authService,
  required WebSocketManager webSocketManager,
  required Logger logger,
}) {
  return webSocketHandler((channel, protocol) async {
    // 设置认证超时
    final authCompleter = Completer<Map<String, dynamic>?>();

    // 监听首条消息
    final subscription = channel.stream.listen(
      (message) {
        if (!authCompleter.isCompleted) {
          final data = jsonDecode(message);
          if (data['type'] == 'auth') {
            authCompleter.complete(data);
          } else {
            authCompleter.complete(null);
          }
        }
      },
      onDone: () => authCompleter.complete(null),
    );

    // 等待认证（5秒超时）
    final authData = await authCompleter.future.timeout(
      Duration(seconds: 5),
      onTimeout: () => null,
    );

    await subscription.cancel();

    // 验证认证信息
    if (authData == null) {
      channel.sink.add(jsonEncode({
        'type': 'auth_error',
        'error': '认证超时',
      }));
      await channel.sink.close();
      return;
    }

    final token = authData['token'];
    final deviceId = authData['device_id'];
    final payload = authService.verifyToken(token);

    if (payload == null) {
      channel.sink.add(jsonEncode({
        'type': 'auth_error',
        'error': '无效的 token',
      }));
      await channel.sink.close();
      return;
    }

    final userId = payload['sub'];

    // 发送成功响应
    channel.sink.add(jsonEncode({
      'type': 'auth_success',
      'user_id': userId,
    }));

    // 注册连接
    webSocketManager.registerChannel(userId, deviceId, channel);
  });
}
```

### 连接管理器

```dart
// lib/services/websocket_manager.dart

class WebSocketManager {
  // userId -> deviceId -> WebSocketConnection
  final Map<String, Map<String, WebSocketConnection>> _connections = {};

  /// 注册连接
  void registerChannel(String userId, String deviceId, WebSocketChannel channel) {
    _connections.putIfAbsent(userId, () => {});
    _connections[userId]![deviceId] = WebSocketConnection(
      userId: userId,
      deviceId: deviceId,
      channel: channel,
      connectedAt: DateTime.now(),
    );

    // 监听连接关闭
    channel.stream.listen(
      (message) => _handleMessage(userId, deviceId, message),
      onDone: () => unregister(userId, deviceId),
    );
  }

  /// 广播文件更新
  void broadcastFileUpdate(
    String userId,
    String filePath,
    String md5,
    DateTime modifiedAt,
    String sourceDeviceId,
  ) {
    final userConnections = _connections[userId];
    if (userConnections == null) return;

    final message = jsonEncode({
      'type': 'file_updated',
      'data': {
        'file_path': filePath,
        'md5': md5,
        'modified_at': modifiedAt.toUtc().toIso8601String(),
        'source_device_id': sourceDeviceId,
      },
    });

    for (final entry in userConnections.entries) {
      // 排除源设备
      if (entry.key == sourceDeviceId) continue;

      try {
        entry.value.channel.sink.add(message);
      } catch (e) {
        unregister(userId, entry.key);
      }
    }
  }

  /// 注销连接
  void unregister(String userId, String deviceId) {
    _connections[userId]?.remove(deviceId);
    if (_connections[userId]?.isEmpty ?? false) {
      _connections.remove(userId);
    }
  }
}
```

### 在文件推送时广播

```dart
// lib/routes/sync_routes.dart

Future<Response> _handlePush(Request request) async {
  // ... 保存文件 ...

  // 广播更新通知
  if (_webSocketManager != null) {
    _webSocketManager!.broadcastFileUpdate(
      userId,
      filePath,
      newMd5,
      DateTime.now(),
      deviceId,  // 来源设备 ID
    );
  }

  return Response.ok(...);
}
```

## 防循环更新机制

为避免更新循环（A 推送 → B 收到通知 → B 拉取 → B 推送 → A 收到通知...），采用以下策略：

1. **源设备排除**: 广播时排除触发更新的设备
2. **MD5 比较**: 如果本地 MD5 与通知中的 MD5 相同，跳过拉取
3. **时间窗口**: 记录最近上传的文件，短时间内不重复拉取

```dart
void _handleFileUpdated(Map<String, dynamic> data) {
  // 1. 排除本设备
  if (data['source_device_id'] == _deviceId) return;

  // 2. MD5 比较
  final localMd5 = await _getLocalMd5(data['file_path']);
  if (localMd5 == data['md5']) return;

  // 3. 检查最近上传
  if (_wasRecentlyUploaded(data['file_path'])) return;

  // 拉取更新
  await _pullFile(data['file_path']);
}
```

## 错误处理

### 连接断开

- 客户端检测到连接断开后，应等待 5 秒后重连
- 重连时需要重新发送认证消息

### 认证失败

- 检查 token 是否有效
- 检查 token 是否过期
- 可能需要重新登录获取新 token

### 超时处理

- 认证超时: 5 秒
- 心跳超时: 60 秒无响应则断开重连

## 依赖

### 服务端 (pubspec.yaml)

```yaml
dependencies:
  shelf_web_socket: ^3.0.0
  web_socket_channel: ^3.0.0
```

### 客户端 (pubspec.yaml)

```yaml
dependencies:
  web_socket_channel: ^3.0.0
```
