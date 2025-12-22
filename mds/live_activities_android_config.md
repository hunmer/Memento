# Android Live Activities 配置指南

## 概述

本文档详细说明如何在 Android 项目中配置 Live Activities 功能。Android 使用 RemoteViews 实现类似 iOS Live Activities 的功能。

## 前置条件

- Android API Level 24 (Android 7.0) 或更高版本
- Flutter 3.0 或更高版本
- 已安装 live_activities 插件

## 配置步骤

### 1. 检查依赖

已在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  live_activities: ^2.4.3
```

### 2. 配置权限

已在 `android/app/src/main/AndroidManifest.xml` 中添加所需权限：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
```

### 3. 配置 MainActivity

已在 `android/app/src/main/kotlin/github/hunmer/memento/MainActivity.kt` 中添加 LiveActivityManager 初始化：

```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    // 初始化 Live Activities 支持
    LiveActivityManagerHolder.instance = CustomLiveActivityManager(this)
    // ... 其他初始化代码
}
```

### 4. 创建 CustomLiveActivityManager

已创建 `android/app/src/main/kotlin/github/hunmer/memento/CustomLiveActivityManager.kt`：

- 继承自 `LiveActivityManager`
- 实现 `buildNotification()` 方法
- 提供自定义 RemoteViews 布局
- 支持图片加载和进度显示

### 5. 创建布局文件

已创建 `android/app/src/main/res/layout/live_activity.xml`：

- 定义 RemoteViews 布局
- 包含标题、描述、进度条、计时器等组件
- 使用标准 Android 布局属性

### 6. 验证配置

#### 检查清单

- [ ] `pubspec.yaml` 包含 `live_activities` 依赖
- [ ] `AndroidManifest.xml` 包含必要的权限
- [ ] `MainActivity.kt` 初始化了 `LiveActivityManagerHolder`
- [ ] `CustomLiveActivityManager.kt` 实现完整
- [ ] `live_activity.xml` 布局文件存在
- [ ] 通知图标 `ic_notification` 存在

#### 测试代码

在 Flutter 中测试：

```dart
final _liveActivitiesPlugin = LiveActivities();

// 初始化插件（Android 不需要 appGroupId）
await _liveActivitiesPlugin.init();

// 检查设备支持
final isSupported = await _liveActivitiesPlugin.areActivitiesEnabled();

// 创建活动
final activityId = await _liveActivitiesPlugin.createActivity({
  'title': 'Memento 任务',
  'subtitle': '正在处理中...',
  'progress': 0.5,
  'status': '进行中',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'iconUrl': 'https://example.com/icon.png',
});
```

## 布局自定义

### 修改 live_activity.xml

可以根据需要修改布局文件：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="16dp">

    <!-- 自定义你的布局 -->
    <TextView
        android:id="@+id/title"
        android:textColor="@android:color/black"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:textSize="16sp"
        android:textStyle="bold" />

    <!-- 更多组件... -->

</LinearLayout>
```

### 修改 CustomLiveActivityManager

在 `buildNotification()` 方法中自定义通知：

```kotlin
override suspend fun buildNotification(
    notification: Notification.Builder,
    event: String,
    data: Map<String, Any>
): Notification {
    val title = data["title"] as String
    val subtitle = data["subtitle"] as String

    // 自定义通知
    return notification
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle(title)
        .setContentText(subtitle)
        .setCustomContentView(remoteViews)
        .setCustomBigContentView(remoteViews)
        .setOngoing(true)
        .build()
}
```

## 高级功能

### 1. 自定义图片加载

在 `CustomLiveActivityManager` 中可以实现自定义图片加载逻辑：

```kotlin
suspend fun loadImageBitmap(imageUrl: String?): Bitmap? {
    return withContext(Dispatchers.IO) {
        // 自定义图片加载逻辑
        // 例如：缓存、压缩、格式转换等
    }
}
```

### 2. 动态更新

通过 `updateActivity()` 方法可以动态更新活动：

```dart
await _liveActivitiesPlugin.updateActivity(activityId, {
  'title': '更新后的标题',
  'progress': 0.8,
  'status': '更新中...',
});
```

### 3. 添加操作按钮

在 `CustomLiveActivityManager` 中可以添加操作按钮：

```kotlin
val pendingIntent = PendingIntent.getActivity(...)

return notification
    .addAction(R.drawable.ic_action, "操作", pendingIntent)
    .build()
```

## 性能优化

### 1. 图片大小限制

- 图片大小不应超过 4KB
- 使用 `resizeFactor` 参数压缩图片
- 优先使用本地资源而不是网络图片

### 2. 更新频率

- 避免过于频繁的更新（建议间隔 >= 2秒）
- 批量更新多个字段
- 在应用进入后台时暂停更新

### 3. 内存管理

- 及时释放不需要的 Bitmap
- 使用弱引用避免内存泄漏
- 监控内存使用情况

## 常见问题

### 问题 1: 通知不显示

**原因**:
- 缺少通知权限
- Foreground Service 未正确配置
- 设备不支持（API < 24）

**解决方案**:
```dart
// 检查设备支持
final isSupported = await _liveActivitiesPlugin.areActivitiesEnabled();
if (!isSupported) {
  print('设备不支持 Live Activities');
}

// 检查通知权限
final permission = await Permission.notification.status;
if (permission.isDenied) {
  await Permission.notification.request();
}
```

### 问题 2: 图片不显示

**原因**:
- 图片大小超过限制
- 网络图片加载失败
- 图片格式不支持

**解决方案**:
- 使用 `LiveActivityFileFromAsset` 加载本地图片
- 压缩网络图片：`LiveActivityFileFromUrl.image(url, imageOptions: LiveActivityImageFileOptions(resizeFactor: 0.5))`
- 确保图片格式为 PNG 或 JPG

### 问题 3: 更新不及时

**原因**:
- 应用被系统杀死
- 网络连接不稳定
- 更新频率过高

**解决方案**:
- 实现推送通知更新（需要服务器支持）
- 降低更新频率
- 在 `buildNotification()` 中实现错误处理

## 测试

### 1. 设备测试

1. 在 Android 设备上运行应用
2. 授予通知权限
3. 进入设置页面
4. 点击 "Live Activities 测试"
5. 创建活动并观察通知

### 2. 模拟器测试

Android 模拟器支持 API 24+，可以用于测试：
1. 创建 Android 模拟器（API 24+）
2. 运行应用
3. 测试所有功能

## 参考资源

- [Android RemoteViews 文档](https://developer.android.com/reference/android/widget/RemoteViews)
- [live_activities 插件文档](https://pub.dev/packages/live_activities)
- [Android 通知指南](https://developer.android.com/guide/topics/ui/notifiers/notifications)
