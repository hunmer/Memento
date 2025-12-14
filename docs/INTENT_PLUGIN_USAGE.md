# Memento Intent Plugin 使用指南

## 快速开始

### 访问测试页面

1. 打开 Memento 应用
2. 进入 **设置** 页面
3. 在"开发者测试"部分找到 **"Intent 测试"**
4. 点击进入测试页面

### 使用测试页面

#### 1. 查看平台信息
- 测试页面顶部显示当前平台版本
- 显示 Scheme 注册状态

#### 2. 动态注册 Scheme
- 在"Scheme"字段输入要注册的 URL Scheme（如：`memento`）
- 在"Host"字段输入主机名（如：`example.com`）可选
- 在"Path Prefix"字段输入路径前缀（如：`/app`）可选
- 点击"注册 Scheme"按钮

#### 3. 测试深度链接
注册 Scheme 后：
1. 在手机浏览器中输入 `memento://example.com/app`
2. 观察应用是否被打开
3. 查看测试页面的日志区域，确认收到深度链接

#### 4. 注销 Scheme
- 点击"注销 Scheme"按钮
- 状态会更新为"未注册"

#### 5. 查看实时日志
- 所有 Intent 事件都会实时显示在日志区域
- 包括深度链接、分享内容、Intent 数据等
- 点击右上角的清空图标可以清空日志

## 测试场景

### 场景 1：测试深度链接
```bash
# 注册 Scheme 后，在浏览器或任何支持的应用中输入：
memento://example.com/app

# 或者带查询参数：
memento://example.com/app?param1=value1&param2=value2
```

### 场景 2：测试分享文本
1. 在任何应用中选择文本内容
2. 点击"分享"
3. 选择"Memento"应用
4. 观察应用是否接收到分享的文本

### 场景 3：测试分享图片/视频
1. 在任何应用中打开一张图片或视频
2. 点击分享按钮
3. 选择"Memento"应用
4. 观察应用是否接收到文件信息

## 功能说明

### 深度链接 (Deep Link)
当其他应用或浏览器通过 URL Scheme 打开应用时触发：
```dart
intent.onDeepLink = (Uri uri) {
  print('收到深度链接: $uri');
  // 可以根据 uri.path, uri.queryParameters 等进行路由处理
};
```

### 分享文本 (Shared Text)
当其他应用分享文本内容时触发：
```dart
intent.onSharedText = (String text) {
  print('收到分享文本: $text');
  // 可以将文本保存或显示
};
```

### 分享文件 (Shared Files)
当其他应用分享图片、视频等文件时触发：
```dart
intent.onSharedFiles = (List<SharedMediaFile> files) {
  print('收到 ${files.length} 个文件');
  for (var file in files) {
    print('文件: ${file.path}, 类型: ${file.type}');
  }
  // 可以处理文件，如下载、显示等
};
```

### Intent 数据 (Intent Data)
所有 Intent 事件的原始数据：
```dart
intent.onIntentData = (IntentData data) {
  print('Action: ${data.action}');
  print('Data: ${data.data}');
  print('Type: ${data.type}');
  print('Extras: ${data.extras}');
};
```

## API 使用示例

### 基本初始化
```dart
import 'package:memento_intent/memento_intent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MementoIntent.instance.init();
  runApp(MyApp());
}
```

### 设置回调
```dart
class _MyAppState extends State<MyApp> {
  final IntentPlugin _intent = MementoIntent.instance;

  @override
  void initState() {
    super.initState();
    _intent.onDeepLink = (Uri uri) {
      // 处理深度链接
    };
    _intent.onSharedText = (String text) {
      // 处理分享文本
    };
    _intent.onSharedFiles = (List<SharedMediaFile> files) {
      // 处理分享文件
    };
  }
}
```

### 动态注册 Scheme
```dart
// 注册
final success = await _intent.registerDynamicScheme(
  scheme: 'myapp',
  host: 'example.com',
  pathPrefix: '/home',
);

if (success) {
  print('注册成功!');
}

// 注销
await _intent.unregisterDynamicScheme();
```

### 获取已注册的 Schemes
```dart
final schemes = await _intent.getDynamicSchemes();
print('已注册的 Schemes: $schemes');
```

## 注意事项

### Android 平台
- 需要 Android 11+ 才能完美支持动态注册
- 某些设备可能需要应用重启才能生效
- 建议在应用启动时注册常用的 Scheme

### iOS 平台
- iOS 不支持运行时动态注册 URL Scheme
- 需要在 `Info.plist` 中预先配置静态 Scheme
- 插件主要用于数据收集和验证

### 通用注意事项
1. **权限**：确保应用有访问相关内容的权限
2. **生命周期**：在合适的时机初始化和清理插件
3. **线程安全**：回调函数可能在不同线程调用，注意线程安全
4. **异常处理**：建议在回调函数中添加 try-catch 避免应用崩溃

## 故障排除

### 深度链接无法接收
- ✅ 检查 Scheme 是否已正确注册
- ✅ 检查 URL 格式是否正确
- ✅ 重启应用后重试
- ✅ Android 设备检查 DynamicDeepLinkActivity 配置

### 分享内容无法接收
- ✅ 检查其他应用是否支持分享
- ✅ 确认应用权限已正确配置
- ✅ 确保应用在前台或后台运行

### 注册失败
- ✅ 检查参数是否正确
- ✅ 检查平台版本兼容性
- ✅ 查看日志获取详细错误信息

## 更多资源

- [插件 README](./memento_intent/README.md) - 详细的 API 文档
- [实现总结](./MEMENTO_INTENT_IMPLEMENTATION.md) - 技术实现详情
- 示例代码：`memento_intent/example/lib/main.dart`

## 反馈与支持

如有问题或建议，请：
1. 查看日志获取详细错误信息
2. 参考故障排除部分
3. 查看插件 README 文档
4. 联系开发者
