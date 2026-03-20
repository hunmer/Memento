# Memento Sync Server (Node.js + TypeScript)

基于 Node.js + TypeScript 的 Memento 同步服务器

## 功能特性
      - ✅ 端到端加密（AES-256-GCM）
      - ✅ JWT 认证 + API Key 支持
      - ✅ 文件同步（push/pull/list/delete)
      - ✅ WebSocket 实时同步
      - ✅ 19 个插件的 RESTful API
      - ✅ **插件系统（安装/启用/禁用/卸载、 before/after 钩子)
      - ✅ 纯文件存储（无需数据库）
      - ✅ ZIP 数据导出
      - ✅ Vue 3 管理界面
      - ✅ 插件商店配置

      - ✅ 从商店安装插件
      - ✅ 上传 ZIP 安装

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

### 插件系统 API (`/api/v1/system/plugins`)

> 所有端点需要管理员权限

| 端点 | 方法 | 说明 |
|------|------|------|
| `/` | GET | 获取已安装插件列表 |
| `/:uuid` | GET | 获取单个插件详情 |
| `/upload` | POST | 上传 ZIP 安装插件 |
| `/:uuid/enable` | POST | 启用插件 |
| `/:uuid/disable` | POST | 禁用插件 |
| `/:uuid` | DELETE | 卸载插件 |
| `/store` | GET | 获取商店插件列表 |
| `/store/install` | POST | 从商店安装插件 |
| `/config` | GET/PUT | 获取/更新商店配置 |

## 插件系统

### 插件结构

插件以 ZIP 文件形式分发，包含以下文件：

```
plugin.zip
├── metadata.json    # 必需 - 插件元信息
└── main.js          # 必需 - 入口文件
```

### metadata.json 示例

```json
{
  "uuid": "data-sync-logger",
  "title": "数据同步日志记录器",
  "author": "Memento",
  "description": "监听插件数据变更并记录日志",
  "version": "1.0.0",
  "website": "https://github.com/memento/data-sync-logger",
  "permissions": {
    "dataAccess": [],
    "operations": ["read"],
    "networkAccess": false
  },
  "events": ["chat::*", "todo::*"]
}
```

### main.js 示例

```javascript
module.exports.metadata = require('./metadata.json');

module.exports.onLoad = async function() {
  console.log('插件已加载');
};

module.exports.handlers = {
  'chat::before:createChannel': async function(ctx) {
    console.log('创建频道前:', ctx.data);
    return ctx; // 可以修改 ctx.data 或设置 ctx.canceled = true
  },
  'chat::after:createChannel': async function(ctx) {
    console.log('创建频道后:', ctx.success);
  }
};
```

### 事件命名格式

```
{pluginId}::{timing}:{action}{Entity}
```

- `timing`: `before` 或 `after`
- `action`: `create`, `read`, `update`, `delete`
- `entity`: 实体名称（如 `Channel`, `Task`, `Note` 等）

示例：
- `chat::before:createChannel` - 创建频道前
- `todo::after:deleteTask` - 删除任务后
- `notes::*` - 所有 notes 事件（通配符）

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

# 插件系统 API 测试 (需要服务器运行)
node test-api.mjs
```

### 插件系统测试结果

| 测试 | 状态 |
|------|------|
| 登录获取 Token | ✅ |
| 获取已安装插件列表 | ✅ |
| 获取/更新商店配置 | ✅ |
| 上传插件 (ZIP) | ✅ |
| 启用/禁用插件 | ✅ |
| 卸载插件 | ✅ |

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
