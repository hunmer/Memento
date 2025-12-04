# Memento Intent Plugin

一个 Flutter 原生插件，用于处理 Android 和 iOS 平台上的 Intent、深度链接和分享内容。

## 功能特性

### Android 平台
- ✅ 动态注册/注销 URL Scheme
- ✅ 深度链接处理
- ✅ 分享文本接收
- ✅ 分享文件接收（图片、视频）
- ✅ Intent 数据监听

### iOS 平台
- ✅ URL Scheme 管理（静态配置）
- ✅ 深度链接处理
- ✅ 分享文本接收
- ✅ 分享文件接收
- ✅ Intent 数据监听

## 快速开始

### 1. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  memento_intent:
    path: ./memento_intent
```

### 2. 初始化插件

在应用启动时初始化插件：

```dart
import 'package:memento_intent/memento_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Intent 插件
  await MementoIntent.instance.init();

  runApp(MyApp());
}
```

### 3. 设置回调

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MementoIntent _intent = MementoIntent.instance;

  @override
  void initState() {
    super.initState();
    _setupIntentCallbacks();
  }

  void _setupIntentCallbacks() {
    // 深度链接回调
    _intent.onDeepLink = (Uri uri) {
      print('收到深度链接: $uri');
      // 处理深度链接
      _handleDeepLink(uri);
    };

    // 分享文本回调
    _intent.onSharedText = (String text) {
      print('收到分享文本: $text');
      // 处理分享文本
    };

    // 分享文件回调
    _intent.onSharedFiles = (List<SharedMediaFile> files) {
      print('收到分享文件: ${files.length} 个文件');
      for (var file in files) {
        print('  - ${file.path} (${file.type})');
      }
    };

    // Intent 数据回调
    _intent.onIntentData = (IntentData data) {
      print('收到 Intent 数据: ${data.toJson()}');
    };
  }
}
```

### 4. 动态注册 Scheme

```dart
// 注册一个深度链接 Scheme
final success = await MementoIntent.instance.registerDynamicScheme(
  scheme: 'myapp',
  host: 'example.com',
  pathPrefix: '/app',
);

if (success) {
  print('Scheme 注册成功!');
} else {
  print('Scheme 注册失败');
}
```

### 5. 注销 Scheme

```dart
final success = await MementoIntent.instance.unregisterDynamicScheme();
if (success) {
  print('Scheme 注销成功!');
}
```

## API 参考

### 类

#### MementoIntent
主要的插件类，使用单例模式。

##### 属性
- `onDeepLink`: 深度链接回调
- `onSharedText`: 分享文本回调
- `onSharedFiles`: 分享文件回调
- `onIntentData`: Intent 数据回调

##### 方法
- `init()`: 初始化插件
- `registerDynamicScheme(...)`: 注册动态 Scheme
- `unregisterDynamicScheme()`: 注销动态 Scheme
- `getDynamicSchemes()`: 获取已注册的 Schemes
- `dispose()`: 清理资源

#### SharedMediaFile
分享文件模型。

##### 属性
- `path`: 文件路径
- `type`: 文件类型（image/video/file）

#### IntentData
Intent 数据模型。

##### 属性
- `action`: Action 字符串
- `data`: 数据字符串
- `type`: MIME 类型
- `extras`: 额外数据

## 测试页面

在 Memento 应用中，已经集成了一个 Intent 测试页面，位于：
`lib/screens/intent_test_screen/intent_test_screen.dart`

访问方式：
1. 打开应用设置页面
2. 找到"开发者测试"部分
3. 点击"Intent 测试"

测试页面提供了以下功能：
- 查看平台信息
- 动态注册/注销 Scheme
- 实时日志显示
- 深度链接接收测试
- 分享内容接收测试

## Android 配置

### AndroidManifest.xml

在主应用的 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<activity
    android:name=".DynamicDeepLinkActivity"
    android:enabled="false"
    android:exported="true"
    android:launchMode="singleTop">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

注意：`DynamicDeepLinkActivity` 需要在主应用中实现，用于处理动态注册的深度链接。

## iOS 配置

### Info.plist

在 `ios/Runner/Info.plist` 中添加 URL Scheme：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.myapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

### AppDelegate.swift

在 `ios/Runner/AppDelegate.swift` 中添加 URL 处理：

```swift
override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // MementoIntent 插件会自动处理 URL
    return super.application(app, open: url, options: options)
}
```

## 使用场景

### 场景 1：活动页深度链接
```dart
// 活动开始时注册临时 Scheme
await MementoIntent.instance.registerDynamicScheme(
  scheme: 'double11',
  host: 'gift.myapp.com',
  pathPrefix: '/2025',
);

// 活动结束后注销
await MementoIntent.instance.unregisterDynamicScheme();
```

### 场景 2：多租户应用
```dart
// 为不同客户注册不同的 Scheme
await MementoIntent.instance.registerDynamicScheme(
  scheme: 'customerA',
  host: 'app.customer-a.com',
);

await MementoIntent.instance.registerDynamicScheme(
  scheme: 'customerB',
  host: 'app.customer-b.com',
);
```

### 场景 3：企业集成
```dart
// 为企业微信/钉钉等企业应用注册专属 Scheme
await MementoIntent.instance.registerDynamicScheme(
  scheme: 'wework',
  host: 'app.weixin.qq.com',
);
```

## 注意事项

1. **Android 动态注册**：需要 Android 11+ 才能完美支持动态注册
2. **iOS 限制**：iOS 不支持运行时动态注册 URL Scheme，需要在 Info.plist 中预先配置
3. **权限**：确保应用有处理对应类型的权限（如文件访问权限）
4. **生命周期**：插件在应用启动时应尽早初始化
5. **资源清理**：在应用退出时调用 `dispose()` 方法

## 常见问题

### Q: 深度链接无法接收？
A: 请检查：
1. Scheme 是否已正确注册
2. URL 格式是否正确
3. 应用是否在后台运行
4. Android 端检查 DynamicDeepLinkActivity 是否配置

### Q: 分享内容无法接收？
A: 请检查：
1. 其他应用是否支持分享
2. 权限是否正确配置
3. 应用是否在前台运行

### Q: 如何测试深度链接？
A: 在浏览器中输入格式如：`myapp://example.com/app`

## 许可证

本项目基于 MIT 许可证开源。

## 作者

hunmer

## 更新日志

### v1.0.0
- 初始版本发布
- 支持 Android 和 iOS 平台
- 动态 Scheme 注册功能
- 深度链接处理
- 分享内容接收
