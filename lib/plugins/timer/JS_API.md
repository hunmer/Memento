# Timer 插件 JS API 文档

## API 概览

Timer 插件提供了 9 个 JS API 方法,用于在 JavaScript 环境中管理和控制计时器。

## API 列表

### 1. getTimers()

获取所有计时器任务列表。

**调用方式:**
```javascript
const timers = await window.memento.timer.getTimers();
console.log(JSON.parse(timers));
```

**返回格式:**
```json
[
  {
    "id": "1705300800000",
    "name": "测试计时器",
    "color": 4284513675,
    "icon": 58223,
    "group": "默认",
    "isRunning": false,
    "repeatCount": 1,
    "remainingRepeatCount": 1,
    "enableNotification": false,
    "createdAt": "2025-01-15T08:00:00.000Z",
    "timerItems": [
      {
        "id": "1705300801000",
        "name": "正计时10秒",
        "description": null,
        "type": "countUp",
        "duration": 10,
        "completedDuration": 0,
        "isRunning": false,
        "isCompleted": false,
        "remainingDuration": 10,
        "repeatCount": 1,
        "enableNotification": false
      }
    ]
  }
]
```

---

### 2. createTimer(name, duration, type, group?)

创建新的计时器任务。

**参数:**
- `name` (String): 计时器名称
- `duration` (int): 计时时长(秒)
- `type` (String): 计时器类型,可选值:
  - `countUp`: 正计时
  - `countDown`: 倒计时
  - `pomodoro`: 番茄钟
- `group` (String, 可选): 分组名称,默认为 "默认"

**调用示例:**
```javascript
// 创建正计时 60 秒
const result = await window.memento.timer.createTimer('学习计时', 60, 'countUp', '工作');
console.log(JSON.parse(result));

// 创建倒计时 300 秒(5分钟)
const result2 = await window.memento.timer.createTimer('午休提醒', 300, 'countDown');
console.log(JSON.parse(result2));
```

**返回格式:**
```json
{
  "success": true,
  "taskId": "1705300800000",
  "message": "计时器创建成功"
}
```

---

### 3. deleteTimer(timerId)

删除指定的计时器任务。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const result = await window.memento.timer.deleteTimer('1705300800000');
console.log(JSON.parse(result));
```

**返回格式:**
```json
{
  "success": true,
  "message": "计时器已删除"
}
```

---

### 4. startTimer(timerId)

启动指定的计时器任务。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const result = await window.memento.timer.startTimer('1705300800000');
console.log(JSON.parse(result));
```

**返回格式:**
```json
{
  "success": true,
  "message": "计时器已启动",
  "taskId": "1705300800000",
  "isRunning": true
}
```

---

### 5. pauseTimer(timerId)

暂停正在运行的计时器任务。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const result = await window.memento.timer.pauseTimer('1705300800000');
console.log(JSON.parse(result));
```

**返回格式:**
```json
{
  "success": true,
  "message": "计时器已暂停",
  "taskId": "1705300800000",
  "isRunning": false
}
```

---

### 6. stopTimer(timerId)

停止计时器任务(暂停 + 停止前台通知)。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const result = await window.memento.timer.stopTimer('1705300800000');
console.log(JSON.parse(result));
```

**返回格式:**
```json
{
  "success": true,
  "message": "计时器已停止",
  "taskId": "1705300800000",
  "isRunning": false
}
```

---

### 7. resetTimer(timerId)

重置计时器任务,清除进度。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const result = await window.memento.timer.resetTimer('1705300800000');
console.log(JSON.parse(result));
```

**返回格式:**
```json
{
  "success": true,
  "message": "计时器已重置",
  "taskId": "1705300800000"
}
```

---

### 8. getTimerStatus(timerId)

获取指定计时器的详细状态。

**参数:**
- `timerId` (String): 计时器任务 ID

**调用示例:**
```javascript
const status = await window.memento.timer.getTimerStatus('1705300800000');
console.log(JSON.parse(status));
```

**返回格式:**
```json
{
  "taskId": "1705300800000",
  "name": "测试多计时器",
  "isRunning": true,
  "isCompleted": false,
  "elapsedDuration": 5,
  "repeatCount": 1,
  "remainingRepeatCount": 1,
  "currentTimerIndex": 0,
  "activeTimer": {
    "id": "1705300801000",
    "name": "正计时10秒",
    "type": "countUp",
    "duration": 10,
    "completedDuration": 5,
    "remainingDuration": 5,
    "isRunning": true,
    "isCompleted": false,
    "formattedRemainingTime": "00:00:05"
  },
  "timerItems": [
    {
      "id": "1705300801000",
      "name": "正计时10秒",
      "type": "countUp",
      "duration": 10,
      "completedDuration": 5,
      "remainingDuration": 5,
      "isCompleted": false
    },
    {
      "id": "1705300802000",
      "name": "倒计时10秒",
      "type": "countDown",
      "duration": 10,
      "completedDuration": 0,
      "remainingDuration": 10,
      "isCompleted": false
    }
  ]
}
```

---

### 9. getHistory()

获取所有已完成的计时器任务历史记录。

**调用示例:**
```javascript
const history = await window.memento.timer.getHistory();
console.log(JSON.parse(history));
```

**返回格式:**
```json
{
  "total": 2,
  "tasks": [
    {
      "id": "1705300800000",
      "name": "学习记录",
      "group": "工作",
      "createdAt": "2025-01-15T08:00:00.000Z",
      "totalDuration": 3600,
      "timerItems": [
        {
          "name": "专注时间",
          "type": "countUp",
          "completedDuration": 3600
        }
      ]
    }
  ]
}
```

---

## 完整使用示例

### 1. 创建并启动一个正计时器

```javascript
// 创建计时器
const createResult = await window.memento.timer.createTimer(
  '学习时间',
  3600,
  'countUp',
  '学习'
);
const { taskId } = JSON.parse(createResult);

// 启动计时器
await window.memento.timer.startTimer(taskId);

// 获取状态
const status = await window.memento.timer.getTimerStatus(taskId);
console.log('当前状态:', JSON.parse(status));
```

### 2. 批量管理计时器

```javascript
// 获取所有计时器
const timers = JSON.parse(await window.memento.timer.getTimers());

// 启动所有未运行的计时器
for (const timer of timers) {
  if (!timer.isRunning) {
    await window.memento.timer.startTimer(timer.id);
  }
}

// 暂停所有正在运行的计时器
for (const timer of timers) {
  if (timer.isRunning) {
    await window.memento.timer.pauseTimer(timer.id);
  }
}
```

### 3. 定时查询计时器状态

```javascript
const timerId = '1705300800000';

// 每秒查询一次状态
const interval = setInterval(async () => {
  const status = JSON.parse(await window.memento.timer.getTimerStatus(timerId));

  if (status.isCompleted) {
    console.log('计时器已完成!');
    clearInterval(interval);
  } else if (status.activeTimer) {
    console.log(
      `进度: ${status.activeTimer.formattedRemainingTime} ` +
      `(${status.activeTimer.completedDuration}/${status.activeTimer.duration}秒)`
    );
  }
}, 1000);
```

### 4. 查看历史统计

```javascript
const history = JSON.parse(await window.memento.timer.getHistory());

console.log(`已完成 ${history.total} 个计时任务`);

// 计算总计时时长
const totalSeconds = history.tasks.reduce(
  (sum, task) => sum + task.totalDuration,
  0
);

const hours = Math.floor(totalSeconds / 3600);
const minutes = Math.floor((totalSeconds % 3600) / 60);
console.log(`总计时: ${hours}小时${minutes}分钟`);
```

---

## 错误处理

所有 API 在发生错误时会抛出异常,建议使用 try-catch 捕获:

```javascript
try {
  const result = await window.memento.timer.startTimer('invalid_id');
  console.log(result);
} catch (error) {
  console.error('启动失败:', error.message);
  // 错误消息示例: "计时器不存在"
}
```

---

## 注意事项

1. **异步调用**: 所有 API 都是异步的,必须使用 `await` 或 `.then()`
2. **JSON 解析**: 返回值都是 JSON 字符串,需要用 `JSON.parse()` 解析
3. **ID 持久化**: 计时器 ID 在重启应用后保持不变,可以安全保存
4. **并发控制**: 一个任务只能有一个活动的计时器,多个计时器会按顺序执行
5. **平台限制**: `stopTimer` 涉及前台通知,仅在 Android/iOS 平台生效

---

## 数据类型说明

### TimerType (计时器类型)

- `countUp`: 正计时 - 从 0 开始向上计时
- `countDown`: 倒计时 - 从设定时间开始向下计时
- `pomodoro`: 番茄钟 - 工作和休息交替(当前 API 仅支持基础创建)

### 时间单位

所有时间参数和返回值统一使用**秒(seconds)**为单位。

### 颜色格式

`color` 字段使用 ARGB32 格式的整数表示,可通过以下方式转换:

```javascript
// 转换为 CSS 颜色字符串
function argb32ToCss(argb) {
  const a = (argb >> 24) & 0xFF;
  const r = (argb >> 16) & 0xFF;
  const g = (argb >> 8) & 0xFF;
  const b = argb & 0xFF;
  return `rgba(${r}, ${g}, ${b}, ${a / 255})`;
}

const cssColor = argb32ToCss(4284513675);
```

---

**更新日期**: 2025-11-14
**版本**: v1.0.0
