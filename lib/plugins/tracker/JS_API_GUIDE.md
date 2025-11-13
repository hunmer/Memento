# Tracker 插件 JS API 使用指南

本文档描述了 Tracker（目标追踪）插件提供的 JavaScript API，可用于通过 JS 脚本管理目标和记录。

---

## API 列表

### 测试 API

#### `testSync()`

**描述**: 同步测试 API，用于验证 JS Bridge 连接是否正常。

**参数**: 无

**返回值**:
```json
{
  "status": "ok",
  "message": "目标追踪插件同步测试成功！",
  "timestamp": "2025-01-15T12:30:00.000Z"
}
```

**示例**:
```javascript
const result = memento.tracker.testSync();
console.log(result);
```

---

## 目标管理 API

### `getGoals(status?, group?)`

**描述**: 获取目标列表，支持按状态和分组筛选。

**参数**:
- `status` (string, 可选): 目标状态
  - `'active'`: 进行中的目标
  - `'completed'`: 已完成的目标
  - 不传则返回所有目标
- `group` (string, 可选): 分组名称（如 "学习"、"健康"）

**返回值**: Goal 对象数组的 JSON 字符串

**示例**:
```javascript
// 获取所有目标
const allGoals = await memento.tracker.getGoals();

// 获取进行中的目标
const activeGoals = await memento.tracker.getGoals('active');

// 获取"学习"分组的目标
const studyGoals = await memento.tracker.getGoals(null, '学习');

// 获取"健康"分组中已完成的目标
const completedHealthGoals = await memento.tracker.getGoals('completed', '健康');
```

**返回数据格式**:
```json
[
  {
    "id": "1736950800000",
    "name": "每日阅读",
    "icon": "57455",
    "iconColor": 4294198070,
    "unitType": "分钟",
    "targetValue": 30.0,
    "currentValue": 15.0,
    "dateSettings": {
      "type": "daily",
      "startDate": null,
      "endDate": null,
      "selectedDays": null,
      "monthDay": null
    },
    "reminderTime": "09:00",
    "isLoopReset": true,
    "createdAt": "2025-01-15T08:30:00.000Z",
    "group": "学习",
    "imagePath": null,
    "progressColor": null
  }
]
```

---

### `getGoal(goalId)`

**描述**: 获取单个目标的详细信息。

**参数**:
- `goalId` (string, 必需): 目标 ID

**返回值**: Goal 对象的 JSON 字符串

**示例**:
```javascript
const goal = await memento.tracker.getGoal('1736950800000');
const goalData = JSON.parse(goal);
console.log(`目标名称: ${goalData.name}, 进度: ${goalData.currentValue}/${goalData.targetValue}`);
```

**错误**:
- 如果目标不存在，抛出 `ArgumentError: Goal not found: <goalId>`

---

### `createGoal(name, unitType, targetValue, group?, icon?, dateType?)`

**描述**: 创建新目标。

**参数**:
- `name` (string, 必需): 目标名称
- `unitType` (string, 必需): 单位类型（如 "次"、"分钟"、"页"）
- `targetValue` (number, 必需): 目标值
- `group` (string, 可选): 分组名称，默认为 "默认"
- `icon` (string, 可选): 图标代码点（Material Icons），默认为 "57455"
- `dateType` (string, 可选): 日期类型，默认为 "daily"
  - `'daily'`: 每日目标
  - `'weekly'`: 每周目标
  - `'monthly'`: 每月目标
  - `'custom'`: 自定义日期范围

**返回值**: 创建的 Goal 对象的 JSON 字符串

**示例**:
```javascript
// 创建每日阅读目标
const goal = await memento.tracker.createGoal(
  '每日阅读',
  '分钟',
  30,
  '学习'
);

// 创建每周运动目标
const weeklyGoal = await memento.tracker.createGoal(
  '每周运动',
  '小时',
  5,
  '健康',
  null,
  'weekly'
);
```

---

### `updateGoal(goalId, updateJson)`

**描述**: 更新目标信息。

**参数**:
- `goalId` (string, 必需): 目标 ID
- `updateJson` (string, 必需): 更新数据的 JSON 字符串

**返回值**: 更新后的 Goal 对象的 JSON 字符串

**示例**:
```javascript
// 更新目标名称和目标值
const updated = await memento.tracker.updateGoal(
  '1736950800000',
  JSON.stringify({
    name: '每日深度阅读',
    targetValue: 60
  })
);

// 更新提醒时间和分组
const updated2 = await memento.tracker.updateGoal(
  '1736950800000',
  JSON.stringify({
    reminderTime: '20:00',
    group: '个人成长'
  })
);
```

**可更新字段**:
- `name`: 目标名称
- `icon`: 图标代码点
- `iconColor`: 图标颜色
- `unitType`: 单位类型
- `targetValue`: 目标值
- `currentValue`: 当前值
- `dateSettings`: 日期设置对象
- `reminderTime`: 提醒时间
- `isLoopReset`: 是否循环重置
- `group`: 分组
- `imagePath`: 背景图片路径
- `progressColor`: 进度条颜色

---

### `deleteGoal(goalId)`

**描述**: 删除目标及其所有记录。

**参数**:
- `goalId` (string, 必需): 目标 ID

**返回值**: `true`

**示例**:
```javascript
await memento.tracker.deleteGoal('1736950800000');
```

---

## 记录管理 API

### `recordData(goalId, value, note?, dateTime?)`

**描述**: 为目标添加完成记录。

**参数**:
- `goalId` (string, 必需): 目标 ID
- `value` (number, 必需): 记录值（必须为正数）
- `note` (string, 可选): 备注信息
- `dateTime` (string, 可选): 记录时间（ISO 8601 格式），默认为当前时间

**返回值**: 创建的 Record 对象的 JSON 字符串

**示例**:
```javascript
// 添加今日阅读记录
const record = await memento.tracker.recordData(
  '1736950800000',
  30,
  '阅读《代码整洁之道》'
);

// 添加指定时间的记录
const pastRecord = await memento.tracker.recordData(
  '1736950800000',
  45,
  '昨日补记',
  '2025-01-14T20:00:00.000Z'
);
```

**返回数据格式**:
```json
{
  "id": "1736951000000",
  "goalId": "1736950800000",
  "value": 30.0,
  "note": "阅读《代码整洁之道》",
  "recordedAt": "2025-01-15T12:30:00.000Z",
  "durationSeconds": null
}
```

**注意事项**:
- 记录会自动更新目标的 `currentValue`
- 会触发 `onRecordAdded` 事件

---

### `getRecords(goalId, limit?)`

**描述**: 获取目标的记录历史。

**参数**:
- `goalId` (string, 必需): 目标 ID
- `limit` (number, 可选): 返回的最大记录数，不传则返回所有记录

**返回值**: Record 对象数组的 JSON 字符串（按时间倒序排列）

**示例**:
```javascript
// 获取所有记录
const allRecords = await memento.tracker.getRecords('1736950800000');

// 获取最近 10 条记录
const recentRecords = await memento.tracker.getRecords('1736950800000', 10);

const records = JSON.parse(recentRecords);
records.forEach(record => {
  console.log(`${record.recordedAt}: ${record.value} ${record.note || ''}`);
});
```

---

### `deleteRecord(recordId)`

**描述**: 删除单条记录。

**参数**:
- `recordId` (string, 必需): 记录 ID

**返回值**: `true`

**示例**:
```javascript
await memento.tracker.deleteRecord('1736951000000');
```

**注意事项**:
- 删除记录会自动从目标的 `currentValue` 中减去对应值

---

## 统计 API

### `getProgress(goalId)`

**描述**: 获取目标的进度信息。

**参数**:
- `goalId` (string, 必需): 目标 ID

**返回值**: 进度信息的 JSON 字符串

**示例**:
```javascript
const progress = await memento.tracker.getProgress('1736950800000');
const progressData = JSON.parse(progress);

console.log(`进度: ${progressData.percentage}%`);
console.log(`完成状态: ${progressData.isCompleted ? '已完成' : '进行中'}`);
```

**返回数据格式**:
```json
{
  "goalId": "1736950800000",
  "currentValue": 15.0,
  "targetValue": 30.0,
  "progress": 0.5,
  "percentage": "50.0",
  "isCompleted": false
}
```

---

### `getStats(goalId?)`

**描述**: 获取统计信息。不传参数返回全局统计，传 goalId 返回单个目标统计。

**参数**:
- `goalId` (string, 可选): 目标 ID

**返回值**: 统计信息的 JSON 字符串

**示例**:

**全局统计**:
```javascript
const stats = await memento.tracker.getStats();
const statsData = JSON.parse(stats);

console.log(`总目标数: ${statsData.totalGoals}`);
console.log(`今日完成: ${statsData.todayCompleted}`);
console.log(`本月完成: ${statsData.monthCompleted}`);
console.log(`整体进度: ${(statsData.overallProgress * 100).toFixed(1)}%`);
console.log(`分组列表: ${statsData.groups.join(', ')}`);
```

**全局统计返回格式**:
```json
{
  "totalGoals": 5,
  "todayCompleted": 2,
  "monthCompleted": 8,
  "monthAdded": 3,
  "todayRecords": 10,
  "overallProgress": 0.6,
  "groups": ["学习", "健康", "工作"]
}
```

**单个目标统计**:
```javascript
const goalStats = await memento.tracker.getStats('1736950800000');
const goalStatsData = JSON.parse(goalStats);

console.log(`目标名称: ${goalStatsData.goalName}`);
console.log(`总记录数: ${goalStatsData.totalRecords}`);
console.log(`累计值: ${goalStatsData.totalValue}`);
```

**单个目标统计返回格式**:
```json
{
  "goalId": "1736950800000",
  "goalName": "每日阅读",
  "totalRecords": 25,
  "totalValue": 750.0,
  "currentValue": 15.0,
  "targetValue": 30.0,
  "progress": 0.5,
  "isCompleted": false
}
```

---

## 完整使用示例

### 示例 1: 创建并跟踪每日阅读目标

```javascript
// 1. 创建目标
const goal = await memento.tracker.createGoal(
  '每日阅读',
  '分钟',
  30,
  '学习',
  '57455', // book icon
  'daily'
);
const goalData = JSON.parse(goal);
const goalId = goalData.id;

// 2. 添加记录
await memento.tracker.recordData(goalId, 15, '早上阅读技术文档');
await memento.tracker.recordData(goalId, 20, '晚上阅读小说');

// 3. 查看进度
const progress = await memento.tracker.getProgress(goalId);
console.log('当前进度:', JSON.parse(progress).percentage + '%');

// 4. 查看统计
const stats = await memento.tracker.getStats(goalId);
const statsData = JSON.parse(stats);
console.log(`总记录数: ${statsData.totalRecords}`);
console.log(`累计阅读: ${statsData.totalValue} 分钟`);
```

---

### 示例 2: 批量管理目标

```javascript
// 获取所有进行中的目标
const activeGoals = await memento.tracker.getGoals('active');
const goals = JSON.parse(activeGoals);

// 遍历并更新每个目标
for (const goal of goals) {
  if (goal.currentValue < goal.targetValue * 0.5) {
    console.log(`目标 "${goal.name}" 进度较慢，需要加油！`);
  }
}

// 批量记录数据（例如：统一记录今日完成情况）
const todayValue = 10;
for (const goal of goals) {
  if (goal.group === '健康') {
    await memento.tracker.recordData(goal.id, todayValue, '今日完成');
  }
}
```

---

### 示例 3: 生成周报

```javascript
// 获取所有目标的统计信息
const globalStats = await memento.tracker.getStats();
const stats = JSON.parse(globalStats);

let report = `## 本周目标追踪报告\n\n`;
report += `- 总目标数: ${stats.totalGoals}\n`;
report += `- 本月完成: ${stats.monthCompleted}\n`;
report += `- 今日记录: ${stats.todayRecords}\n`;
report += `- 整体进度: ${(stats.overallProgress * 100).toFixed(1)}%\n\n`;

// 遍历每个分组
for (const group of stats.groups) {
  report += `### ${group}\n\n`;
  const groupGoals = await memento.tracker.getGoals(null, group);
  const goals = JSON.parse(groupGoals);

  for (const goal of goals) {
    const goalStats = await memento.tracker.getStats(goal.id);
    const data = JSON.parse(goalStats);
    report += `- **${goal.name}**: ${data.currentValue}/${data.targetValue} ${goal.unitType} `;
    report += `(${(data.progress * 100).toFixed(1)}%)\n`;
  }
  report += '\n';
}

console.log(report);
```

---

## 数据模型说明

### Goal 对象

```typescript
interface Goal {
  id: string;                    // 唯一 ID（时间戳字符串）
  name: string;                  // 目标名称
  icon: string;                  // 图标代码点（Material Icons）
  iconColor?: number;            // 图标颜色（Color.value）
  unitType: string;              // 单位类型（如 "次"、"分钟"、"页"）
  targetValue: number;           // 目标值
  currentValue: number;          // 当前值
  dateSettings: DateSettings;    // 日期设置
  reminderTime?: string;         // 提醒时间（HH:mm 格式）
  isLoopReset: boolean;          // 是否循环重置
  createdAt: string;             // 创建时间（ISO 8601）
  group: string;                 // 分组名称
  imagePath?: string;            // 背景图片路径
  progressColor?: number;        // 进度条颜色（Color.value）
}
```

### DateSettings 对象

```typescript
interface DateSettings {
  type: 'daily' | 'weekly' | 'monthly' | 'custom';  // 日期类型
  startDate?: string;            // 开始日期（ISO 8601，仅 custom 类型）
  endDate?: string;              // 结束日期（ISO 8601，仅 custom 类型）
  selectedDays?: string[];       // 选中的星期（仅 weekly 类型）
  monthDay?: number;             // 月份日期（仅 monthly 类型）
}
```

### Record 对象

```typescript
interface Record {
  id: string;                    // 唯一 ID（时间戳字符串）
  goalId: string;                // 关联的目标 ID
  value: number;                 // 记录值
  note?: string;                 // 备注
  recordedAt: string;            // 记录时间（ISO 8601）
  durationSeconds?: number;      // 持续时间（秒，计时器使用）
}
```

---

## 错误处理

所有 API 在遇到错误时会抛出异常，建议使用 try-catch 捕获：

```javascript
try {
  const goal = await memento.tracker.getGoal('invalid_id');
} catch (error) {
  console.error('获取目标失败:', error.message);
}
```

**常见错误**:
- `Goal not found: <goalId>`: 目标不存在
- `Record value must be positive`: 记录值必须为正数
- `End date must be after start date`: 日期范围无效

---

## 事件系统

Tracker 插件会广播以下事件：

### `onRecordAdded`

**触发时机**: 每次添加记录时

**事件数据**: `Value<Record>` 对象

**用途**: 其他插件可以监听此事件实现联动功能（如自动生成日记、活动记录等）

---

## 性能建议

1. **批量操作**: 如需更新多个目标，建议使用循环而非并发调用
2. **数据缓存**: 频繁访问的数据（如目标列表）建议在 JS 侧缓存
3. **限制记录数**: 使用 `getRecords(goalId, limit)` 的 limit 参数避免一次性加载过多数据

---

## 更新日志

- **2025-01-15**: 初始版本，实现 11 个 API
  - 测试 API: `testSync`
  - 目标管理: `getGoals`, `getGoal`, `createGoal`, `updateGoal`, `deleteGoal`
  - 记录管理: `recordData`, `getRecords`, `deleteRecord`
  - 统计: `getProgress`, `getStats`

---

**文档维护者**: Memento 开发团队
**最后更新**: 2025-01-15
