import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:memento_widgets/memento_widgets.dart';

class WidgetsConfigScreen extends StatefulWidget {
  const WidgetsConfigScreen({super.key});

  @override
  State<WidgetsConfigScreen> createState() => _WidgetsConfigScreenState();
}

class _WidgetsConfigScreenState extends State<WidgetsConfigScreen> {
  final MyWidgetManager _widgetManager = MyWidgetManager();
  StreamSubscription<Uri?>? _widgetClickSubscription;
  String _statusMessage = '准备就绪';
  String _textValue = '你好,Memento!';

  @override
  void initState() {
    super.initState();
    _widgetManager.init(null);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetClick,
    );
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  void _handleWidgetClick(Uri? uri) {
    if (!mounted || uri == null) {
      return;
    }
    setState(() {
      _statusMessage = '小组件点击: ${uri.toString()}';
    });
  }

  Future<void> _updateTextWidget() async {
    setState(() {
      _statusMessage = '更新文本小组件...';
    });

    try {
      final saved = await _widgetManager.saveString('text_key', _textValue);
      if (!saved) {
        setState(() {
          _statusMessage = '保存文本失败';
        });
        return;
      }

      // 指定文本小组件名称进行更新
      final success = await _widgetManager.updateWidget(
        widgetName: 'TextWidgetProvider',
      );

      setState(() {
        _statusMessage = success ? '文本小组件已更新!' : '更新失败';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '更新文本小组件时出错: $e';
      });
    }
  }

  Future<void> _updateImageWidget() async {
    setState(() {
      _statusMessage = '更新图像小组件...';
    });

    try {
      final success = await _widgetManager.renderFlutterWidget(
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
                const Icon(Icons.widgets, size: 80, color: Colors.white),
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

      if (!success) {
        setState(() {
          _statusMessage = '渲染图像失败';
        });
        return;
      }

      // 指定图像小组件名称进行更新
      final updated = await _widgetManager.updateWidget(
        widgetName: 'ImageWidgetProvider',
      );

      setState(() {
        _statusMessage = updated ? '图像小组件已更新!' : '更新失败';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '更新图像小组件时出错: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小组件配置'), elevation: 2),
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
                  style: TextStyle(fontSize: 16, color: Colors.blue.shade900),
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
            const SizedBox(height: 12),

            // 同时更新两个小组件按钮
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _statusMessage = '同时更新两个小组件...';
                });

                try {
                  await _widgetManager.saveString('text_key', _textValue);

                  final success = await _widgetManager.renderFlutterWidget(
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.teal],
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
                              Icons.widgets,
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

                  // 不指定 widgetName，同时更新两个
                  final updated = await _widgetManager.updateWidget();

                  setState(() {
                    _statusMessage = updated ? '所有小组件已更新!' : '更新失败';
                  });
                } catch (e) {
                  setState(() {
                    _statusMessage = '更新小组件时出错: $e';
                  });
                }
              },
              icon: const Icon(Icons.widgets),
              label: const Text('同时更新两个小组件'),
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
                        '5. 在此页面点击按钮更新小组件内容',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        '支持的文本键',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• text_key: 文本小组件内容\n'
                        '• image_key: 图像小组件内容\n'
                        '• widget_type_<id>: 小组件类型标识',
                        style: TextStyle(fontSize: 12, height: 1.5),
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
