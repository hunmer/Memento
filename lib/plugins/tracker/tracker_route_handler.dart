import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/tracker/tracker_plugin.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/tracker/models/goal.dart';
import 'package:Memento/plugins/tracker/models/record.dart';
import 'package:uuid/uuid.dart';

/// 目标追踪插件路由处理器
class TrackerRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'tracker';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理目标追踪进度路由
    // 格式: /tracker/progress?goalId={goalId}&value={value}
    // 或者深度链接格式: memento://tracker/progress?goalId={goalId}&value={value}
    if (routeName.startsWith('/tracker/progress') ||
        routeName.startsWith('/tracker_progress')) {
      return _handleProgressRoute(routeName, settings.arguments);
    }

    return null;
  }

  /// 处理目标追踪进度路由
  Route<dynamic> _handleProgressRoute(String routeName, Object? arguments) {
    String? goalId;
    double? value;

    // 优先从 arguments 中获取（来自小组件点击或 NFC 扫描）
    if (arguments is Map<String, String>) {
      goalId = arguments['goalId'];
      final valueStr = arguments['value'];
      value = valueStr != null ? double.tryParse(valueStr) : null;
    } else if (arguments is Map<String, dynamic>) {
      goalId = arguments['goalId']?.toString();
      final valueRaw = arguments['value'];
      if (valueRaw is double) {
        value = valueRaw;
      } else if (valueRaw is int) {
        value = valueRaw.toDouble();
      } else if (valueRaw is String) {
        value = double.tryParse(valueRaw);
      }
    }

    // 备用：从 URI 中解析
    if (goalId == null || value == null) {
      final uri = Uri.parse(routeName);
      goalId ??= uri.queryParameters['goalId'];
      final valueStr = uri.queryParameters['value'];
      value ??= valueStr != null ? double.tryParse(valueStr) : null;
    }

    debugPrint('目标追踪进度路由处理: goalId=$goalId, value=$value');

    // 如果有有效的 goalId 和 value，执行添加记录
    if (goalId != null && value != null && value > 0) {
      return _handleAddProgress(goalId, value);
    }

    // 没有有效参数，正常打开目标追踪插件
    return createRoute(const TrackerMainView());
  }

  /// 处理添加进度逻辑
  Route<dynamic> _handleAddProgress(String goalId, double value) {
    debugPrint('执行添加目标进度: goalId=$goalId, value=$value');

    // 创建一个包装器 Widget 来添加记录并显示结果
    return createRoute(_AddProgressScreen(goalId: goalId, value: value));
  }
}

/// 添加进度屏幕
/// 用于处理 NFC 扫描触发的进度增加
class _AddProgressScreen extends StatefulWidget {
  final String goalId;
  final double value;

  const _AddProgressScreen({
    required this.goalId,
    required this.value,
  });

  @override
  State<_AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<_AddProgressScreen> {
  bool _isProcessing = true;
  String _message = '正在加载目标信息...';
  bool _success = false;
  Goal? _goal;

  @override
  void initState() {
    super.initState();
    _addProgressAndShowResult();
  }

  Future<void> _addProgressAndShowResult() async {
    try {
      final trackerPlugin =
          PluginManager.instance.getPlugin('tracker') as TrackerPlugin?;

      if (trackerPlugin == null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = '目标追踪插件未找到';
        });
        Toast.error('目标追踪插件未找到');
        return;
      }

      // 查找对应的 Goal
      final controller = trackerPlugin.controller;
      final goals = await controller.getAllGoals();
      final goal = goals.firstWhere(
        (g) => g.id == widget.goalId,
        orElse: () => throw ArgumentError('目标不存在'),
      );

      setState(() {
        _goal = goal;
        _message = '正在添加进度...';
      });

      // 创建完成记录
      final record = Record(
        id: const Uuid().v4(),
        goalId: widget.goalId,
        value: widget.value,
        note: 'NFC 快速记录',
        recordedAt: DateTime.now(),
      );

      // 添加记录
      await controller.addRecord(record, goal);

      setState(() {
        _isProcessing = false;
        _success = true;
        _message = '进度添加成功！';
      });

      Toast.success('已为「${goal.name}」增加 ${widget.value}');

      // 3秒后自动返回
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      debugPrint('添加进度失败: $e');
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = '添加失败: $e';
      });
      Toast.error('添加失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 添加进度'),
        backgroundColor: Colors.red,
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
                      ? Colors.red.withOpacity(0.1)
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
                            color: Colors.red,
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

              // 目标名称和增加的值
              if (_goal != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.track_changes,
                      color: Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _goal!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ ${widget.value} ${_goal!.unitType}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前进度: ${_goal!.currentValue} / ${_goal!.targetValue} ${_goal!.unitType}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              const SizedBox(height: 24),

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
              if (!_isProcessing) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const TrackerMainView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.track_changes),
                  label: const Text('查看目标'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_success)
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
