# LiveActivitiesController 使用指南

## 概述

`LiveActivitiesController` 是一个单例控制器，用于管理 iOS 和 Android 的 Live Activities（实时活动/动态岛）功能。

## 快速开始

### 1. 初始化

在应用启动时初始化控制器（通常在 `main.dart` 或应用入口）：

```dart
import 'package:memento/screens/settings_screen/controllers/live_activities_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Live Activities
  await LiveActivitiesController.instance.init(
    appGroupId: 'group.github.hunmer.memento',
    urlScheme: 'memento',
    requireNotificationPermission: true,
  );

  runApp(MyApp());
}
```

### 2. 创建活动

#### 方式一：使用静态便捷方法

```dart
// 创建任务进度活动
final activityId = await LiveActivitiesController.createTaskActivity(
  title: '导出数据',
  subtitle: '正在处理...',
  progress: 0.0,
  status: '准备开始',
);

if (activityId != null) {
  print('活动创建成功: $activityId');
}
```

#### 方式二：使用控制器实例

```dart
final controller = LiveActivitiesController.instance;

final activityId = await controller.createActivity(
  'my_task_123',
  {
    'title': '自定义任务',
    'subtitle': '处理中',
    'progress': 0.5,
    'status': '进度 50%',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  },
);
```

### 3. 更新活动

#### 方式一：使用静态便捷方法

```dart
// 更新进度
await LiveActivitiesController.updateTaskProgress(
  activityId,
  progress: 0.75,
  status: '进度 75%',
);
```

#### 方式二：使用控制器实例

```dart
await controller.updateActivity(
  activityId,
  {
    'progress': 0.75,
    'status': '进度 75%',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  },
);
```

### 4. 完成/结束活动

#### 方式一：使用静态便捷方法（带完成动画）

```dart
// 会先更新为完成状态，等待2秒后结束
await LiveActivitiesController.completeTask(activityId);
```

#### 方式二：直接结束

```dart
await controller.endActivity(activityId);
```

### 5. 监听活动事件

```dart
await controller.init(
  appGroupId: 'group.github.hunmer.memento',
  onActivityUpdate: (event) {
    event.map(
      active: (activity) {
        print('活动激活: ${activity.activityId}');
      },
      ended: (activity) {
        print('活动结束: ${activity.activityId}');
      },
      stale: (activity) {
        print('活动过期: ${activity.activityId}');
      },
      unknown: (activity) {
        print('未知状态');
      },
    );
  },
  onUrlScheme: (schemeData) {
    print('收到 URL Scheme: ${schemeData.url}');
    // 处理用户从动态岛点击的动作
  },
);
```

## 完整示例

### 示例：数据导出任务

```dart
class ExportController {
  String? _activityId;

  Future<void> exportData() async {
    // 1. 创建活动
    _activityId = await LiveActivitiesController.createTaskActivity(
      title: '导出数据',
      subtitle: '正在准备...',
      progress: 0.0,
      status: '准备开始',
    );

    try {
      // 2. 执行导出任务
      for (var i = 0; i < 10; i++) {
        // 模拟导出步骤
        await Future.delayed(Duration(seconds: 1));

        // 更新进度
        if (_activityId != null) {
          await LiveActivitiesController.updateTaskProgress(
            _activityId!,
            progress: (i + 1) / 10,
            status: '导出中 ${(i + 1) * 10}%',
          );
        }
      }

      // 3. 完成任务
      if (_activityId != null) {
        await LiveActivitiesController.completeTask(_activityId!);
      }

      print('导出完成');
    } catch (e) {
      // 4. 错误处理
      if (_activityId != null) {
        await LiveActivitiesController.updateTaskProgress(
          _activityId!,
          status: '导出失败: $e',
        );

        await Future.delayed(Duration(seconds: 2));
        await LiveActivitiesController.instance.endActivity(_activityId!);
      }
    }
  }
}
```

### 示例：WebDAV 同步

```dart
class WebDAVSyncController {
  Future<void> syncData() async {
    final activityId = await LiveActivitiesController.createTaskActivity(
      title: 'WebDAV 同步',
      subtitle: '连接服务器...',
      progress: 0.0,
      status: '正在连接',
    );

    if (activityId == null) return;

    try {
      // 连接
      await LiveActivitiesController.updateTaskProgress(
        activityId,
        progress: 0.2,
        status: '已连接，准备上传',
      );

      // 上传
      await LiveActivitiesController.updateTaskProgress(
        activityId,
        progress: 0.5,
        status: '上传中...',
      );

      // 下载
      await LiveActivitiesController.updateTaskProgress(
        activityId,
        progress: 0.8,
        status: '下载中...',
      );

      // 完成
      await LiveActivitiesController.completeTask(activityId);

    } catch (e) {
      await LiveActivitiesController.updateTaskProgress(
        activityId,
        status: '同步失败',
      );
      await Future.delayed(Duration(seconds: 2));
      await LiveActivitiesController.instance.endActivity(activityId);
    }
  }
}
```

## API 参考

### 初始化方法

```dart
Future<bool> init({
  required String appGroupId,         // App Group ID (iOS必需)
  String urlScheme = 'memento',       // URL Scheme
  bool requireNotificationPermission, // 是否需要通知权限
  Function(ActivityUpdate)? onActivityUpdate,  // 活动状态回调
  Function(UrlSchemeData)? onUrlScheme,        // URL Scheme回调
})
```

### 活动管理方法

```dart
// 创建活动
Future<String?> createActivity(String activityId, Map<String, dynamic> data)

// 更新活动
Future<bool> updateActivity(String activityId, Map<String, dynamic> data)

// 结束活动
Future<bool> endActivity(String activityId)

// 获取所有活动
Future<List<String>> getAllActivities()

// 结束所有活动
Future<void> endAllActivities()
```

### 静态便捷方法

```dart
// 创建任务活动
static Future<String?> createTaskActivity({
  required String title,
  String subtitle = '',
  double progress = 0.0,
  String status = '准备开始',
})

// 更新任务进度
static Future<bool> updateTaskProgress(
  String activityId, {
  double? progress,
  String? status,
})

// 完成任务
static Future<bool> completeTask(String activityId)
```

## 属性访问

```dart
// 获取控制器实例
final controller = LiveActivitiesController.instance;

// 检查是否已初始化
if (controller.isInitialized) { ... }

// 检查是否支持
if (controller.isSupported) { ... }

// 直接访问插件
final plugin = controller.plugin;
```

## 数据格式

活动数据必须包含以下字段（与 Swift ContentState 定义匹配）：

```dart
{
  'title': String,        // 标题
  'subtitle': String,     // 副标题
  'progress': double,     // 进度 (0.0-1.0)
  'status': String,       // 状态文本
  'timestamp': int,       // 时间戳（毫秒）
}
```

## 注意事项

1. **iOS 配置要求**：
   - Widget Extension
   - App Group ID
   - Push Notifications
   - Info.plist 中添加 `NSSupportsLiveActivities = YES`

2. **Android 配置要求**：
   - CustomLiveActivityManager
   - live_activity.xml 布局
   - Foreground Service 权限

3. **单例模式**：控制器使用单例，确保全局只有一个实例

4. **初始化检查**：调用前务必确保 `isInitialized` 为 true

5. **设备支持**：iOS 16.1+ 或 Android API 24+

6. **资源清理**：应用退出时调用 `dispose()` 清理资源

## 故障排查

### 活动创建失败

```dart
final activityId = await LiveActivitiesController.createTaskActivity(...);

if (activityId == null) {
  // 检查：
  // 1. 控制器是否已初始化
  // 2. 设备是否支持
  // 3. 权限是否授予
  // 4. iOS 配置是否正确
}
```

### 监听不到状态变化

确保在初始化时设置回调：

```dart
await controller.init(
  appGroupId: '...',
  onActivityUpdate: (event) { ... },
  onUrlScheme: (data) { ... },
);
```

### iOS 动态岛不显示

检查 Xcode 配置：
1. Widget Extension 是否正确添加
2. App Group ID 是否一致
3. ContentState 字段是否匹配
