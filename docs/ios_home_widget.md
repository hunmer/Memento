# iOS 桌面小组件功能

## 概述

将 Memento 应用内的主页小组件（HomeWidget）渲染到 iOS 桌面小组件上，支持三种尺寸。

## 架构

```
Flutter App                           iOS Widget Extension
┌─────────────────┐                  ┌─────────────────────┐
│ HomeWidget       │                  │ MementoFlutter      │
│ (AddWidgetDialog)│                  │ Widget.swift        │
└────────┬────────┘                  └──────────┬──────────┘
         │                                      │
         ▼                                      ▼
┌─────────────────┐  App Group   ┌─────────────────────┐
│ IOSWidget       │─────────────▶│ UserDefaults        │
│ SyncService     │              │ (group.github.      │
└────────┬────────┘              │ hunmer.memento)     │
         │                       └─────────────────────┘
         ▼
┌─────────────────┐
│ IOSWidget       │
│ Renderer        │
│ (PNG 图片)       │
└─────────────────┘
```

## 文件结构

### Dart 端

```
lib/
├── core/app_widgets/
│   ├── models/
│   │   └── ios_widget_config.dart      # 配置模型
│   └── services/
│       ├── ios_widget_sync_service.dart # 同步服务
│       ├── ios_widget_renderer.dart     # 渲染器
│       └── widget_size_mapper.dart      # 尺寸映射
│
└── screens/ios_widget_config/
    └── ios_widget_config_screen.dart    # 配置页面
```

### iOS 端

```
ios/MyAppWidget/
├── MementoFlutterWidget.swift    # Widget 定义
├── MyAppWidget.entitlements      # App Group 权限
└── Info.plist
```

## 核心类

### IOSWidgetConfig

```dart
class IOSWidgetConfig {
  final String widgetKind;      // iOS Widget Kind
  final String homeWidgetId;    // 对应的 HomeWidget ID
  final String pluginId;        // 插件 ID
  final IOSWidgetSize size;     // small/wide/large
  final Map<String, dynamic> config;
  final DateTime lastUpdated;
}
```

### IOSWidgetSize

| 尺寸 | iOS Family | 点尺寸 | 用途 |
|------|-----------|--------|------|
| `small` | systemSmall | 170×170 | 单个小组件 |
| `wide` | systemMedium | 364×170 | 横向组件 |
| `large` | systemLarge | 364×382 | 大型组件 |

### WidgetSizeMapper

提供 HomeWidgetSize 与 IOSWidgetSize 的双向映射：

```dart
// HomeWidget → iOS
final iosSize = WidgetSizeMapper.homeToIOS(homeWidgetSize);

// iOS → HomeWidget
final homeSize = WidgetSizeMapper.iosToHome(iosSize);
```

## 使用流程

### 1. 配置小组件

```dart
// 打开配置页面
Navigator.pushNamed(context, '/ios_widget_config');
```

### 2. 程序化创建

```dart
final config = await IOSWidgetSyncService().createConfig(
  homeWidgetId: 'chat_overview',
  iosSize: IOSWidgetSize.small,
  config: {'showUnread': true},
);
```

### 3. 刷新小组件

```dart
// 刷新所有
await IOSWidgetSyncService().refreshAllWidgets();

// 刷新指定
await IOSWidgetRenderer.refreshWidget('memento_widget_small');
```

## iOS 配置

### App Group

确保主应用和 Widget Extension 共享相同的 App Group：

```
group.github.hunmer.memento
```

### Entitlements

`ios/MyAppWidget/MyAppWidget.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.github.hunmer.memento</string>
    </array>
</dict>
</plist>
```

### URL Scheme

点击小组件跳转到配置页面：

```
memento://widget/config?kind=small
```

## 数据存储

使用 App Group 的 UserDefaults 存储：

| Key | 类型 | 说明 |
|-----|------|------|
| `ios_widget_config_{kind}` | JSON String | 配置信息 |
| `ios_widget_image_{kind}` | Data | 渲染的 PNG 图片 |

## 注意事项

1. **平台限制**：仅支持 iOS，Android 需使用原生 Widget 机制
2. **渲染时机**：配置保存时渲染，数据更新后需手动调用 `refreshWidget()`
3. **图片大小**：使用 @3x 像素密度，注意内存占用
4. **更新频率**：iOS Widget 默认每小时更新一次
