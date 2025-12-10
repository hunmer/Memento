import 'package:flutter/material.dart';
import 'package:Memento/core/routing/plugin_route_handler.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/dialogs/add_usage_record_dialog.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/models/usage_record.dart';
import 'package:Memento/core/services/toast_service.dart';

/// 物品插件路由处理器
class GoodsRouteHandler extends PluginRouteHandler {
  @override
  String get pluginId => 'goods';

  @override
  Route<dynamic>? handleRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // 处理物品使用记录路由
    // 格式: /goods/usage?itemId={itemId}&action=add_usage
    // 或者深度链接格式: memento://goods/usage?itemId={itemId}&action=add_usage
    if (routeName.startsWith('/goods/usage') ||
        routeName.startsWith('/goods_usage')) {
      return _handleUsageRoute(routeName, settings.arguments);
    }

    return null;
  }

  /// 处理物品使用记录路由
  Route<dynamic> _handleUsageRoute(String routeName, Object? arguments) {
    String? itemId;
    String? action;

    // 优先从 arguments 中获取（来自小组件点击或 NFC 扫描）
    if (arguments is Map<String, String>) {
      itemId = arguments['itemId'];
      action = arguments['action'];
    } else if (arguments is Map<String, dynamic>) {
      itemId = arguments['itemId']?.toString();
      action = arguments['action']?.toString();
    }

    // 备用：从 URI 中解析
    if (itemId == null || action == null) {
      final uri = Uri.parse(routeName);
      itemId ??= uri.queryParameters['itemId'];
      action ??= uri.queryParameters['action'];
    }

    debugPrint('物品使用记录路由处理: itemId=$itemId, action=$action');

    // 如果 action=add_usage，执行添加使用记录
    if (action == 'add_usage' && itemId != null) {
      return _handleAddUsageRecord(itemId);
    }

    // 没有有效参数，正常打开物品插件
    return createRoute(const GoodsMainView());
  }

  /// 处理添加使用记录逻辑
  Route<dynamic> _handleAddUsageRecord(String itemId) {
    debugPrint('执行添加物品使用记录: itemId=$itemId');

    // 创建一个包装器 Widget 来添加使用记录并显示结果
    return createRoute(_AddUsageRecordScreen(itemId: itemId));
  }
}

/// 添加使用记录屏幕
/// 用于处理 NFC 扫描触发的添加使用记录
class _AddUsageRecordScreen extends StatefulWidget {
  final String itemId;

  const _AddUsageRecordScreen({required this.itemId});

  @override
  State<_AddUsageRecordScreen> createState() => _AddUsageRecordScreenState();
}

class _AddUsageRecordScreenState extends State<_AddUsageRecordScreen> {
  bool _isProcessing = true;
  String _message = '正在加载物品信息...';
  bool _success = false;
  GoodsItem? _goodsItem;
  String? _warehouseId;

  @override
  void initState() {
    super.initState();
    _loadItemAndShowDialog();
  }

  Future<void> _loadItemAndShowDialog() async {
    try {
      final plugin = GoodsPlugin.instance;

      // 查找物品
      final result = plugin.findGoodsItemById(widget.itemId);

      if (result == null) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _message = '物品不存在或已被删除';
        });
        Toast.error('物品不存在');
        return;
      }

      setState(() {
        _goodsItem = result.item;
        _warehouseId = result.warehouseId;
        _isProcessing = false;
        _message = '已找到物品，请填写使用记录';
      });

      // 自动弹出添加使用记录对话框
      if (mounted) {
        _showAddUsageRecordDialog();
      }
    } catch (e) {
      debugPrint('加载物品失败: $e');
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = '加载失败: $e';
      });
      Toast.error('加载失败: $e');
    }
  }

  Future<void> _showAddUsageRecordDialog() async {
    if (_goodsItem == null || _warehouseId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddUsageRecordDialog(),
    );

    if (result != null) {
      await _saveUsageRecord(result);
    } else {
      // 用户取消了对话框
      setState(() {
        _message = '已取消添加使用记录';
      });
    }
  }

  Future<void> _saveUsageRecord(Map<String, dynamic> recordData) async {
    if (_goodsItem == null || _warehouseId == null) return;

    setState(() {
      _isProcessing = true;
      _message = '正在保存使用记录...';
    });

    try {
      final plugin = GoodsPlugin.instance;

      // 创建使用记录
      final usageRecord = UsageRecord(
        date: recordData['date'] as DateTime,
        duration: recordData['duration'] as int?,
        location: recordData['location'] as String?,
        note: recordData['note'] as String?,
      );

      // 更新物品的使用记录
      final updatedItem = _goodsItem!.addUsageRecord(
        usageRecord.date,
        note: usageRecord.note,
        duration: usageRecord.duration,
        location: usageRecord.location,
      );

      // 保存到存储
      await plugin.saveGoodsItem(_warehouseId!, updatedItem);

      setState(() {
        _isProcessing = false;
        _success = true;
        _message = '使用记录已添加！';
        _goodsItem = updatedItem;
      });

      Toast.success('「${_goodsItem!.title}」使用记录已添加');
    } catch (e) {
      debugPrint('保存使用记录失败: $e');
      setState(() {
        _isProcessing = false;
        _success = false;
        _message = '保存失败: $e';
      });
      Toast.error('保存失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 添加使用记录'),
        backgroundColor: Colors.orange,
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
                      ? Colors.orange.withOpacity(0.1)
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
                            color: Colors.orange,
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

              // 物品名称
              if (_goodsItem != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _goodsItem!.icon ?? Icons.inventory_2,
                      color: _goodsItem!.iconColor ?? Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _goodsItem!.title,
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

              // 最近使用记录
              if (!_isProcessing && _success && _goodsItem != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '共 ${_goodsItem!.usageRecords.length} 条使用记录',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // 操作按钮
              if (!_isProcessing) ...[
                if (!_success && _goodsItem != null) ...[
                  ElevatedButton.icon(
                    onPressed: _showAddUsageRecordDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('重新添加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const GoodsMainView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory),
                  label: const Text('查看物品'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success ? Colors.orange : Colors.grey,
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
