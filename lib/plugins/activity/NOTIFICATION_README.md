# 活动插件通知栏服务使用说明

## 概述

活动插件现已支持Android常驻通知栏服务，能够显示距离上次活动记录的时间和内容，并提供快速记录活动的入口。

## 功能特性

- ✅ **常驻通知栏**：在Android状态栏显示活动提醒
- ✅ **实时更新**：每分钟自动更新显示距离上次活动的时间
- ✅ **智能检测**：显示上次记录的活动内容和时长
- ✅ **快速操作**：点击通知可直接打开活动表单
- ✅ **按钮操作**：提供"记录活动"和"忽略"快捷按钮
- ✅ **权限管理**：自动请求和检查通知权限
- ✅ **平台适配**：仅在Android平台启用，其他平台自动跳过

## 使用方法

### 1. 启用通知服务

#### 方法一：通过代码启用
```dart
import 'package:memento/plugins/activity/activity_plugin.dart';

// 启用活动通知服务
await ActivityPlugin.instance.enableActivityNotification();

// 检查是否已启用
final isEnabled = ActivityPlugin.instance.isNotificationEnabled();

// 禁用通知服务
await ActivityPlugin.instance.disableActivityNotification();
```

#### 方法二：通过JS API启用
```javascript
// 在WebView或JS环境中调用
await memento.activity.enableNotification();

// 获取通知状态
const status = await memento.activity.getNotificationStatus();

// 禁用通知
await memento.activity.disableNotification();
```

### 2. 监听通知点击事件

通知点击事件会自动通过全局事件系统广播，在ActivityTimelineScreen中已自动处理：

```dart
// 在ActivityTimelineScreen中已自动实现监听
eventManager.subscribe('activity_notification_tapped', (args) {
  // 自动打开活动表单
});
```

### 3. 测试功能

```dart
import 'package:memento/plugins/activity/services/activity_notification_test.dart';

// 运行测试
final test = ActivityNotificationTest();
await test.initialize();

// 运行所有测试
final results = await test.runAllTests();

// 显示测试结果
ActivityNotificationTest.showTestResults(context, results);
```

## 技术实现

### 架构组件

1. **ActivityNotificationService**：核心通知服务类
   - 位置：`lib/plugins/activity/services/activity_notification_service.dart`
   - 功能：管理通知的创建、更新、销毁

2. **ActivityPlugin**：插件集成
   - 位置：`lib/plugins/activity/activity_plugin.dart`
   - 功能：提供统一的API接口

3. **NotificationController**：通知控制器
   - 位置：`lib/core/notification_controller.dart`
   - 功能：处理通知点击事件

4. **ActivityTimelineScreen**：UI事件处理
   - 位置：`lib/plugins/activity/screens/activity_timeline_screen/activity_timeline_screen.dart`
   - 功能：监听通知点击并打开表单

5. **ActivityForegroundService**：Android前台服务
   - 位置：`android/app/src/main/kotlin/github/hunmer/memento/ActivityForegroundService.kt`
   - 功能：Android系统级常驻通知

### 关键方法

#### ActivityNotificationService
- `initialize()`：初始化通知服务
- `enable()`：启用通知并启动前台服务
- `disable()`：禁用通知并停止前台服务
- `_updateNotification()`：更新通知内容
- `detectOptimalActivityTime()`：智能检测建议的活动时间

#### ActivityPlugin
- `enableActivityNotification()`：启用活动通知
- `disableActivityNotification()`：禁用活动通知
- `isNotificationEnabled()`：检查通知状态

## 配置要求

### Android权限
以下权限已在`AndroidManifest.xml`中配置：
- `FOREGROUND_SERVICE`：前台服务权限
- `FOREGROUND_SERVICE_DATA_SYNC`：数据同步前台服务类型
- `POST_NOTIFICATIONS`：发送通知权限

### Android服务配置
```xml
<service
    android:name="github.hunmer.memento.ActivityForegroundService"
    android:exported="false"
    android:foregroundServiceType="dataSync" />
```

### 依赖包
- `awesome_notifications`：Flutter通知插件
- 已集成到项目中，无需额外配置

## 通知内容格式

### 标准通知
- **标题**：`活动记录提醒`
- **内容**：`距离上次活动「活动标题 (时长)」已过去 X 小时 Y 分钟前`

### 示例
- "距离上次活动「晨间锻炼 (30分钟)」已过去 2 小时 15 分钟前"
- "距离上次活动「工作会议 (1小时)」已过去 45 分钟前"

## 交互行为

### 点击通知本体
- 打开应用并导航到活动页面
- 自动显示活动记录表单

### 点击"记录活动"按钮
- 直接打开活动记录表单
- 可快速创建新的活动记录

### 点击"忽略"按钮
- 关闭当前通知
- 服务继续运行，下次更新时重新显示

## 注意事项

### 性能优化
- 通知每分钟更新一次，降低电池消耗
- 使用前台服务确保通知不被系统清除
- 仅在有活动记录时显示通知

### 兼容性
- 仅支持Android 8.0+（API 26+）
- 需要用户手动授予通知权限（Android 13+）
- 其他平台自动跳过，不影响正常功能

### 故障排除

#### 通知不显示
1. 检查通知权限是否已授予
2. 确认设备通知系统设置
3. 查看应用通知是否被禁用

#### 前台服务启动失败
1. 检查`AndroidManifest.xml`权限配置
2. 确认targetSdkVersion兼容性
3. 查看日志中的错误信息

#### 通知内容不更新
1. 确认活动数据是否正确
2. 检查定时器是否正常运行
3. 验证网络和存储权限

## 开发建议

### 添加设置界面
建议在活动插件的设置页面中添加通知开关：

```dart
SwitchListTile(
  title: Text('启用活动提醒'),
  subtitle: Text('在通知栏显示距离上次活动的时间'),
  value: ActivityPlugin.instance.isNotificationEnabled(),
  onChanged: (value) async {
    if (value) {
      await ActivityPlugin.instance.enableActivityNotification();
    } else {
      await ActivityPlugin.instance.disableActivityNotification();
    }
  },
)
```

### 自定义通知更新间隔
可以扩展ActivityNotificationService支持自定义更新间隔：

```dart
// 添加间隔设置
await _notificationService.setUpdateInterval(5); // 5分钟更新一次
```

### 多语言支持
确保通知文本支持国际化，参考现有的本地化实现。

## 更新日志

### v1.0.0
- ✅ 实现基础常驻通知功能
- ✅ 支持点击打开活动表单
- ✅ 添加Android前台服务支持
- ✅ 实现智能时间检测
- ✅ 完成权限管理和错误处理
- ✅ 添加完整的测试套件

---

**开发完成时间**：2025年11月24日
**开发者**：AI Assistant
**支持平台**：Android (主要), 跨平台兼容