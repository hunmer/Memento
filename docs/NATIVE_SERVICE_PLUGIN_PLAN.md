# Memento 原生服务插件化重构计划

> **创建日期**: 2024-12-04
> **状态**: 待实施
> **范围**: 前台服务管理器 + 通知管理器

---

## 1. 项目概述

### 1.1 目标
将 Memento 项目中的原生平台服务抽取为独立的 Flutter 插件，实现：
- 主项目彻底移除 `awesome_notifications` 和 `flutter_foreground_task` 依赖
- 对外暴露简洁统一的 API，隐藏底层实现细节
- 提高代码复用性和维护性

### 1.2 范围
| 插件名称 | 封装依赖 | 源代码行数 |
|---------|---------|-----------|
| `memento_foreground_service` | flutter_foreground_task ^9.1.0 | ~400行 (含原生) |
| `memento_notifications` | awesome_notifications ^0.10.1 | ~260行 |

### 1.3 策略
- **命名规范**: `memento_xxx` 前缀
- **存放位置**: `plugins/` 目录 (与 `lib/plugins/` 同级)
- **兼容策略**: 直接替换，一次性迁移所有调用点

---

## 2. 插件架构设计

### 2.1 memento_foreground_service

#### 目录结构
```
plugins/memento_foreground_service/
├── lib/
│   ├── memento_foreground_service.dart      # 主入口，导出公开API
│   ├── src/
│   │   ├── foreground_service.dart          # 核心服务类
│   │   ├── foreground_service_config.dart   # 配置类
│   │   ├── notification_config.dart         # 通知配置
│   │   └── permission_helper.dart           # 权限助手
│   └── memento_foreground_service_method_channel.dart
├── android/
│   ├── src/main/kotlin/com/memento/foreground_service/
│   │   ├── MementoForegroundServicePlugin.kt
│   │   ├── TimerForegroundService.kt        # 从主项目迁移
│   │   └── ActivityForegroundService.kt     # 从主项目迁移
│   └── src/main/AndroidManifest.xml
├── ios/
│   └── Classes/
│       └── MementoForegroundServicePlugin.swift
├── pubspec.yaml
└── README.md
```

#### 公开 API 设计
```dart
// lib/memento_foreground_service.dart
library memento_foreground_service;

export 'src/foreground_service.dart';
export 'src/foreground_service_config.dart';
export 'src/notification_config.dart';
```

```dart
// lib/src/foreground_service.dart
class MementoForegroundService {
  static final MementoForegroundService instance = MementoForegroundService._();
  MementoForegroundService._();

  /// 初始化服务（自动请求权限）
  Future<void> initialize({ForegroundServiceConfig? config});

  /// 启动前台服务
  Future<ServiceResult> startService({
    required int serviceId,
    required String title,
    required String content,
    String? notificationIcon,
    List<ServiceButton>? buttons,
    String? initialRoute,
    required Function() callback,
  });

  /// 停止前台服务
  Future<ServiceResult> stopService();

  /// 更新通知内容
  Future<void> updateNotification({
    required String title,
    required String content,
    int? progress,
    String? bigText,
  });

  /// 检查服务状态
  Future<bool> get isRunning;

  /// 添加数据回调
  void addDataCallback(Function(Object) callback);
  void removeDataCallback(Function(Object) callback);
}

// 配置类
class ForegroundServiceConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final Duration eventInterval;
  final bool autoRunOnBoot;
  final bool allowWakeLock;
  // ...
}

// 服务按钮
class ServiceButton {
  final String key;
  final String label;
  final Color? color;
}

// 服务结果
class ServiceResult {
  final bool success;
  final String? error;
}
```

#### MethodChannel 设计
```dart
// 通道名称（保持向后兼容或使用新名称）
const String kTimerServiceChannel = 'com.memento.foreground_service/timer';
const String kActivityServiceChannel = 'com.memento.foreground_service/activity';

// 方法列表
// timer_service:
//   - startTimerService(taskId, taskName, subTimers, currentIndex)
//   - updateTimerService(...)
//   - stopTimerService(taskId)
//
// activity_service:
//   - startActivityNotificationService()
//   - updateActivityNotification(title, content)
//   - stopActivityNotificationService()
```

---

### 2.2 memento_notifications

#### 目录结构
```
plugins/memento_notifications/
├── lib/
│   ├── memento_notifications.dart           # 主入口
│   ├── src/
│   │   ├── notification_service.dart        # 核心服务类
│   │   ├── notification_channel.dart        # 通知通道配置
│   │   ├── notification_content.dart        # 通知内容模型
│   │   ├── notification_action.dart         # 通知动作/按钮
│   │   └── notification_listener.dart       # 事件监听器
│   └── memento_notifications_method_channel.dart
├── android/
│   └── src/main/AndroidManifest.xml         # 权限声明
├── ios/
│   └── Classes/
├── pubspec.yaml
└── README.md
```

#### 公开 API 设计
```dart
// lib/memento_notifications.dart
library memento_notifications;

export 'src/notification_service.dart';
export 'src/notification_channel.dart';
export 'src/notification_content.dart';
export 'src/notification_action.dart';
export 'src/notification_listener.dart';
```

```dart
// lib/src/notification_service.dart
class MementoNotifications {
  static final MementoNotifications instance = MementoNotifications._();
  MementoNotifications._();

  /// 初始化通知服务
  Future<void> initialize({
    List<MementoNotificationChannel>? channels,
    bool debug = false,
  });

  /// 设置事件监听器
  void setListeners({
    OnNotificationCreated? onCreated,
    OnNotificationDisplayed? onDisplayed,
    OnNotificationDismissed? onDismissed,
    OnNotificationAction? onAction,
  });

  /// 请求通知权限
  Future<bool> requestPermission();

  /// 检查通知权限
  Future<bool> checkPermission();

  /// 创建基础通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelKey,
    MementoNotificationLayout layout = MementoNotificationLayout.basic,
    String? bigPicture,
    String? largeIcon,
    List<MementoNotificationButton>? buttons,
    Map<String, String>? payload,
  });

  /// 取消通知
  Future<void> cancel(int id);
  Future<void> cancelAll();

  /// 获取已调度的通知列表
  Future<List<MementoScheduledNotification>> getScheduledNotifications();
}

// 通知通道
class MementoNotificationChannel {
  final String key;
  final String name;
  final String description;
  final Color defaultColor;
  final MementoNotificationImportance importance;
  final bool playSound;
  final bool enableVibration;
}

// 通知布局类型
enum MementoNotificationLayout {
  basic,
  bigPicture,
  bigText,
  inbox,
  progressBar,
}

// 通知按钮
class MementoNotificationButton {
  final String key;
  final String label;
  final MementoButtonAction actionType;
  final Color? color;
}

// 回调类型定义
typedef OnNotificationCreated = Future<void> Function(MementoReceivedNotification);
typedef OnNotificationDisplayed = Future<void> Function(MementoReceivedNotification);
typedef OnNotificationDismissed = Future<void> Function(MementoReceivedAction);
typedef OnNotificationAction = Future<void> Function(MementoReceivedAction);
```

---

## 3. 实施步骤

### 阶段一：创建 memento_foreground_service 插件

#### 步骤 1.1：创建插件项目
```bash
cd /Users/Zhuanz/Documents/Memento
mkdir -p plugins
cd plugins
flutter create --template=plugin --platforms=android,ios memento_foreground_service
```

#### 步骤 1.2：配置 pubspec.yaml
```yaml
# plugins/memento_foreground_service/pubspec.yaml
name: memento_foreground_service
description: Memento 前台服务管理插件，封装 flutter_foreground_task
version: 1.0.0

environment:
  sdk: ^3.7.0
  flutter: ">=3.7.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_foreground_task: ^9.1.0  # 内部依赖，不对外暴露

flutter:
  plugin:
    platforms:
      android:
        package: com.memento.foreground_service
        pluginClass: MementoForegroundServicePlugin
      ios:
        pluginClass: MementoForegroundServicePlugin
```

#### 步骤 1.3：迁移 Dart 代码
**源文件**: `lib/core/services/foreground_task_manager.dart` (113行)

**迁移内容**:
- 权限请求逻辑 (第23-38行)
- 服务配置逻辑 (第42-63行)
- 服务启动/停止逻辑 (第66-101行)
- 数据回调管理 (第104-111行)

#### 步骤 1.4：迁移原生代码 (Android)
**源文件**:
- `android/app/src/main/kotlin/.../TimerForegroundService.kt` (271行)
- `android/app/src/main/kotlin/.../ActivityForegroundService.kt`

**迁移到**:
- `plugins/memento_foreground_service/android/src/main/kotlin/com/memento/foreground_service/`

**需要修改**:
1. 更新 package 声明
2. 更新 MethodChannel 名称
3. 更新 R 资源引用方式

#### 步骤 1.5：配置 AndroidManifest.xml
```xml
<!-- plugins/memento_foreground_service/android/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />

    <application>
        <service
            android:name=".TimerForegroundService"
            android:exported="false"
            android:foregroundServiceType="dataSync" />
        <service
            android:name=".ActivityForegroundService"
            android:exported="false"
            android:foregroundServiceType="dataSync" />
    </application>
</manifest>
```

---

### 阶段二：创建 memento_notifications 插件

#### 步骤 2.1：创建插件项目
```bash
cd /Users/Zhuanz/Documents/Memento/plugins
flutter create --template=plugin --platforms=android,ios memento_notifications
```

#### 步骤 2.2：配置 pubspec.yaml
```yaml
# plugins/memento_notifications/pubspec.yaml
name: memento_notifications
description: Memento 通知管理插件，封装 awesome_notifications
version: 1.0.0

environment:
  sdk: ^3.7.0
  flutter: ">=3.7.0"

dependencies:
  flutter:
    sdk: flutter
  awesome_notifications: ^0.10.1  # 内部依赖，不对外暴露

flutter:
  plugin:
    platforms:
      android:
        package: com.memento.notifications
        pluginClass: MementoNotificationsPlugin
      ios:
        pluginClass: MementoNotificationsPlugin
```

#### 步骤 2.3：迁移 Dart 代码
**源文件**: `lib/core/notification_controller.dart` (257行)

**迁移内容**:
- 初始化逻辑和通道配置 (第8-53行)
- 权限请求 (第56-67行)
- 通知生命周期回调 (第70-125行)
- 通知创建方法 (第128-204行)
- 通知管理方法 (第207-219行)
- 活动通知特殊处理 (第222-255行) → 改为可配置的事件回调

#### 步骤 2.4：配置 AndroidManifest.xml
```xml
<!-- plugins/memento_notifications/android/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
</manifest>
```

---

### 阶段三：主项目迁移

#### 步骤 3.1：添加本地插件依赖
```yaml
# pubspec.yaml
dependencies:
  # 移除这两行:
  # awesome_notifications: ^0.10.1
  # flutter_foreground_task: ^9.1.0

  # 添加本地插件:
  memento_foreground_service:
    path: ./plugins/memento_foreground_service
  memento_notifications:
    path: ./plugins/memento_notifications
```

#### 步骤 3.2：更新 import 语句

**需要修改的文件列表**:

| 文件路径 | 修改类型 |
|---------|---------|
| `lib/core/notification_controller.dart` | 删除，使用新插件 |
| `lib/core/services/foreground_task_manager.dart` | 删除，使用新插件 |
| `lib/plugins/activity/services/activity_notification_service.dart` | 更新 import |
| `lib/plugins/tracker/utils/tracker_notification_utils.dart` | 更新 import |
| `lib/plugins/calendar/utils/calendar_notification_utils.dart` | 更新 import |
| `lib/main.dart` | 更新初始化代码 |

#### 步骤 3.3：API 映射表

**NotificationController → MementoNotifications**:
```dart
// 旧 API
NotificationController.initialize();
NotificationController.requestPermission();
NotificationController.createBasicNotification(id: 1, title: 'T', body: 'B');
NotificationController.cancelNotification(1);

// 新 API
MementoNotifications.instance.initialize();
MementoNotifications.instance.requestPermission();
MementoNotifications.instance.showNotification(id: 1, title: 'T', body: 'B');
MementoNotifications.instance.cancel(1);
```

**ForegroundTaskManager → MementoForegroundService**:
```dart
// 旧 API
ForegroundTaskManager().startService(...);
ForegroundTaskManager().stopService();
ForegroundTaskManager().isServiceRunning();

// 新 API
MementoForegroundService.instance.startService(...);
MementoForegroundService.instance.stopService();
MementoForegroundService.instance.isRunning;
```

#### 步骤 3.4：清理主项目原生代码

**从主项目删除**:
- `android/app/src/main/kotlin/.../TimerForegroundService.kt`
- `android/app/src/main/kotlin/.../ActivityForegroundService.kt`

**更新 AndroidManifest.xml**:
移除已迁移到插件的 Service 声明和权限声明。

---

## 4. 关键技术点

### 4.1 封装第三方插件而不暴露其 API

```dart
// 错误示例 - 暴露了 awesome_notifications 的类型
import 'package:awesome_notifications/awesome_notifications.dart';
export 'package:awesome_notifications/awesome_notifications.dart'; // ❌

// 正确示例 - 定义自己的类型
class MementoNotificationChannel {
  // 自定义属性，内部转换为 NotificationChannel
}

class MementoNotifications {
  Future<void> initialize({List<MementoNotificationChannel>? channels}) async {
    // 内部转换
    final awesomeChannels = channels?.map((c) => NotificationChannel(
      channelKey: c.key,
      channelName: c.name,
      // ...
    )).toList();

    await AwesomeNotifications().initialize(null, awesomeChannels ?? []);
  }
}
```

### 4.2 原生代码资源引用

插件内的原生代码无法直接访问主项目的 R 资源，需要通过以下方式处理：

```kotlin
// 方案1: 使用 meta-data 传递资源 ID
val iconResId = context.packageManager
    .getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
    .metaData.getInt("com.memento.foreground_service.NOTIFICATION_ICON")

// 方案2: 使用通用图标
.setSmallIcon(android.R.drawable.ic_notification_overlay)

// 方案3: 通过参数传递资源名称，动态获取
val iconResId = context.resources.getIdentifier(
    iconName, "drawable", context.packageName
)
```

### 4.3 MethodChannel 命名空间

为避免与主项目冲突，插件使用独立的 Channel 命名空间：

```dart
// 插件内部
const String kPluginChannel = 'com.memento.foreground_service/main';
const String kTimerChannel = 'com.memento.foreground_service/timer';

// 主项目原有 (需要迁移或保持兼容)
const String kOldTimerChannel = 'github.hunmer.memento/timer_service';
```

### 4.4 事件回调的解耦

通知点击事件不应直接依赖业务逻辑，通过事件回调解耦：

```dart
// 旧代码 - 直接调用业务逻辑
static Future<void> onActionReceivedMethod(ReceivedAction action) async {
  if (action.payload?['type'] == 'activity_reminder') {
    eventManager.broadcast('activity_notification_tapped', ...); // ❌ 耦合
  }
}

// 新代码 - 通过回调解耦
MementoNotifications.instance.setListeners(
  onAction: (action) async {
    // 由调用方决定如何处理
    if (action.payload?['type'] == 'activity_reminder') {
      eventManager.broadcast('activity_notification_tapped', ...);
    }
  },
);
```

---

## 5. 风险与挑战

### 5.1 原生代码调试
- **风险**: 插件内的原生代码调试比主项目更复杂
- **缓解**: 添加详细日志，使用 `flutter run --verbose`

### 5.2 权限配置合并
- **风险**: 插件的 AndroidManifest.xml 权限可能与主项目重复或冲突
- **缓解**: Flutter 会自动合并，但需验证最终 manifest

### 5.3 资源访问
- **风险**: 插件无法直接访问主项目的 drawable 资源
- **缓解**: 使用 meta-data 或动态资源查找

### 5.4 与 memento_widgets 的兼容性
- **风险**: 小组件可能直接使用了 NotificationController
- **缓解**: 检查 memento_widgets 的依赖，必要时更新

---

## 6. 验证方案

### 6.1 单元测试
```dart
// test/memento_foreground_service_test.dart
void main() {
  test('startService should return success', () async {
    final result = await MementoForegroundService.instance.startService(
      serviceId: 1,
      title: 'Test',
      content: 'Test content',
      callback: () {},
    );
    expect(result.success, isTrue);
  });
}
```

### 6.2 集成测试清单
- [ ] 前台服务能够正常启动和停止
- [ ] 计时器通知能够实时更新
- [ ] 活动提醒通知能够按时触发
- [ ] 通知点击能够正确路由到应用
- [ ] 通知按钮点击能够触发回调
- [ ] 权限请求对话框正常显示
- [ ] Android 14+ 设备兼容性
- [ ] iOS 设备后台任务正常

### 6.3 回归测试
使用 grep 确保所有调用点已迁移：
```bash
# 确保主项目不再直接引用旧依赖
grep -r "awesome_notifications" lib/
grep -r "flutter_foreground_task" lib/
grep -r "NotificationController" lib/
grep -r "ForegroundTaskManager" lib/
```

---

## 7. 时间估算

| 阶段 | 任务 | 预计时间 |
|-----|------|---------|
| 阶段一 | 创建 memento_foreground_service | 2-3 小时 |
| 阶段二 | 创建 memento_notifications | 2-3 小时 |
| 阶段三 | 主项目迁移 | 1-2 小时 |
| 验证 | 测试与调试 | 1-2 小时 |
| **总计** | | **6-10 小时** |

---

## 8. 关键文件索引

### 需要阅读的源文件
```
# Dart 代码
lib/core/notification_controller.dart                    # 257行
lib/core/services/foreground_task_manager.dart           # 113行
lib/plugins/activity/services/activity_notification_service.dart  # 342行
lib/plugins/tracker/utils/tracker_notification_utils.dart
lib/plugins/calendar/utils/calendar_notification_utils.dart
lib/main.dart                                            # 初始化代码

# 原生代码
android/app/src/main/kotlin/.../TimerForegroundService.kt    # 271行
android/app/src/main/kotlin/.../ActivityForegroundService.kt
android/app/src/main/kotlin/.../MainActivity.kt              # MethodChannel 注册
android/app/src/main/AndroidManifest.xml                     # 权限和服务声明
ios/Runner/AppDelegate.swift                                 # iOS 配置

# 参考现有插件
floating_ball_plugin/                                        # 参考结构
memento_widgets/                                             # 参考结构
```

### 需要创建的目录结构
```
plugins/
├── memento_foreground_service/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
└── memento_notifications/
    ├── lib/
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

---

## 附录：完整 API 对照表

### NotificationController → MementoNotifications

| 旧 API | 新 API |
|--------|--------|
| `NotificationController.initialize()` | `MementoNotifications.instance.initialize()` |
| `NotificationController.requestPermission()` | `MementoNotifications.instance.requestPermission()` |
| `NotificationController.checkPermission()` | `MementoNotifications.instance.checkPermission()` |
| `NotificationController.createBasicNotification(...)` | `MementoNotifications.instance.showNotification(...)` |
| `NotificationController.createCustomNotification(...)` | `MementoNotifications.instance.showNotification(...)` |
| `NotificationController.createBigPictureNotification(...)` | `MementoNotifications.instance.showNotification(layout: bigPicture, ...)` |
| `NotificationController.cancelNotification(id)` | `MementoNotifications.instance.cancel(id)` |
| `NotificationController.cancelAllNotifications()` | `MementoNotifications.instance.cancelAll()` |
| `NotificationController.getActiveNotifications()` | `MementoNotifications.instance.getScheduledNotifications()` |

### ForegroundTaskManager → MementoForegroundService

| 旧 API | 新 API |
|--------|--------|
| `ForegroundTaskManager()` (构造函数) | `MementoForegroundService.instance` (单例) |
| `.initCommunicationPort()` | 内部自动处理 |
| `.requestPermissions()` | `initialize()` 时自动处理 |
| `.initService()` | `initialize(config: ...)` |
| `.startService(...)` | `.startService(...)` |
| `.stopService()` | `.stopService()` |
| `.isServiceRunning()` | `.isRunning` |
| `.addDataCallback(cb)` | `.addDataCallback(cb)` |
| `.removeDataCallback(cb)` | `.removeDataCallback(cb)` |

---

**文档版本**: 1.0
**最后更新**: 2024-12-04
