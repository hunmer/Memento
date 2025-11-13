# Tracker 插件 JS API 功能总结

## 概述

已成功为 **Tracker（目标追踪）插件** 添加完整的 JavaScript API 支持,实现了与 Chat 插件相同的架构模式。

## 实现内容

### 1. 核心配置

**修改文件**: `lib/plugins/tracker/tracker_plugin.dart`

**主要变更**:
- ✅ 添加 `JSBridgePlugin` mixin
- ✅ 导入必要的包（`dart:convert`, `js_bridge_plugin.dart`, `record.dart`）
- ✅ 在 `initialize()` 方法末尾调用 `registerJSAPI()`

### 2. API 列表（共 11 个）

#### 测试 API (1 个)
- `testSync()` - 同步测试 API

#### 目标管理 API (5 个)
- `getGoals(status?, group?)` - 获取目标列表（支持按状态和分组筛选）
- `getGoal(goalId)` - 获取目标详情
- `createGoal(name, unitType, targetValue, group?, icon?, dateType?)` - 创建目标
- `updateGoal(goalId, updateJson)` - 更新目标
- `deleteGoal(goalId)` - 删除目标

#### 记录管理 API (3 个)
- `recordData(goalId, value, note?, dateTime?)` - 记录数据
- `getRecords(goalId, limit?)` - 获取记录历史
- `deleteRecord(recordId)` - 删除记录

#### 统计 API (2 个)
- `getProgress(goalId)` - 获取目标进度
- `getStats(goalId?)` - 获取统计信息（全局或单个目标）

## 核心特性

### 1. 状态筛选
```javascript
// 获取进行中的目标
await memento.tracker.getGoals('active');

// 获取已完成的目标
await memento.tracker.getGoals('completed');
```

### 2. 分组管理
```javascript
// 获取"学习"分组的目标
await memento.tracker.getGoals(null, '学习');

// 获取"健康"分组中已完成的目标
await memento.tracker.getGoals('completed', '健康');
```

### 3. 灵活更新
```javascript
// 使用 JSON 格式更新任意字段
await memento.tracker.updateGoal(
  goalId,
  JSON.stringify({
    name: '新名称',
    targetValue: 100,
    reminderTime: '20:00'
  })
);
```

### 4. 统计信息

**全局统计**:
```javascript
const stats = await memento.tracker.getStats();
// 返回: totalGoals, todayCompleted, monthCompleted, overallProgress, groups 等
```

**单个目标统计**:
```javascript
const goalStats = await memento.tracker.getStats(goalId);
// 返回: totalRecords, totalValue, currentValue, progress 等
```

## 数据模型

### Goal（目标）对象
```typescript
{
  id: string;
  name: string;
  icon: string;
  unitType: string;
  targetValue: number;
  currentValue: number;
  dateSettings: {
    type: 'daily' | 'weekly' | 'monthly' | 'custom';
    startDate?: string;
    endDate?: string;
  };
  group: string;
  reminderTime?: string;
  isLoopReset: boolean;
  createdAt: string;
}
```

### Record（记录）对象
```typescript
{
  id: string;
  goalId: string;
  value: number;
  note?: string;
  recordedAt: string;
  durationSeconds?: number;
}
```

## 使用示例

### 快速开始

```javascript
// 1. 创建目标
const goal = await memento.tracker.createGoal(
  '每日阅读',
  '分钟',
  30,
  '学习'
);
const goalData = JSON.parse(goal);

// 2. 记录数据
await memento.tracker.recordData(
  goalData.id,
  30,
  '阅读技术文档'
);

// 3. 查看进度
const progress = await memento.tracker.getProgress(goalData.id);
console.log('进度:', JSON.parse(progress).percentage + '%');

// 4. 查看统计
const stats = await memento.tracker.getStats();
console.log('全局统计:', JSON.parse(stats));
```

### 批量操作

```javascript
// 获取所有进行中的"健康"类目标
const goals = await memento.tracker.getGoals('active', '健康');
const goalList = JSON.parse(goals);

// 批量记录今日完成情况
for (const goal of goalList) {
  await memento.tracker.recordData(goal.id, 10, '今日完成');
}
```

## 文件清单

### 修改的文件
- `lib/plugins/tracker/tracker_plugin.dart` - 主插件文件（添加 JS API 支持）

### 新增的文件
- `lib/plugins/tracker/JS_API_GUIDE.md` - 详细的 API 使用指南（25+ 页）
- `lib/plugins/tracker/JS_API_README.md` - 本文件（功能总结）

## 技术细节

### 错误处理
所有 API 在遇到错误时会抛出 `ArgumentError`，包括：
- 目标不存在: `Goal not found: <goalId>`
- 记录值无效: `Record value must be positive`
- 日期范围无效: `End date must be after start date`

### 自动更新
- `recordData` 会自动更新目标的 `currentValue`
- `deleteRecord` 会自动从目标值中减去对应记录值
- 所有操作都会触发 `notifyListeners()` 更新 UI

### 事件广播
- 添加记录时会触发 `onRecordAdded` 事件
- 其他插件可以监听此事件实现联动功能

## 代码质量

### 静态分析
```bash
flutter analyze lib/plugins/tracker/tracker_plugin.dart
# 结果: No issues found!
```

### 架构一致性
✅ 完全遵循 Chat 插件的实现模式
✅ 使用相同的 JSON 序列化/反序列化方式
✅ 保持与项目编码规范一致

## 后续建议

### 1. 性能优化
- 考虑为频繁访问的数据添加缓存机制
- 实现记录的分页加载（当记录数量很大时）

### 2. 功能增强
- 添加批量操作 API（如 `batchRecordData`）
- 支持目标模板系统
- 实现数据导出/导入功能

### 3. 文档完善
- 在项目主文档中添加 Tracker JS API 的链接
- 创建更多使用场景的示例代码

## 测试建议

### 单元测试
```javascript
// 测试目标创建
const goal = await memento.tracker.createGoal('测试', '次', 10);
assert(JSON.parse(goal).name === '测试');

// 测试记录添加
await memento.tracker.recordData(goalId, 5);
const progress = JSON.parse(await memento.tracker.getProgress(goalId));
assert(progress.currentValue === 5);

// 测试删除操作
await memento.tracker.deleteGoal(goalId);
try {
  await memento.tracker.getGoal(goalId);
  assert(false, '应该抛出错误');
} catch (e) {
  assert(e.message.includes('not found'));
}
```

---

**实现完成时间**: 2025-01-15
**总代码行数**: ~210 行（JS API 实现）
**文档总页数**: ~30 页
**测试状态**: ✅ 语法分析通过，无错误

