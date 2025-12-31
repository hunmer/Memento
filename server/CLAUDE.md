# Memento 同步服务器 (Memento Sync Server)

[根目录](../CLAUDE.md) > **server**

---

## 模块概述

Memento 同步服务器是基于 Dart 和 Shelf 框架开发的轻量级 Web 服务，提供端到端加密的文件同步和插件数据 API。服务器采用纯文件存储，无需数据库依赖，所有用户数据以加密形式存储，服务器无法解密。

### 核心特性

- **端到端加密**：所有文件数据由客户端加密后存储，服务器无法解密
- **JWT 认证**：基于 JWT Token 的用户认证机制
- **插件 API**：为 19 个插件提供 RESTful API 接口
- **冲突检测**：基于 MD5 的文件同步冲突检测
- **ZIP 导出**：支持导出用户数据为 ZIP 文件
- **管理界面**：内置 Web 管理界面（`/admin/`）

### 技术栈

- **框架**: Shelf (Dart Web 框架)
- **认证**: JWT (dart_jsonwebtoken)
- **加密**: 客户端负责加密，服务器仅存储密文
- **路由**: shelf_router
- **CORS**: shelf_cors_headers

---

## 项目结构

```
server/
├── bin/
│   └── server.dart              # 服务器入口
├── lib/
│   ├── config/
│   │   └── server_config.dart   # 服务器配置
│   ├── middleware/
│   │   ├── auth_middleware.dart # JWT 认证中间件
│   │   └── api_enabled_middleware.dart  # API 启用中间件
│   ├── routes/
│   │   ├── auth_routes.dart     # 认证路由
│   │   ├── sync_routes.dart     # 同步路由
│   │   └── plugin_routes/       # 插件路由目录
│   │       ├── chat_routes.dart
│   │       ├── notes_routes.dart
│   │       └── ... (19 个插件)
│   ├── services/
│   │   ├── auth_service.dart    # 认证服务
│   │   ├── file_storage_service.dart  # 文件存储服务
│   │   ├── encryption_service.dart    # 加密服务
│   │   └── plugin_data_service.dart   # 插件数据服务
│   └── repositories/            # 数据仓储层
│       ├── server_activity_repository.dart
│       ├── server_agent_chat_repository.dart
│       └── ... (对应各插件)
├── test/                        # 测试文件
├── admin/                       # 管理界面静态文件
├── pubspec.yaml                 # 项目配置
└── .env                         # 环境变量配置
```

---

## 核心架构

### 服务层架构

```
server.dart (入口)
  │
  ├── ServerConfig (配置)
  │   ├── 从环境变量加载
  │   └── 数据目录、端口、JWT 密钥
  │
  ├── AuthService (认证服务)
  │   ├── 注册用户
  │   ├── 登录验证
  │   ├── Token 生成与验证
  │   └── 用户 Salt 管理
  │
  ├── FileStorageService (文件存储服务)
  │   ├── 用户数据目录管理
  │   ├── 加密文件读写
  │   ├── 文件列表与删除
  │   ├── 同步日志记录
  │   └── 目录树生成
  │
  ├── PluginDataService (插件数据服务)
  │   ├── 管理 19 个插件的 Repository
  │   ├── API 启用/禁用控制
  │   └── 数据的 CRUD 操作
  │
  └── Routes (路由层)
      ├── /health              # 健康检查
      ├── /version             # 版本信息
      ├── /admin/*             # 管理界面
      ├── /api/v1/auth/*       # 认证 API
      ├── /api/v1/sync/*       # 同步 API (需认证)
      └── /api/v1/plugins/*    # 插件 API (需认证 + API 启用)
          ├── chat
          ├── notes
          ├── activity
          ├── goods
          ├── bill
          ├── todo
          ├── agent_chat
          ├── calendar_album
          ├── calendar
          ├── checkin
          ├── contact
          ├── database
          ├── day
          ├── diary
          ├── nodes
          ├── openai
          ├── store
          ├── timer
          └── tracker
```

---

## API 端点

### 公开端点

| 端点 | 方法 | 说明 |
|-----|------|------|
| `/health` | GET | 健康检查 |
| `/version` | GET | 版本信息 |
| `/` | GET | 重定向到管理界面 |
| `/admin/` | GET | 管理界面主页 |
| `/admin/*` | GET | 管理界面静态资源 |

### 认证 API (`/api/v1/auth`)

| 端点 | 方法 | 说明 |
|-----|------|------|
| `/register` | POST | 用户注册 |
| `/login` | POST | 用户登录 |
| `/enable-api` | POST | 启用 API 访问 |
| `/disable-api` | POST | 禁用 API 访问 |
| `/api-status` | GET | API 状态查询 |

#### 注册请求示例

```json
{
  "username": "user@example.com",
  "password": "user_password",
  "device_id": "device_unique_id",
  "device_name": "My Phone"
}
```

#### 注册响应示例

```json
{
  "success": true,
  "user_id": "uuid",
  "token": "jwt_token",
  "expires_at": "2125-01-01T00:00:00.000Z",
  "user_salt": "salt_for_client_encryption"
}
```

### 同步 API (`/api/v1/sync`) - 需认证

| 端点 | 方法 | 说明 |
|-----|------|------|
| `/push` | POST | 推送加密文件 |
| `/pull/<filePath>` | GET | 拉取加密文件 |
| `/list` | GET | 列出用户所有文件 |
| `/delete/<filePath>` | DELETE | 删除文件 |
| `/status` | GET | 同步状态 |
| `/tree` | GET | 获取目录树结构 |
| `/export` | POST | 导出 ZIP 文件 |
| `/download/<fileName>` | GET | 下载导出文件 |

#### 推送文件示例

```json
{
  "file_path": "configs/chat/settings.json",
  "encrypted_data": "base64_encrypted_content",
  "old_md5": "previous_md5",
  "new_md5": "current_md5"
}
```

#### 冲突响应 (409)

```json
{
  "success": false,
  "error": "conflict",
  "file_path": "configs/chat/settings.json",
  "server_data": "server_encrypted_data",
  "server_md5": "server_file_md5",
  "server_updated_at": "2025-01-01T00:00:00.000Z"
}
```

### 插件 API (`/api/v1/plugins/*`) - 需认证 + API 启用

每个插件提供标准的 CRUD 操作：

| 端点 | 方法 | 说明 |
|-----|------|------|
| `/<plugin>/items` | GET | 获取所有项目 |
| `/<plugin>/item/<id>` | GET | 获取单个项目 |
| `/<plugin>/item` | POST | 创建项目 |
| `/<plugin>/item/<id>` | PUT | 更新项目 |
| `/<plugin>/item/<id>` | DELETE | 删除项目 |

---

## 核心服务

### AuthService (认证服务)

**文件**: `lib/services/auth_service.dart`

**职责**:
- 用户注册和登录
- JWT Token 生成和验证
- 用户 Salt 管理（用于客户端加密密钥派生）
- 设备信息管理

**关键方法**:

```dart
class AuthService {
  // 注册新用户
  Future<AuthResponse> register(RegisterRequest request);

  // 用户登录
  Future<AuthResponse> login(LoginRequest request);

  // 刷新 Token
  Future<AuthResponse> refreshToken(RefreshTokenRequest request);

  // 验证 Token
  Map<String, dynamic>? verifyToken(String token);

  // 从 Token 获取用户 ID
  String? getUserIdFromToken(String token);
}
```

**Token 有效期**: 默认 36500 天（100 年），实际为永久有效

---

### FileStorageService (文件存储服务)

**文件**: `lib/services/file_storage_service.dart`

**职责**:
- 管理用户数据目录（按用户 ID 隔离）
- 加密文件的读写操作
- 文件 MD5 校验
- 同步日志记录
- 目录树生成
- ZIP 导出

**关键方法**:

```dart
class FileStorageService {
  // 读取加密文件
  Future<Map<String, dynamic>?> readEncryptedFile(
    String userId,
    String filePath,
  );

  // 写入加密文件
  Future<void> writeEncryptedFile(
    String userId,
    String filePath,
    String encryptedData,
    String md5,
  );

  // 列出用户文件
  Future<List<Map<String, dynamic>>> listUserFiles(String userId);

  // 删除文件
  Future<bool> deleteFile(String userId, String filePath);

  // 获取目录树
  Future<DirectoryTree> getDirectoryTree(String userId);

  // 导出为 ZIP
  Future<Map<String, dynamic>> exportUserDataAsZip(String userId);

  // 记录同步日志
  Future<void> logSync({
    required String userId,
    required String action,
    required String filePath,
    String? details,
  });
}
```

**目录结构**:
```
data/
├── users/
│   ├── <user_id>/
│   │   ├── configs/
│   │   ├── app_data/
│   │   ├── exports/
│   │   └── sync_logs.json
│   └── ...
└── .index/
    └── users.json
```

---

### PluginDataService (插件数据服务)

**文件**: `lib/services/plugin_data_service.dart`

**职责**:
- 管理 19 个插件的 Repository
- API 启用/禁用控制（按用户维度）
- 插件数据的 CRUD 操作代理

**支持的插件**:
```dart
const supportedPlugins = [
  'chat', 'notes', 'activity', 'goods', 'bill',
  'todo', 'agent_chat', 'calendar_album', 'calendar',
  'checkin', 'contact', 'database', 'day', 'diary',
  'nodes', 'openai', 'store', 'timer', 'tracker'
];
```

**关键方法**:
```dart
class PluginDataService {
  // 获取插件的 Repository
  dynamic getPluginRepository(String pluginId);

  // 检查用户是否启用了插件的 API 访问
  bool isPluginApiEnabled(String userId, String pluginId);

  // 启用插件 API
  void enablePluginApi(String userId, String pluginId);

  // 禁用插件 API
  void disablePluginApi(String userId, String pluginId);
}
```

---

### ServerConfig (服务器配置)

**文件**: `lib/config/server_config.dart`

**环境变量配置**:

| 变量名 | 默认值 | 说明 |
|-------|--------|------|
| `SERVER_PORT` | 8080 | 服务器监听端口 |
| `SERVER_DATA_DIR` | ./data | 用户数据存储目录 |
| `JWT_SECRET` | (随机生成) | JWT 签名密钥 |
| `TOKEN_EXPIRY_DAYS` | 36500 | Token 有效期（天） |
| `CORS_ENABLED` | true | 是否启用 CORS |
| `CORS_ORIGINS` | * | CORS 允许的源 |

**.env 示例**:
```env
SERVER_PORT=8080
SERVER_DATA_DIR=./data
JWT_SECRET=your-secret-key-here
TOKEN_EXPIRY_DAYS=36500
CORS_ENABLED=true
CORS_ORIGINS=*
```

---

## 中间件

### AuthMiddleware (认证中间件)

**文件**: `lib/middleware/auth_middleware.dart`

**职责**:
- 验证 JWT Token
- 从 Token 中提取用户 ID
- 将用户 ID 添加到请求上下文

**使用**:
```dart
Pipeline()
  .addMiddleware(authMiddleware(authService))
  .addHandler(syncRoutes.router.call)
```

### ApiEnabledMiddleware (API 启用中间件)

**文件**: `lib/middleware/api_enabled_middleware.dart`

**职责**:
- 检查用户是否启用了指定插件的 API 访问
- 如果未启用，返回 403 Forbidden

**使用**:
```dart
Pipeline()
  .addMiddleware(authMiddleware(authService))
  .addMiddleware(apiEnabledMiddleware(pluginDataService))
  .addHandler(pluginRoutes.router.call)
```

---

## 插件路由

### 路由模式

每个插件路由遵循相同的模式：

```dart
class PluginRoutes {
  final PluginDataService _dataService;

  Router get router {
    final router = Router();

    // GET /items - 获取所有项目
    router.get('/items', _getItems);

    // GET /item/<id> - 获取单个项目
    router.get('/item/<id>', _getItem);

    // POST /item - 创建项目
    router.post('/item', _createItem);

    // PUT /item/<id> - 更新项目
    router.put('/item/<id>', _updateItem);

    // DELETE /item/<id> - 删除项目
    router.delete('/item/<id>', _deleteItem);

    return router;
  }
}
```

### 插件 Repository

每个插件对应一个 Repository 类，位于 `lib/repositories/` 目录：

- `ServerActivityRepository`
- `ServerAgentChatRepository`
- `ServerBillRepository`
- `ServerCalendarRepository`
- 等等...

**Repository 示例**:
```dart
class ServerChatRepository {
  final PluginDataService _dataService;

  Future<List<Map<String, dynamic>>> getItems(String userId) async {
    final enabled = _dataService.isPluginApiEnabled(userId, 'chat');
    if (!enabled) throw Exception('API not enabled');

    // 读取并返回数据
  }
}
```

---

## 安全特性

### 端到端加密

1. **客户端加密**: 所有文件数据由客户端使用 AES 加密
2. **用户 Salt**: 服务器为每个用户生成唯一的 Salt，用于客户端密钥派生
3. **密文存储**: 服务器仅存储加密后的数据，无法解密
4. **MD5 校验**: 使用 MD5 检测文件变化和冲突

### 冲突检测

同步推送时：
1. 客户端提供 `old_md5`（上次同步时的 MD5）
2. 服务器检查当前文件的 MD5
3. 如果 MD5 不匹配，返回 409 Conflict
4. 客户端根据策略处理冲突（服务器优先/客户端优先/手动合并）

### 路径安全

- 防止路径遍历攻击：拒绝包含 `..` 或以 `/` 开头的路径
- 文件名验证：导出文件名中拒绝包含 `..` 或 `/`

---

## 启动与运行

### 安装依赖

```bash
cd server
dart pub get
```

### 配置环境变量

创建 `.env` 文件或设置环境变量。

### 运行服务器

```bash
dart run bin/server.dart
```

### 输出示例

```
====================================
  Memento Sync Server
  http://0.0.0.0:8080
====================================

可用端点:
  GET  /                    - 重定向到管理界面
  GET  /admin               - 管理界面
  GET  /health              - 健康检查
  GET  /version             - 版本信息
  POST /api/v1/auth/register - 用户注册
  POST /api/v1/auth/login    - 用户登录
  POST /api/v1/auth/enable-api  - 启用 API 访问
  POST /api/v1/auth/disable-api - 禁用 API 访问
  GET  /api/v1/auth/api-status  - API 状态查询
  POST /api/v1/sync/push     - 推送文件 (需认证)
  GET  /api/v1/sync/pull/*   - 拉取文件 (需认证)
  GET  /api/v1/sync/list     - 文件列表 (需认证)
```

---

## 测试

### 运行测试

```bash
cd server
dart test
```

### 测试文件

- `test/routes/chat_routes_test.dart`
- `test/routes/notes_routes_test.dart`
- `test/routes/todo_routes_test.dart`
- `test/test_helpers.dart`

---

## 常见问题

### Q1: 如何修改 JWT 密钥？

在 `.env` 文件中设置 `JWT_SECRET`：

```env
JWT_SECRET=your-very-secure-secret-key
```

### Q2: 如何备份数据？

用户数据存储在 `data/users/` 目录。可以直接复制该目录进行备份，或使用 `/api/v1/sync/export` 端点导出 ZIP 文件。

### Q3: 如何重置用户密码？

由于服务器只存储密码哈希，无法直接重置密码。用户需要：
1. 重新注册（使用相同的用户名会提示已存在）
2. 或者在客户端实现"忘记密码"功能

### Q4: 如何禁用某个用户的插件 API？

调用 `/api/v1/auth/disable-api` 端点：

```bash
curl -X POST http://localhost:8080/api/v1/auth/disable-api \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"plugin_id": "chat"}'
```

### Q5: 如何添加新的插件 API？

1. 在 `lib/repositories/` 创建 `server_<plugin>_repository.dart`
2. 在 `lib/routes/plugin_routes/` 创建 `<plugin>_routes.dart`
3. 在 `bin/server.dart` 中挂载新路由
4. 在 `PluginDataService` 中注册插件

### Q6: 服务器能查看用户数据吗？

**不能**。所有文件数据由客户端使用用户 Salt 派生的密钥加密后存储。服务器只能看到密文，无法解密。

### Q7: 如何修改数据存储目录？

在 `.env` 文件中设置 `SERVER_DATA_DIR`：

```env
SERVER_DATA_DIR=/path/to/data
```

---

## 相关文档

- [shared_models - 共享数据模型](../shared_models/CLAUDE.md)
- [lib/core - 核心功能](../lib/core/CLAUDE.md)
- [lib/plugins - 插件系统](../lib/plugins/CLAUDE.md)
