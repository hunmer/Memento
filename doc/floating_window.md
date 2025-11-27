在 Flutter 中实现**安卓全局悬浮球（应用外部悬浮窗）**，纯 Flutter 本身无法直接做到，因为 Flutter 的 View 是嵌入在 Activity 里的，而全局悬浮窗需要使用 Android 原生的 `WindowManager` 添加 TYPE_APPLICATION_OVERLAY（Android 8.0+ 改为 TYPE_APPLICATION_OVERLAY）类型的 View，这属于系统级权限。

目前最成熟且稳定的做法是：**Flutter + 原生 Android 插件（platform channel）结合**。

### 推荐方案（2025 年最新可行方式）

#### 方案一：使用成熟插件（强烈推荐新手）
使用社区维护最活跃、最稳定的插件：

```yaml
# pubspec.yaml
dependencies:
  flutter_overlay_window: ^0.5.0   # 2025年仍在持续维护
```

GitHub: https://github.com/jianxing123/flutter_overlay_window

这个插件专为全局悬浮球/小窗聊天头设计，支持 Android 和 iOS（iOS 有限制）。

##### 使用步骤：

1. 添加权限（AndroidManifest.xml）

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Android 13+ 需要这个 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

2. 在 `AndroidManifest.xml` 的 `<application>` 里注册服务

```xml
<service
    android:name="com.pravera.flutter_overlay_window.OverlayService"
    android:foregroundServiceType="mediaProjection"
    android:exported="false" />
```

3. 实现代码
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FloatingMenuWidget(),
  ));
}

class FloatingMenuWidget extends StatefulWidget {
  const FloatingMenuWidget({Key? key}) : super(key: key});
  @override
  State<FloatingMenuWidget> createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends State<FloatingMenuWidget>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<IconData> icons = [
    Icons.home,
    Icons.favorite,
    Icons.search,
    Icons.settings,
    Icons.camera_alt,
    Icons.message,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  void toggleMenu() {
    setState(() {
      isExpanded = !isExpanded;
    });
    if (isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        // 点击空白处收起
        onTap: isExpanded
            ? () {
                toggleMenu();
              }
            : null,
        child: Container(
          color: isExpanded ? Colors.black12 : Colors.transparent,
          child: Stack(
            children: [
              // 主球（可拖动）
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: toggleMenu,
                  child: DragTargetWidget(  // 自定义可拖拽组件（下面有代码）
                    onDragEnd: () {}, // 拖完后可以保存位置
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),

              // 展开的圆形菜单
              if (isExpanded)
                ...List.generate(icons.length, (index) {
                  final double angle = index * 2.4 / icons.length; // 调整间距
                  final double radius = 100.0; // 展开半径
                  return AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      final double currentRadius = radius * _scaleAnimation.value;
                      return Transform(
                        transform: Matrix4.identity()
                          ..translate(
                            50 + currentRadius * math.cos(angle * math.pi),
                            50 + currentRadius * math.sin(angle * math.pi),
                          ),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        // 这里处理每个按钮的点击事件
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("点击了第 $index 个按钮")),
                        );
                        toggleMenu(); // 可选：点击后自动收起
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: Icon(icons[index], color: Colors.blueAccent),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// 可拖拽的小球（插件自带拖拽也很简单，这里用最简实现）
class DragTargetWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDragEnd;
  const DragTargetWidget({required this.child, this.onDragEnd, Key? key}) : super(key: key);

  @override
  State<DragTargetWidget> createState() => _DragTargetWidgetState();
}

class _DragTargetWidgetState extends State<DragTargetWidget> {
  double x = 0, y = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },
        onPanEnd: (_) => widget.onDragEnd?.call(),
        child: widget.child,
      ),
    );
  }
}