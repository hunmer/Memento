# 任务计划：Dart 后端迁移到 Node.js + TypeScript

## 目标
将 Dart (Shelf框架) 后端服务完整迁移到 Node.js + TypeScript，保持所有功能不变，并在完成后编写集成测试文件验证接口运行情况。

---

## 源系统分析

### 技术栈
- **框架**: Dart + Shelf
- **认证**: JWT (dart_jsonwebtoken)
- **加密**: AES-256-GCM (encrypt 包)
- **存储**: 纯文件系统 (JSON)
- **WebSocket**: shelf_web_socket

### 核心功能模块
| 模块 | 文件 | 功能 |
|------|------|------|
| 入口 | bin/server.dart | 服务启动、路由注册、WebSocket |
| 认证 | auth_service.dart | JWT、用户管理、API Key |
| 存储 | file_storage_service.dart | 文件读写、索引、ZIP导出 |
| 加密 | encryption_service.dart | AES-256-GCM 加解密 |
| 插件数据 | plugin_data_service.dart | 插件数据访问、密钥管理 |
| WebSocket | websocket_manager.dart | 连接管理、广播通知 |
| 文件监听 | file_watcher_service.dart | 文件变化监听 |

### API 端点
- **公开**: /health, /version, /admin/*
- **认证**: /api/v1/auth/* (register, login, refresh, api-keys, etc.)
- **同步**: /api/v1/sync/* (push, pull, list, delete, export, ws)
- **插件**: /api/v1/plugins/* (19个插件的 CRUD)

---

## 迁移计划

### Phase 1: 项目初始化与基础架构 [ ] pending
**目标**: 搭建 Node.js + TypeScript 项目骨架

**任务**:
- [ ] 1.1 创建 server-nodejs 目录
- [ ] 1.2 初始化 package.json，配置 TypeScript
- [ ] 1.3 安装核心依赖 (express, jsonwebtoken, ws, etc.)
- [ ] 1.4 配置 tsconfig.json 和项目结构
- [ ] 1.5 设置环境变量加载 (dotenv)
- [ ] 1.6 创建基础入口文件 (src/index.ts)

**验收标准**:
- TypeScript 编译通过
- 服务可启动并监听端口

---

### Phase 2: 核心服务迁移 [ ] pending
**目标**: 迁移所有核心服务类

**任务**:
- [ ] 2.1 配置管理 (config/serverConfig.ts)
- [ ] 2.2 加密服务 (services/encryptionService.ts) - AES-256-GCM
- [ ] 2.3 文件存储服务 (services/fileStorageService.ts)
- [ ] 2.4 认证服务 (services/authService.ts) - JWT + 用户管理 + API Key
- [ ] 2.5 插件数据服务 (services/pluginDataService.ts)
- [ ] 2.6 WebSocket 管理器 (services/webSocketManager.ts)
- [ ] 2.7 文件监听服务 (services/fileWatcherService.ts)

**验收标准**:
- 所有服务可独立实例化
- 加密/解密与 Dart 版本兼容

---

### Phase 3: 中间件迁移 [ ] pending
**目标**: 迁移认证和权限中间件

**任务**:
- [ ] 3.1 认证中间件 (middleware/authMiddleware.ts) - JWT + API Key
- [ ] 3.2 API 启用中间件 (middleware/apiEnabledMiddleware.ts)
- [ ] 3.3 CORS 中间件
- [ ] 3.4 请求日志中间件

**验收标准**:
- 中间件正确拦截未授权请求
- JWT 和 API Key 认证都能正常工作

---

### Phase 4: 路由迁移 [ ] pending
**目标**: 迁移所有 API 路由

**任务**:
- [ ] 4.1 健康检查路由 (GET /health, /version)
- [ ] 4.2 认证路由 (routes/authRoutes.ts)
  - register, login, refresh
  - set-encryption-key, clear-encryption-key, has-encryption-key
  - re-encrypt
  - api-keys (CRUD)
  - user-info
- [ ] 4.3 同步路由 (routes/syncRoutes.ts)
  - push, pull, pull-decrypted, info
  - list, delete, batch-delete
  - status, tree, index
  - export, download
- [ ] 4.4 插件路由 (routes/pluginRoutes/*)
  - 19 个插件路由 (chat, notes, activity, goods, bill, todo, etc.)
- [ ] 4.5 管理界面静态文件服务 (/admin/*)

**验收标准**:
- 所有 API 端点与 Dart 版本一致
- 请求/响应格式完全兼容

---

### Phase 5: WebSocket 迁移 [ ] pending
**目标**: 实现 WebSocket 实时同步功能

**任务**:
- [ ] 5.1 WebSocket 服务器设置
- [ ] 5.2 连接认证流程
- [ ] 5.3 心跳机制 (ping/pong)
- [ ] 5.4 文件更新广播

**验收标准**:
- WebSocket 连接可建立
- 认证流程正确
- 文件更新可广播到其他设备

---

### Phase 6: 类型定义与共享模型 [ ] pending
**目标**: 创建 TypeScript 类型定义

**任务**:
- [ ] 6.1 用户相关类型 (UserInfo, DeviceInfo, etc.)
- [ ] 6.2 认证相关类型 (AuthResponse, RegisterRequest, etc.)
- [ ] 6.3 同步相关类型 (SyncResponse, PullResponse, etc.)
- [ ] 6.4 API Key 类型
- [ ] 6.5 插件数据类型

**验收标准**:
- 所有 API 请求/响应有完整类型定义
- 类型与 Dart shared_models 兼容

---

### Phase 7: 集成测试 [ ] pending
**目标**: 编写完整的接口测试

**任务**:
- [ ] 7.1 测试框架搭建 (Jest/Mocha)
- [ ] 7.2 认证 API 测试
  - 用户注册/登录
  - Token 刷新
  - API Key 管理
  - 加密密钥设置
- [ ] 7.3 同步 API 测试
  - 文件推送/拉取
  - 冲突检测
  - 批量删除
  - ZIP 导出
- [ ] 7.4 插件 API 测试
  - 各插件 CRUD 操作
- [ ] 7.5 WebSocket 测试
  - 连接认证
  - 消息广播

**验收标准**:
- 所有测试通过
- 测试覆盖率 > 80%

---

## 技术选型

| 功能 | Dart | Node.js |
|------|------|---------|
| Web 框架 | Shelf | Express |
| 路由 | shelf_router | express.Router |
| JWT | dart_jsonwebtoken | jsonwebtoken |
| 加密 | encrypt (AES-GCM) | crypto (内置) |
| UUID | uuid | uuid |
| 文件监听 | dart:io | chokidar |
| WebSocket | shelf_web_socket | ws |
| 环境变量 | dotenv | dotenv |
| ZIP | archive | archiver |
| 测试 | test | Jest |

---

## 文件结构

```
server-nodejs/
├── src/
│   ├── index.ts              # 入口
│   ├── config/
│   │   └── serverConfig.ts   # 配置
│   ├── services/
│   │   ├── authService.ts
│   │   ├── encryptionService.ts
│   │   ├── fileStorageService.ts
│   │   ├── pluginDataService.ts
│   │   ├── webSocketManager.ts
│   │   └── fileWatcherService.ts
│   ├── middleware/
│   │   ├── authMiddleware.ts
│   │   └── apiEnabledMiddleware.ts
│   ├── routes/
│   │   ├── authRoutes.ts
│   │   ├── syncRoutes.ts
│   │   └── pluginRoutes/
│   │       ├── chatRoutes.ts
│   │       └── ... (19个)
│   ├── repositories/
│   │   └── ... (各插件)
│   └── types/
│       └── index.ts          # 类型定义
├── tests/
│   ├── auth.test.ts
│   ├── sync.test.ts
│   └── plugins.test.ts
├── package.json
├── tsconfig.json
└── .env.example
```

---

## 风险与注意事项

1. **加密兼容性**: AES-256-GCM 的 IV 和密文格式必须与 Dart 客户端完全兼容
2. **JWT 兼容性**: Token 格式和签名必须与现有客户端兼容
3. **文件格式**: JSON 文件结构必须与 Dart 版本完全一致
4. **WebSocket 协议**: 消息格式必须与客户端兼容

---

## 进度跟踪

| Phase | 状态 | 开始时间 | 完成时间 |
|-------|------|----------|----------|
| Phase 1 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 2 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 3 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 4 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 5 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 6 | ✅ completed | 2026-03-20 | 2026-03-20 |
| Phase 7 | ✅ completed | 2026-03-20 | 2026-03-20 |

---

## 错误记录

| 错误 | 阶段 | 解决方案 |
|------|------|----------|
| (暂无) | - | - |
