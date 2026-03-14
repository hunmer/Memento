# 双向数据同步实现文档

## 概述

本次实现为 Memento 添加了完整的双向数据同步功能，支持从服务端主动拉取新文件（例如通过 MCP 更新的数据），并实时通知在线客户端。

## 功能特性

- ✅ 推送成功后记录文件和最后修改日期
- ✅ 同步时比较服务端/客户端时间戳决定同步方向
- ✅ WebSocket 实时通知客户端文件更新
- ✅ 当前路由匹配时自动刷新页面
- ✅ 多层防循环更新机制

---

## 新增文件

### 1. 同步记录服务

**文件**: `lib/core/services/sync_record_service.dart`

**职责**:
- 记录推送成功时间（`last_upload_time`）
- 记录服务器文件修改时间（`server_modified_time`）
- 判断是否需要从服务端拉取

**数据模型** (`configs/sync_records.json`):
```json
{
  "version": 1,
  "last_updated": "2026-03-14T10:00:00Z",
  "records": {
    "diary/2024-01-01.json": {
      "last_upload_time": "2026-03-14T09:30:00Z",
      "server_modified_time": "2026-03-14T09:30:00Z"
    }
  }
}
```

**核心方法**:
| 方法 | 说明 |
|------|------|
| `recordUpload(filePath, serverTime)` | 推送成功后记录 |
| `recordPull(filePath, serverTime)` | 拉取成功后记录 |
| `needsPull(filePath, serverModifiedTime)` | 判断是否需要拉取 |
| `wasRecentlyUploaded(filePath)` | 检查5秒内是否上传过 |

---

### 2. 服务端 WebSocket 管理器

**文件**: `server/lib/services/websocket_manager.dart`

**职责**:
- 管理客户端 WebSocket 连接（按 userId/deviceId 组织）
- 广播文件更新通知（自动排除源设备）
- 连接生命周期管理

**连接存储结构**:
```dart
// userId -> deviceId -> WebSocketConnection
Map<String, Map<String, WebSocketConnection>> _connections
```

**消息协议** (服务端 -> 客户端):
```json
{
  "type": "file_updated",
  "data": {
    "file_path": "diary/2024-01-01.json",
    "md5": "abc123...",
    "modified_at": "2026-03-14T10:00:00Z",
    "source_device_id": "device_456"
  }
}
```

**核心方法**:
| 方法 | 说明 |
|------|------|
| `register(userId, deviceId, socket)` | 注册新连接 |
| `unregister(userId, deviceId)` | 注销连接 |
| `broadcastFileUpdate(...)` | 广播文件更新（排除源设备） |
| `isUserOnline(userId)` | 检查用户是否在线 |

---

### 3. 客户端 WebSocket 服务

**文件**: `lib/core/services/sync_websocket_service.dart`

**职责**:
- 与服务器建立 WebSocket 连接
- 接收文件更新通知
- 触发文件拉取和路由刷新
- 防循环更新机制

**连接参数**:
```dart
connect({
  required String serverUrl,
  required String token,
  required String deviceId,
})
```

**配置常量**:
| 常量 | 值 | 说明 |
|------|-----|------|
| `_reconnectIntervalSeconds` | 5 | 重连间隔（秒） |
| `_pingIntervalSeconds` | 30 | 心跳间隔（秒） |

---

### 4. 路由刷新管理器

**文件**: `lib/core/route/route_refresh_manager.dart`

**职责**:
- 根据文件路径判断对应的插件
- 检查当前路由是否匹配
- 触发插件刷新事件

**文件路径 -> 插件ID 映射**:
```dart
const Map<String, String> _fileToPlugin = {
  'diary/': 'diary',
  'chat/': 'chat',
  'notes/': 'notes',
  'todo/': 'todo',
  'activity/': 'activity',
  'bill/': 'bill',
  'tracker/': 'tracker',
  'goods/': 'goods',
  'contact/': 'contact',
  'habits/': 'habits',
  'checkin/': 'checkin',
  'calendar/': 'calendar',
  'calendar_album/': 'calendar_album',
  'timer/': 'timer',
  'database/': 'database',
  'day/': 'day',
  'nodes/': 'nodes',
  'store/': 'store',
};
```

**刷新事件**:
- `${pluginId}_refresh` - 插件特定刷新事件
- `sync_data_updated` - 通用数据更新事件

---

## 修改的文件

### 1. 客户端同步服务

**文件**: `lib/core/services/sync_client_service.dart`

**新增/修改**:

| 方法 | 说明 |
|------|------|
| `bidirectionalSync(filePath)` | **新增** - 双向同步，自动判断推送/拉取方向 |
| `getServerFileInfo(filePath)` | **新增** - 获取服务端文件元信息 |
| `syncFile(filePath)` | **修改** - 推送成功后记录到 SyncRecordService |
| `pullFile(filePath)` | **修改** - 拉取成功后记录到 SyncRecordService |
| `_authHeaders()` | **修改** - 添加 `X-Device-ID` 请求头 |

**双向同步逻辑**:
```
1. 获取服务端文件信息
2. 如果服务端没有此文件 → 推送
3. 比较时间戳:
   - 服务端修改时间 > 本地最后上传时间 → 拉取
   - 否则 → 推送
```

---

### 2. 服务端同步路由

**文件**: `server/lib/routes/sync_routes.dart`

**新增端点**:

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/v1/sync/info/<filePath>` | GET | 获取文件元信息（不含内容） |

**响应示例**:
```json
{
  "success": true,
  "exists": true,
  "file_path": "diary/2024-01-01.json",
  "md5": "abc123...",
  "modified_at": "2026-03-14T10:00:00Z",
  "size": 1024
}
```

**修改 `_handlePush()`**:
- 推送成功后通过 WebSocketManager 广播文件更新通知

---

### 3. 服务端认证中间件

**文件**: `server/lib/middleware/auth_middleware.dart`

**新增函数**:
```dart
/// 从请求头获取设备 ID
String? getDeviceIdFromContext(Request request) {
  return request.headers['x-device-id'];
}
```

---

### 4. 服务端入口

**文件**: `server/bin/server.dart`

**修改**:
```dart
// 初始化 WebSocket 管理器
final webSocketManager = WebSocketManager();
logger.info('WebSocket 管理器初始化完成');

// 同步路由 (传递 WebSocketManager)
final syncRoutes = SyncRoutes(storageService, webSocketManager);
```

---

## 防循环更新机制

```
┌─────────────────────────────────────────────────────────────┐
│                    多层防护机制                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  第1层: 设备ID过滤                                          │
│  ┌──────────┐    推送携带 device_id    ┌──────────────┐    │
│  │ Client A │ ──────────────────────> │ Server       │    │
│  │ device_1 │                         │              │    │
│  └──────────┘                         └──────────────┘    │
│                                              │             │
│                                              │ 广播排除    │
│                                              │ device_1    │
│  ┌──────────┐                         ┌──────▼──────┐    │
│  │ Client B │ <───────────────────────│ WebSocket   │    │
│  │ device_2 │   source_device_id      │             │    │
│  └──────────┘                         └─────────────┘    │
│                                                            │
│  第2层: 时间窗口防护                                        │
│  上传后 5 秒内忽略来自服务端的同一文件通知                   │
│                                                            │
│  第3层: MD5 比对                                           │
│  如果通知中的 MD5 与本地 MD5 相同，跳过拉取                 │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 使用示例

### 客户端初始化

```dart
// 1. 初始化同步记录服务
final recordService = SyncRecordService();
await recordService.initialize(storage);

// 2. 初始化同步客户端
final syncClient = SyncClientService(
  serverUrl: 'https://sync.example.com',
  storage: storage,
  encryption: encryption,
  recordService: recordService,
);
await syncClient.initialize(
  token: token,
  userId: userId,
  deviceId: deviceId,
);

// 3. 初始化 WebSocket 服务
final wsService = SyncWebSocketService();
wsService.configure(
  syncClientService: syncClient,
  recordService: recordService,
  routeRefreshManager: RouteRefreshManager(),
);
await wsService.connect(
  serverUrl: 'https://sync.example.com',
  token: token,
  deviceId: deviceId,
);
```

### 执行双向同步

```dart
// 单个文件双向同步
final result = await syncClient.bidirectionalSync('diary/2024-01-01.json');

// 全量同步（使用双向逻辑）
final results = await syncClient.fullSync();
```

---

## API 端点汇总

| 端点 | 方法 | 说明 | 认证 |
|------|------|------|------|
| `/api/v1/sync/push` | POST | 推送加密文件 | ✅ |
| `/api/v1/sync/pull/<filePath>` | GET | 拉取加密文件 | ✅ |
| `/api/v1/sync/info/<filePath>` | GET | 获取文件元信息 | ✅ |
| `/api/v1/sync/list` | GET | 列出用户所有文件 | ✅ |
| `/api/v1/sync/delete/<filePath>` | DELETE | 删除文件 | ✅ |
| `/api/v1/sync/status` | GET | 同步状态 | ✅ |
| `/api/v1/sync/tree` | GET | 获取目录树结构 | ✅ |

---

## 验证方案

### 1. 同步记录测试
- 推送文件后检查 `configs/sync_records.json`
- 验证时间戳正确记录

### 2. 双向同步测试
- 模拟服务端文件更新，验证客户端正确拉取
- 模拟客户端更新，验证客户端正确推送

### 3. WebSocket 测试
- 开启两个客户端实例
- 在一个客户端修改文件
- 验证另一个客户端收到通知并更新

### 4. 防循环测试
- 修改文件触发上传
- 验证不会因服务端通知再次触发拉取

---

## 变更记录

- **2026-03-14**: 初始实现双向数据同步功能
