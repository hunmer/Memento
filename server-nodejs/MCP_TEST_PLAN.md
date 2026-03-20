# MCP 工具验证与修复计划

## 用户意图

用户的后端从 Dart (`/server`) 迁移到了 Node.js (`/server-nodejs`)，但有些 MCP 工具执行的返回值跟 Dart 版本不一致（经常是空值或者报错）。

## 任务目标

1. **启动 server-nodejs** - Node.js 版本的后端服务器
2. **依次执行 MCP 工具** - 使用已配置好的 memento MCP 工具
3. **验证结果** - 参照未加密的数据文件 (`C:\Users\Administrator\Documents\app_data`) 来验证返回值是否正确
4. **修复问题** - 发现问题后立即修复
5. **重启验证** - 每修复一个 MCP 工具就立刻重启服务器继续验证

## 环境配置

### 服务器配置
- **端口**: 8874
- **数据目录**: `./data` (相对于 server-nodejs)
- **管理员账号**: admin / admin123

### MCP 配置 (已配置完成)
"MEMENTO_API_KEY": "mk_MXlfZ1-c-cJX_RS7OmHeERIPGeeiT-qmSBEAG_vxnnQ",
"MEMENTO_ENCRYPTION_KEY": "Gh5zO9b1kvFwlvWkpgusy1ZK+4vtlr8XKWKRn1iVQMI=",
"MEMENTO_SERVER_URL": "http://localhost:8874"

## 测试数据位置

用于验证的未加密数据文件：
```
C:\Users\Administrator\Documents\app_data\
├── activity/          # 活动记录
├── agent_chat/        # Agent 聊天
├── bill/              # 账单
├── calendar/          # 日历
├── calendar_album/    # 日记相册
├── chat/              # 聊天
├── checkin/           # 签到
├── configs/           # 配置
├── contact/           # 联系人
├── core/              # 核心
├── data/              # 数据
├── databases/         # 数据库
├── day/               # 纪念日
├── diary/             # 日记
├── goods/             # 物品管理
├── habits/            # 习惯
├── nodes/             # 节点
├── notes/             # 笔记
├── openai/            # AI 助手
├── store/             # 物品兑换
├── timer/             # 计时器
├── tracker/           # 目标追踪
├── tts/               # 文本转语音
└── webview/           # WebView
```

## MCP 工具列表

需要验证的工具模块：

### 1. Activity (活动记录)
- `memento_activity_getActivities` - 获取活动记录列表
- `memento_activity_createActivity` - 创建活动记录
- `memento_activity_updateActivity` - 更新活动记录
- `memento_activity_deleteActivity` - 删除活动记录
- `memento_activity_getTodayStats` - 获取今日统计

### 2. Bill (账单)
- `memento_bill_getAccounts` - 获取账户列表
- `memento_bill_getBills` - 获取账单列表
- `memento_bill_createBill` - 创建账单
- `memento_bill_updateBill` - 更新账单
- `memento_bill_deleteBill` - 删除账单
- `memento_bill_getStats` - 获取统计

### 3. Calendar (日历)
- `memento_calendar_getEvents` - 获取日历事件列表
- `memento_calendar_createEvent` - 创建日历事件
- `memento_calendar_updateEvent` - 更新日历事件
- `memento_calendar_deleteEvent` - 删除日历事件
- `memento_calendar_completeEvent` - 完成日历事件
- `memento_calendar_searchEvents` - 搜索日历事件

### 4. Chat (聊天)
- `memento_chat_getChannels` - 获取频道列表
- `memento_chat_createChannel` - 创建频道
- `memento_chat_updateChannel` - 更新频道
- `memento_chat_deleteChannel` - 删除频道
- `memento_chat_getMessages` - 获取消息列表
- `memento_chat_sendMessage` - 发送消息
- `memento_chat_deleteMessage` - 删除消息
- `memento_chat_searchMessages` - 搜索消息

### 5. Checkin (签到)
- `memento_checkin_getItems` - 获取打卡项目列表
- `memento_checkin_createItem` - 创建打卡项目
- `memento_checkin_updateItem` - 更新打卡项目
- `memento_checkin_deleteItem` - 删除打卡项目
- `memento_checkin_addRecord` - 添加打卡记录
- `memento_checkin_getStats` - 获取统计

### 6. Contact (联系人)
- `memento_contact_getContacts` - 获取联系人列表
- `memento_contact_createContact` - 创建联系人
- `memento_contact_updateContact` - 更新联系人
- `memento_contact_deleteContact` - 删除联系人
- `memento_contact_searchContacts` - 搜索联系人
- `memento_contact_getStats` - 获取统计

### 7. Day (纪念日)
- `memento_day_getMemorialDays` - 获取纪念日列表
- `memento_day_createMemorialDay` - 创建纪念日
- `memento_day_updateMemorialDay` - 更新纪念日
- `memento_day_deleteMemorialDay` - 删除纪念日
- `memento_day_searchMemorialDays` - 搜索纪念日
- `memento_day_getStats` - 获取统计

### 8. Diary (日记)
- `memento_diary_getEntries` - 获取日记列表
- `memento_diary_getEntry` - 获取指定日期的日记
- `memento_diary_createEntry` - 创建日记
- `memento_diary_updateEntry` - 更新日记
- `memento_diary_deleteEntry` - 删除日记
- `memento_diary_searchEntries` - 搜索日记
- `memento_diary_getStats` - 获取统计

### 9. Goods (物品管理)
- `memento_goods_getWarehouses` - 获取仓库列表
- `memento_goods_getItems` - 获取物品列表
- `memento_goods_createItem` - 创建物品
- `memento_goods_updateItem` - 更新物品
- `memento_goods_deleteItem` - 删除物品
- `memento_goods_searchItems` - 搜索物品

### 10. Notes (笔记)
- `memento_notes_getNotes` - 获取笔记列表
- `memento_notes_createNote` - 创建笔记
- `memento_notes_updateNote` - 更新笔记
- `memento_notes_deleteNote` - 删除笔记
- `memento_notes_searchNotes` - 搜索笔记

### 11. Todo (任务)
- `memento_todo_getTasks` - 获取任务列表
- `memento_todo_createTask` - 创建任务
- `memento_todo_updateTask` - 更新任务
- `memento_todo_completeTask` - 完成任务
- `memento_todo_getTodayTasks` - 获取今日任务
- `memento_todo_getOverdueTasks` - 获取过期任务
- `memento_todo_searchTasks` - 搜索任务
- `memento_todo_getStats` - 获取统计

### 12. Tracker (目标追踪)
- `memento_tracker_getGoals` - 获取追踪目标列表
- `memento_tracker_createGoal` - 创建追踪目标
- `memento_tracker_updateGoal` - 更新追踪目标
- `memento_tracker_deleteGoal` - 删除追踪目标
- `memento_tracker_addRecord` - 添加追踪记录
- `memento_tracker_getStats` - 获取统计

## 测试流程

```
1. 启动 server-nodejs
   └─> npm run dev

2. 对每个模块:
   a. 调用 MCP 工具获取数据
   b. 对比 app_data 中的未加密数据
   c. 如果结果不一致:
      - 分析问题原因
      - 修复 server-nodejs 代码
      - 重启服务器
      - 重新验证

3. 记录所有发现的问题和修复方案
```

## 测试进度

| 模块 | 状态 | 问题 | 修复状态 |
|------|------|------|----------|
| Activity | 待测试 | - | - |
| Bill | 待测试 | - | - |
| Calendar | 待测试 | - | - |
| Chat | 待测试 | - | - |
| Checkin | 待测试 | - | - |
| Contact | 待测试 | - | - |
| Day | 待测试 | - | - |
| Diary | 待测试 | - | - |
| Goods | 待测试 | - | - |
| Notes | 待测试 | - | - |
| Todo | 待测试 | - | - |
| Tracker | 待测试 | - | - |

## 注意事项

1. **数据格式**: 服务器期望加密格式 (`{encrypted_data, md5}`)，但测试数据是未加密的纯 JSON
2. **目录结构**: 服务器使用多用户结构 (`data/users/{userId}/`)，测试数据是扁平结构
3. **修复后立即验证**: 每修复一个问题就重启服务器并验证
