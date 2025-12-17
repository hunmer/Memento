[根目录](../../../CLAUDE.md) > [lib](../../) > [plugins](../) > **habits**

---

# 习惯追踪插件 (Habits Plugin) - 模块文档

> **变更记录 (Changelog)**
> - **2025-12-17T12:10:45+08:00**: 完整更新 - 识别 JS API、UseCase 架构、Repository 模式、Android 小组件支持、数据选择器等新特性

## 模块职责

习惯追踪插件是 Memento 的核心功能模块之一，提供：

- **习惯管理**: 创建、编辑、删除习惯，支持图标、图片、标签、分组
- **技能系统**: 将习惯关联到技能，实现目标导向的习惯培养（一万小时理念）
- **完成记录**: 记录习惯的完成情况和时长，支持备注
- **计时器功能**: 内置倒计时/正计时器，支持暂停、恢复、状态持久化
- **双视图模式**: 支持列表视图和卡片视图切换
- **分组管理**: 按技能或自定义分组组织习惯
- **统计功能**: 完成次数、累计时长、历史记录
- **事件系统**: 广播计时器的启动、停止事件，同步小组件
- **JS API**: 15+ 个 JavaScript API 方法，支持跨模块调用
- **数据选择器**: 可被其他模块选择习惯数据
- **Android 小组件**: 支持习惯统计、周视图、分组列表等小组件
- **UseCase 架构**: 采用 UseCase + Repository 架构模式

---

## 入口与启动

### 插件主类

**文件**: `habits_plugin.dart`

```dart
class HabitsPlugin extends PluginBase with JSBridgePlugin {
  // 单例模式
  static HabitsPlugin get instance;

  // 四大控制器
  late final HabitController _habitController;
  late final SkillController _skillController;
  late final CompletionRecordController _recordController;
  late final TimerController _timerController;

  // UseCase 架构
  late final ClientHabitsRepository _repository;
  late final HabitsUseCase _useCase;
}
```

**初始化流程**:
1. 创建 TimerController（单例）
2. 创建 SkillController 并加载数据
3. 创建 HabitController（依赖 timerController 和 skillController）
4. 创建 CompletionRecordController（依赖 habitController 和 skillController）
5. 创建 ClientHabitsRepository 适配器
6. 创建 HabitsUseCase 实例
7. 注册 JS API
8. 注册数据选择器

### 主界面入口

**文件**: `widgets/habits_bottom_bar.dart`

**布局**: 底部导航栏双 Tab 结构
- Tab 0: 习惯列表（CombinedHabitsView）
- Tab 1: 技能列表（SkillsList）
- 悬浮按钮: 动态切换添加习惯/技能

---

## 对外接口

### JS API (JavaScript 接口)

插件提供 15+ 个 JavaScript API 方法，支持跨模块调用：

#### 习惯管理 API
```javascript
// 获取习惯列表（支持分页）
Memento.habits.getHabits({ offset: 0, count: 10 })

// 根据ID获取习惯
Memento.habits.getHabitById({ habitId: "xxx" })

// 创建习惯
Memento.habits.createHabit({
  title: "晨跑",
  durationMinutes: 30,
  skillId: "skill-001"
})

// 更新习惯
Memento.habits.updateHabit({
  habitId: "xxx",
  title: "夜跑"
})

// 删除习惯
Memento.habits.deleteHabit({ habitId: "xxx" })
```

#### 技能管理 API
```javascript
// 获取技能列表（支持分页）
Memento.habits.getSkills({ offset: 0, count: 10 })

// 创建技能
Memento.habits.createSkill({
  title: "健康生活",
  targetMinutes: 10000
})
```

#### 打卡记录 API
```javascript
// 打卡（创建完成记录）
Memento.habits.checkIn({
  habitId: "xxx",
  durationMinutes: 30,
  notes: "今天跑了5公里"
})

// 获取完成记录
Memento.habits.getCompletionRecords({
  habitId: "xxx",
  offset: 0,
  count: 10
})

// 删除完成记录
Memento.habits.deleteCompletionRecord({ recordId: "xxx" })
```

#### 统计 API
```javascript
// 获取习惯统计
Memento.habits.getStats({
  habitId: "xxx"
}) // 返回: { totalDurationMinutes, completionCount }

// 获取今日习惯
Memento.habits.getTodayHabits()
```

#### 计时器 API
```javascript
// 启动计时器
Memento.habits.startTimer({
  habitId: "xxx",
  initialSeconds: 1800
})

// 停止计时器
Memento.habits.stopTimer({ habitId: "xxx" })

// 获取计时器状态
Memento.habits.getTimerStatus({ habitId: "xxx" })
// 返回: { isRunning, elapsedSeconds, isCountdown }
```

### 数据选择器

插件注册了数据选择器，可被其他模块调用：

```dart
// 选择习惯
pluginDataSelectorService.select(
  context: context,
  selectorId: 'habits.habit',
  onSelected: (items) {
    final habit = items.first.rawData as Habit;
    // 处理选中的习惯
  },
);
```

**特性**:
- 支持搜索（标题、分组、标签）
- 显示累计时长和完成次数
- 单选模式

### Android 小组件 API

插件支持多种 Android 桌面小组件：

1. **习惯统计小组件** (1x1, 2x2)
   - 显示习惯总数、技能总数
   - 快速进入插件

2. **习惯周视图小组件** (2x2)
   - 显示选中习惯的周完成情况
   - 热力图形式展示

3. **习惯分组列表小组件** (2x2)
   - 按技能分组显示习惯
   - 快速访问常用习惯

---

## 关键依赖与配置

### 外部依赖

- `shared_models`: UseCase 和 Repository 接口定义
- `uuid`: UUID 生成（通过 `HabitsUtils.generateId()`）
- `path`: 路径处理

### 插件依赖

- **Core Event System**: 事件广播系统（计时器事件）
- **StorageManager**: 数据持久化
- **ImageUtils**: 图片路径处理
- **CircleIconPicker**: 图标选择器组件
- **ImagePickerDialog**: 图片选择对话框
- **PluginWidgetSyncHelper**: Android 小组件同步

### 存储路径

**根目录**: `habits/`

**存储结构**:
```
habits/
├── habits.json                  # 所有习惯数据
├── skills.json                  # 所有技能数据
├── records/
│   ├── <habitId>.json          # 习惯的完成记录
│   └── ...
├── habit_images/               # 习惯封面图片
│   ├── <uuid>.jpg
│   └── ...
└── habit_images/               # 技能封面图片
    ├── <uuid>.jpg
    └── ...
```

---

## 数据模型

### Habit (习惯)

**文件**: `models/habit.dart`

```dart
class Habit {
  final String id;                  // 唯一ID（UUID v4）
  final String title;               // 习惯标题
  final String? notes;              // 备注（可选）
  final String? group;              // 分组名称（可选）
  final String? icon;               // 图标代码（MaterialIcons codePoint字符串）
  final String? image;              // 封面图片路径（可选）
  final List<int> reminderDays;     // 提醒日期（0-6代表周日-周六）
  final int intervalDays;           // 间隔天数（0表示每天）
  final int durationMinutes;        // 持续时长（分钟）
  final List<String> tags;          // 标签列表
  final String? skillId;            // 关联的技能ID（可选）
}
```

### Skill (技能)

**文件**: `models/skill.dart`

```dart
class Skill {
  final String id;                  // 唯一ID
  final String title;               // 技能名称
  final String? description;        // 描述（可选）
  final String? notes;              // 备注（可选）
  final String? group;              // 分组名称（可选）
  final String? icon;               // 图标代码（可选）
  final String? image;              // 封面图片路径（可选）
  final int targetMinutes;          // 目标时长（分钟，0表示无目标）
  final int maxDurationMinutes;     // 最大时长限制（0表示无限制）
}
```

### CompletionRecord (完成记录)

**文件**: `models/completion_record.dart`

```dart
class CompletionRecord {
  final String id;                  // 唯一ID
  final String parentId;            // 父习惯ID
  final DateTime date;              // 完成日期
  final Duration duration;          // 持续时长
  final String notes;               // 备注
}
```

### 小组件相关模型

**文件**: `models/habits_weekly_widget_data.dart`

```dart
class HabitsWeeklyData {
  final int year;                   // 年份
  final int week;                   // 周数
  final String weekStart;           // 周开始日期 (MM.dd)
  final String weekEnd;             // 周结束日期 (MM.dd)
  final List<HabitWeeklyItem> habitItems; // 习惯周数据
}

class HabitWeeklyItem {
  final String habitId;             // 习惯ID
  final String habitTitle;          // 习惯标题
  final String habitIcon;           // 习惯图标（emoji或字符）
  final List<int> dailyMinutes;     // 每日时长（7天）
  final int colorValue;             // 颜色值（ARGB）
}
```

---

## 架构设计

### UseCase + Repository 架构

插件采用了 UseCase + Repository 架构模式：

```
HabitsPlugin (JS API 适配层)
    ↓
HabitsUseCase (业务逻辑层)
    ↓
ClientHabitsRepository (数据访问适配层)
    ↓
Controllers (具体实现)
    ↓
StorageManager (数据持久化)
```

**优势**:
- 清晰的职责分离
- 易于测试（可 mock Repository）
- 支持多种数据源
- 业务逻辑集中管理

### 控制器层设计

#### 1. HabitController
- 管理 CRUD 操作
- 默认数据初始化（8个示例习惯）
- 事件广播（数据变更）
- 小组件同步

#### 2. SkillController
- 技能 CRUD 操作
- 按标题查找（唯一性检查）
- 与习惯的关联管理

#### 3. CompletionRecordController
- 完成记录 CRUD 操作
- 统计功能（总时长、完成次数）
- 技能级别的数据聚合

#### 4. TimerController (单例)
- 全局计时器管理
- 状态持久化
- 事件广播（启动/停止）

---

## 界面层结构

### 主要界面组件

| 组件 | 文件 | 职责 |
|------|------|------|
| `HabitsBottomBar` | `widgets/habits_bottom_bar.dart` | 底部导航栏主界面 |
| `CombinedHabitsView` | `widgets/habits_list/habits_view.dart` | 习惯列表视图（双视图模式） |
| `HabitsAppBar` | `widgets/habits_list/habits_app_bar.dart` | 习惯列表AppBar |
| `HabitsList` | `widgets/habits_list/habits_list.dart` | 习惯列表组件 |
| `HabitsHistoryList` | `widgets/habits_list/habits_history_list.dart` | 历史记录列表 |
| `SkillsList` | `widgets/skills_list.dart` | 技能列表视图 |
| `SkillDetailPage` | `widgets/skill_detail_page.dart` | 技能详情页 |
| `HabitForm` | `widgets/habit_form.dart` | 习惯创建/编辑表单 |
| `SkillForm` | `widgets/skill_form.dart` | 技能创建/编辑表单 |
| `TimerDialog` | `widgets/timer_dialog.dart` | 计时器对话框 |
| `HabitCard` | `widgets/habit_card.dart` | 习惯卡片组件 |
| `StatisticsTab` | `widgets/statistics_tab.dart` | 统计信息Tab |
| `CompletionRecordsTab` | `widgets/completion_records_tab.dart` | 完成记录Tab |
| `CommonRecordList` | `widgets/common_record_list.dart` | 通用记录列表 |

### 双视图模式

习惯列表支持两种视图模式：

1. **列表视图**
   - 按技能分组
   - 显示习惯详情
   - 支持长按查看历史

2. **卡片视图**
   - 2列网格布局
   - 显示封面图片
   - 快速计时按钮
   - 视觉化展示

---

## 事件系统

### 事件类型

| 事件名 | 触发时机 | 用途 |
|-------|---------|------|
| `habit_timer_started` | 计时器启动时 | 更新UI、同步小组件 |
| `habit_timer_stopped` | 计时器停止时 | 更新UI、同步小组件 |
| `habit_completion_record_saved` | 保存完成记录时 | 同步周视图小组件 |
| `habit_data_changed` | 习惯数据变更时 | 同步分组列表小组件 |
| `skill_data_changed` | 技能数据变更时 | 同步分组列表小组件 |

---

## 小组件服务

### HabitsWidgetService

**文件**: `services/habits_widget_service.dart`

**功能**:
- 计算习惯周统计数据
- ISO 8601 周数计算
- 习惯图标和颜色处理
- 支持多个习惯的周视图

**核心方法**:
```dart
// 计算周数据
Future<HabitsWeeklyData> calculateWeekData(
  List<String> habitIds,
  int weekOffset,
)

// 计算每日时长（支持多个记录聚合）
Future<List<int>> _calculateDailyMinutes(
  String habitId,
  DateTime weekStart,
)
```

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **代码覆盖率**: 0%
- **已知问题**:
  - `CompletionRecordController` 构造函数参数 `skillControlle` 拼写错误
  - 提醒功能未实现（`reminderDays` 字段未使用）
  - 技能目标时长未在 UI 中展示

### 测试建议

1. **高优先级**：
   - `HabitController` - CRUD 操作和默认数据创建
   - `TimerController` - 单例模式、状态持久化、计时器管理
   - `ClientHabitsRepository` - UseCase 适配层
   - `HabitsUtils` - 工具方法

2. **中优先级**：
   - `SkillController` - 唯一性检查
   - `CompletionRecordController` - 数据聚合逻辑
   - `HabitsWidgetService` - 周统计计算

3. **低优先级**：
   - UI 组件测试
   - 事件广播测试

---

## 常见问题 (FAQ)

### Q1: 如何实现连续打卡统计？

参考 `CompletionRecordController` 中的实现思路：

```dart
Future<int> getStreakDays(String habitId) async {
  final records = await getHabitCompletionRecords(habitId);
  if (records.isEmpty) return 0;

  // 按日期降序排序
  records.sort((a, b) => b.date.compareTo(a.date));

  int streak = 0;
  DateTime? lastDate;

  for (final record in records) {
    final recordDate = DateTime(
      record.date.year,
      record.date.month,
      record.date.day,
    );

    if (lastDate == null) {
      streak = 1;
      lastDate = recordDate;
    } else {
      final diff = lastDate.difference(recordDate).inDays;
      if (diff == 1) {
        streak++;
        lastDate = recordDate;
      } else {
        break;
      }
    }
  }

  return streak;
}
```

### Q2: 如何处理计时器的持久化？

`TimerController` 自动处理持久化：

```dart
// 计时器状态保存
await storage.writeJson(
  'habits/timers/$habitId.json',
  {
    'elapsedSeconds': elapsedSeconds,
    'isCountdown': isCountdown,
    'notes': notes,
  },
);

// 恢复计时器状态
final timerData = storage.readJson('habits/timers/$habitId.json');
```

### Q3: 如何扩展技能的目标功能？

在 `SkillDetailPage` 中添加进度显示：

```dart
// 计算进度
final totalDuration = await recordController.getTotalDuration(skill.id);
final progress = skill.targetMinutes > 0
    ? (totalDuration / skill.targetMinutes).clamp(0.0, 1.0)
    : 0.0;

// 显示进度条
LinearProgressIndicator(value: progress);
Text('${(totalDuration / 60).toStringAsFixed(1)} / ${(skill.targetMinutes / 60).toStringAsFixed(1)} 小时');
```

### Q4: 如何优化大量数据的加载性能？

建议实现分页加载和缓存：

```dart
class HabitController {
  final Map<String, _CachedStats> _statsCache = {};

  Future<int> getTotalDuration(String habitId) async {
    // 检查缓存
    final cached = _statsCache[habitId];
    if (cached != null && !cached.isExpired) {
      return cached.totalDuration;
    }

    // 计算并缓存
    final totalMinutes = await _calculateTotalDuration(habitId);
    _statsCache[habitId] = _CachedStats(
      totalDuration: totalMinutes,
      timestamp: DateTime.now(),
    );

    return totalMinutes;
  }
}
```

---

## 目录结构

```
habits/
├── habits_plugin.dart                    # 插件主类
├── models/
│   ├── habit.dart                        # 习惯模型
│   ├── skill.dart                        # 技能模型
│   ├── completion_record.dart            # 完成记录模型
│   ├── habits_weekly_widget_config.dart  # 周视图小组件配置
│   └── habits_weekly_widget_data.dart    # 周视图小组件数据
├── controllers/
│   ├── habit_controller.dart             # 习惯控制器
│   ├── skill_controller.dart             # 技能控制器
│   ├── completion_record_controller.dart # 完成记录控制器
│   └── timer_controller.dart             # 计时器控制器（单例）
├── repositories/
│   └── client_habits_repository.dart     # Repository 适配器
├── services/
│   └── habits_widget_service.dart        # 小组件业务逻辑
├── widgets/
│   ├── habits_bottom_bar.dart            # 底部导航栏
│   ├── habits_list/
│   │   ├── habits_view.dart              # 习惯列表视图（双视图）
│   │   ├── habits_app_bar.dart           # AppBar
│   │   ├── habits_list.dart              # 列表组件
│   │   └── habits_history_list.dart      # 历史记录
│   ├── skills_list.dart                  # 技能列表
│   ├── skill_detail_page.dart            # 技能详情
│   ├── habit_form.dart                   # 习惯表单
│   ├── skill_form.dart                   # 技能表单
│   ├── timer_dialog.dart                 # 计时器对话框
│   ├── habit_card.dart                   # 习惯卡片
│   ├── statistics_tab.dart               # 统计Tab
│   ├── completion_records_tab.dart       # 记录Tab
│   └── common_record_list.dart           # 通用记录列表
├── screens/
│   ├── habits_weekly_config_screen.dart  # 周视图配置
│   ├── habit_group_list_selector_screen.dart # 分组选择器
│   └── habit_timer_selector_screen.dart   # 计时器选择器
├── utils/
│   └── habits_utils.dart                 # 工具类
├── l10n/
│   ├── habits_translations.dart          # 国际化入口
│   ├── habits_translations_zh.dart       # 中文
│   └── habits_translations_en.dart       # 英文
├── home_widgets.dart                     # 主页小组件注册
└── habits_route_handler.dart             # 路由处理器
```

---

## 关键实现细节

### 1. 单例模式的计时器管理

```dart
class TimerController {
  static TimerController? _instance;

  factory TimerController() {
    return _instance ??= TimerController._internal();
  }

  TimerController._internal() {
    _timers = {};
  }
}
```

### 2. 事件驱动的 UI 更新

```dart
// 在 CombinedHabitsView 中订阅
@override
void initState() {
  super.initState();
  EventManager.instance.subscribe('habit_timer_started', _onTimerEvent);
  EventManager.instance.subscribe('habit_timer_stopped', _onTimerEvent);
}

// 处理事件
void _onTimerEvent(EventArgs args) {
  if (args is HabitTimerEventArgs) {
    setState(() {
      _timingStatus[args.habitId] = args.isRunning;
    });
  }
}
```

### 3. 默认数据初始化

插件首次运行时创建 8 个示例习惯，关联到预设技能：

- 晨跑、冥想、健身 → 健康生活
- 阅读、英语学习、学习新技能 → 学习提升
- 写作 → 创意艺术
- 时间回顾 → 工作效率

### 4. 图片路径处理

```dart
// 网络图片和本地图片的统一处理
FutureBuilder<String>(
  future: _image!.startsWith('http')
      ? Future.value(_image!)
      : ImageUtils.getAbsolutePath(_image!),
  builder: (context, snapshot) {
    return snapshot.hasData
        ? _image!.startsWith('http')
            ? Image.network(snapshot.data!)
            : Image.file(File(snapshot.data!))
        : CircularProgressIndicator();
  },
)
```

---

## 性能优化建议

1. **分页加载**: 实现记录的分页加载，避免一次性加载大量数据
2. **缓存统计**: 缓存计算结果，设置合理的过期时间
3. **图片优化**: 使用缩略图，延迟加载
4. **计时器优化**: 使用 Isolate 处理计时逻辑，避免阻塞 UI

---

## 变更记录 (Changelog)

- **2025-12-17**: 完整更新 - 识别 JS API、UseCase 架构、Repository 模式、Android 小组件支持、数据选择器等新特性
- **2025-11-13**: 初始化文档，识别基础架构和功能

---

**上级目录**: [返回插件目录](../) | [返回根文档](../../../CLAUDE.md)