import 'package:flutter/material.dart';
import 'package:memento_widgets/memento_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final manager = MyWidgetManager(); // 获取单例实例
  await manager.init(null); // Android 不需要 App Group ID
  runApp(MyApp(manager: manager));
}

class MyApp extends StatelessWidget {
  final MyWidgetManager manager;

  const MyApp({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memento Widgets Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: WidgetTestPage(manager: manager),
    );
  }
}

class WidgetTestPage extends StatefulWidget {
  final MyWidgetManager manager;

  const WidgetTestPage({super.key, required this.manager});

  @override
  State<WidgetTestPage> createState() => _WidgetTestPageState();
}

class _WidgetTestPageState extends State<WidgetTestPage> {
  String _textValue = '默认文本';
  String _statusMessage = '准备就绪';

  @override
  void initState() {
    super.initState();
    // 注册小组件点击回调
    widget.manager.registerInteractivityCallback((Uri? uri) {
      if (uri != null) {
        setState(() {
          _statusMessage = '小组件点击: $uri';
        });
      }
    });
  }

  Future<void> _updateTextWidget() async {
    setState(() {
      _statusMessage = '更新文本小组件...';
    });

    // 保存新的文本数据
    await widget.manager.saveString('text_key', _textValue);

    // 更新小组件
    final success = await widget.manager.updateWidget();

    setState(() {
      _statusMessage = success ? '文本小组件已更新!' : '更新失败';
    });
  }

  Future<void> _updateImageWidget() async {
    setState(() {
      _statusMessage = '更新图像小组件...';
    });

    // 渲染 Flutter UI 为图像
    final success = await widget.manager.renderFlutterWidget(
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.flutter_dash,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _textValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      key: 'image_key',
      logicalSize: const Size(300, 300),
      pixelRatio: 2.0,
    );

    if (success) {
      // 更新小组件
      await widget.manager.updateWidget();
    }

    setState(() {
      _statusMessage = success ? '图像小组件已更新!' : '更新失败';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('小组件测试'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态消息
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 文本输入
            TextField(
              decoration: const InputDecoration(
                labelText: '输入文本',
                border: OutlineInputBorder(),
                hintText: '输入要显示在小组件上的文本',
              ),
              onChanged: (value) {
                setState(() {
                  _textValue = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 更新文本小组件按钮
            ElevatedButton.icon(
              onPressed: _updateTextWidget,
              icon: const Icon(Icons.text_fields),
              label: const Text('更新文本小组件'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // 更新图像小组件按钮
            ElevatedButton.icon(
              onPressed: _updateImageWidget,
              icon: const Icon(Icons.image),
              label: const Text('更新图像小组件'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // 使用说明
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '使用说明',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. 在桌面长按空白区域\n'
                        '2. 选择"小组件"\n'
                        '3. 找到"文本小组件"或"图像小组件"\n'
                        '4. 拖动到桌面\n'
                        '5. 在此应用中点击按钮更新小组件内容',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

