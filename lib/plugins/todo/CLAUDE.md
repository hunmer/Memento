[根目录](../../../CLAUDE.md) > [lib](../../) > [plugins](../) > **todo**

---

# 待办事项插件 (Todo Plugin) - 模块文档

## 模块职责

待办事项插件是 Memento 的任务管理核心模块,提供:

- **任务管理**: 创建、编辑、删除任务
- **任务状态追踪**: 待办、进行中、已完成三种状态
- **任务计时器**: 内置计时功能,追踪任务执行时长
- **子任务管理**: 支持为任务添加多个子任务
- **优先级系统**: 低、中、高三级优先级
- **标签管理**: 支持为任务添加自定义标签
- **提醒功能**: 支持为任务设置多个提醒时间
- **视图模式**: 支持列表视图和网格视图切换
- **过滤与排序**: 按标签、优先级、日期等多维度筛选和排序
- **历史记录**: 保留已完成任务的历史记录
- **事件系统**: 广播任务的添加、更新、删除、完成事件

---

## 入口与启动

### 插件主类

**文件**: `todo_plugin.dart`

```dart
class TodoPlugin extends BasePlugin {
    @override
    String get id => 'todo';

    @override
    Future<void> initialize() async {
        taskController = TaskController(storageManager, storageDir);
        reminderController = ReminderController();

        // 加载默认设置
        await loadSettings({
            'defaultView': 'list',
            'defaultSortBy': 'dueDate',
            'reminderAdvanceTime': 60,
        });
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

**文件**: `views/todo_main_view.dart`

**路由**: 通过 `TodoPlugin.buildMainView()` 返回 `TodoMainView`,内部支持:
- **列表视图** (`TaskListView`): 线性展示任务,支持滑动删除
- **四象限视图** (`TodoFourQuadrantView`): 按紧急重要程度将任务划分为四个象限

---

## 对外接口

### 核心 API

#### 统计接口

```dart
// 获取总任务数
int getTotalTaskCount();

// 获取最近7天的任务数
int getWeeklyTaskCount();
```

#### TaskController 控制器

**文件**: `controllers/task_controller.dart`

```dart
// 创建新任务
Future<Task> createTask({
  required String title,
  String? description,
  DateTime? startDate,
  DateTime? dueDate,
  TaskPriority priority = TaskPriority.medium,
  List<String>? tags,
  List<Subtask>? subtasks,
  List<DateTime>? reminders,
});

// 添加任务
Future<void> addTask(Task task);

// 更新任务
Future<void> updateTask(Task task);

// 删除任务(已完成任务会移入历史记录)
Future<void> deleteTask(String taskId);

// 更新任务状态(自动处理计时器)
Future<void> updateTaskStatus(String taskId, TaskStatus status);

// 子任务管理
Future<void> addSubtask(String taskId, String title);
Future<void> updateSubtaskStatus(String taskId, String subtaskId, bool isCompleted);

// 标签管理
Future<void> addTagToTask(String taskId, String tag);
Future<void> removeTagFromTask(String taskId, String tag);
List<String> getAllTags();
List<Task> getTasksByTag(String tag);

// 过滤与排序
void applyFilter(Map<String, dynamic> filter);
void clearFilter();
void setSortBy(SortBy sortBy);

// 视图模式
void toggleViewMode();

// 历史记录管理
Future<void> removeFromHistory(String taskId);

// 统计接口
int getTaskCountByStatus(TaskStatus status, {String? tag});
int getIncompleteTaskCount({String? tag});
int getTotalTaskCount();
int getWeeklyTaskCount();
```

#### ReminderController 控制器

**文件**: `controllers/reminder_controller.dart`

```dart
// 添加提醒
void addReminder(Task task, DateTime reminderTime);

// 移除提醒
void removeReminder(String taskId, DateTime reminderTime);

// 清除任务的所有提醒
void clearReminders(String taskId);

// 获取任务的所有提醒
List<DateTime> getReminders(String taskId);

// 检查任务是否有提醒
bool hasReminders(String taskId);

// 处理错过的提醒(自动推迟1小时)
void handleMissedReminder(Task task, DateTime reminderTime);
```

---

## 关键依赖与配置

### 外部依赖

- `uuid`: 生成唯一任务ID
- `intl`: 日期格式化

### 插件依赖

- **Core Event System**: 事件广播系统
- **StorageManager**: 数据持久化

### 存储路径

**根目录**: `todo/`

**存储结构**:
```
todo/
└── tasks.json              # 所有任务数据(包括活动任务和已完成任务历史)
```

**存储文件格式** (`tasks.json`):
```json
{
  "tasks": [
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
        },
        {
          "id": "1234567891",
          "title": "编写API文档",
          "isCompleted": false
        }
      ],
      "reminders": ["2025-01-18T09:00:00.000Z"],
      "startTime": "2025-01-16T10:30:00.000Z",
      "duration": 7200000
    }
  ],
  "completedTasks": [
    {
      "id": "660e8400-e29b-41d4-a716-446655440001",
      "title": "已完成的任务",
      "completedDate": "2025-01-14T15:30:00.000Z",
      ...
    }
  ]
}
```

---

## 数据模型

### Task (任务)

**文件**: `models/task.dart`

```dart
enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class Task {
  String id;                    // 唯一ID(UUID v4)
  String title;                 // 任务标题
  String? description;          // 任务描述(可选)
  DateTime createdAt;           // 创建时间
  DateTime? startDate;          // 开始日期(可选)
  DateTime? dueDate;            // 截止日期(可选)
  TaskPriority priority;        // 优先级
  TaskStatus status;            // 任务状态
  List<String> tags;            // 标签列表
  List<Subtask> subtasks;       // 子任务列表
  List<DateTime> reminders;     // 提醒时间列表

  // 计时器字段
  DateTime? completedDate;      // 完成日期(仅已完成任务)
  DateTime? startTime;          // 计时开始时间
  Duration? duration;           // 累计持续时间

  // 计时器方法
  void startTimer();            // 启动计时
  void stopTimer();             // 停止计时
  void completeTask();          // 完成任务(停止计时)

  // 计算属性
  Color get priorityColor;      // 优先级颜色(绿/橙/红)
  IconData get statusIcon;      // 状态图标
  String get formattedDuration; // 格式化时长(HH:MM:SS)
  bool get isTimerRunning;      // 是否正在计时

  Map<String, dynamic> toJson();
  factory Task.fromJson(Map<String, dynamic> json);
  Task copyWith({...});
}
```

**优先级颜色映射**:
- `low` → 绿色 (Colors.green)
- `medium` → 橙色 (Colors.orange)
- `high` → 红色 (Colors.red)

**状态图标映射**:
- `todo` → 未勾选圆圈 (Icons.radio_button_unchecked)
- `inProgress` → 播放按钮 (Icons.play_circle_outline)
- `done` → 勾选圆圈 (Icons.check_circle_outline)

### Subtask (子任务)

**文件**: `models/subtask.dart`

```dart
class Subtask {
  String id;                    // 唯一ID(时间戳字符串)
  String title;                 // 子任务标题
  bool isCompleted;             // 是否完成

  Map<String, dynamic> toJson();
  factory Subtask.fromJson(Map<String, dynamic> json);
}
```

### Category (分类)

**文件**: `models/category.dart`

```dart
class Category {
  String id;                    // 唯一ID
  String name;                  // 分类名称
  String color;                 // 颜色编码(如 '#FF0000')
  String icon;                  // 图标标识(如 'work', 'personal')

  Color get colorValue;         // 转换为 Color 对象
  IconData get iconData;        // 转换为 IconData 对象

  Map<String, dynamic> toJson();
  factory Category.fromJson(Map<String, dynamic> json);
}
```

**预定义图标映射**:
- `work` → Icons.work
- `personal` → Icons.person
- `shopping` → Icons.shopping_cart
- `health` → Icons.favorite
- `education` → Icons.school
- 默认 → Icons.label

---

## 界面层结构

### 主要界面组件

| 组件 | 文件 | 职责 |
|------|------|------|
| `TodoMainView` | `views/todo_main_view.dart` | 插件主视图容器 |
| `TaskListView` | `widgets/task_list_view.dart` | 任务列表视图 |
| `TodoFourQuadrantView` | `views/todo_four_quadrant_view.dart` | 任务四象限视图 |
| `TaskListItem` | `widgets/task_list_item.dart` | 列表项组件 |
| `TaskDetailView` | `widgets/task_detail_view.dart` | 任务详情页 |
| `TaskForm` | `widgets/task_form.dart` | 任务创建/编辑表单 |
| `FilterDialog` | `widgets/filter_dialog.dart` | 过滤器对话框 |
| `AddTaskButton` | `widgets/add_task_button.dart` | 浮动添加按钮 |
| `HistoryCompletedView` | `widgets/history_completed_view.dart` | 已完成任务历史视图 |
| `HistoryTaskDetailView` | `widgets/history_task_detail_view.dart` | 历史任务详情页 |

### TodoMainView 布局

**布局结构**:
```
Scaffold
├── AppBar
│   ├── 标题 (待办事项)
│   ├── 过滤按钮 (filter_alt)
│   ├── 视图切换按钮 (view_list/dashboard)
│   ├── 历史记录按钮 (history)
│   └── 排序菜单 (sort)
│       ├── 按截止日期排序
│       ├── 按优先级排序
│       └── 自定义排序
├── AnimatedBuilder (监听 TaskController)
│   └── TaskListView / TodoFourQuadrantView (动态切换)
└── FloatingActionButton (AddTaskButton)
```

**关键特性**:
- 实时计时器更新(每秒刷新正在进行的任务)
- 双视图模式切换(列表/网格)
- 多维度过滤(关键词、优先级、标签、日期范围、完成状态)
- 三种排序方式(截止日期、优先级、自定义)
- 点击任务进入详情页
- 列表模式支持滑动删除

### TaskForm 表单

**核心组件**: 全屏 Scaffold 表单

**功能**:
- 任务标题输入(必填)
- 任务描述输入(可选,多行)
- 日期范围选择器(开始日期+截止日期)
- 优先级选择器(SegmentedButton)
- 标签管理(Chip + 添加对话框)
- 子任务管理(动态列表,支持添加/删除/勾选)
- 提醒时间选择(TimePicke,自动处理过期时间)

**验证规则**:
- 标题不能为空
- 提醒时间如果已过期,自动推迟到明天同一时间

### TaskDetailView 详情页

**核心组件**: 全屏 Scaffold 详情页

**功能**:
- 任务状态切换(点击状态图标循环切换)
- 编辑按钮(进入 TaskForm)
- 删除按钮(带二次确认)
- 任务计时器(开始/暂停/完成按钮)
- 实时时长显示(每秒更新)
- 任务信息展示(描述、标签、日期、子任务、提醒)

**计时器特性**:
- 显示格式化时长(HH:MM:SS)
- 进行中任务高亮显示
- 开始计时自动切换状态为"进行中"
- 暂停计时切换回"待办"状态
- 完成任务自动停止计时并标记所有子任务为完成

---

## 控制器层

### TaskController

**文件**: `controllers/task_controller.dart`

**核心职责**:
- 任务 CRUD 操作
- 任务状态管理(自动处理计时器)
- 子任务管理
- 标签管理
- 过滤与排序逻辑
- 视图模式切换
- 历史记录管理
- 统计数据计算

**重要方法**:

```dart
// 任务状态更新(智能处理计时器)
Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);

  // 如果从进行中切换,停止计时
  if (task.status == TaskStatus.inProgress) {
    task.stopTimer();
  }

  task.status = status;

  // 如果切换到进行中,启动计时
  if (status == TaskStatus.inProgress) {
    task.startTimer();
  }

  // 如果标记为完成,停止计时并完成所有子任务
  if (status == TaskStatus.done) {
    task.completeTask();
    for (var subtask in task.subtasks) {
      subtask.isCompleted = true;
    }
  }

  await _saveTasks();
}

// 智能过滤逻辑
void _applyFilter(Map<String, dynamic> filter) {
  _filteredTasks = _tasks.where((task) {
    // 关键词过滤(标题+描述)
    final keyword = filter['keyword'] as String?;
    if (keyword != null && keyword.isNotEmpty) {
      final match = task.title.toLowerCase().contains(keyword.toLowerCase()) ||
                    (task.description?.toLowerCase().contains(keyword.toLowerCase()) ?? false);
      if (!match) return false;
    }

    // 优先级过滤
    final priority = filter['priority'] as TaskPriority?;
    if (priority != null && task.priority != priority) return false;

    // 标签过滤(必须包含所有选中标签)
    final tags = filter['tags'] as List<String>?;
    if (tags != null && tags.isNotEmpty) {
      if (!tags.every((tag) => task.tags.contains(tag))) return false;
    }

    // 日期范围过滤(检查任务时间段与过滤范围是否有交集)
    final filterStartDate = filter['startDate'] as DateTime?;
    final filterEndDate = filter['endDate'] as DateTime?;
    if (filterStartDate != null || filterEndDate != null) {
      // 任务没有日期则不符合条件
      if (task.startDate == null && task.dueDate == null) return false;

      // 检查时间范围交集
      if (filterStartDate != null && task.dueDate != null) {
        if (task.dueDate!.isBefore(filterStartDate)) return false;
      }
      if (filterEndDate != null && task.startDate != null) {
        if (task.startDate!.isAfter(filterEndDate)) return false;
      }
    }

    // 完成状态过滤
    final showCompleted = filter['showCompleted'] as bool? ?? true;
    final showIncomplete = filter['showIncomplete'] as bool? ?? true;
    if (!showCompleted && task.status == TaskStatus.done) return false;
    if (!showIncomplete && task.status != TaskStatus.done) return false;

    return true;
  }).toList();

  _sortTasks();
}
```

### ReminderController

**文件**: `controllers/reminder_controller.dart`

**核心职责**:
- 管理待处理提醒
- 调度本地通知(TODO: 需集成 flutter_local_notifications)
- 处理错过的提醒

**注意**: 当前提醒功能仅在内存中管理,实际通知功能需要集成本地通知插件。

---

## 事件系统

### 事件类型

**文件**: `controllers/task_controller.dart`

| 事件名 | 触发时机 | 参数 |
|-------|---------|------|
| `task_added` | 新建任务时 | `ItemEventArgs(itemId, title, action: 'added')` |
| `task_deleted` | 删除任务时 | `ItemEventArgs(itemId, title, action: 'deleted')` |
| `task_completed` | 任务完成并移入历史时 | `ItemEventArgs(itemId, title, action: 'completed')` |

### 事件广播示例

```dart
// 在 TaskController 中
void _notifyEvent(String action, Task task) {
  final eventArgs = ItemEventArgs(
    eventName: 'task_$action',
    itemId: task.id,
    title: task.title,
    action: action,
  );
  EventManager.instance.broadcast('task_$action', eventArgs);
}

// 添加任务时
await addTask(task);
_notifyEvent('added', task);

// 删除任务时(已完成任务会触发 completed 事件)
if (task.status == TaskStatus.done) {
  _notifyEvent('completed', task);
}
_notifyEvent('deleted', task);
```

---

## 卡片视图

插件在主页提供卡片视图,展示:

**布局**:
```
┌─────────────────────────────┐
│ ☑️ 待办事项                 │
├─────────────────────────────┤
│  总任务数    │   七日任务数  │
│     15      │       8       │
└─────────────────────────────┘
```

**实现**: `todo_plugin.dart` 中的 `buildCardView()` 方法

**数据来源**:
- 总任务数: `taskController.getTotalTaskCount()`
- 七日任务数: `taskController.getWeeklyTaskCount()`

---

## 国际化

### 支持语言

- 简体中文 (zh)
- 英语 (en)

### 本地化文件

| 文件 | 语言 |
|------|------|
| `l10n/todo_localizations.dart` | 本地化接口 |
| `l10n/todo_localizations_zh.dart` | 中文翻译 |
| `l10n/todo_localizations_en.dart` | 英文翻译 |

### 关键字符串

```dart
abstract class TodoLocalizations {
  String get name;                          // 插件名称
  String get totalTasksCount;               // 总任务数
  String get weeklyTasksCount;              // 七日任务数
  String get taskDetailsTitle;              // 任务详情
  String get newTask;                       // 新建任务
  String get editTask;                      // 编辑任务
  String get deleteTaskTitle;               // 删除任务
  String get deleteTaskMessage;             // 确认删除消息
  String get title;                         // 标题
  String get description;                   // 描述
  String get startDate;                     // 开始日期
  String get dueDate;                       // 截止日期
  String get priority;                      // 优先级
  String get low;                           // 低
  String get medium;                        // 中
  String get high;                          // 高
  String get tags;                          // 标签
  String get addTag;                        // 添加标签
  String get subtasks;                      // 子任务
  String get reminders;                     // 提醒
  String get addReminder;                   // 添加提醒
  String get timer;                         // 计时器
  String get duration;                      // 持续时间
  String get start;                         // 开始
  String get pause;                         // 暂停
  String get complete;                      // 完成
  String get sortByDueDate;                 // 按截止日期排序
  String get sortByPriority;                // 按优先级排序
  String get customSort;                    // 自定义排序
  String get filterTasksTitle;              // 筛选任务
  String get showCompleted;                 // 显示已完成
  String get showIncomplete;                // 显示未完成
  String get completedTasksHistoryTitle;    // 已完成任务历史
}
```

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **已知问题**: 提醒功能未完全实现(需集成本地通知插件)

### 测试建议

1. **高优先级**:
   - `TaskController.updateTaskStatus()` - 测试计时器自动处理逻辑
   - `TaskController._applyFilter()` - 测试复杂过滤条件
   - `TaskController.updateSubtaskStatus()` - 测试自动完成任务逻辑
   - `Task.startTimer()/stopTimer()` - 测试时间计算准确性
   - 删除任务时历史记录处理

2. **中优先级**:
   - 标签管理 - 测试添加/删除标签
   - 子任务管理 - 测试子任务全部完成时自动完成任务
   - 事件广播 - 测试事件是否正确触发
   - 排序逻辑 - 测试三种排序方式
   - 日期范围过滤 - 测试边界条件

3. **低优先级**:
   - UI 交互逻辑
   - 国际化字符串完整性
   - 视图模式切换
   - 卡片视图统计展示

---

## 常见问题 (FAQ)

### Q1: 如何实现任务计时功能?

任务计时通过 `Task` 模型的三个字段实现:
- `startTime`: 记录开始计时的时间点
- `duration`: 累计持续时间
- `status`: 任务状态(inProgress 时正在计时)

```dart
// 开始计时
void startTimer() {
  status = TaskStatus.inProgress;
  startTime = DateTime.now();
  duration = null; // 重置持续时间
}

// 停止计时
void stopTimer() {
  if (startTime != null) {
    final currentDuration = DateTime.now().difference(startTime!);
    duration = (duration ?? Duration.zero) + currentDuration;
  }
}

// 显示时长(实时计算)
String get formattedDuration {
  Duration totalDuration = duration ?? Duration.zero;
  if (status == TaskStatus.inProgress && startTime != null) {
    totalDuration += DateTime.now().difference(startTime!);
  }
  return _formatDuration(totalDuration); // HH:MM:SS
}
```

### Q2: 子任务全部完成时如何自动完成主任务?

在 `TaskController.updateSubtaskStatus()` 中实现:

```dart
Future<void> updateSubtaskStatus(
  String taskId,
  String subtaskId,
  bool isCompleted,
) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);
  final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);

  subtask.isCompleted = isCompleted;

  // 检查所有子任务是否都已完成
  final allCompleted = task.subtasks.every((s) => s.isCompleted);

  if (allCompleted && task.subtasks.isNotEmpty) {
    task.status = TaskStatus.done; // 自动完成主任务
  } else if (task.status == TaskStatus.done) {
    task.status = TaskStatus.inProgress; // 取消完成状态
  }

  await _saveTasks();
}
```

### Q3: 如何实现任务过滤?

使用 `TaskController.applyFilter()` 方法:

```dart
// 过滤参数格式
Map<String, dynamic> filter = {
  'keyword': '文档',                          // 关键词搜索
  'priority': TaskPriority.high,             // 优先级过滤
  'tags': ['工作', '紧急'],                   // 标签过滤(AND逻辑)
  'startDate': DateTime(2025, 1, 1),         // 日期范围开始
  'endDate': DateTime(2025, 1, 31),          // 日期范围结束
  'showCompleted': false,                    // 隐藏已完成
  'showIncomplete': true,                    // 显示未完成
};

taskController.applyFilter(filter);

// 清除过滤
taskController.clearFilter();
```

### Q4: 如何添加新的排序方式?

1. 在 `task_controller.dart` 中扩展 `SortBy` 枚举:
```dart
enum SortBy { dueDate, priority, custom, createdDate } // 添加 createdDate
```

2. 在 `_sortTasks()` 方法中添加排序逻辑:
```dart
void _sortTasks() {
  switch (_sortBy) {
    case SortBy.createdDate:
      _tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 最新的在前
      break;
    // ... 其他排序方式
  }
}
```

3. 在 `todo_main_view.dart` 的 AppBar 中添加菜单项:
```dart
PopupMenuItem(
  value: SortBy.createdDate,
  child: Text('按创建时间排序'),
),
```

### Q5: 如何实现本地通知提醒?

当前 `ReminderController` 中提醒功能未完全实现,需要集成 `flutter_local_notifications` 插件:

**步骤**:

1. 添加依赖到 `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

2. 在 `ReminderController` 中初始化插件:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderController extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);
  }
}
```

3. 实现 `_scheduleReminder()` 方法:
```dart
void _scheduleReminder(Task task, DateTime reminderTime) {
  _notificationsPlugin.zonedSchedule(
    task.id.hashCode,
    '任务提醒',
    task.title,
    tz.TZDateTime.from(reminderTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'todo_reminders',
        '待办提醒',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

### Q6: 历史记录中的任务能否恢复?

当前实现中,已完成任务移入历史后只能查看不能恢复。如需恢复功能,可添加:

```dart
// 在 TaskController 中添加方法
Future<void> restoreFromHistory(String taskId) async {
  final historyTask = _completedTasks.firstWhere((t) => t.id == taskId);

  // 创建新任务(重置状态)
  final restoredTask = historyTask.copyWith(
    status: TaskStatus.todo,
    completedDate: null,
    startTime: null,
    duration: null,
  );

  // 添加回活动任务列表
  _tasks.add(restoredTask);

  // 从历史记录中移除
  _completedTasks.removeWhere((t) => t.id == taskId);

  await _saveTasks();
  notifyListeners();
}
```

---

## 目录结构

```
todo/
├── todo_plugin.dart                              # 插件主类
├── models/
│   ├── models.dart                               # 模型导出文件
│   ├── task.dart                                 # 任务模型(含计时器逻辑)
│   ├── subtask.dart                              # 子任务模型
│   └── category.dart                             # 分类模型(未使用)
├── controllers/
│   ├── controllers.dart                          # 控制器导出文件
│   ├── task_controller.dart                      # 任务控制器(核心业务逻辑)
│   └── reminder_controller.dart                  # 提醒控制器
├── views/
│   └── todo_main_view.dart                       # 主视图(双视图切换)
│   └── todo_four_quadrant_view.dart              # 四象限视图
├── widgets/
│   ├── task_list_view.dart                       # 列表视图
│   ├── task_list_item.dart                       # 列表项组件
│   ├── task_detail_view.dart                     # 任务详情页
│   ├── task_form.dart                            # 任务表单(创建/编辑)
│   ├── filter_dialog.dart                        # 过滤器对话框
│   ├── add_task_button.dart                      # 浮动添加按钮
│   ├── history_completed_view.dart               # 历史记录视图
│   └── history_task_detail_view.dart             # 历史任务详情页
└── l10n/
    ├── todo_localizations.dart                   # 国际化接口
    ├── todo_localizations_zh.dart                # 中文翻译
    └── todo_localizations_en.dart                # 英文翻译
```

---

## 关键实现细节

### 任务计时器机制

```dart
// Task 模型中的计时器实现
class Task {
  DateTime? startTime;    // 计时开始时间点
  Duration? duration;     // 累计持续时间

  // 启动计时
  void startTimer() {
    if (status != TaskStatus.inProgress) {
      status = TaskStatus.inProgress;
    }
    startTime = DateTime.now();
    duration = null; // 清空之前的累计时间,重新开始
  }

  // 停止计时(累加时长)
  void stopTimer() {
    if (startTime != null) {
      final currentDuration = DateTime.now().difference(startTime!);
      duration = (duration ?? Duration.zero) + currentDuration;
    }
  }

  // 实时计算显示时长
  String get formattedDuration {
    Duration totalDuration = duration ?? Duration.zero;

    // 如果正在计时,加上当前时段
    if (status == TaskStatus.inProgress && startTime != null) {
      totalDuration += DateTime.now().difference(startTime!);
    }

    return _formatDuration(totalDuration);
  }

  // 格式化为 HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
```

**设计要点**:
- `startTime` 记录当前计时段的开始时间
- `duration` 累加所有历史计时段的总时长
- 每次 `startTimer()` 清空 `duration`,重新开始计时
- 每次 `stopTimer()` 将当前时段累加到 `duration`
- `formattedDuration` 实时计算,包含正在计时的时段

### 智能状态管理

```dart
// 在 TaskController 中
Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
  final task = _tasks.firstWhere((t) => t.id == taskId);
  final oldStatus = task.status;

  // 1. 如果从进行中切换,先停止计时
  if (oldStatus == TaskStatus.inProgress) {
    task.stopTimer();
  }

  task.status = status;

  // 2. 如果切换到进行中,启动计时
  if (status == TaskStatus.inProgress) {
    task.startTimer();
  }

  // 3. 如果标记为完成,自动完成所有子任务
  if (status == TaskStatus.done) {
    task.completeTask(); // 停止计时
    for (var subtask in task.subtasks) {
      subtask.isCompleted = true;
    }
  }

  await _saveTasks();
  notifyListeners();
}
```

### 过滤器日期范围逻辑

```dart
// 检查任务时间段与过滤范围是否有交集
if (filterStartDate != null || filterEndDate != null) {
  // 任务没有日期则不符合条件
  if (task.startDate == null && task.dueDate == null) return false;

  // 检查任务的截止日期是否早于过滤开始日期
  if (filterStartDate != null && task.dueDate != null) {
    if (task.dueDate!.isBefore(filterStartDate)) return false;
  }

  // 如果任务只有开始日期,检查是否早于过滤开始日期
  if (filterStartDate != null && task.dueDate == null && task.startDate != null) {
    if (task.startDate!.isBefore(filterStartDate)) return false;
  }

  // 检查任务的开始日期是否晚于过滤结束日期
  if (filterEndDate != null && task.startDate != null) {
    if (task.startDate!.isAfter(filterEndDate)) return false;
  }

  // 如果任务只有截止日期,检查是否晚于过滤结束日期
  if (filterEndDate != null && task.startDate == null && task.dueDate != null) {
    if (task.dueDate!.isAfter(filterEndDate)) return false;
  }
}
```

**原理**: 任务时间段 [startDate, dueDate] 与过滤范围 [filterStartDate, filterEndDate] 有交集

### 实时UI更新机制

```dart
// 在 TodoMainView 中
@override
void initState() {
  super.initState();
  _plugin = TodoPlugin.instance;

  // 每秒检查是否有正在计时的任务
  _timer = Timer.periodic(const Duration(seconds: 1), (_) {
    bool hasActiveTimer = false;
    for (final task in _plugin.taskController.tasks) {
      if (task.status == TaskStatus.inProgress && task.startTime != null) {
        hasActiveTimer = true;
        break;
      }
    }

    // 只有在有活动计时器时才刷新UI
    if (hasActiveTimer) {
      setState(() {});
    }
  });
}
```

**优化**: 仅当存在正在计时的任务时才执行 UI 刷新,避免不必要的性能开销

---

## 依赖关系

### 核心依赖

- **BasePlugin**: 插件基类
- **StorageManager**: 数据持久化
- **EventManager**: 事件广播系统
- **PluginManager**: 插件管理器
- **ConfigManager**: 配置管理器

### 第三方包依赖

- `uuid: ^4.0.0` - UUID生成
- `intl: ^0.18.0` - 日期格式化

### 可选依赖(未实现)

- `flutter_local_notifications` - 本地通知(提醒功能)

---

## 性能优化建议

### 1. 过滤性能优化

当任务数量较大时,过滤操作可能成为性能瓶颈:

```dart
// 建议:使用索引加速
class TaskController extends ChangeNotifier {
  // 按标签索引
  Map<String, List<Task>> _tagIndex = {};

  // 按优先级索引
  Map<TaskPriority, List<Task>> _priorityIndex = {};

  // 重建索引
  void _rebuildIndexes() {
    _tagIndex.clear();
    _priorityIndex.clear();

    for (final task in _tasks) {
      // 标签索引
      for (final tag in task.tags) {
        _tagIndex.putIfAbsent(tag, () => []).add(task);
      }

      // 优先级索引
      _priorityIndex.putIfAbsent(task.priority, () => []).add(task);
    }
  }

  // 使用索引加速过滤
  void _applyFilterWithIndex(Map<String, dynamic> filter) {
    List<Task> candidates = _tasks;

    // 先用索引缩小范围
    if (filter['priority'] != null) {
      candidates = _priorityIndex[filter['priority']] ?? [];
    }

    if (filter['tags'] != null && (filter['tags'] as List).isNotEmpty) {
      final tag = (filter['tags'] as List).first;
      candidates = _tagIndex[tag] ?? [];
    }

    // 再进行详细过滤
    _filteredTasks = candidates.where((task) {
      // ... 详细过滤逻辑
    }).toList();
  }
}
```

### 2. 大列表渲染优化

使用 `ListView.builder` 而非 `ListView`:

```dart
// 当前实现已采用 ListView.builder,这是正确的做法
ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    final task = tasks[index];
    return TaskListItem(task: task);
  },
)
```

### 3. 计时器优化

避免为每个任务创建单独的 Timer:

```dart
// 当前实现在 TodoMainView 中使用单个 Timer
// 这是正确的做法,避免了多个 Timer 的性能开销
_timer = Timer.periodic(const Duration(seconds: 1), (_) {
  // 只有在有活动计时器时才刷新
  if (hasActiveTimer) {
    setState(() {});
  }
});
```

---

## 变更记录 (Changelog)

- **2025-11-13**: 初始化待办事项插件文档,识别 21 个文件、3 个数据模型、3 个事件类型、任务计时器系统、多维度过滤与排序、历史记录管理

---

**上级目录**: [返回插件目录](../../../CLAUDE.md#模块索引) | [返回根文档](../../../CLAUDE.md)
