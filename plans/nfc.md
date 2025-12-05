把 NFC 读写功能单独抽成一个 Flutter 插件（local plugin 或发布到 pub 的 plugin），主应用只通过插件调用，是工业级项目中最常见、最干净的架构。

### 为什么应该单独抽成插件？

| 好处 | 说明 |
|------|------|
| 代码隔离、职责清晰 | 主项目不被 native 权限、Manifest、Info.plist 污染 |
| 可复用 | 多个 App（甚至公司其他项目）都能直接引入这个 NFC 插件 |
| 易测试、易维护 | 插件可以独立跑 example 项目测试所有 NFC 场景 |
| 版本管理方便 | 以后升级 nfc_manager、修复 bug、支持新标签类型支持，只改插件就行 |
| 减少主工程编译时间 | 主项目只依赖 Dart 接口，native 代码都在插件里 |

### 推荐结构

```
memento_nfc/                     ← 独立插件项目
├── lib/
│   ├── memento_nfc.dart          ← 对外暴露的纯 Dart 接口
│   └── src/
│       └── nfc_manager_impl.dart   ← 实际调用 nfc_manager 的实现
├── android/
│   ├── src/main/kotlin/com/example/memento_nfc/
│   └── AndroidManifest.xml         ← 只在这里声明 NFC 权限和 intent-filter
├── ios/
│   ├── Runner.xcworkspace
│   └── Info.plist                  ← 只在这里加 NFC 权限
├── example/                        ← 插件自带的可独立运行的测试 App
│   └── lib/main.dart
└── pubspec.yaml

your_main_app/                      ← 你的主业务 App
└── pubspec.yaml
    dependencies:
      memento_nfc:
        path: ../memento_nfc             # 本地开发
        # git: url: git@github.com:xxx/memento_nfc.git  # 以后可以改成 git
```

```

### 实现步骤（手把手）

1. 创建本地插件
```bash
flutter create --template=plugin --platforms=android,ios -a kotlin -i swift memento_nfc
```

2. 修改插件的 `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  nfc_manager: ^3.5.0
  nfc_manager_ndef: ^0.1.0
```

3. 编写 Dart 接口（lib/memento_nfc.dart）
```dart
import 'dart:async';
import 'package:flutter/services.dart';

class MyNfcPlugin {
  static const MethodChannel _channel = MethodChannel('memento_nfc');

  // 写入 AAR（推荐写法，Android 自动打开 App）
  static Future<bool> writeAar({required String packageName}) async {
    try {
      await _channel.invokeMethod('writeAar', {'packageName': packageName});
      return true;
    } catch (e) {
      return false;
    }
  }

  // 写入自定义 URI（iOS 推荐）
  static Future<bool> writeUri(String uri) async {
    try {
      await _channel.invokeMethod('writeUri', {'uri': uri});
      return true;
    } catch (e) {
      return false;
    }
  }

  // 开始监听 NFC（主 App 想实时接收标签数据时调用）
  static Future<void> startListening(Function(String) onTagDiscovered) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTagDiscovered') {
        onTagDiscovered(call.arguments as String);
      }
    });
    await _channel.invokeMethod('startListening');
  }

  static Future<void> stopListening() => _channel.invokeMethod('stopListening');
}
```

4. Android 原生实现（android/src/main/kotlin/.../MyNfcPlugin.kt）
```kotlin
class MyNfcPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "memento_nfc")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      {
      "writeAar" -> writeAar(call.argument<String>("packageName")!!, result)
      "writeUri" -> writeUri(call.argument<String>("uri")!!, result)
      // ... 其他方法
      else -> result.notImplemented()
    }
  }

  private fun writeAar(packageName: String, result: Result) {
    // 使用 nfc_manager 原生 API 写入 AAR，代码和前面一样
    // 完成后 result.success(true)
  }
}
```

5. 在插件的 AndroidManifest.xml 中统一声明 NFC 权限和 intent-filter
```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />

<application>
  <activity android:name=".MyNfcActivity" android:exported="true">
    <intent-filter>
      <action android:name="android.nfc.action.NDEF_DISCOVERED"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <data android:mimeType="application/vnd.com.yourcompany.yourapp"/>
    </intent-filter>
  </activity>
</application>
```

6. 主项目引入插件
```yaml
dependencies:
  memento_nfc:
    path: ../memento_nfc   # 开发阶段
```

使用：
```dart
ElevatedButton(
  onPressed: () async {
    bool ok = await MyNfcPlugin.writeAar(
      packageName: "com.yourcompany.yourapp"
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? "写入成功" : "写入失败"))
    );
  },
  child: Text("写入 NFC：打开本 App"),
)
```