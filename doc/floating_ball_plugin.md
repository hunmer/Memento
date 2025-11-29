### 创建完整Flutter自定义插件示例：Floating Ball Plugin

基于您的需求，我将提供一个完整的Flutter自定义插件示例，用于实现Android悬浮球功能（自动吸附侧边、点击展开多个按钮）。这个插件名为`floating_ball_plugin`，其中所有核心逻辑（如悬浮窗创建、拖动、吸附和展开）都放在Android的Kotlin代码中（复用之前的`FloatingBallService`）。Flutter（Dart）侧仅通过平台通道（MethodChannel）调用Kotlin方法来启动/停止悬浮球。

这个示例遵循Flutter官方文档的插件开发流程（截至2025年的最佳实践，包括null safety、生命周期管理和测试建议）。插件是Android专属的（因为悬浮窗是Android特有功能；iOS不支持系统级overlay）。

#### 前提条件
- Flutter SDK 3.38.1 或更高版本（2025年推荐）。
- Android设备/模拟器（需授予SYSTEM_ALERT_WINDOW权限）。
- 在插件的Android部分添加权限：在`android/src/main/AndroidManifest.xml`中添加：
  ```xml
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
  ```

#### 步骤1: 创建插件项目
在终端运行以下命令创建插件（指定Android平台，使用Kotlin）：
```bash
flutter create --org com.example --template=plugin --platforms=android -a kotlin floating_ball_plugin
```
这会生成：
- `lib/floating_ball_plugin.dart`：Dart API。
- `android/src/main/kotlin/com/example/floating_ball_plugin/FloatingBallPlugin.kt`：Kotlin实现。
- `example/`：示例Flutter app。
- `pubspec.yaml`：插件配置。

#### 步骤2: 配置pubspec.yaml
编辑根目录的`pubspec.yaml`，添加插件平台配置：
```yaml
name: floating_ball_plugin
description: A Flutter plugin for Android floating ball with auto-snap and expandable buttons.
version: 0.0.1
homepage: https://example.com

environment:
  sdk: '>=3.4.4 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  plugin:
    platforms:
      android:
        package: com.example.floating_ball_plugin
        pluginClass: FloatingBallPlugin
```

#### 步骤3: 实现Dart API（lib/floating_ball_plugin.dart）
Dart侧定义公共方法，通过MethodChannel调用Android侧。添加权限请求逻辑（使用`permission_handler`插件，或手动Intent；这里简化用手动方式）。
```dart
import 'package:flutter/services.dart';

class FloatingBallPlugin {
  static const MethodChannel _channel = MethodChannel('floating_ball_plugin');

  /// 启动悬浮球
  static Future<String?> startFloatingBall() async {
    try {
      final String? result = await _channel.invokeMethod('startFloatingBall');
      return result;
    } on PlatformException {
      return 'Failed to start floating ball';
    }
  }

  /// 停止悬浮球
  static Future<String?> stopFloatingBall() async {
    try {
      final String? result = await _channel.invokeMethod('stopFloatingBall');
      return result;
    } on PlatformException {
      return 'Failed to stop floating ball';
    }
  }
}
```

#### 步骤4: 实现Android Kotlin侧（android/src/main/kotlin/com/example/floating_ball_plugin/FloatingBallPlugin.kt）
这里注册MethodChannel，并处理调用。启动/停止时使用Service（FloatingBallService）。
```kotlin
package com.example.floating_ball_plugin

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FloatingBallPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context  // 用于启动Service

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "floating_ball_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "startFloatingBall" -> {
        val intent = Intent(context, FloatingBallService::class.java)
        context.startService(intent)
        result.success("Floating ball started")
      }
      "stopFloatingBall" -> {
        val intent = Intent(context, FloatingBallService::class.java)
        context.stopService(intent)
        result.success("Floating ball stopped")
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
```

#### 步骤5: 添加FloatingBallService（android/src/main/kotlin/com/example/floating_ball_plugin/FloatingBallService.kt）
直接复用您之前的完整Kotlin代码（悬浮球逻辑）。将它放在同一包下，并确保在插件的AndroidManifest.xml中声明Service：
```xml
<!-- 在 android/src/main/AndroidManifest.xml 的 <application> 内添加 -->
<service android:name=".FloatingBallService" />
```
FloatingBallService.kt 的代码（完整复制之前的实现）：
```kotlin
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.content.ContextCompat

class FloatingBallService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var params: WindowManager.LayoutParams? = null
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var isExpanded = false
    private val expandedButtons = mutableListOf<View>()

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // 获取屏幕尺寸
        val displayMetrics = resources.displayMetrics
        screenWidth = displayMetrics.widthPixels
        screenHeight = displayMetrics.heightPixels

        // 创建悬浮球视图（假设使用一个 ImageView，您可以替换为自定义布局）
        floatingView = ImageView(this).apply {
            setImageDrawable(ContextCompat.getDrawable(this@FloatingBallService, android.R.drawable.ic_menu_add)) // 替换为您的图标
            setOnTouchListener(touchListener)
        }

        // 悬浮球参数
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenWidth - 100 // 初始位置：右侧中间
            y = screenHeight / 2
        }

        windowManager.addView(floatingView, params)
    }

    private val touchListener = View.OnTouchListener { v, event ->
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params!!.x
                initialY = params!!.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
            }
            MotionEvent.ACTION_MOVE -> {
                params!!.x = initialX + (event.rawX - initialTouchX).toInt()
                params!!.y = initialY + (event.rawY - initialTouchY).toInt()
                windowManager.updateViewLayout(floatingView, params)
            }
            MotionEvent.ACTION_UP -> {
                // 自动吸附侧边
                val mid = screenWidth / 2
                val targetX = if (params!!.x < mid) 0 else screenWidth - floatingView.width
                params!!.x = targetX
                windowManager.updateViewLayout(floatingView, params)

                // 判断是否为点击（移动距离小）
                if (Math.abs(event.rawX - initialTouchX) < 10 && Math.abs(event.rawY - initialTouchY) < 10) {
                    toggleExpand()
                }
            }
        }
        true
    }

    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f

    // 展开/关闭多个按钮
    private fun toggleExpand() {
        if (isExpanded) {
            closeExpandedButtons()
        } else {
            showExpandedButtons()
        }
        isExpanded = !isExpanded
    }

    // 根据位置展示多个按钮
    private fun showExpandedButtons() {
        val ballX = params!!.x
        val ballY = params!!.y
        val buttonSize = 100 // 子按钮大小（dp），可调整
        val direction = if (ballX == 0) 1 else -1 // 左侧向右展开（1），右侧向左展开（-1）

        // 创建 3 个子按钮
        for (i in 1..3) {
            val buttonView = ImageView(this).apply {
                setImageDrawable(ContextCompat.getDrawable(this@FloatingBallService, android.R.drawable.ic_menu_info_details)) // 替换图标
                setOnClickListener {
                    Toast.makeText(this@FloatingBallService, "按钮 $i 被点击", Toast.LENGTH_SHORT).show()
                    toggleExpand() // 点击后关闭
                }
            }

            val buttonParams = WindowManager.LayoutParams(
                buttonSize,
                buttonSize,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = ballX + direction * i * buttonSize // 根据方向计算位置
                y = ballY
            }

            windowManager.addView(buttonView, buttonParams)
            expandedButtons.add(buttonView)
        }
    }

    private fun closeExpandedButtons() {
        expandedButtons.forEach { windowManager.removeView(it) }
        expandedButtons.clear()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (floatingView.isAttachedToWindow) {
            windowManager.removeView(floatingView)
        }
        closeExpandedButtons()
    }
}
```

#### 步骤6: 在示例App中使用插件（example/lib/main.dart）
编辑示例app的`pubspec.yaml`添加依赖（path指向插件根目录）：
```yaml
dependencies:
  flutter:
    sdk: flutter
  floating_ball_plugin:
    path: ../
```

然后在`main.dart`中使用：
```dart
import 'package:flutter/material.dart';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:permission_handler/permission_handler.dart';  // 添加permission_handler依赖处理权限

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Unknown';

  Future<void> _requestPermissionAndStart() async {
    final status = await Permission.systemAlertWindow.request();
    if (status.isGranted) {
      final result = await FloatingBallPlugin.startFloatingBall();
      setState(() => _status = result ?? 'Started');
    } else {
      setState(() => _status = 'Permission denied');
    }
  }

  Future<void> _stopFloatingBall() async {
    final result = await FloatingBallPlugin.stopFloatingBall();
    setState(() => _status = result ?? 'Stopped');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Floating Ball Plugin Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status'),
              ElevatedButton(
                onPressed: _requestPermissionAndStart,
                child: const Text('启动悬浮球'),
              ),
              ElevatedButton(
                onPressed: _stopFloatingBall,
                child: const Text('停止悬浮球'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 步骤7: 测试和运行
1. 在插件根目录运行`flutter pub get`。
2. 进入`example/`目录：`cd example`。
3. 运行`flutter pub get`（添加permission_handler依赖：`flutter pub add permission_handler`）。
4. 运行app：`flutter run`。
5. 在设备上授予overlay权限。

#### 最佳实践（2025年更新）
- **联邦插件**：如果扩展到多平台，拆分成联邦插件（app-facing包依赖平台包）。
- **测试**：在`test/`添加Dart单元测试；在Android Studio打开`android/`测试Kotlin。
- **发布**：更新`README.md`和`CHANGELOG.md`，用`flutter pub publish`发布到pub.dev。
- **性能**：对于复杂交互，用EventChannel推送事件从Kotlin到Dart。
- **隐私**：如果访问敏感数据，添加隐私清单。

这个插件完整地将逻辑交给Kotlin处理，Flutter仅控制启动/停止。如果需要添加更多方法（如配置参数）或iOS stub，请反馈！