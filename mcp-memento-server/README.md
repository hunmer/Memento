# Memento MCP Server

MCP (Model Context Protocol) 服务，用于 AI 工具访问 Memento 应用数据。

## 功能

提供以下插件的 AI 工具：

- **Chat** - 聊天频道和消息管理
- **Notes** - 笔记和文件夹管理
- **Activity** - 活动记录和统计
- **Goods** - 物品和仓库管理
- **Bill** - 账单和账户管理
- **Todo** - 任务管理

## 安装

```bash
cd mcp-memento-server
npm install
npm run build
```

## 配置

创建 `.env` 文件（已提供 `.env.example` 模板）：

```bash
# Memento 后端服务器地址 (默认端口: 8080)
MEMENTO_SERVER_URL=http://localhost:8080

# JWT 认证令牌 (从 Memento 应用获取)
MEMENTO_AUTH_TOKEN=your-jwt-token
```

或者设置环境变量：

```bash
# Unix/Linux/macOS
export MEMENTO_SERVER_URL="http://localhost:8080"
export MEMENTO_AUTH_TOKEN="your-jwt-token"

# Windows PowerShell
$env:MEMENTO_SERVER_URL="http://localhost:8080"
$env:MEMENTO_AUTH_TOKEN="your-jwt-token"

# Windows CMD
set MEMENTO_SERVER_URL=http://localhost:8080
set MEMENTO_AUTH_TOKEN=your-jwt-token
```

### 获取认证令牌

1. 在 Memento 应用中登录
2. 进入设置 > 数据同步
3. 启用 API 访问
4. 复制生成的 Token

## 在 Claude Desktop 中使用

编辑 Claude Desktop 配置文件：

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "memento": {
      "command": "node",
      "args": ["path/to/mcp-memento-server/dist/index.js"],
      "env": {
        "MEMENTO_SERVER_URL": "http://localhost:8080",
        "MEMENTO_AUTH_TOKEN": "your-jwt-token"
      }
    }
  }
}
```

## 可用工具

### Chat 插件

| 工具名 | 描述 |
|--------|------|
| `memento_chat_getChannels` | 获取聊天频道列表 |
| `memento_chat_createChannel` | 创建新的聊天频道 |
| `memento_chat_getMessages` | 获取指定频道的消息列表 |
| `memento_chat_sendMessage` | 向频道发送消息 |

### Notes 插件

| 工具名 | 描述 |
|--------|------|
| `memento_notes_getNotes` | 获取笔记列表 |
| `memento_notes_createNote` | 创建新笔记 |
| `memento_notes_updateNote` | 更新笔记 |
| `memento_notes_searchNotes` | 搜索笔记 |

### Activity 插件

| 工具名 | 描述 |
|--------|------|
| `memento_activity_getActivities` | 获取活动记录列表 |
| `memento_activity_createActivity` | 创建活动记录 |
| `memento_activity_getTodayStats` | 获取今日活动统计 |

### Goods 插件

| 工具名 | 描述 |
|--------|------|
| `memento_goods_getWarehouses` | 获取仓库列表 |
| `memento_goods_getItems` | 获取物品列表 |
| `memento_goods_createItem` | 创建物品 |
| `memento_goods_searchItems` | 搜索物品 |

### Bill 插件

| 工具名 | 描述 |
|--------|------|
| `memento_bill_getAccounts` | 获取账户列表 |
| `memento_bill_getBills` | 获取账单列表 |
| `memento_bill_createBill` | 创建账单 |
| `memento_bill_getStats` | 获取账单统计 |

### Todo 插件

| 工具名 | 描述 |
|--------|------|
| `memento_todo_getTasks` | 获取任务列表 |
| `memento_todo_createTask` | 创建任务 |
| `memento_todo_updateTask` | 更新任务 |
| `memento_todo_completeTask` | 完成任务 |
| `memento_todo_getTodayTasks` | 获取今日任务 |
| `memento_todo_getOverdueTasks` | 获取过期任务 |
| `memento_todo_searchTasks` | 搜索任务 |
| `memento_todo_getStats` | 获取任务统计 |

## 开发

```bash
# 开发模式运行
npm run dev

# 使用 MCP Inspector 调试（自动加载 .env）
npm run inspector

# 构建
npm run build

# 清理构建产物
npm run clean
```

### MCP Inspector 调试

MCP Inspector 是官方的 MCP 服务调试工具，提供图形化界面来测试工具调用。

**使用步骤：**

1. 确保已配置 `.env` 文件
2. 运行 `npm run inspector`
3. 浏览器自动打开调试界面
4. 在界面中测试各个工具

**Inspector 特性：**
- ✅ 自动加载 `.env` 环境变量
- ✅ 实时查看工具调用和响应
- ✅ 测试工具参数和返回值
- ✅ 验证环境变量配置

## API 端点

MCP 服务通过以下 HTTP API 与 Memento 服务器通信：

- `POST /api/v1/auth/enable-api` - 启用 API 访问
- `POST /api/v1/auth/disable-api` - 禁用 API 访问
- `GET /api/v1/auth/api-status` - 查询 API 状态
- `/api/v1/plugins/chat/*` - Chat 插件 API
- `/api/v1/plugins/notes/*` - Notes 插件 API
- `/api/v1/plugins/activity/*` - Activity 插件 API
- `/api/v1/plugins/goods/*` - Goods 插件 API
- `/api/v1/plugins/bill/*` - Bill 插件 API
- `/api/v1/plugins/todo/*` - Todo 插件 API

## 许可证

MIT
