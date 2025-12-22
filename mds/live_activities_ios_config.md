# iOS Live Activities 配置指南

## 概述

本文档详细说明如何在 iOS 项目中配置 Live Activities 功能。配置完成后，用户可以在锁屏界面或动态岛中查看实时活动通知。

## 前置条件

- iOS 16.1 或更高版本
- Xcode 14.0 或更高版本
- 有效的 Apple Developer 账号（用于配置证书和描述文件）

## 配置步骤

### 1. 启用 Live Activities 支持

已在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 2. 创建 Widget Extension

#### 步骤 1: 在 Xcode 中创建 Extension

1. 打开 `ios/Runner.xcworkspace` 文件
2. 在项目导航器中，右键点击项目根目录
3. 选择 **New** > **Target...**
4. 在模板选择页面，找到并选择 **Widget Extension**
5. 点击 **Next** 按钮

#### 步骤 2: 配置 Extension

1. **Product Name**: 输入 `MementoWidget`（或其他名称）
2. **Interface**: 选择 **Swift**（推荐）
3. **Language**: 选择 **Swift**
4. **Embed in Application**: 确保选择的是 **Runner**
5. 点击 **Finish** 按钮

#### 步骤 3: 激活 Scheme

当选择 Finish 后，会弹出提示框，点击 **Activate** 按钮。

### 3. 配置 Capabilities

#### 步骤 1: 添加 App Groups

1. 在项目导航器中，选择 **Runner** 目标
2. 切换到 **Signing & Capabilities** 标签
3. 点击 **+ Capability** 按钮
4. 在弹出窗口中搜索并选择 **App Groups**
5. 点击 **Enter** 添加

6. 重复上述步骤，为 **MementoWidget** 目标也添加 **App Groups** 能力

7. 在 App Groups 配置界面：
   - 勾选 **group.github.hunmer.memento**（或根据你的 Bundle ID 调整）
   - 确保 Runner 和 MementoWidget 都勾选同一个 App Group

#### 步骤 2: 添加 Push Notifications

1. 在 **Runner** 目标中
2. 点击 **+ Capability** 按钮
3. 搜索并选择 **Push Notifications**
4. 点击 **Enter** 添加

> 注意：Widget Extension 不需要 Push Notifications 能力

### 4. 配置证书和描述文件

1. 确保所有目标的 **Team** 设置为你的开发团队
2. 确保 **Bundle Identifier** 设置正确：
   - Runner: `github.hunmer.memento`
   - MementoWidget: `github.hunmer.memento.MementoWidget`
3. 重新选择或更新 **Provisioning Profile**

### 5. 验证配置

#### 检查列表

- [ ] `ios/Runner/Info.plist` 包含 `NSSupportsLiveActivities` 设置为 `true`
- [ ] `ios/MementoWidget/Info.plist` 包含 `NSSupportsLiveActivities` 设置为 `true`
- [ ] Runner 和 MementoWidget 都配置了 App Groups
- [ ] Runner 配置了 Push Notifications
- [ ] 所有目标的 Bundle ID 配置正确
- [ ] 所有目标都配置了有效的证书和描述文件

#### 常见问题

**问题 1**: 无法创建 Live Activity

检查：
- App Groups 配置是否正确
- 是否使用了相同的 App Group ID
- NSSupportsLiveActivities 是否在两个 Info.plist 中都设置为 true

**问题 2**: Xcode 构建错误

尝试：
- 清理构建文件夹（Product > Clean Build Folder）
- 删除 DerivedData 文件夹
- 重启 Xcode

**问题 3**: 设备上测试时 Live Activity 不显示

检查：
- 设备是否运行 iOS 16.1 或更高版本
- 应用是否被授予通知权限
- 是否已启用 Live Activities（通过 areActivitiesEnabled() 检查）

## 文件说明

### 已创建的文件

1. **ios/MementoWidget/MementoWidgetLiveActivity.swift**
   - Widget Extension 的主文件
   - 包含 LiveActivitiesAppAttributes 定义
   - 包含 Live Activity 和 Dynamic Island 的 UI 定义

2. **ios/MementoWidget/Info.plist**
   - Widget Extension 的配置信息
   - 包含 NSSupportsLiveActivities 设置

3. **ios/MementoWidget/MementoWidget.entitlements**
   - 权限配置文件
   - 包含 Push Notifications 权限

### 在 Flutter 中使用

在 Flutter 代码中初始化：

```dart
final _liveActivitiesPlugin = LiveActivities();

// 初始化插件
await _liveActivitiesPlugin.init(
  appGroupId: 'group.github.hunmer.memento',
  urlScheme: 'memento',
  requireNotificationPermission: true,
);

// 检查设备支持
final isSupported = await _liveActivitiesPlugin.areActivitiesEnabled();

// 创建活动
final activityId = await _liveActivitiesPlugin.createActivity({
  'title': '任务标题',
  'subtitle': '任务描述',
  'progress': 0.5,
  'status': '进行中',
});
```

## 测试

1. 在设备上运行应用
2. 打开应用并授予通知权限
3. 进入设置页面
4. 点击 "Live Activities 测试"
5. 点击 "创建活动" 按钮
6. 观察设备锁屏界面或动态岛区域

## 参考资源

- [Apple 官方文档 - Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [live_activities 插件文档](https://pub.dev/packages/live_activities)
- [App Groups 指南](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
