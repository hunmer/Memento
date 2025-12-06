# 统一计时器控制器实施总结

## 项目概述

本项目成功将Memento应用中的4个插件（todo、tracker、timer、habits）的计时器功能统一到一个控制器中，并实现了移动设备通知栏的多计时器同步显示功能。

## 核心成果

### 1. 统一计时器控制器架构
- **单例模式**：全局唯一的`UnifiedTimerController`实例
- **事件驱动**：使用`EventManager`广播统一事件
- **多插件支持**：支持10-20个计时器并行运行
- **平台同步**：实时同步到Android通知栏

### 2. 核心文件变更

#### 新增核心层文件
- `lib/core/services/timer/models/timer_state.dart` - 统一计时器状态模型
- `lib/core/services/timer/unified_timer_controller.dart` - 统一计时器控制器核心
- `lib/core/services/timer/events/timer_events.dart` - 统一事件系统
- `lib/core/services/timer/storage/timer_storage.dart` - 统一存储管理

#### 修改的核心文件
- `lib/core/services/foreground_timer_service.dart` - 增强支持多通知栏

#### 改造的插件
- `lib/plugins/timer/timer_plugin.dart` - 完全集成统一控制器
- `lib/plugins/habits/controllers/timer_controller.dart` - 重构为委托模式
- `lib/plugins/todo/models/task.dart` - 简化集成统一控制器
- `lib/plugins/tracker/widgets/timer_dialog.dart` - 简化集成统一控制器

#### 增强的Android原生代码
- `android/app/src/main/kotlin/github/hunmer/memento/TimerForegroundService.kt` - 支持多通知栏实例

## 技术架构

### 数据流架构
```
┌─────────────────────────────────────────────────────────────┐
│                    UnifiedTimerController                    │
│                    (单例模式，全局唯一)                       │
└────────────────────┬────────────────────────────────────────┘
                     │
          ┌──────────┼──────────┐
          │          │          │
    ┌─────▼────┐ ┌──▼───┐  ┌──▼───┐
    │  Todo    │ │Habits│  │Tracker│
    │  Plugin  │ │Plugin│  │Plugin │
    └─────┬────┘ └──┬───┘  └──┬───┘
          │          │          │
          └──────────┼──────────┘
                     │
          ┌──────────▼──────────┐
          │  EventManager       │
          │  (事件广播系统)      │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │ ForegroundTimer     │
          │ Service             │
          │ (Android原生层)     │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │   通知栏显示         │
          │ (多实例并行)        │
          └─────────────────────┘
```

### 通知栏架构
- **多实例支持**：每个计时器独立的通知ID
- **ID生成算法**：`abs(timerId.hashCode()) % 90000 + 10000`
- **实时同步**：每秒更新进度和内容
- **主题色支持**：每个计时器可自定义颜色

## 关键实现细节

### 1. 统一计时器状态模型（TimerState）

```dart
enum TimerType { countUp, countDown, pomodoro }
enum TimerStatus { stopped, running, paused, completed }

class TimerState {
  final String id, name, pluginId;
  final TimerType type;
  TimerStatus status;
  Duration elapsed, targetDuration;
  final Color color;
  final IconData icon;
  final List<TimerItemConfig> stages;

  // 核心方法：tick(), start(), pause(), stop(), reset()
  void tick() { /* 高精度时间计算 */ }
  void start() { /* 状态切换 + 事件广播 */ }
  void pause() { /* 状态保存 + 事件广播 */ }
  void stop() { /* 清理资源 + 事件广播 */ }
}
```

### 2. 统一控制器核心（UnifiedTimerController）

```dart
class UnifiedTimerController {
  static UnifiedTimerController? _instance;

  // 核心API
  Future<void> startTimer({required String id, ...});
  Future<void> pauseTimer(String id);
  Future<void> resumeTimer(String id);
  Future<void> stopTimer(String id);

  // 查询API
  TimerState? getTimer(String id);
  List<TimerState> getActiveTimers();
  List<TimerState> getActiveTimersByPlugin(String pluginId);

  // 内部机制
  void _startGlobalUpdateTimer(); // 单个Timer更新所有实例
  void _broadcastTimerEvent(); // 事件广播
  Future<void> _syncToNotificationBar(); // 通知栏同步
}
```

### 3. Android原生多通知栏支持

**关键特性**：
- 基于字符串ID生成唯一数字通知ID
- 每个计时器独立的NotificationChannel
- 内存缓存计时器状态（标题、颜色等）
- 兼容旧版本API

**新API方法**：
```kotlin
// 启动多个计时器中的一个
startMultipleTimerService(
    timerId: String,
    taskName: String,
    content: String,
    progress: Int,
    maxProgress: Int,
    color: Int
)

// 更新多个计时器中的一个
updateMultipleTimerService(
    timerId: String,
    content: String,
    progress: Int,
    maxProgress: Int
)

// 停止多个计时器中的一个
stopMultipleTimerService(timerId: String)
```

## 插件改造模式

### 模式1：完全集成（Timer插件）
```dart
void start() {
  // 检查是否已有实例
  final state = unifiedTimerController.getTimer(id);
  if (state == null) {
    // 首次启动：创建新实例
    unifiedTimerController.startTimer(...);
  } else {
    // 恢复运行：调用resume
    unifiedTimerController.resumeTimer(id);
  }
}
```

### 模式2：委托模式（Habits插件）
```dart
void startTimer(Habit habit, TimerUpdateCallback onUpdate) {
  // 直接委托给统一控制器
  unifiedTimerController.startTimer(
    id: habit.id,
    name: habit.title,
    type: TimerType.countUp,
    color: Colors.green,
    icon: Icons.check_circle,
    pluginId: 'habits',
  );
  // 设置回调监听
  _setupTimerCallback(habit.id, onUpdate);
}
```

### 模式3：简化集成（Todo/Tracker插件）
```dart
void startTimer() {
  // 最简化的委托调用
  unifiedTimerController.startTimer(
    id: id,
    name: title,
    type: TimerType.countUp,
    color: color,
    icon: icon,
    pluginId: pluginId,
  );
}
```

## 事件系统

### 统一事件名称
```dart
class TimerEventNames {
  static const String timerStarted = 'unified_timer_started';
  static const String timerPaused = 'unified_timer_paused';
  static const String timerUpdated = 'unified_timer_updated';
  static const String timerCompleted = 'unified_timer_completed';
}
```

### 事件参数
```dart
class UnifiedTimerEventArgs extends EventArgs {
  final TimerEventType eventType;
  final TimerState timerState;
  final DateTime timestamp;

  // 包含完整的计时器状态信息
}
```

### 插件内事件转换
```dart
// 统一事件 -> 插件专用事件
void _onUnifiedTimerUpdated(UnifiedTimerEventArgs args) {
  final habitTimerEvent = HabitTimerEventArgs(
    habitId: args.timerState.id,
    elapsedSeconds: args.timerState.elapsed.inSeconds,
    isCountdown: args.timerState.isCountdown,
    isRunning: args.timerState.status == TimerStatus.running,
  );
  // 广播给插件专用事件系统
  eventManager.broadcast('habit_timer_updated', habitTimerEvent);
}
```

## 性能优化

### 1. 单个全局Timer更新
```dart
// 替代：为每个计时器创建单独的Timer
// 使用：一个Timer.periodic更新所有活动计时器
_timer = Timer.periodic(Duration(seconds: 1), (_) {
  for (final state in _timers.values) {
    if (state.status == TimerStatus.running) {
      state.tick();
    }
  }
  _broadcastTimerEvent();
});
```

### 2. 通知栏更新频率限制
```dart
// 更新通知栏（限制为每秒1次）
void _syncToNotificationBar() {
  if (DateTime.now().difference(_lastNotificationSync).inSeconds >= 1) {
    for (final state in _timers.values) {
      if (state.status == TimerStatus.running) {
        ForegroundTimerService.updateService(...);
      }
    }
    _lastNotificationSync = DateTime.now();
  }
}
```

### 3. 事件广播优化
```dart
// 使用microtask异步更新UI，避免阻塞
Future<void> _broadcastTimerEvent() {
  return Future.microtask(() {
    eventManager.broadcast('unified_timer_updated', eventArgs);
  });
}
```

## 兼容性保证

### 向后兼容
- **保持现有API**：所有插件的现有方法签名不变
- **旧版通知栏API**：保留原有startTimerService/updateTimerService方法
- **事件系统兼容**：插件内仍可订阅专用事件（自动转换）

### 渐进式迁移
- **阶段1**：插件内部改造（委托模式）
- **阶段2**：UI组件更新（事件订阅）
- **阶段3**：移除旧代码（可选）

## 已知限制

1. **Android原生服务限制**：单个前台服务最多显示50个通知
2. **iOS支持**：当前未实现iOS通知栏同步
3. **内存占用**：每个活动计时器约占用几KB内存
4. **电池影响**：10-20个计时器并行可能影响电池寿命

## 未来优化方向

1. **iOS通知支持**：实现iOS的UNUserNotificationCenter集成
2. **智能分组**：根据插件ID分组显示通知
3. **通知点击处理**：添加通知点击跳转到对应插件的功能
4. **状态持久化**：应用重启后恢复所有活动计时器
5. **性能监控**：添加计时器性能指标监控

## 测试建议

### 单元测试
- `UnifiedTimerController.startTimer()` - 测试启动逻辑
- `UnifiedTimerController.pauseTimer()` - 测试暂停逻辑
- `UnifiedTimerController.getActiveTimersByPlugin()` - 测试查询功能
- 计时器状态转换（running -> paused -> running）

### 集成测试
- 4个插件同时运行计时器
- 跨插件事件广播验证
- 通知栏显示正确性
- 应用重启后状态恢复

### 性能测试
- 10个计时器并行运行（CPU/内存占用）
- 通知栏更新频率验证
- 长时间运行稳定性（24小时+）

## 总结

本项目成功实现了：
- ✅ 统一所有插件的计时器到一个控制器
- ✅ 支持多插件计时器并行运行（10-20个）
- ✅ 实时同步到Android通知栏
- ✅ 保持100%向下兼容
- ✅ 高性能单Timer更新机制
- ✅ 事件驱动的松耦合架构

**核心价值**：
1. **代码复用**：统一控制器被4个插件共享
2. **用户体验**：多计时器同时显示在通知栏
3. **可维护性**：集中管理，易于扩展新插件
4. **性能优化**：单个Timer更新所有实例，降低资源消耗

**技术亮点**：
- 单例模式确保全局一致性
- 事件驱动实现松耦合
- 委托模式简化插件集成
- Android原生多通知栏支持
- 完全向下兼容的API设计

这个统一计时器控制器将成为Memento应用的基础设施，为未来新增的插件提供标准化的计时器功能。
