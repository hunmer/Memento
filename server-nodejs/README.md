# Memento Sync Server (Node.js + TypeScript)

基于 Node.js + TypeScript 的 Memento 同步服务器

## 功能特性

- ✅ 端到端加密（AES-256-GCM）
- ✅ JWT 认证 + API Key 支持
- ✅ 文件同步（push/pull/list/delete）
- ✅ WebSocket 实时同步
- ✅ 19 个插件的 RESTful API
- ✅ 纯文件存储（无需数据库）
- ✅ ZIP 数据导出

## 快速开始

### 1. 安装依赖

```bash
cd server-nodejs
npm install
```

### 2. 配置环境变量

复制示例配置文件：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# 服务器配置
PORT=8874
DATA_DIR=./data

# JWT 配置
JWT_SECRET=your-secure-secret-key
TOKEN_EXPIRY_DAYS=36500

# CORS 配置
ENABLE_CORS=true
CORS_ORIGINS=*

# 日志配置
ENABLE_LOGGING=true
```

### 3. 启动服务器

开发模式（热重载）：

```bash
npm run dev
```

生产模式：

```bash
npm run build
npm start
```

## API 端点

### 公开端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/version` | GET | 版本信息 |

### 认证 API (`/api/v1/auth`)

| 端点 | 方法 | 说明 |
|------|------|------|
| `/register` | POST | 用户注册 |
| `/login` | POST | 用户登录 |
| `/refresh` | POST | 刷新 Token |
| `/set-encryption-key` | POST | 设置加密密钥 |
| `/clear-encryption-key` | POST | 清除加密密钥 |
| `/has-encryption-key` | GET | 检查密钥状态 |
| `/api-keys` | GET/POST | API Key 管理 |
| `/api-keys/:id` | DELETE | 撤销 API Key |
| `/user-info` | GET | 获取用户信息 |

### 同步 API (`/api/v1/sync`)

| 端点 | 方法 | 说明 |
|------|------|------|
| `/push` | POST | 推送加密文件 |
| `/pull/*` | GET | 拉取加密文件 |
| `/list` | GET | 文件列表 |
| `/delete/*` | DELETE | 删除文件 |
| `/batch-delete` | POST | 批量删除 |
| `/status` | GET | 同步状态 |
| `/tree` | GET | 目录树 |
| `/index` | GET | 文件索引 |
| `/export` | POST | 导出 ZIP |
| `/download/*` | GET | 下载导出文件 |
| `/ws` | WS | WebSocket 实时同步 |

### 插件 API (`/api/v1/plugins/:pluginId`)

支持 19 个插件，每个都有标准 CRUD：

| 端点 | 方法 | 说明 |
|------|------|------|
| `/items` | GET | 获取列表 |
| `/item/:id` | GET | 获取单个 |
| `/item` | POST | 创建 |
| `/item/:id` | PUT | 更新 |
| `/item/:id` | DELETE | 删除 |

**插件列表**:
chat, notes, activity, goods, bill, todo, agent_chat, calendar_album, calendar, checkin, contact, database, day, diary, nodes, openai, store, timer, tracker

## 认证方式

### JWT Token

```http
Authorization: Bearer <token>
```

### API Key

```http
X-API-Key: <api_key>
```

## 加密

所有用户数据都使用 AES-256-GCM 加密。加密密钥由客户端生成和管理，服务器仅存储密文。

### 加密格式

```
base64(iv).base64(ciphertext + authTag)
```

- IV 长度: 16 字节
- 密钥长度: 32 字节 (256-bit)

## 项目结构

```
server-nodejs/
├── src/
│   ├── index.ts              # 入口
│   ├── config/
│   │   └── serverConfig.ts   # 配置
│   ├── services/
│   │   ├── authService.ts    # 认证服务
│   │   ├── encryptionService.ts # 加密服务
│   │   ├── fileStorageService.ts # 文件存储
│   │   ├── pluginDataService.ts # 插件数据
│   │   ├── webSocketManager.ts # WebSocket
│   │   └── fileWatcherService.ts # 文件监听
│   ├── middleware/
│   │   ├── authMiddleware.ts # 认证中间件
│   │   └── apiEnabledMiddleware.ts # API 启用检查
│   ├── routes/
│   │   ├── authRoutes.ts     # 认证路由
│   │   ├── syncRoutes.ts     # 同步路由
│   │   └── pluginRoutes/     # 插件路由
│   └── types/
│       └── index.ts          # 类型定义
├── tests/
│   └── api.test.ts           # 集成测试
├── package.json
├── tsconfig.json
├── jest.config.js
└── .env.example
```

## 运行测试

```bash
# 运行所有测试
npm test

# 带覆盖率报告
npm run test:coverage
```

## 开发

```bash
# 开发模式
npm run dev

# 编译
npm run build

# 代码检查
npm run lint
```

## 与 Dart 版本的兼容性

此 Node.js 版本与原 Dart 服务器完全兼容：

- ✅ 相同的 API 端点和响应格式
- ✅ 相同的加密格式（AES-256-GCM）
- ✅ 相同的 JWT Token 格式
- ✅ 相同的文件存储结构
- ✅ 相同的 WebSocket 协议

## 许可证

MIT
