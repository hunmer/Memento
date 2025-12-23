# ForegroundTimerService - 前台计时器服务

## 概述

`ForegroundTimerService` 是一个跨平台的前台通知服务，用于在后台运行计时器任务时显示持续通知。

### 平台实现

| 平台 | 实现方式 | 特性 |
|------|---------|------|
| **Android** | MethodChannel 调用原生前台服务 | 状态栏通知、进度条、自定义颜色 |
| **iOS** | Live Activities (动态岛/灵动岛) | 动态岛显示、锁屏卡片、实时更新 |
| **桌面端/Web** | 静默忽略 | 无前台服务 |

---

## 重构说明

### 主要变更

1. **iOS 端替换为 Live Activities**
   - 原实现：使用 MethodChannel 调用原生代码
   - 新实现：使用 `LiveActivitiesController` 管理动态岛
   - 优势：更现代的 UI、更好的用户体验、无需编写原生代码

2. **平台判断优化**
   - 新增 `_isIOS` 和 `_isAndroid` 属性
   - 在每个方法中根据平台分别处理
   - 更清晰的代码结构

3. **活动ID映射**
   - 新增 `_iosActivityIds` 映射表
   - 管理计时器ID与Live Activity ID的对应关系
   - 支持多个计时器同时运行

---

## 使用方法

### 1. 基本用法

```dart
import 'package:memento/core/services/foreground_timer_service.dart';

// 启动前台服务
await ForegroundTimerService.startService(
  id: 'my_timer_1',
  title: '专注计时',
  content: '00:05:00',
  progress: 0,
  maxProgress: 300, // 5分钟 = 300秒
  color: Colors.blue, // Android 使用
);

// 更新进度
await ForegroundTimerService.updateService(
  id: 'my_timer_1',
  content: '00:04:30',
  progress: 30,
  maxProgress: 300,
);

// 停止服务
await ForegroundTimerService.stopService('my_timer_1');
```

### 2. 完整示例：番茄钟计时器

```dart
class PomodoroTimer {
  String? _timerId;
  Timer? _updateTimer;
  int _remainingSeconds = 1500; // 25分钟
  final int _totalSeconds = 1500;

  Future<void> start() async {
    _timerId = 'pomodoro_${DateTime.now().millisecondsSinceEpoch}';

    // 启动前台服务
    await ForegroundTimerService.startService(
      id: _timerId!,
      title: '番茄钟',
      content: _formatTime(_remainingSeconds),
      progress: 0,
      maxProgress: _totalSeconds,
      color: Colors.red,
    );

    // 启动倒计时
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        await stop();
        return;
      }

      // 更新前台通知
      await ForegroundTimerService.updateService(
        id: _timerId!,
        content: _formatTime(_remainingSeconds),
        progress: _totalSeconds - _remainingSeconds,
        maxProgress: _totalSeconds,
      );
    });
  }

  Future<void> stop() async {
    _updateTimer?.cancel();

    if (_timerId != null) {
      await ForegroundTimerService.stopService(_timerId!);
      _timerId = null;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
```

### 3. 多计时器管理

```dart
class MultiTimerManager {
  final Map<String, Timer> _timers = {};

  Future<void> addTimer(String id, String title) async {
    int elapsed = 0;

    await ForegroundTimerService.startService(
      id: id,
      title: title,
      content: '00:00:00',
      progress: 0,
      maxProgress: 100, // 假设最大100秒
    );

    _timers[id] = Timer.periodic(Duration(seconds: 1), (timer) async {
      elapsed++;

      await ForegroundTimerService.updateService(
        id: id,
        content: _formatTime(elapsed),
        progress: elapsed,
        maxProgress: 100,
      );

      if (elapsed >= 100) {
        await removeTimer(id);
      }
    });
  }

  Future<void> removeTimer(String id) async {
    _timers[id]?.cancel();
    _timers.remove(id);
    await ForegroundTimerService.stopService(id);
  }

  Future<void> removeAllTimers() async {
    for (final id in _timers.keys.toList()) {
      await removeTimer(id);
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
```

---

## API 参考

### startService

启动前台通知服务

**参数：**
- `id` (String, required): 计时器唯一标识
- `title` (String, required): 通知标题
- `content` (String, required): 通知内容（通常是时间字符串）
- `progress` (int, required): 当前进度（0-100）
- `maxProgress` (int, required): 最大进度（100）
- `color` (Color?, optional): 主题色（仅 Android 使用）

**平台行为：**
- Android: 创建前台服务通知
- iOS: 创建 Live Activity

**返回：**
- `Future<void>`

### updateService

更新前台通知

**参数：**
- `id` (String, required): 计时器唯一标识
- `content` (String, required): 通知内容
- `progress` (int, required): 当前进度（0-100）
- `maxProgress` (int, required): 最大进度（100）

**平台行为：**
- Android: 更新通知栏内容
- iOS: 更新 Live Activity 数据

**返回：**
- `Future<void>`

### stopService

停止前台通知服务

**参数：**
- `id` (String, required): 计时器唯一标识

**平台行为：**
- Android: 移除前台服务通知
- iOS: 结束 Live Activity

**返回：**
- `Future<void>`

---

## 平台特性对比

### Android 前台服务

**优势：**
- 系统级支持，稳定性高
- 可自定义通知样式
- 支持自定义颜色
- 支持通知操作按钮

**限制：**
- 需要 Foreground Service 权限
- 通知无法完全隐藏
- UI 相对传统

### iOS Live Activities

**优势：**
- 现代化 UI（动态岛/锁屏卡片）
- 用户体验更好
- 无需额外权限配置
- 实时更新流畅

**限制：**
- 仅支持 iOS 16.1+
- 需要配置 App Group
- 需要 Widget Extension
- 数据格式固定

---

## iOS Live Activities 配置

### 必需配置

1. **App Group ID**
   - 在 Xcode 中创建: `group.github.hunmer.memento`
   - Runner 和 Widget Extension 都需要添加

2. **Widget Extension**
   - 创建 Widget Extension 目标
   - 实现 `ActivityConfiguration`
   - 定义 `ContentState` 数据结构

3. **Info.plist**
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

4. **ContentState 字段**
   ```swift
   struct ContentState: ActivityContentStateProtocol {
       var title: String
       var subtitle: String
       var progress: Double      // 0.0-1.0
       var status: String
       var timestamp: Int
   }
   ```

### 自动初始化

`ForegroundTimerService` 会在首次调用时自动初始化 `LiveActivitiesController`：

```dart
// 首次调用时自动初始化
await ForegroundTimerService.startService(...);

// 后续调用直接使用
await ForegroundTimerService.updateService(...);
```

如果需要手动初始化（例如在应用启动时）：

```dart
import 'package:memento/screens/settings_screen/controllers/live_activities_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 手动初始化
  await LiveActivitiesController.instance.init(
    appGroupId: 'group.github.hunmer.memento',
    urlScheme: 'memento',
  );

  runApp(MyApp());
}
```

---

## 注意事项

### 通用

1. **计时器ID唯一性**
   - 每个计时器必须有唯一的 ID
   - 建议使用 `'${pluginId}_${timestamp}'` 格式

2. **进度值范围**
   - `progress` 和 `maxProgress` 应该对应实际计时
   - iOS 会自动转换为 0.0-1.0 的百分比
   - Android 直接使用整数值

3. **内容格式化**
   - 建议使用统一的时间格式化方法
   - 可使用 `_formatTime` 工具方法

### Android 特定

1. **权限要求**
   ```xml
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   ```

2. **原生代码依赖**
   - 需要在 Android 端实现 MethodChannel 处理器
   - 实现位置: `MainActivity.kt` 或专门的 Service 类

### iOS 特定

1. **系统版本要求**
   - 最低 iOS 16.1
   - 低版本系统会静默失败（不影响主功能）

2. **活动限制**
   - 同时最多 8 个 Live Activities
   - 建议及时结束不需要的活动

3. **数据同步**
   - Live Activities 通过 App Group 共享数据
   - 确保 App Group ID 配置正确

---

## 故障排查

### Android 通知不显示

**检查清单：**
1. 权限是否授予：`FOREGROUND_SERVICE`
2. MethodChannel 是否正确实现
3. 通知渠道是否创建

### iOS Live Activity 不显示

**检查清单：**
1. iOS 版本是否 >= 16.1
2. App Group ID 是否正确配置
3. Widget Extension 是否正确实现
4. ContentState 字段是否匹配
5. 查看控制台日志：`debugPrint` 输出

### 多计时器冲突

**解决方案：**
- 确保每个计时器使用不同的 ID
- 停止计时器前检查 ID 是否存在
- 使用 Map 管理多个计时器实例

---

## 相关文件

- **服务实现**: `lib/core/services/foreground_timer_service.dart`
- **iOS 控制器**: `lib/screens/settings_screen/controllers/live_activities_controller.dart`
- **Android 原生**: `android/app/src/main/kotlin/.../MainActivity.kt`
- **iOS Widget**: `ios/MyAppWidget/MyAppWidget.swift`

---

## 变更记录

- **2025-12-23**: iOS 端重构为使用 Live Activities
  - 替换 MethodChannel 为 LiveActivitiesController
  - 新增平台判断逻辑
  - 新增活动ID映射管理
  - 优化代码结构和注释
