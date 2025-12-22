# Live Activities 问题修复报告

## 修复日期
2025-12-21

## 已修复的问题

### 1. 测试页面 API 调用错误

**问题描述**：
- `createActivity` 方法期望 2 个位置参数，但只提供了 1 个
- 参数类型不匹配：Map<String, dynamic> 不能赋值给 String
- `stale` 参数是必需的但未提供
- 存在未使用的导入和变量

**修复方案**：
- 修正了 `createActivity` 的调用方式：
  ```dart
  // 修复前
  final id = await _liveActivitiesPlugin.createActivity(activityModel);

  // 修复后
  final id = await _liveActivitiesPlugin.createActivity(
    activityId,
    activityModel,
    staleIn: const Duration(minutes: 10),
  );
  ```

- 移除了未使用的导入：`package:live_activities/models/live_activity_file.dart`
- 移除了未使用的变量声明

**涉及文件**：
- `lib/screens/settings_screen/screens/live_activities_test_screen.dart`

### 2. iOS 版本兼容性问题

**问题描述**：
Swift 编译器错误：
- `'addSceneDelegate' is only available in iOS 13.0 or newer`
- `'Insecure' is only available in iOS 13.0 or newer`
- `'hash(data:)' is only available in iOS 13.0 or newer`

**问题原因**：
项目中的某些目标的 iOS 部署目标设置为 18.2，导致与 live_activities 插件（需要 iOS 13.0+）不兼容。

**修复方案**：
- 统一所有目标的 iOS 部署目标为 13.0
- 执行命令：
  ```bash
  sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 18\.2/IPHONEOS_DEPLOYMENT_TARGET = 13.0/g' ios/Runner.xcodeproj/project.pbxproj
  ```

**涉及文件**：
- `ios/Runner.xcodeproj/project.pbxproj`

**验证结果**：
```bash
$ grep "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | sort | uniq
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
```

所有目标的部署目标现在都是 13.0。

## 修复后的配置清单

### ✅ 已完成的工作

#### iOS 平台配置
- [x] Info.plist 配置（NSSupportsLiveActivities）
- [x] Widget Extension 模板文件
- [x] 权限配置文件
- [x] iOS 部署目标统一为 13.0

#### Android 平台配置
- [x] MainActivity.kt 集成
- [x] CustomLiveActivityManager 实现
- [x] live_activity.xml 布局文件

#### Flutter 端配置
- [x] 测试页面创建（API 修复完成）
- [x] 设置页面入口
- [x] 路由配置

#### 文档
- [x] iOS 配置指南
- [x] Android 配置指南
- [x] 问题修复报告（本文件）

## 需要手动完成的配置（仅 iOS）

由于需要在 Xcode 中进行图形界面操作，以下配置需要手动完成：

### 1. 创建 Widget Extension

1. 在 Xcode 中打开 `ios/Runner.xcworkspace`
2. 右键点击项目根目录 → **New** → **Target...**
3. 选择 **Widget Extension** → **Next**
4. 配置：
   - Product Name: `MementoWidget`
   - Interface: **Swift**
   - Language: **Swift**
   - Embed in Application: **Runner**
5. 点击 **Finish**，然后点击 **Activate**

### 2. 配置 App Groups

**Runner 目标**：
1. 选择 **Runner** 目标
2. 切换到 **Signing & Capabilities** 标签
3. 点击 **+ Capability**
4. 搜索并选择 **App Groups**
5. 配置 App Group ID: `group.github.hunmer.memento`

**MementoWidget 目标**：
1. 重复上述步骤，为 **MementoWidget** 目标添加 **App Groups** 能力
2. 使用相同的 App Group ID: `group.github.hunmer.memento`

### 3. 配置 Push Notifications

1. 在 **Runner** 目标中
2. 点击 **+ Capability**
3. 搜索并选择 **Push Notifications**

### 4. 配置证书和描述文件

1. 确保所有目标的 **Team** 设置为你的开发团队
2. 确保 **Bundle Identifier** 配置正确：
   - Runner: `github.hunmer.memento`
   - MementoWidget: `github.hunmer.memento.MementoWidget`
3. 选择或更新 **Provisioning Profile**

### 5. 验证配置

- [ ] 检查 `ios/Runner/Info.plist` 包含 `NSSupportsLiveActivities = true`
- [ ] 检查 `ios/MementoWidget/Info.plist` 包含 `NSSupportsLiveActivities = true`
- [ ] 确认 Runner 和 MementoWidget 都配置了相同的 App Groups
- [ ] 确认 Runner 配置了 Push Notifications
- [ ] 确认所有目标都配置了有效的证书和描述文件

## 测试步骤

### 1. iOS 设备测试

1. 确保设备运行 iOS 16.1 或更高版本
2. 完成上述 Xcode 配置
3. 运行应用：`flutter run -d <device_id>`
4. 进入 "设置" → "开发者测试" → "Live Activities 测试"
5. 点击 "创建活动"
6. 观察锁屏界面或动态岛区域

### 2. Android 设备测试

1. 确保设备运行 Android API 24 或更高版本
2. 运行应用：`flutter run -d <device_id>`
3. 授予通知权限
4. 进入 "设置" → "开发者测试" → "Live Activities 测试"
5. 点击 "创建活动"
6. 观察通知栏

## 常见问题及解决方案

### Q1: 仍然出现 Swift 编译器错误

**解决方案**：
1. 清理构建文件夹：Product → Clean Build Folder
2. 删除 DerivedData 文件夹
3. 重启 Xcode
4. 重新运行 `flutter clean && flutter pub get && flutter run`

### Q2: 设备上 Live Activity 不显示

**检查清单**：
- [ ] 设备运行 iOS 16.1+ 或 Android API 24+
- [ ] 应用已授予通知权限
- [ ] `areActivitiesEnabled()` 返回 `true`
- [ ] iOS: 已配置 App Groups 和 Widget Extension
- [ ] Android: 已配置 Foreground Service 权限

### Q3: 图片不显示或显示异常

**解决方案**：
- 确保图片大小 < 4KB
- 使用 `LiveActivityFileFromAsset` 加载本地图片
- 压缩网络图片：`LiveActivityFileFromUrl.image(url, imageOptions: LiveActivityImageFileOptions(resizeFactor: 0.5))`

## 参考资源

- [live_activities 插件文档](https://pub.dev/packages/live_activities)
- [iOS 配置指南](live_activities_ios_config.md)
- [Android 配置指南](live_activities_android_config.md)
- [Apple 官方文档 - Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)

## 状态

- ✅ 所有代码问题已修复
- ✅ iOS 部署目标已统一
- ✅ 测试页面 API 调用已修正
- ⚠️ 需要手动完成 Xcode 配置
- ⚠️ 需要在实际设备上测试

---

**注意**：iOS 平台的 Widget Extension、App Groups 和 Push Notifications 配置必须在 Xcode 中手动完成，无法通过命令行或代码文件自动配置。
