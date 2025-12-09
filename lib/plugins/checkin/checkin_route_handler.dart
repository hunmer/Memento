import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/checkin/checkin_plugin.dart';
import 'package:Memento/plugins/checkin/screens/checkin_item_selector_screen.dart';
import 'package:Memento/plugins/checkin/models/checkin_item.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 打卡插件路由处理器
class CheckinRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'checkin';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理打卡小组件配置路由
    // 格式: /checkin_item_selector?widgetId={widgetId}
    // 或者 widgetId 通过 settings.arguments 传递
    if (routeName.startsWith('/checkin_item_selector')) {
      return _handleItemSelectorRoute(routeName, settings.arguments);
    }

    // 处理打卡小组件点击路由（已配置状态）
    // 格式: /checkin_item?itemId={itemId}&date={date}
    // 或者深度链接格式: /checkin/item?itemId={itemId}&action=checkin
    if (routeName.startsWith('/checkin_item') ||
        routeName.startsWith('/checkin/item')) {
      return _handleItemClickRoute(routeName, settings.arguments);
    }

    return null;
  }

  /// 处理打卡项选择器路由
  Route<dynamic> _handleItemSelectorRoute(String routeName, Object? arguments) {
    int? widgetId;

    // 优先从 arguments 中获取 widgetId（来自 main.dart 的路由处理）
    if (arguments is Map<String, dynamic>) {
      final widgetIdValue = arguments['widgetId'];
      if (widgetIdValue is int) {
        widgetId = widgetIdValue;
      } else if (widgetIdValue is String) {
        widgetId = int.tryParse(widgetIdValue);
      }
    } else if (arguments is Map<String, String>) {
      final widgetIdStr = arguments['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    // 备用：从 URI 中解析 widgetId
    if (widgetId == null) {
      final uri = Uri.parse(routeName);
      final widgetIdStr = uri.queryParameters['widgetId'];
      widgetId = widgetIdStr != null ? int.tryParse(widgetIdStr) : null;
    }

    debugPrint('打卡小组件配置路由: widgetId=$widgetId');
    return createRoute(CheckinItemSelectorScreen(widgetId: widgetId));
  }

  /// 处理打卡项点击路由
  Route<dynamic> _handleItemClickRoute(String routeName, Object? arguments) {
    String? itemId;
    String? date;
    String? action;

    // 优先从 arguments 中获取（来自小组件点击或 NFC 扫描）
    if (arguments is Map<String, String>) {
      itemId = arguments['itemId'];
      date = arguments['date'];
      action = arguments['action'];
    } else if (arguments is Map<String, dynamic>) {
      itemId = arguments['itemId']?.toString();
      date = arguments['date']?.toString();
      action = arguments['action']?.toString();
    }

    // 备用：从 URI 中解析
    if (itemId == null || action == null) {
      final uri = Uri.parse(routeName);
      itemId ??= uri.queryParameters['itemId'];
      date ??= uri.queryParameters['date'];
      action ??= uri.queryParameters['action'];
    }

    debugPrint('打卡路由处理: itemId=$itemId, date=$date, action=$action');

    // 如果 action=checkin，执行自动签到
    if (action == 'checkin' && itemId != null) {
      return _handleAutoCheckin(itemId);
    }

    // 如果有 itemId，打开打卡插件并自动展示打卡记录对话框
    if (itemId != null) {
      return createRoute(CheckinMainView(itemId: itemId, targetDate: date));
    }

    // 没有 itemId，正常打开打卡插件
    return createRoute(const CheckinMainView());
  }

  /// 处理自动签到逻辑
  Route<dynamic> _handleAutoCheckin(String itemId) {
    debugPrint('执行自动签到: itemId=$itemId');

    // 创建一个包装器 Widget 来执行签到并显示结果
    return createRoute(_AutoCheckinScreen(itemId: itemId));
  }
}

/// 自动签到屏幕
/// 用于处理 NFC 扫描触发的自动签到
class _AutoCheckinScreen extends StatefulWidget {
  final String itemId;

  const _AutoCheckinScreen({required this.itemId});

  @override
  State<_AutoCheckinScreen> createState() => _AutoCheckinScreenState();
}

class _AutoCheckinScreenState extends State<_AutoCheckinScreen> {
  bool _isProcessing = true;
  String _message = '正在签到...';
  bool _success = false;
  CheckinItem? _checkinItem;

  @override
  void initState() {
    super.initState();
    _performCheckin();
  }

  Future<void> _performCheckin() async {
    try {
      final plugin = CheckinPlugin.instance;
      final items = plugin.checkinItems;

      // 查找签到项目
      final item = items.firstWhere(
        (item) => item.id == widget.itemId,
        orElse: () => throw Exception('签到项目不存在'),
      );

      setState(() {
        _checkinItem = item;
      });

      // 检查今天是否已签到
      if (item.isCheckedToday()) {
        setState(() {
          _isProcessing = false;
          _success = true;
          _message = '今天已经签到过了！';
        });
        Toast.info('${item.name}: 今天已经签到过了');
        return;
      }

      // 执行签到
      final now = DateTime.now();
      final record = CheckinRecord(
        startTime: now,
        endTime: now,
        checkinTime: now,
      );

      await item.addCheckinRecord(record);
      await plugin.triggerSave();

      setState(() {
        _isProcessing = false;
        _success = true;
        _message = '签到成功！';
      });

      Toast.success('${item.name}: 签到成功！连续 ${item.getConsecutiveDays()} 天');
    } catch (e) {
      debugPrint('自动签到失败: $e');
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = '签到失败: $e';
      });
      Toast.error('签到失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 签到'),
        backgroundColor: Colors.teal,
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
                      ? Colors.teal.withOpacity(0.1)
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
                            color: Colors.teal,
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

              // 签到项目名称
              if (_checkinItem != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _checkinItem!.icon,
                      color: _checkinItem!.color,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _checkinItem!.name,
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

              // 连续签到天数
              if (!_isProcessing && _success && _checkinItem != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '连续签到 ${_checkinItem!.getConsecutiveDays()} 天',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // 操作按钮
              if (!_isProcessing) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => CheckinMainView(
                          itemId: widget.itemId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.checklist),
                  label: const Text('查看签到记录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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
