import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/habits/habits_plugin.dart';
import 'package:Memento/plugins/habits/widgets/timer_dialog.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/plugin_manager.dart';

/// 习惯插件路由处理器
class HabitsRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'habits';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理习惯计时器路由
    // 格式: /habit/timer?habitId={habitId}&action=start_timer
    // 或者深度链接格式: memento://habit/timer?habitId={habitId}&action=start_timer
    if (routeName.startsWith('/habit/timer') ||
        routeName.startsWith('/habit_timer')) {
      return _handleTimerRoute(routeName, settings.arguments);
    }

    return null;
  }

  /// 处理习惯计时器路由
  Route<dynamic> _handleTimerRoute(String routeName, Object? arguments) {
    String? habitId;
    String? action;

    // 优先从 arguments 中获取（来自小组件点击或 NFC 扫描）
    if (arguments is Map<String, String>) {
      habitId = arguments['habitId'];
      action = arguments['action'];
    } else if (arguments is Map<String, dynamic>) {
      habitId = arguments['habitId']?.toString();
      action = arguments['action']?.toString();
    }

    // 备用：从 URI 中解析
    if (habitId == null || action == null) {
      final uri = Uri.parse(routeName);
      habitId ??= uri.queryParameters['habitId'];
      action ??= uri.queryParameters['action'];
    }

    debugPrint('习惯计时器路由处理: habitId=$habitId, action=$action');

    // 如果 action=start_timer，执行启动计时器
    if (action == 'start_timer' && habitId != null) {
      return _handleStartTimer(habitId);
    }

    // 如果 action=show_dialog，显示计时器对话框
    if (action == 'show_dialog' && habitId != null) {
      return _handleShowDialog(habitId);
    }

    // 没有有效参数，正常打开习惯插件
    return createRoute(const HabitsMainView());
  }

  /// 处理启动计时器逻辑
  Route<dynamic> _handleStartTimer(String habitId) {
    debugPrint('执行启动习惯计时器: habitId=$habitId');

    // 创建一个包装器 Widget 来启动计时器并显示对话框
    return createRoute(_StartTimerScreen(habitId: habitId));
  }

  /// 处理显示计时器对话框逻辑
  Route<dynamic> _handleShowDialog(String habitId) {
    debugPrint('显示习惯计时器对话框: habitId=$habitId');

    // 创建一个包装器 Widget 来显示对话框
    return createRoute(_ShowTimerDialogScreen(habitId: habitId));
  }
}

/// 启动计时器屏幕
/// 用于处理 NFC 扫描触发的计时器启动
class _StartTimerScreen extends StatefulWidget {
  final String habitId;

  const _StartTimerScreen({required this.habitId});

  @override
  State<_StartTimerScreen> createState() => _StartTimerScreenState();
}

class _StartTimerScreenState extends State<_StartTimerScreen> {
  bool _isProcessing = true;
  String _message = '正在加载习惯信息...';
  bool _success = false;
  dynamic _habit;

  @override
  void initState() {
    super.initState();
    _loadHabitAndShowDialog();
  }

  Future<void> _loadHabitAndShowDialog() async {
    try {
      final habitsPlugin =
          PluginManager.instance.getPlugin('habits') as HabitsPlugin?;

      if (habitsPlugin == null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = '习惯插件未找到';
        });
        Toast.error('习惯插件未找到');
        return;
      }

      // 查找对应的 Habit
      final habitController = habitsPlugin.getHabitController();
      final habits = habitController.getHabits();
      final habit = habits.cast<dynamic>().firstWhere(
            (h) => h.id == widget.habitId,
            orElse: () => null,
          );

      if (habit == null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = '习惯不存在或已被删除';
        });
        Toast.error('习惯不存在');
        return;
      }

      setState(() {
        _habit = habit;
        _isProcessing = false;
        _message = '已找到习惯，正在启动计时器';
        _success = true;
      });

      // 自动弹出计时器对话框
      if (mounted) {
        await _showTimerDialog(habitsPlugin, habitController);
      }
    } catch (e) {
      debugPrint('加载习惯失败: $e');
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = '加载失败: $e';
      });
      Toast.error('加载失败: $e');
    }
  }

  Future<void> _showTimerDialog(
    HabitsPlugin plugin,
    dynamic controller,
  ) async {
    if (_habit == null) return;

    // 显示计时器对话框
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TimerDialog(
        habit: _habit,
        controller: controller,
        initialTimerData: plugin.timerController.getTimerData(
          widget.habitId,
        ),
      ),
    );

    // 对话框关闭后返回
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 启动计时器'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 状态图标
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? Colors.amber.withOpacity(0.1)
                      : (_success
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                child: _isProcessing
                    ? const Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            color: Colors.amber,
                          ),
                        ),
                      )
                    : Icon(
                        _success ? Icons.check_circle : Icons.error,
                        size: 64,
                        color: _success ? Colors.green : Colors.red,
                      ),
              ),
              const SizedBox(height: 32),

              // 习惯名称
              if (_habit != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _habit.icon != null
                          ? IconData(int.parse(_habit.icon!),
                              fontFamily: 'MaterialIcons')
                          : Icons.auto_awesome,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _habit.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 状态消息
              Text(
                _message,
                style: TextStyle(
                  fontSize: 18,
                  color: _isProcessing
                      ? Colors.grey[700]
                      : (_success ? Colors.green[700] : Colors.red[700]),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // 操作按钮
              if (!_isProcessing && !_success) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HabitsMainView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('查看习惯'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示计时器页面屏幕
/// 用于处理小组件点击触发的计时器页面显示
class _ShowTimerDialogScreen extends StatefulWidget {
  final String habitId;

  const _ShowTimerDialogScreen({required this.habitId});

  @override
  State<_ShowTimerDialogScreen> createState() =>
      _ShowTimerDialogScreenState();
}

class _ShowTimerDialogScreenState extends State<_ShowTimerDialogScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟到第一帧之后执行，避免在 initState 中访问 InheritedWidget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTimerDialog();
    });
  }

  Future<void> _showTimerDialog() async {
    try {
      final habitsPlugin =
          PluginManager.instance.getPlugin('habits') as HabitsPlugin?;

      if (habitsPlugin == null) {
        Toast.error('习惯插件未找到');
        return;
      }

      // 查找对应的 Habit
      final habitController = habitsPlugin.getHabitController();
      final habits = habitController.getHabits();
      final habit = habits.cast<dynamic>().firstWhere(
            (h) => h.id == widget.habitId,
            orElse: () => null,
          );

      if (habit == null) {
        Toast.error('习惯不存在');
        return;
      }

      // 显示计时器对话框
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => TimerDialog(
            habit: habit,
            controller: habitController,
            initialTimerData: habitsPlugin.timerController.getTimerData(
              widget.habitId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('显示计时器对话框失败: $e');
      Toast.error('加载失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 显示完整的习惯页面，但不传递 habitId，避免自动打开编辑表单
    return const HabitsMainView();
  }
}
