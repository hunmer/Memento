# 研究发现：Dart 后端分析

## 1. 项目概览

### 1.1 基本信息
- **路径**: `D:\Memento\server`
- **框架**: Dart + Shelf
- **描述**: Memento 同步服务器 - 端到端加密的文件同步服务

### 1.2 核心特性
- 端到端加密（服务器无法解密用户数据）
- JWT 认证 + API Key 支持
- 19 个插件的 RESTful API
- WebSocket 实时同步
- 纯文件存储（无数据库）

---

## 2. 依赖分析

### 2.1 pubspec.yaml 依赖
```yaml
dependencies:
  shelf: ^1.4.1              # Web 框架
  shelf_router: ^1.1.4       # 路由
  shelf_cors_headers: ^0.1.5 # CORS
  shelf_static: ^1.1.2       # 静态文件
  shelf_web_socket: ^3.0.0   # WebSocket
  web_socket_channel: ^3.0.0
  crypto: ^3.0.3             # MD5
  encrypt: ^5.0.3            # AES
  dart_jsonwebtoken: ^2.14.0 # JWT
  dotenv: ^4.2.0             # 环境变量
  args: ^2.5.0               # 命令行参数
  logging: ^1.2.0            # 日志
  path: ^1.9.0               # 路径处理
  uuid: ^4.3.3               # UUID
  archive: ^3.4.10           # ZIP
  shared_models:
    path: ../shared_models
```

### 2.2 Node.js 等效依赖
| Dart 包 | Node.js 包 |
|---------|------------|
| shelf | express |
| shelf_router | express.Router |
| shelf_cors_headers | cors |
| shelf_static | express.static |
| shelf_web_socket | ws + express-ws |
| crypto (dart) | crypto (Node 内置) |
| encrypt | crypto (Node 内置) |
| dart_jsonwebtoken | jsonwebtoken |
| dotenv | dotenv |
| uuid | uuid |
| archive | archiver |
| logging | winston/pino |

---

## 3. 文件结构分析

### 3.1 源文件清单
```
server/
├── bin/
│   └── server.dart          # 入口 (620 行)
├── lib/
│   ├── config/
│   │   └── server_config.dart    # 配置 (87 行)
│   ├── middleware/
│   │   ├── auth_middleware.dart       # 认证中间件 (122 行)
│   │   └── api_enabled_middleware.dart
│   ├── models/
│   │   └── api_key.dart       # API Key 模型
│   ├── repositories/
│   │   ├── server_agent_chat_repository.dart
│   │   ├── server_calendar_album_repository.dart
│   │   ├── server_calendar_repository.dart
│   │   ├── server_chat_repository.dart
│   │   ├── server_checkin_repository.dart
│   │   ├── server_database_repository.dart
│   │   ├── server_nodes_repository.dart
│   │   ├── server_openai_repository.dart
│   │   ├── server_store_repository.dart
│   │   ├── server_timer_repository.dart
│   │   ├── server_tracker_repository.dart
│   │   └── server_todo_repository.dart
│   ├── routes/
│   │   ├── auth_routes.dart   # 认证路由 (532 行)
│   │   ├── sync_routes.dart   # 同步路由 (736 行)
│   │   └── plugin_routes/
│   │       ├── activity_routes.dart
│   │       ├── agent_chat_routes.dart
│   │       ├── bill_routes.dart
│   │       ├── calendar_album_routes.dart
│   │       ├── calendar_routes.dart
│   │       ├── chat_routes.dart (330 行)
│   │       ├── checkin_routes.dart
│   │       ├── contact_routes.dart
│   │       ├── database_routes.dart
│   │       ├── day_routes.dart
│   │       ├── diary_routes.dart
│   │       ├── goods_routes.dart
│   │       ├── nodes_routes.dart
│   │       ├── notes_routes.dart
│   │       ├── openai_routes.dart
│   │       ├── store_routes.dart
│   │       ├── timer_routes.dart
│   │       ├── tracker_routes.dart
│   │       └── todo_routes.dart
│   └── services/
│       ├── auth_service.dart          # 认证服务 (296 行)
│       ├── encryption_service.dart    # 加密服务 (186 行)
│       ├── file_storage_service.dart  # 文件存储 (693 行)
│       ├── file_watcher_service.dart  # 文件监听
│       ├── plugin_data_service.dart   # 插件数据服务 (377 行)
│       └── websocket_manager.dart     # WebSocket 管理 (306 行)
└── admin-vue/               # 管理界面 (Vue)
```

---

## 4. API 端点分析

### 4.1 公开端点
| 端点 | 方法 | 功能 |
|------|------|------|
| `/` | GET | 重定向到管理界面 |
| `/health` | GET | 健康检查 |
| `/version` | GET | 版本信息 |
| `/admin/*` | GET | 管理界面静态文件 |

### 4.2 认证 API (无需认证)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/v1/auth/register` | POST | 用户注册 |
| `/api/v1/auth/login` | POST | 用户登录 |
| `/api/v1/auth/refresh` | POST | 刷新 Token |

### 4.3 认证 API (需认证)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/v1/auth/set-encryption-key` | POST | 设置加密密钥 |
| `/api/v1/auth/clear-encryption-key` | POST | 清除加密密钥 |
| `/api/v1/auth/has-encryption-key` | GET | 检查密钥状态 |
| `/api/v1/auth/re-encrypt` | POST | 重新加密文件 |
| `/api/v1/auth/api-keys` | POST | 创建 API Key |
| `/api/v1/auth/api-keys` | GET | 列出 API Keys |
| `/api/v1/auth/api-keys/<id>` | DELETE | 撤销 API Key |
| `/api/v1/auth/user-info` | GET | 获取用户信息 |

### 4.4 同步 API (需认证)
| 端点 | 方法 | 功能 |
|------|------|------|
| `/api/v1/sync/push` | POST | 推送文件 |
| `/api/v1/sync/pull/<path>` | GET | 拉取文件 |
| `/api/v1/sync/pull-decrypted/<path>` | GET | 拉取解密文件 |
| `/api/v1/sync/info/<path>` | GET | 文件元信息 |
| `/api/v1/sync/list` | GET | 文件列表 |
| `/api/v1/sync/delete/<path>` | DELETE | 删除文件 |
| `/api/v1/sync/batch-delete` | POST | 批量删除 |
| `/api/v1/sync/status` | GET | 同步状态 |
| `/api/v1/sync/tree` | GET | 目录树 |
| `/api/v1/sync/index` | GET | 文件索引 |
| `/api/v1/sync/export` | POST | 导出 ZIP |
| `/api/v1/sync/download/<name>` | GET | 下载导出文件 |
| `/api/v1/sync/ws` | WS | WebSocket 连接 |

### 4.5 插件 API (需认证 + API 启用)
19 个插件，每个都有标准 CRUD：
- `GET /api/v1/plugins/<plugin>/items` - 列表
- `GET /api/v1/plugins/<plugin>/item/<id>` - 详情
- `POST /api/v1/plugins/<plugin>/item` - 创建
- `PUT /api/v1/plugins/<plugin>/item/<id>` - 更新
- `DELETE /api/v1/plugins/<plugin>/item/<id>` - 删除

**插件列表**:
chat, notes, activity, goods, bill, todo, agent_chat, calendar_album, calendar, checkin, contact, database, day, diary, nodes, openai, store, timer, tracker

---

## 5. 加密机制分析

### 5.1 加密服务 (ServerEncryptionService)
- **算法**: AES-256-GCM
- **密钥格式**: Base64 编码的 32 字节密钥
- **密文格式**: `base64(iv).base64(ciphertext)`
- **IV 长度**: 16 字节

### 5.2 密钥管理
- 密钥仅存储在内存中，不持久化
- 通过 `X-Encryption-Key` 请求头传递
- 首次设置时创建验证文件 `.key_verification.json`

### 5.3 关键实现细节
```dart
// 加密
final iv = encrypt.IV.fromSecureRandom(16);
final encrypted = encrypter.encrypt(data, iv: iv);
return '${iv.base64}.${encrypted.base64}';

// 解密
final parts = encryptedString.split('.');
final iv = encrypt.IV.fromBase64(parts[0]);
final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
return encrypter.decrypt(encrypted, iv: iv);
```

---

## 6. JWT 认证分析

### 6.1 Token 格式
- **Payload**: `{ sub: userId, iat: timestamp, exp: timestamp }`
- **签名算法**: HS256
- **有效期**: 36500 天 (约 100 年，实际永久)

### 6.2 双重认证支持
1. **JWT Token**: `Authorization: Bearer <token>`
2. **API Key**: `X-API-Key: <api_key>`

---

## 7. 文件存储结构

```
data/
├── users/
│   └── {userId}/
│       ├── .file_index.json      # 文件索引
│       ├── .key_verification.json # 密钥验证
│       ├── configs/
│       ├── app_data/
│       └── {plugin_id}/
│           └── {filename}.json
├── auth/
│   └── users.json                # 用户数据
│   └── api_keys/
│       └── {userId}.json         # API Keys
├── exports/
│   └── memento_export_xxx.zip
└── logs/
    └── sync_2024-01-01.log
```

### 7.1 加密文件格式
```json
{
  "encrypted_data": "base64(iv).base64(ciphertext)",
  "md5": "md5_hash_of_decrypted_data",
  "updated_at": "ISO8601_timestamp",
  "is_binary": false
}
```

---

## 8. WebSocket 协议

### 8.1 连接流程
1. 客户端连接 `/api/v1/sync/ws`
2. 发送认证消息: `{ type: "auth", token: "...", device_id: "..." }`
3. 服务端验证并返回: `{ type: "auth_success", user_id: "..." }`

### 8.2 消息类型
- `ping` → `pong` (心跳)
- `ack` (确认)
- `file_updated` (文件更新通知)

### 8.3 广播机制
- 文件更新时广播给同一用户的其他设备
- 排除触发更新的源设备

---

## 9. shared_models 依赖

服务器使用 `shared_models` 包中的：
- `UserInfo`, `DeviceInfo` - 用户模型
- `AuthResponse`, `RegisterRequest`, `LoginRequest` - 认证模型
- `SyncResponse`, `PullResponse`, `FileListResponse` - 同步模型
- `Result<T>` - 结果类型
- `ChatUseCase`, 各插件 UseCase - 业务逻辑
- Repository 接口

---

## 10. 迁移注意事项

### 10.1 必须保持兼容
1. **加密格式**: `iv.ciphertext` 格式必须一致
2. **JWT Token**: 签名密钥和算法必须一致
3. **文件格式**: JSON 结构必须完全一致
4. **WebSocket 消息**: JSON 格式必须一致

### 10.2 可优化项
1. 使用 TypeScript 类型替代 Dart 类型
2. 使用 Express 中间件链替代 Shelf Pipeline
3. 使用 chokidar 替代 Dart 文件监听

### 10.3 测试策略
1. 单元测试：各服务类的核心方法
2. 集成测试：API 端点功能
3. 兼容性测试：与 Dart 客户端互操作
