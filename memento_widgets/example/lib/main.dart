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
    // 注册小组件点击回调
    widget.manager.registerInteractivityCallback((Uri? uri) {
      if (uri != null) {
        setState(() {
          _statusMessage = '小组件点击: $uri';
        });
        
        // 检查是否是习惯计时器对话框请求
        if (uri.path == '/plugin/habits/timer' && uri.host == 'memento') {
          final habitId = uri.queryParameters['habitId'];
          if (habitId != null) {
            // 显示计时器对话框
            showTimerDialog(context, habitId);
          }
        }
      }
    });
  }

  /// 显示习惯计时器对话框
  void showTimerDialog(BuildContext context, String habitId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: TimerDialogWidget(
            habitId: habitId,
            onClose: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
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



/// 计时器对话框组件
class TimerDialogWidget extends StatefulWidget {
  final String habitId;
  final VoidCallback onClose;

  const TimerDialogWidget({
    super.key,
    required this.habitId,
    required this.onClose,
  });

  @override
  State<TimerDialogWidget> createState() => _TimerDialogWidgetState();
}

class _TimerDialogWidgetState extends State<TimerDialogWidget> {
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  bool _isCountdown = true;
  int _durationMinutes = 25;

  @override
  void initState() {
    super.initState();
    // TODO: 从共享Preferences读取计时器状态
    // 这里可以添加从Android端读取状态的逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 对话框标题
          Row(
            children: [
              const Icon(
                Icons.timer,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '习惯计时器',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 计时显示
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatTime(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 播放/暂停按钮
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? '暂停' : '开始'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning
                      ? Colors.orange.shade600
                      : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 模式切换按钮
              OutlinedButton.icon(
                onPressed: _switchMode,
                icon: const Icon(Icons.swap_horiz),
                label: Text(_isCountdown ? '正计时' : '倒计时'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 完成按钮
          if (_elapsedSeconds > 0)
            ElevatedButton.icon(
              onPressed: _completeTimer,
              icon: const Icon(Icons.check_circle),
              label: const Text('完成计时'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime() {
    final displaySeconds = _isCountdown
        ? (_durationMinutes * 60 - _elapsedSeconds).clamp(0, double.infinity).toInt()
        : _elapsedSeconds;

    final hours = displaySeconds ~/ 3600;
    final minutes = (displaySeconds % 3600) ~/ 60;
    final seconds = displaySeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 切换播放/暂停状态
  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
    });
    
    // TODO: 通过MethodChannel通知Android端更新状态
    // 例如：_updateTimerState();
  }

  /// 切换计时模式
  void _switchMode() {
    setState(() {
      _isCountdown = !_isCountdown;
    });
  }

  /// 完成计时
  void _completeTimer() {
    // TODO: 保存计时数据到共享Preferences
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('计时完成！总用时: ${_formatTime()}'),
        backgroundColor: Colors.green,
      ),
    );
    
    // 关闭对话框
    widget.onClose();
  }
}
