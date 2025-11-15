# 脚本事件数据访问指南

## 功能说明

当脚本通过**事件触发器**执行时，可以通过 `args.eventData` 访问触发事件携带的完整数据。

## 使用场景

### 1. 配置事件触发器

在脚本编辑界面的"触发条件"区域：

1. 点击"添加触发器"按钮
2. 从下拉框中选择要监听的事件（如 `calendar_event_added`）
3. 可选择性设置延迟执行时间
4. 保存脚本

### 2. 在脚本中访问事件数据

当事件触发脚本执行时，JavaScript 代码可以通过 `args.eventData` 访问事件数据：

```javascript
// 基本事件信息（所有事件都包含）
const eventName = args.eventData.eventName;        // 事件名称
const whenOccurred = args.eventData.whenOccurred;  // 事件发生时间（ISO 8601 字符串）

// 不同类型的事件包含不同的数据
```

## 事件数据结构

### ItemEventArgs（物品相关事件）

用于 TODO、日记、笔记等项目相关的事件。

**可用字段：**
- `eventName` - 事件名称（string）
- `whenOccurred` - 事件发生时间（ISO 8601 string）
- `itemId` - 项目 ID（string）
- `title` - 项目标题（string）
- `action` - 操作类型（string，如 'added', 'completed', 'deleted'）

**示例代码：**
```javascript
// 监听 TODO 任务添加事件
if (args.event === 'todo_task_added') {
    const taskId = args.eventData.itemId;
    const taskTitle = args.eventData.title;
    const action = args.eventData.action;

    console.log(`新任务已添加: ${taskTitle} (ID: ${taskId})`);

    // 可以调用其他 Memento API 进行处理
    // 例如：发送通知、记录日志、触发其他脚本等
}
```

### Value<T>（单值事件）

携带单个值的事件。

**可用字段：**
- `eventName` - 事件名称（string）
- `whenOccurred` - 事件发生时间（ISO 8601 string）
- `value` - 事件值（类型根据具体事件而定）

**示例代码：**
```javascript
if (args.event === 'setting_changed') {
    const newValue = args.eventData.value;
    console.log(`设置已更改为: ${newValue}`);
}
```

### Values<T1, T2>（双值事件）

携带两个值的事件。

**可用字段：**
- `eventName` - 事件名称（string）
- `whenOccurred` - 事件发生时间（ISO 8601 string）
- `value1` - 第一个值
- `value2` - 第二个值

**示例代码：**
```javascript
if (args.event === 'data_synchronized') {
    const localCount = args.eventData.value1;
    const remoteCount = args.eventData.value2;
    console.log(`同步完成: 本地 ${localCount} 条，远程 ${remoteCount} 条`);
}
```

### UpdateEvent（更新事件）

用于应用更新相关的事件。

**可用字段：**
- `eventName` - 事件名称（string）
- `whenOccurred` - 事件发生时间（ISO 8601 string）
- `version` - 版本号（string）
- `forceUpdate` - 是否强制更新（boolean）
- `changelog` - 更新日志（string，可选）

**示例代码：**
```javascript
if (args.event === 'app_update_available') {
    const version = args.eventData.version;
    const isForced = args.eventData.forceUpdate;
    const changes = args.eventData.changelog || '无更新说明';

    if (isForced) {
        console.log(`⚠️ 发现强制更新: v${version}`);
    } else {
        console.log(`📦 发现可选更新: v${version}`);
    }
    console.log(`更新内容:\n${changes}`);
}
```

## 完整示例

### 示例 1：日记添加提醒

```javascript
// metadata.json 中配置：
// "triggers": [{"event": "diary_entry_added"}]

// script.js
if (args.event === 'diary_entry_added') {
    const diaryTitle = args.eventData.title;
    const diaryId = args.eventData.itemId;
    const addedTime = args.eventData.whenOccurred;

    // 通过 chat 插件发送通知消息
    await Memento.chat.sendMessage(
        'notifications',  // 频道名称
        `📝 新日记已添加\n标题: ${diaryTitle}\n时间: ${new Date(addedTime).toLocaleString()}`
    );

    return {
        success: true,
        message: '已发送日记添加通知'
    };
}
```

### 示例 2：任务完成统计

```javascript
// metadata.json 中配置：
// "triggers": [{"event": "todo_task_completed"}]

// script.js
if (args.event === 'todo_task_completed') {
    const taskTitle = args.eventData.title;
    const completedTime = new Date(args.eventData.whenOccurred);

    // 记录到数据库或发送统计
    const stats = {
        task: taskTitle,
        completedAt: completedTime,
        date: completedTime.toLocaleDateString()
    };

    console.log('任务完成:', stats);

    // 可以调用其他脚本进行统计
    const result = await runScript('task_statistics', stats);

    return {
        success: true,
        completedTask: taskTitle
    };
}
```

### 示例 3：事件数据调试

```javascript
// 打印完整的事件数据结构（用于开发调试）
console.log('=== 事件触发调试信息 ===');
console.log('事件名称:', args.event);
console.log('事件数据:', JSON.stringify(args.eventData, null, 2));
console.log('脚本信息:', scriptInfo);

// 遍历所有事件数据字段
for (const [key, value] of Object.entries(args.eventData)) {
    console.log(`  ${key}: ${value}`);
}

return {
    success: true,
    debug: args.eventData
};
```

## 常见问题

### Q1: 如何知道某个事件包含哪些数据？

**A:** 可以通过以下方法：
1. 查看本文档中的"事件数据结构"部分
2. 使用"示例 3"中的调试代码打印完整的事件数据
3. 查看源代码中的事件定义（`lib/core/event/` 目录）

### Q2: eventData 和直接访问 args 的区别？

**A:**
- `args` - 包含脚本执行的所有参数（事件触发时包含 `event` 和 `eventData`；手动运行时包含用户输入的参数）
- `args.eventData` - 仅在事件触发时存在，包含事件的详细数据
- `args.event` - 触发脚本的事件名称（仅事件触发时存在）

### Q3: 可以同时处理多个事件吗？

**A:** 可以！在 metadata.json 中配置多个触发器：
```json
{
  "triggers": [
    {"event": "diary_entry_added"},
    {"event": "diary_entry_updated"},
    {"event": "diary_entry_deleted"}
  ]
}
```

然后在脚本中用 `if-else` 或 `switch` 判断：
```javascript
switch (args.event) {
    case 'diary_entry_added':
        // 处理添加事件
        break;
    case 'diary_entry_updated':
        // 处理更新事件
        break;
    case 'diary_entry_deleted':
        // 处理删除事件
        break;
}
```

### Q4: 如果事件数据为空怎么办？

**A:** 建议始终进行防御性检查：
```javascript
if (args.eventData) {
    const title = args.eventData.title || '无标题';
    const itemId = args.eventData.itemId || 'unknown';
    // ... 处理逻辑
} else {
    console.warn('事件数据为空');
    return { success: false, error: '无事件数据' };
}
```

## 可用事件列表

以下是系统中常见的事件（根据实际插件可能有所不同）：

### 日历相关
- `calendar_event_added` - 日历事件添加
- `calendar_event_deleted` - 日历事件删除
- `calendar_event_updated` - 日历事件更新

### TODO 相关
- `todo_task_added` - 任务添加
- `todo_task_completed` - 任务完成
- `todo_task_deleted` - 任务删除

### 日记相关
- `diary_entry_added` - 日记添加
- `diary_entry_updated` - 日记更新
- `diary_entry_deleted` - 日记删除

### 笔记相关
- `note_created` - 笔记创建
- `note_updated` - 笔记更新
- `note_deleted` - 笔记删除

*注：具体可用事件请在脚本编辑界面的"触发条件"下拉框中查看。*

## 技术细节

- **数据序列化**: EventArgs 对象通过 `_serializeEventArgs()` 函数转换为 JSON
- **源代码位置**:
  - 序列化逻辑: `lib/plugins/scripts_center/scripts_center_plugin.dart`
  - 事件定义: `lib/core/event/`
- **传递流程**: EventManager → ScriptsCenterPlugin → ScriptExecutor → JavaScript 环境

---

**最后更新**: 2025-11-15
**相关文档**: [INPUT_PARAMS_USAGE.md](./INPUT_PARAMS_USAGE.md)
