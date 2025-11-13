# Todo 插件 JS API 文档

## 概述

Todo 插件现已支持通过 JavaScript 调用任务管理功能。所有 API 均返回 JSON 格式字符串。

## API 列表

### 1. 查询 API

#### `getTasks(status?, priority?)` - 获取任务列表

**参数：**
- `status` (可选): 任务状态，可选值：`'todo'`, `'inProgress'`, `'in_progress'`, `'done'`
- `priority` (可选): 优先级，可选值：`'low'`, `'medium'`, `'high'`

**返回：** 任务数组的 JSON 字符串

**示例：**
```javascript
// 获取所有任务
const allTasks = await Memento.plugins.todo.getTasks();

// 获取待办任务
const todoTasks = await Memento.plugins.todo.getTasks('todo');

// 获取高优先级任务
const highPriorityTasks = await Memento.plugins.todo.getTasks(null, 'high');

// 获取进行中的高优先级任务
const inProgressHigh = await Memento.plugins.todo.getTasks('inProgress', 'high');
```

---

#### `getTask(taskId)` - 获取任务详情

**参数：**
- `taskId` (必需): 任务 ID

**返回：** 任务对象的 JSON 字符串，失败时返回 `{error: '...'}`

**示例：**
```javascript
const task = await Memento.plugins.todo.getTask('550e8400-e29b-41d4-a716-446655440000');
console.log(JSON.parse(task));
```

---

#### `getTodayTasks()` - 获取今日任务

获取今天截止或今天开始的所有任务。

**参数：** 无

**返回：** 今日任务数组的 JSON 字符串

**示例：**
```javascript
const todayTasks = await Memento.plugins.todo.getTodayTasks();
const tasks = JSON.parse(todayTasks);
console.log(`今日有 ${tasks.length} 个任务`);
```

---

#### `getOverdueTasks()` - 获取过期任务

获取截止日期已过且未完成的任务。

**参数：** 无

**返回：** 过期任务数组的 JSON 字符串

**示例：**
```javascript
const overdueTasks = await Memento.plugins.todo.getOverdueTasks();
const tasks = JSON.parse(overdueTasks);
if (tasks.length > 0) {
  console.log(`有 ${tasks.length} 个任务已过期！`);
}
```

---

### 2. 操作 API

#### `createTask(title, description?, startDate?, dueDate?, priority?, tagsJson?)` - 创建任务

**参数：**
- `title` (必需): 任务标题
- `description` (可选): 任务描述
- `startDate` (可选): 开始日期，ISO 8601 格式字符串，例如 `'2025-01-15T00:00:00.000Z'`
- `dueDate` (可选): 截止日期，ISO 8601 格式字符串
- `priority` (可选): 优先级 `'low'`, `'medium'`, `'high'`，默认 `'medium'`
- `tagsJson` (可选): 标签数组的 JSON 字符串，例如 `'["工作","紧急"]'`

**返回：** 新建任务对象的 JSON 字符串

**示例：**
```javascript
// 创建简单任务
const task1 = await Memento.plugins.todo.createTask('完成项目文档');

// 创建完整任务
const task2 = await Memento.plugins.todo.createTask(
  '编写需求分析',
  '详细描述项目需求和功能点',
  '2025-01-15T09:00:00.000Z',
  '2025-01-20T18:00:00.000Z',
  'high',
  '["工作","文档","紧急"]'
);

console.log(JSON.parse(task2));
```

---

#### `updateTask(taskId, updateJson)` - 更新任务

**参数：**
- `taskId` (必需): 任务 ID
- `updateJson` (必需): 更新内容的 JSON 字符串

**可更新字段：**
- `title`: 标题
- `description`: 描述
- `priority`: 优先级 (`'low'`, `'medium'`, `'high'`)
- `status`: 状态 (`'todo'`, `'inProgress'`, `'done'`)
- `startDate`: 开始日期 (ISO 8601 字符串)
- `dueDate`: 截止日期 (ISO 8601 字符串)
- `tags`: 标签数组

**返回：** 更新后的任务对象 JSON 字符串

**示例：**
```javascript
// 更新任务标题和优先级
const updated = await Memento.plugins.todo.updateTask(
  'task-id-here',
  JSON.stringify({
    title: '新标题',
    priority: 'high',
    tags: ['工作', '紧急', '重要']
  })
);

// 更新任务状态
const updated2 = await Memento.plugins.todo.updateTask(
  'task-id-here',
  JSON.stringify({ status: 'inProgress' })
);
```

---

#### `deleteTask(taskId)` - 删除任务

**参数：**
- `taskId` (必需): 任务 ID

**返回：** `{success: true, taskId: '...'}`，失败时返回 `{error: '...'}`

**示例：**
```javascript
const result = await Memento.plugins.todo.deleteTask('task-id-here');
console.log(JSON.parse(result)); // {success: true, taskId: '...'}
```

---

#### `completeTask(taskId)` - 完成任务

标记任务为已完成，会自动停止计时器并完成所有子任务。

**参数：**
- `taskId` (必需): 任务 ID

**返回：** 完成后的任务对象 JSON 字符串

**示例：**
```javascript
const completed = await Memento.plugins.todo.completeTask('task-id-here');
const task = JSON.parse(completed);
console.log(`任务 "${task.title}" 已完成！`);
```

---

## 任务对象结构

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "完成项目文档",
  "description": "编写项目技术文档和用户手册",
  "createdAt": "2025-01-15T08:00:00.000Z",
  "startDate": "2025-01-15T00:00:00.000Z",
  "dueDate": "2025-01-20T00:00:00.000Z",
  "priority": 2,
  "status": 1,
  "tags": ["工作", "文档"],
  "subtasks": [
    {
      "id": "1234567890",
      "title": "编写技术架构",
      "isCompleted": true
    }
  ],
  "reminders": ["2025-01-18T09:00:00.000Z"],
  "startTime": "2025-01-16T10:30:00.000Z",
  "duration": 7200000
}
```

### 字段说明

- **priority**: `0` = low, `1` = medium, `2` = high
- **status**: `0` = todo, `1` = inProgress, `2` = done
- **duration**: 持续时间（毫秒）
- **startTime**: 计时开始时间（仅在 status = inProgress 时有值）
- **completedDate**: 完成日期（仅在 status = done 时有值）

---

## 使用场景示例

### 场景 1: 智能任务提醒

```javascript
// 每天早上检查今日任务和过期任务
async function dailyTaskReminder() {
  const todayTasks = JSON.parse(await Memento.plugins.todo.getTodayTasks());
  const overdueTasks = JSON.parse(await Memento.plugins.todo.getOverdueTasks());

  let message = `早上好！\n\n`;

  if (todayTasks.length > 0) {
    message += `今日有 ${todayTasks.length} 个任务：\n`;
    todayTasks.forEach(task => {
      message += `- ${task.title}\n`;
    });
  }

  if (overdueTasks.length > 0) {
    message += `\n⚠️ ${overdueTasks.length} 个任务已过期！\n`;
    overdueTasks.forEach(task => {
      message += `- ${task.title} (截止: ${task.dueDate})\n`;
    });
  }

  return message;
}
```

### 场景 2: 批量创建任务

```javascript
// 从文本批量创建任务
async function createTasksFromText(text) {
  const lines = text.split('\n').filter(line => line.trim());
  const tasks = [];

  for (const line of lines) {
    const task = await Memento.plugins.todo.createTask(line.trim());
    tasks.push(JSON.parse(task));
  }

  return tasks;
}

// 使用示例
const text = `
完成项目文档
编写测试用例
代码审查
`;
await createTasksFromText(text);
```

### 场景 3: 任务统计分析

```javascript
// 统计任务完成情况
async function getTaskStatistics() {
  const allTasks = JSON.parse(await Memento.plugins.todo.getTasks());

  const stats = {
    total: allTasks.length,
    todo: allTasks.filter(t => t.status === 0).length,
    inProgress: allTasks.filter(t => t.status === 1).length,
    done: allTasks.filter(t => t.status === 2).length,
    high: allTasks.filter(t => t.priority === 2).length,
    medium: allTasks.filter(t => t.priority === 1).length,
    low: allTasks.filter(t => t.priority === 0).length,
  };

  return stats;
}
```

### 场景 4: 自动化工作流

```javascript
// 每周五下午自动创建下周计划任务
async function createWeeklyPlan() {
  const nextMonday = getNextMonday(); // 自定义日期计算函数

  const tasks = [
    { title: '周会准备', priority: 'high' },
    { title: '代码评审', priority: 'medium' },
    { title: '文档更新', priority: 'low' },
  ];

  for (const taskData of tasks) {
    await Memento.plugins.todo.createTask(
      taskData.title,
      '',
      nextMonday.toISOString(),
      null,
      taskData.priority,
      '["每周例行"]'
    );
  }
}
```

---

## 错误处理

所有 API 在失败时会返回包含 `error` 字段的 JSON 对象：

```javascript
const result = await Memento.plugins.todo.getTask('invalid-id');
const data = JSON.parse(result);

if (data.error) {
  console.error('操作失败:', data.error);
} else {
  console.log('任务:', data.title);
}
```

---

## 注意事项

1. **日期格式**: 所有日期参数必须使用 ISO 8601 格式字符串（例如 `'2025-01-15T09:00:00.000Z'`）
2. **JSON 序列化**: `tags` 参数需要传入 JSON 字符串，例如 `'["标签1","标签2"]'`
3. **异步调用**: 所有 API 都是异步的，需要使用 `await` 或 `.then()`
4. **返回值解析**: API 返回的是 JSON 字符串，需要使用 `JSON.parse()` 解析
5. **任务状态**: 使用 `completeTask()` 会自动完成所有子任务并停止计时器

---

## 集成示例

在聊天频道中使用 AI 管理任务：

```javascript
// AI 可以通过对话创建任务
用户: "帮我创建一个任务：明天下午3点开会"

AI: await Memento.plugins.todo.createTask(
  '下午3点开会',
  '',
  null,
  '2025-01-16T15:00:00.000Z',
  'medium',
  '["会议"]'
);

// AI 可以查询并汇报任务
用户: "今天有什么任务？"

AI: const tasks = JSON.parse(await Memento.plugins.todo.getTodayTasks());
// 然后格式化输出任务列表
```

---

**最后更新**: 2025-11-14
**版本**: 1.0.0
