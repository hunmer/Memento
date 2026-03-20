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
- **Diary** - 日记管理
- **Checkin** - 签到管理
- **Calendar** - 日历事件
- **Contact** - 联系人管理
- **Tracker** - 目标追踪
- **Day** - 纪念日管理

## 安装

```bash
cd mcp-memento-server
npm install
npm run build
```

## 配置

### 方式一：创建 .env 文件（推荐）

```bash
# 复制模板
cp .env.example .env
```

编辑 `.env` 文件：

```env
# Memento 后端服务器地址
MEMENTO_SERVER_URL=http://localhost:8080

# API Key 认证（从管理面板获取）
MEMENTO_API_KEY=mk_live_your_api_key_here
MEMENTO_ENCRYPTION_KEY=your_base64_encryption_key_here
```

### 方式二：环境变量

```bash
# Unix/Linux/macOS
export MEMENTO_SERVER_URL="http://localhost:8080"
export MEMENTO_API_KEY="mk_live_your_api_key"
export MEMENTO_ENCRYPTION_KEY="your_base64_encryption_key"

# Windows PowerShell
$env:MEMENTO_SERVER_URL="http://localhost:8080"
$env:MEMENTO_API_KEY="mk_live_your_api_key"
$env:MEMENTO_ENCRYPTION_KEY="your_base64_encryption_key"
```

### 获取 API Key

1. 启动 Memento Server
2. 访问管理面板 http://localhost:8080/admin/
3. 使用默认账号登录: `admin` / `admin123`
4. 进入 "API Keys" 选项卡
5. 点击 "创建 API Key"
6. 输入名称、选择过期时间
7. **重要**: 从 Memento 客户端获取加密密钥（设置 > 开发者选项）
8. 保存显示的 API Key 和加密密钥

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
        "MEMENTO_API_KEY": "mk_live_your_api_key",
        "MEMENTO_ENCRYPTION_KEY": "your_base64_encryption_key"
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
| `memento_chat_updateChannel` | 更新频道信息 |
| `memento_chat_deleteChannel` | 删除频道 |
| `memento_chat_getMessages` | 获取指定频道的消息列表 |
| `memento_chat_sendMessage` | 向频道发送消息 |
| `memento_chat_deleteMessage` | 删除消息 |
| `memento_chat_searchMessages` | 搜索消息 |

### Notes 插件

| 工具名 | 描述 |
|--------|------|
| `memento_notes_getNotes` | 获取笔记列表 |
| `memento_notes_createNote` | 创建新笔记 |
| `memento_notes_updateNote` | 更新笔记 |
| `memento_notes_deleteNote` | 删除笔记 |
| `memento_notes_searchNotes` | 搜索笔记 |

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

### Diary 插件

| 工具名 | 描述 |
|--------|------|
| `memento_diary_getEntries` | 获取日记列表 |
| `memento_diary_getEntry` | 获取指定日期的日记 |
| `memento_diary_createEntry` | 创建日记 |
| `memento_diary_updateEntry` | 更新日记 |
| `memento_diary_deleteEntry` | 删除日记 |
| `memento_diary_searchEntries` | 搜索日记 |
| `memento_diary_getStats` | 获取日记统计 |

### Activity 插件

| 工具名 | 描述 |
|--------|------|
| `memento_activity_getActivities` | 获取活动记录列表 |
| `memento_activity_createActivity` | 创建活动记录 |
| `memento_activity_updateActivity` | 更新活动记录 |
| `memento_activity_deleteActivity` | 删除活动记录 |
| `memento_activity_getTodayStats` | 获取今日活动统计 |

### Bill 插件

| 工具名 | 描述 |
|--------|------|
| `memento_bill_getAccounts` | 获取账户列表 |
| `memento_bill_getBills` | 获取账单列表 |
| `memento_bill_createBill` | 创建账单 |
| `memento_bill_updateBill` | 更新账单 |
| `memento_bill_deleteBill` | 删除账单 |
| `memento_bill_getStats` | 获取账单统计 |

### Goods 插件

| 工具名 | 描述 |
|--------|------|
| `memento_goods_getWarehouses` | 获取仓库列表 |
| `memento_goods_getItems` | 获取物品列表 |
| `memento_goods_createItem` | 创建物品 |
| `memento_goods_updateItem` | 更新物品 |
| `memento_goods_deleteItem` | 删除物品 |
| `memento_goods_searchItems` | 搜索物品 |

### Checkin 插件

| 工具名 | 描述 |
|--------|------|
| `memento_checkin_getItems` | 获取签到项目列表 |
| `memento_checkin_createItem` | 创建签到项目 |
| `memento_checkin_updateItem` | 更新签到项目 |
| `memento_checkin_deleteItem` | 删除签到项目 |
| `memento_checkin_addRecord` | 添加签到记录 |
| `memento_checkin_getStats` | 获取签到统计 |

### Calendar 插件

| 工具名 | 描述 |
|--------|------|
| `memento_calendar_getEvents` | 获取日历事件 |
| `memento_calendar_createEvent` | 创建事件 |
| `memento_calendar_updateEvent` | 更新事件 |
| `memento_calendar_deleteEvent` | 删除事件 |
| `memento_calendar_completeEvent` | 完成事件 |
| `memento_calendar_searchEvents` | 搜索事件 |

### Contact 插件

| 工具名 | 描述 |
|--------|------|
| `memento_contact_getContacts` | 获取联系人列表 |
| `memento_contact_createContact` | 创建联系人 |
| `memento_contact_updateContact` | 更新联系人 |
| `memento_contact_deleteContact` | 删除联系人 |
| `memento_contact_searchContacts` | 搜索联系人 |
| `memento_contact_getStats` | 获取联系人统计 |

### Tracker 插件

| 工具名 | 描述 |
|--------|------|
| `memento_tracker_getGoals` | 获取目标列表 |
| `memento_tracker_createGoal` | 创建目标 |
| `memento_tracker_updateGoal` | 更新目标 |
| `memento_tracker_deleteGoal` | 删除目标 |
| `memento_tracker_addRecord` | 添加记录 |
| `memento_tracker_getStats` | 获取追踪统计 |

### Day 插件

| 工具名 | 描述 |
|--------|------|
| `memento_day_getMemorialDays` | 获取纪念日列表 |
| `memento_day_createMemorialDay` | 创建纪念日 |
| `memento_day_updateMemorialDay` | 更新纪念日 |
| `memento_day_deleteMemorialDay` | 删除纪念日 |
| `memento_day_searchMemorialDays` | 搜索纪念日 |
| `memento_day_getStats` | 获取纪念日统计 |

## 开发

```bash
# 开发模式运行
npm run dev

# 使用 MCP Inspector 调试
npm run inspector

# 构建
npm run build
```

## 故障排除

### 认证失败

```
Error: API Key 无效或已过期
```

**解决方案：**
1. 检查 API Key 是否正确复制（包含 `mk_live_` 前缀）
2. 在管理面板检查 API Key 是否已过期
3. 确认加密密钥与创建 API Key 时使用的一致

### 无法连接服务器

```
Error: fetch failed
```

**解决方案：**
1. 确认 Memento Server 正在运行
2. 检查 `MEMENTO_SERVER_URL` 是否正确
3. 如果使用 HTTPS，确保证书有效

## 许可证

MIT
