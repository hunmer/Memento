[根目录](../../../CLAUDE.md) > [lib](../../) > [plugins](../) > **habits**

---

# 习惯追踪插件 (Habits Plugin) - 模块文档

## 模块职责

习惯追踪插件是 Memento 的核心功能模块之一，提供：

- **习惯管理**: 创建、编辑、删除习惯
- **技能系统**: 将习惯关联到技能，实现目标导向的习惯培养
- **完成记录**: 记录习惯的完成情况和时长
- **计时器功能**: 内置倒计时/正计时器，支持暂停、恢复
- **双视图模式**: 支持列表视图和卡片视图切换
- **分组管理**: 按技能或自定义分组组织习惯
- **图标与图片**: 支持自定义图标和封面图片
- **统计功能**: 完成次数、累计时长、历史记录
- **事件系统**: 广播计时器的启动、停止事件

---

## 入口与启动

### 插件主类

**文件**: `habits_plugin.dart`

```dart
class HabitsPlugin extends PluginBase {
    @override
    String get id => 'habits';

    @override
    Future<void> initialize() async {
        _timerController = TimerController();
        _habitController = HabitController(
            storage,
            timerController: _timerController,
        );
        _skillController = SkillController(storage);
        _recordController = CompletionRecordController(
            storage,
            habitController: _habitController,
            skillControlle: _skillController,
        );
    }

    @override
    Future<void> registerToApp(
        PluginManager pluginManager,
        ConfigManager configManager,
    ) async {
        // 插件已在 initialize() 中完成初始化
    // 这里可以添加额外的应用级注册逻辑
    }
}
```

### 主界面入口

**文件**: `widgets/habits_home.dart`

**路由**: 通过 `HabitsPlugin.buildMainView()` 返回 `HabitsMainView`，其内部渲染 `HabitsHome`

**布局**: 底部导航栏双 Tab 结构（习惯列表 + 技能列表）

---

## 对外接口

### 核心 API

#### 统计接口

```dart
// 获取习惯数量
int getHabitCount();

// 获取技能数量
int getSkillCount();
```

#### HabitController 控制器

**文件**: `controllers/habit_controller.dart`

```dart
// 加载所有习惯
Future<List<Habit>> loadHabits();

// 获取习惯列表
List<Habit> getHabits();

// 保存习惯（创建或更新）
Future<void> saveHabit(Habit habit);

// 删除习惯
Future<void> deleteHabit(String id);

// 计时器模式监听器
void addTimerModeListener(TimerModeListener listener);
void removeTimerModeListener(TimerModeListener listener);
void notifyTimerModeChanged(String habitId, bool isCountdown);
```

#### SkillController 控制器

**文件**: `controllers/skill_controller.dart`

```dart
// 加载所有技能
Future<List<Skill>> loadSkills();

// 获取技能列表
List<Skill> getSkills();

// 根据ID获取技能
Skill getSkillById(String id);

// 根据标题获取技能（唯一性检查）
Skill? getSkillByTitle(String? title);

// 保存技能（创建或更新）
Future<void> saveSkill(Skill skill);

// 删除技能
Future<void> deleteSkill(String id);

// 获取技能的完成记录
Future<List<CompletionRecord>> getSkillCompletionRecords(String skillId);
```

#### CompletionRecordController 控制器

**文件**: `controllers/completion_record_controller.dart`

```dart
// 保存完成记录
Future<void> saveCompletionRecord(String habitId, CompletionRecord record);

// 获取习惯的完成记录
Future<List<CompletionRecord>> getHabitCompletionRecords(String habitId);

// 获取技能的完成记录
Future<List<CompletionRecord>> getSkillCompletionRecords(String skillId);

// 获取技能关联的习惯ID列表
Future<List<String>> getSkillHabitIds(String skillId);

// 获取总时长（分钟）
Future<int> getTotalDuration(String habitId);

// 获取完成次数
Future<int> getCompletionCount(String habitId);

// 删除完成记录
Future<void> deleteCompletionRecord(String recordId);

// 清空习惯的所有完成记录
Future<void> clearAllCompletionRecords(String habitId);
```

#### TimerController 控制器

**文件**: `controllers/timer_controller.dart`

```dart
// 启动计时器
void startTimer(
    Habit habit,
    TimerUpdateCallback onUpdate, {
    Duration? initialDuration,
});

// 停止计时器
void stopTimer(String habitId);

// 暂停计时器
void pauseTimer(String habitId);

// 切换计时器状态
void toggleTimer(String habitId, bool isRunning);

// 设置倒计时模式
void setCountdownMode(String habitId, bool isCountdown);

// 获取计时器数据
Map<String, dynamic>? getTimerData(String habitId);

// 更新计时器数据
void updateTimerData(String habitId, Map<String, dynamic> data);

// 清除计时器数据
void clearTimerData(String habitId);

// 获取所有活动计时器
Map<String, bool> getActiveTimers();

// 检查习惯是否正在计时
bool isHabitTiming(String habitId);
```

---

## 关键依赖与配置

### 外部依赖

- `uuid`: 生成唯一ID（通过 `HabitsUtils.generateId()`）
- `path`: 路径处理

### 插件依赖

- **Core Event System**: 事件广播系统（计时器事件）
- **StorageManager**: 数据持久化
- **ImageUtils**: 图片路径处理
- **CircleIconPicker**: 图标选择器组件
- **ImagePickerDialog**: 图片选择对话框

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
└── habit_images/               # 习惯封面图片
    ├── <uuid>.jpg
    └── ...
```

**习惯数据格式** (`habits.json`):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "晨跑",
    "notes": "每天早上跑步30分钟",
    "group": "健康",
    "icon": "58248",
    "image": "habits/habit_images/abc123.jpg",
    "reminderDays": [1, 2, 3, 4, 5],
    "intervalDays": 0,
    "durationMinutes": 30,
    "tags": ["运动", "健康"],
    "skillId": "skill-001"
  }
]
```

**技能数据格式** (`skills.json`):
```json
[
  {
    "id": "skill-001",
    "title": "健康生活",
    "description": "保持健康的生活方式",
    "notes": "包括运动、饮食、睡眠",
    "group": "健康",
    "icon": "59512",
    "image": "habits/skill_images/xyz789.jpg",
    "targetMinutes": 10000,
    "maxDurationMinutes": 0
  }
]
```

**完成记录格式** (`records/<habitId>.json`):
```json
[
  {
    "id": "record-001",
    "parentId": "550e8400-e29b-41d4-a716-446655440000",
    "date": "2025-01-15T08:30:00.000Z",
    "duration": 1800,
    "notes": "今天跑了5公里"
  }
]
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

  Map<String, dynamic> toMap();
  factory Habit.fromMap(Map<String, dynamic> map);
}
```

**字段说明**:
- `icon`: 存储为 `IconData.codePoint.toString()`，使用时通过 `IconData(int.parse(icon!), fontFamily: 'MaterialIcons')` 恢复
- `image`: 支持网络URL（`http`开头）或本地相对路径
- `reminderDays`: `[1,2,3,4,5]` 表示周一到周五提醒

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

  Map<String, dynamic> toMap();
  factory Skill.fromMap(Map<String, dynamic> map);
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

  Map<String, dynamic> toMap();
  factory CompletionRecord.fromMap(Map<String, dynamic> map);
}
```

**存储格式转换**:
- `duration`: 存储为 `duration.inSeconds`，读取时转换为 `Duration(seconds: ...)`

---

## 界面层结构

### 主要界面组件

| 组件 | 文件 | 职责 |
|------|------|------|
| `HabitsMainView` | `habits_plugin.dart` | 插件主视图容器 |
| `HabitsHome` | `widgets/habits_home.dart` | 底部导航栏主界面 |
| `CombinedHabitsView` | `widgets/habits_list/habits_view.dart` | 习惯列表视图 |
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

### HabitsHome 布局

**布局结构**:
```
Scaffold
├── PageView (禁止手动滑动)
│   ├── CombinedHabitsView (习惯列表)
│   └── SkillsList (技能列表)
└── BottomNavigationBar
    ├── 习惯 (Icons.check_circle)
    └── 技能 (Icons.star)
```

**关键特性**:
- 使用 `KeepAliveWrapper` 保持页面状态
- `PageView` 禁用手动滑动，仅通过底部导航栏切换
- 页面切换动画（300ms，ease曲线）

### CombinedHabitsView 布局

**布局结构**:
```
Column
├── HabitsAppBar
│   ├── 返回按钮
│   ├── 标题（习惯）
│   ├── 视图切换按钮（列表/卡片）
│   └── 添加按钮
└── Expanded
    ├── 卡片视图（GridView 2列）
    │   └── 按技能分组 + 习惯卡片
    └── 列表视图（ListView）
        └── 按技能分组 + 习惯列表项
```

**关键特性**:
- 双视图模式（`_isCardView` 状态切换）
- 按技能自动分组（未关联技能归入"未分类"）
- 卡片视图显示封面图片和计时器按钮
- 列表视图支持长按查看历史记录
- 实时计时器状态更新（监听 `habit_timer_started/stopped` 事件）

### HabitForm 表单

**核心组件**: 全屏 Scaffold 表单

**功能**:
- 图片选择器（圆形头像，支持裁剪）
- 图标选择器（`CircleIconPicker`）
- 标题输入（必填）
- 备注输入（可选，多行）
- 分组输入（可选）
- 时长输入（默认30分钟）
- 技能关联下拉框（必填，可选"请选择技能"）

**验证规则**:
- 标题不能为空
- 必须选择关联的技能

### TimerDialog 对话框

**核心组件**: 全屏对话框

**功能**:
- 显示习惯标题和时长
- 倒计时/正计时模式切换
- 时间显示（格式化为 HH:MM:SS）
- 开始/暂停按钮
- 完成按钮（保存完成记录）
- 备注输入框
- 自动保存计时器状态

**计时器特性**:
- 倒计时模式：从 `durationMinutes` 倒数到 0
- 正计时模式：从 0 开始计时
- 支持暂停/恢复
- 完成时保存 `CompletionRecord`
- 关闭对话框时停止计时器

---

## 控制器层

### HabitController

**文件**: `controllers/habit_controller.dart`

**核心职责**:
- 习惯数据的 CRUD 操作
- 从 `habits/habits.json` 加载/保存数据
- 计时器模式变更通知

**存储机制**:
```dart
// 保存时自动过滤空Map
Future<void> saveHabit(Habit habit) async {
    final habits = getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);

    if (index >= 0) {
        habits[index] = habit;
    } else {
        habits.add(habit);
    }

    await storage.writeJson(
        'habits/habits',
        habits.map((h) => h.toMap()).toList(),
    );
}
```

**计时器模式监听器**:
```dart
// 当计时器模式（倒计时/正计时）改变时通知UI更新
void notifyTimerModeChanged(String habitId, bool isCountdown) {
    for (final listener in _timerModeListeners) {
        listener(habitId, isCountdown);
    }
}
```

### SkillController

**文件**: `controllers/skill_controller.dart`

**核心职责**:
- 技能数据的 CRUD 操作
- 从 `habits/skills.json` 加载/保存数据
- 根据标题查找技能（唯一性检查）

**重要方法**:

```dart
// 根据标题获取技能（避免歧义）
Skill? getSkillByTitle(String? title) {
    if (title == null || title.isEmpty) {
        return null;
    }

    final matchingSkills = _skills.where((s) => s.title == title).toList();

    if (matchingSkills.isEmpty) {
        return null;
    }

    if (matchingSkills.length > 1) {
        return null; // 避免返回模糊结果
    }

    return matchingSkills.first;
}
```

**设计要点**:
- 当多个技能同名时返回 `null`，避免误操作
- 在 UI 中用于按技能分组时获取技能信息

### CompletionRecordController

**文件**: `controllers/completion_record_controller.dart`

**核心职责**:
- 完成记录的 CRUD 操作
- 从 `habits/records/<habitId>.json` 加载/保存数据
- 统计功能（总时长、完成次数）
- 技能与习惯的关联查询

**重要方法**:

```dart
// 获取技能的所有完成记录（聚合所有关联习惯的记录）
Future<List<CompletionRecord>> getSkillCompletionRecords(
    String skillId,
) async {
    final matchingRecords = <CompletionRecord>[];

    // 1. 获取所有属于指定skillId的habitIds
    final skillHabitIds = await getSkillHabitIds(skillId);

    // 2. 获取这些habitIds对应的records
    for (final habitId in skillHabitIds) {
        final path = 'habits/records/$habitId.json';
        if (await storage.fileExists(path)) {
            final data = await storage.readJson(path);
            if (data != null) {
                matchingRecords.addAll(
                    List<Map<String, dynamic>>.from(
                        data as Iterable,
                    ).map((e) => CompletionRecord.fromMap(e)),
                );
            }
        }
    }

    return matchingRecords;
}
```

**设计要点**:
- 每个习惯的完成记录单独存储在 `records/<habitId>.json`
- 技能的统计数据通过聚合所有关联习惯的记录计算

### TimerController

**文件**: `controllers/timer_controller.dart`

**核心职责**:
- 管理所有活动计时器
- 倒计时/正计时模式切换
- 计时器状态持久化
- 事件广播（启动/停止）

**计时器状态管理**:
```dart
class TimerState {
    final Habit habit;
    final TimerUpdateCallback onUpdate;
    bool isRunning = false;
    bool isCountdown = true;
    int elapsedSeconds = 0;
    String? notes = '';
    Timer? _timer;
    final Duration? initialDuration;

    void start() {
        if (isRunning) return;
        isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            elapsedSeconds++;
            onUpdate(elapsedSeconds);
        });
        EventManager.instance.broadcast(
            'habit_timer_started',
            HabitTimerEventArgs(...),
        );
    }

    void stop() {
        isRunning = false;
        _timer?.cancel();
        _timer = null;
        EventManager.instance.broadcast(
            'habit_timer_stopped',
            HabitTimerEventArgs(...),
        );
    }
}
```

**单例模式**:
```dart
class TimerController {
    static TimerController? _instance;

    factory TimerController() {
        return _instance ??= TimerController._internal();
    }

    TimerController._internal() {
        _timers = {};
    }

    Map<String, TimerState> _timers = {};
}
```

**设计要点**:
- 使用单例模式确保全局唯一计时器管理器
- 每个习惯最多一个活动计时器
- 启动新计时器时自动停止旧计时器
- 计时器状态通过 `Map<String, dynamic>` 持久化

---

## 事件系统

### 事件类型

**文件**: `controllers/timer_controller.dart`

| 事件名 | 事件类 | 触发时机 | 参数 |
|-------|--------|---------|------|
| `habit_timer_started` | `HabitTimerEventArgs` | 计时器启动时 | `habitId`, `elapsedSeconds`, `isCountdown`, `isRunning=true` |
| `habit_timer_stopped` | `HabitTimerEventArgs` | 计时器停止时 | `habitId`, `elapsedSeconds`, `isCountdown`, `isRunning=false` |

### 事件广播示例

```dart
// 在 TimerState.start() 中
EventManager.instance.broadcast(
    'habit_timer_started',
    HabitTimerEventArgs(
        habitId: habit.id,
        elapsedSeconds: elapsedSeconds,
        isCountdown: isCountdown,
        isRunning: true,
    ),
);

// 在 CombinedHabitsView 中订阅
EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);

void _onTimerStarted(EventArgs args) {
    if (args is HabitTimerEventArgs) {
        setState(() {
            _timingStatus[args.habitId] = args.isRunning;
        });
    }
}
```

---

## 卡片视图

插件在主页提供卡片视图，展示：

**布局**:
```
┌─────────────────────────────┐
│ ✨ 习惯追踪                │
├─────────────────────────────┤
│   习惯数    │    技能数     │
│      8      │       3       │
└─────────────────────────────┘
```

**实现**: `habits_plugin.dart` 中的 `buildCardView()` 方法

**数据来源**:
- 习惯数: `_habitController.getHabits().length`
- 技能数: `_skillController.getSkills().length`

---

## 国际化

### 支持语言

- 简体中文 (zh)
- 英语 (en)

### 本地化文件

| 文件 | 语言 |
|------|------|
| `l10n/habits_localizations.dart` | 本地化接口 |
| `l10n/habits_localizations_zh.dart` | 中文翻译 |
| `l10n/habits_localizations_en.dart` | 英文翻译 |

### 关键字符串

```dart
abstract class HabitsLocalizations {
  String get name;                          // 插件名称
  String get habits;                        // 习惯
  String get skills;                        // 技能
  String get habitsList;                    // 习惯列表
  String get newHabit;                      // 新建习惯
  String get editHabit;                     // 编辑习惯
  String get deleteHabit;                   // 删除习惯
  String get createHabit;                   // 创建习惯
  String get createSkill;                   // 创建技能
  String get editSkill;                     // 编辑技能
  String get deleteSkill;                   // 删除技能
  String get title;                         // 标题
  String get pleaseEnterTitle;              // 请输入标题
  String get notes;                         // 备注
  String get group;                         // 分组
  String get duration;                      // 时长
  String get minutes;                       // 分钟
  String get skill;                         // 技能
  String get selectSkill;                   // 请选择技能
  String get save;                          // 保存
  String get cancel;                        // 取消
  String get delete;                        // 删除
  String get history;                       // 历史记录
  String get records;                       // 记录
  String get statistics;                    // 统计
  String get completions;                   // 完成次数
  String get totalDuration;                 // 总时长
  String get totalCompletions;              // 总完成次数
  String get sortByName;                    // 按名称排序
  String get sortByCompletions;             // 按完成次数排序
  String get sortByDuration;                // 按时长排序
  String get deleteRecord;                  // 删除记录
  String get deleteRecordMessage;           // 删除记录确认消息
  String get clearAllRecords;               // 清空所有记录
  String get skillName;                     // 技能名称
  String get skillDescription;              // 技能描述
  String get skillGroup;                    // 技能分组
  String get maxDuration;                   // 最大时长
  String get noLimitHint;                   // 无限制提示
  String get statisticsChartsPlaceholder;   // 统计图表占位符
}
```

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **已知问题**:
  - `CompletionRecordController` 构造函数参数 `skillControlle` 拼写错误（应为 `skillController`）
  - 提醒功能未实现（`reminderDays` 字段未使用）

### 测试建议

1. **高优先级**：
   - `HabitController.saveHabit()` - 测试创建、更新逻辑
   - `SkillController.getSkillByTitle()` - 测试唯一性检查逻辑
   - `CompletionRecordController.getSkillCompletionRecords()` - 测试聚合逻辑
   - `TimerController` - 测试计时器启动、停止、状态持久化
   - 图片路径处理 - 测试网络URL和本地路径的区分

2. **中优先级**：
   - 事件广播 - 测试事件是否正确触发
   - 数据持久化 - 测试JSON序列化/反序列化
   - 分组逻辑 - 测试按技能/分组的聚合
   - 统计功能 - 测试总时长、完成次数计算

3. **低优先级**：
   - UI 交互逻辑
   - 国际化字符串完整性
   - 图标选择器

---

## 常见问题 (FAQ)

### Q1: 如何实现习惯提醒功能？

当前 `reminderDays` 字段未使用，建议实现方式：

```dart
// 1. 在 HabitController 中添加提醒调度方法
Future<void> scheduleReminders(Habit habit) async {
    // 使用 flutter_local_notifications 插件
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    for (final day in habit.reminderDays) {
        await notificationsPlugin.zonedSchedule(
            habit.id.hashCode + day,
            '习惯提醒',
            habit.title,
            _getNextWeekday(day, reminderTime),
            const NotificationDetails(...),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
    }
}
```

### Q2: 如何区分倒计时和正计时模式？

在 `TimerDialog` 中：

```dart
// isCountdown = true: 倒计时模式
// 显示时间 = durationMinutes * 60 - elapsedSeconds
final remainingSeconds = (widget.habit.durationMinutes * 60) - elapsedSeconds;

// isCountdown = false: 正计时模式
// 显示时间 = elapsedSeconds
final displaySeconds = elapsedSeconds;
```

用户可通过对话框中的切换按钮改变模式。

### Q3: 如何实现习惯连续天数统计？

当前未实现，建议添加：

```dart
// 在 CompletionRecordController 中
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
            // 第一条记录
            streak = 1;
            lastDate = recordDate;
        } else {
            // 检查是否连续
            final diff = lastDate.difference(recordDate).inDays;
            if (diff == 1) {
                streak++;
                lastDate = recordDate;
            } else {
                break; // 中断连续
            }
        }
    }

    return streak;
}
```

### Q4: 技能的目标时长如何使用？

当前 `targetMinutes` 和 `maxDurationMinutes` 字段未在 UI 中使用，建议在 `SkillDetailPage` 中：

```dart
// 显示进度条
final totalDuration = await recordController.getTotalDuration(skill.id);
final progress = skill.targetMinutes > 0
    ? (totalDuration / skill.targetMinutes).clamp(0.0, 1.0)
    : 0.0;

LinearProgressIndicator(value: progress);
Text('${totalDuration} / ${skill.targetMinutes} 分钟');
```

### Q5: 如何删除技能时同时删除关联习惯？

当前删除技能不会删除关联习惯，建议添加级联删除：

```dart
Future<void> deleteSkillWithHabits(String skillId) async {
    // 1. 删除所有关联习惯
    final habits = habitController.getHabits();
    final relatedHabits = habits.where((h) => h.skillId == skillId).toList();

    for (final habit in relatedHabits) {
        await habitController.deleteHabit(habit.id);
        await recordController.clearAllCompletionRecords(habit.id);
    }

    // 2. 删除技能
    await skillController.deleteSkill(skillId);
}
```

或者提供选项：

```dart
showDialog(
    context: context,
    builder: (context) => AlertDialog(
        title: Text('删除技能'),
        content: Text('是否同时删除关联的 ${relatedHabits.length} 个习惯？'),
        actions: [
            TextButton(
                child: Text('仅删除技能'),
                onPressed: () {
                    // 将关联习惯的 skillId 设为 null
                    for (final habit in relatedHabits) {
                        habitController.saveHabit(
                            habit.copyWith(skillId: null),
                        );
                    }
                    skillController.deleteSkill(skillId);
                    Navigator.pop(context);
                },
            ),
            TextButton(
                child: Text('删除技能和习惯'),
                onPressed: () {
                    deleteSkillWithHabits(skillId);
                    Navigator.pop(context);
                },
            ),
        ],
    ),
);
```

### Q6: 如何导出习惯数据？

建议添加导出功能：

```dart
Future<File> exportHabitsToJson() async {
    final habits = habitController.getHabits();
    final skills = skillController.getSkills();
    final records = <String, List<CompletionRecord>>{};

    for (final habit in habits) {
        records[habit.id] = await recordController.getHabitCompletionRecords(habit.id);
    }

    final exportData = {
        'habits': habits.map((h) => h.toMap()).toList(),
        'skills': skills.map((s) => s.toMap()).toList(),
        'records': records.map(
            (key, value) => MapEntry(key, value.map((r) => r.toMap()).toList()),
        ),
        'exportDate': DateTime.now().toIso8601String(),
    };

    final file = File('habits_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(exportData));
    return file;
}
```

---

## 目录结构

```
habits/
├── habits_plugin.dart                    # 插件主类 + 事件定义
├── models/
│   ├── habit.dart                        # 习惯模型
│   ├── skill.dart                        # 技能模型
│   └── completion_record.dart            # 完成记录模型
├── controllers/
│   ├── habit_controller.dart             # 习惯控制器
│   ├── skill_controller.dart             # 技能控制器
│   ├── completion_record_controller.dart # 完成记录控制器
│   └── timer_controller.dart             # 计时器控制器 + 事件定义
├── widgets/
│   ├── habits_home.dart                  # 主界面（底部导航栏）
│   ├── habits_list/
│   │   ├── habits_view.dart              # 习惯列表视图（双视图模式）
│   │   ├── habits_app_bar.dart           # 习惯列表AppBar
│   │   ├── habits_list.dart              # 习惯列表组件
│   │   └── habits_history_list.dart      # 历史记录列表
│   ├── skills_list.dart                  # 技能列表视图
│   ├── skill_detail_page.dart            # 技能详情页
│   ├── habit_form.dart                   # 习惯创建/编辑表单
│   ├── skill_form.dart                   # 技能创建/编辑表单
│   ├── timer_dialog.dart                 # 计时器对话框
│   ├── habit_card.dart                   # 习惯卡片组件
│   ├── statistics_tab.dart               # 统计信息Tab
│   ├── completion_records_tab.dart       # 完成记录Tab
│   └── common_record_list.dart           # 通用记录列表
├── utils/
│   └── habits_utils.dart                 # 工具类（ID生成、时长格式化）
└── l10n/
    ├── habits_localizations.dart         # 国际化接口
    ├── habits_localizations_zh.dart      # 中文翻译
    └── habits_localizations_en.dart      # 英文翻译
```

---

## 关键实现细节

### 按技能分组的实现

```dart
// 在 CombinedHabitsView 中
final groupedHabits = <String, List<Habit>>{};
for (final habit in habits) {
    final skillTitle = habit.skillId != null
        ? skillController?.getSkillById(habit.skillId!)?.title ?? '未分类'
        : '未分类';
    groupedHabits.putIfAbsent(skillTitle, () => []).add(habit);
}

// 渲染分组
return ListView(
    children: groupedHabits.entries.map((entry) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // 分组标题
                Text(entry.key, style: ...),
                // 分组内的习惯
                ...entry.value.map((habit) => HabitListItem(...)),
            ],
        );
    }).toList(),
);
```

**设计要点**:
- 使用 `Map<String, List<Habit>>` 实现分组
- 未关联技能的习惯归入"未分类"
- 技能被删除后，关联习惯仍显示为"未分类"

### 图片路径处理

```dart
// 在 HabitForm/SkillForm 中
FutureBuilder<String>(
    future: _image!.startsWith('http')
        ? Future.value(_image!)
        : ImageUtils.getAbsolutePath(_image!),
    builder: (context, snapshot) {
        if (snapshot.hasData) {
            return _image!.startsWith('http')
                ? Image.network(snapshot.data!)
                : Image.file(File(snapshot.data!));
        }
        return CircularProgressIndicator();
    },
)
```

**设计要点**:
- 使用 `startsWith('http')` 区分网络URL和本地路径
- 本地路径通过 `ImageUtils.getAbsolutePath()` 转换为绝对路径
- 使用 `FutureBuilder` 异步加载图片

### 计时器状态同步

```dart
// 在 CombinedHabitsView 中
@override
void initState() {
    super.initState();
    final activeTimers = habitsPlugin!.timerController.getActiveTimers();
    _timingStatus.addAll(activeTimers);
    EventManager.instance.subscribe('habit_timer_started', _onTimerStarted);
    EventManager.instance.subscribe('habit_timer_stopped', _onTimerStopped);
}

void _onTimerStarted(EventArgs args) {
    if (args is HabitTimerEventArgs) {
        setState(() {
            _timingStatus[args.habitId] = args.isRunning;
        });
    }
}
```

**设计要点**:
- 初始化时从 `TimerController` 获取所有活动计时器
- 订阅计时器事件实时更新UI
- 使用 `_timingStatus` Map 缓存计时状态，避免频繁查询

### 单例模式的计时器管理

```dart
class TimerController {
    static TimerController? _instance;

    factory TimerController() {
        return _instance ??= TimerController._internal();
    }

    TimerController._internal() {
        _timers = {};
    }

    Map<String, TimerState> _timers = {};
}
```

**设计要点**:
- 使用单例模式确保全局唯一计时器管理器
- 避免多个 `TimerController` 实例导致计时器状态不一致
- 在插件初始化时创建实例

---

## 依赖关系

### 核心依赖

- **PluginBase**: 插件基类
- **StorageManager**: 数据持久化
- **EventManager**: 事件广播系统
- **PluginManager**: 插件管理器

### 第三方包依赖

- `uuid`: UUID生成（通过 `HabitsUtils.generateId()`）
- `path`: 路径处理

### 组件依赖

- **CircleIconPicker**: 圆形图标选择器（`lib/widgets/circle_icon_picker.dart`）
- **ImagePickerDialog**: 图片选择对话框（`lib/widgets/image_picker_dialog.dart`）
- **ImageUtils**: 图片路径工具类（`lib/utils/image_utils.dart`）
- **KeepAliveWrapper**: 页面状态保持组件（`lib/core/widgets/keep_alive_wrapper.dart`）

---

## 性能优化建议

### 1. 完成记录统计优化

当习惯数量较多时，统计功能可能成为性能瓶颈：

```dart
// 当前实现：每次都读取JSON文件
Future<int> getTotalDuration(String habitId) async {
    final records = await getSkillCompletionRecords(habitId);
    return records.fold<int>(
        0,
        (sum, record) => sum + record.duration.inMinutes,
    );
}

// 优化建议：缓存统计数据
class CompletionRecordController {
    final Map<String, _CachedStats> _statsCache = {};

    Future<int> getTotalDuration(String habitId) async {
        final cached = _statsCache[habitId];
        if (cached != null && !cached.isExpired) {
            return cached.totalDuration;
        }

        final records = await getSkillCompletionRecords(habitId);
        final totalDuration = records.fold<int>(
            0,
            (sum, record) => sum + record.duration.inMinutes,
        );

        _statsCache[habitId] = _CachedStats(
            totalDuration: totalDuration,
            completionCount: records.length,
            timestamp: DateTime.now(),
        );

        return totalDuration;
    }
}

class _CachedStats {
    final int totalDuration;
    final int completionCount;
    final DateTime timestamp;

    bool get isExpired => DateTime.now().difference(timestamp).inMinutes > 5;
}
```

### 2. 图片加载优化

```dart
// 使用 CachedNetworkImage 代替 Image.network
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
    imageUrl: imageUrl,
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.broken_image),
)
```

### 3. 列表渲染优化

```dart
// 当前实现已使用 ListView.builder，这是正确的做法
// GridView.builder 也已正确使用
GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
    ),
    itemCount: habits.length,
    itemBuilder: (context, index) => HabitCard(...),
)
```

---

## 变更记录 (Changelog)

- **2025-11-13**: 初始化习惯追踪插件文档，识别 25 个文件、3 个数据模型、4 个控制器、2 个计时器事件类型、双视图模式、技能系统

---

**上级目录**: [返回插件目录](../../../CLAUDE.md#模块索引) | [返回根文档](../../../CLAUDE.md)
