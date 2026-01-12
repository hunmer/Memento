import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

/// 公共小组件选择对话框
///
/// 用于让用户选择插件数据，然后选择一个公共小组件样式
class CommonWidgetSelectorDialog extends StatefulWidget {
  /// 插件小组件定义
  final HomeWidget pluginWidget;

  /// 可选的文件夹ID，如果提供则将组件添加到该文件夹
  final String? folderId;

  /// 可选的要替换的小组件ID，如果提供则为替换模式
  final String? replaceWidgetItemId;

  const CommonWidgetSelectorDialog({
    super.key,
    required this.pluginWidget,
    this.folderId,
    this.replaceWidgetItemId,
  });

  @override
  State<CommonWidgetSelectorDialog> createState() =>
      _CommonWidgetSelectorDialogState();
}

class _CommonWidgetSelectorDialogState extends State<CommonWidgetSelectorDialog> {
  /// 当前选择的数据
  Map<String, dynamic>? _selectedData;

  /// 当前选中的公共小组件
  String? _selectedCommonWidgetId;

  /// 可用的公共小组件列表
  Map<String, Map<String, dynamic>> _availableCommonWidgets = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 650,
        child: Column(
          children: [
            // 顶部标题
            _buildHeader(),

            // 数据选择器区域
            Expanded(
              flex: 1,
              child: _buildDataSelectorSection(),
            ),

            const Divider(height: 1),

            // 公共小组件预览区域
            Expanded(
              flex: 2,
              child: _buildCommonWidgetsSection(),
            ),

            // 底部操作按钮
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// 构建顶部标题
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '选择公共组件样式',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '先选择数据，然后选择一个公共组件样式',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建数据选择器区域
  Widget _buildDataSelectorSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedData != null ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '1',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '选择数据',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _selectedData == null ? _openDataSelector : null,
                icon: const Icon(Icons.touch_app),
                label: const Text('点击选择数据'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          if (_selectedData != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已选择数据: ${_selectedData!['title'] ?? _selectedData!['id'] ?? '未知'}',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                  IconButton(
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      setState(() {
                        _selectedData = null;
                        _selectedCommonWidgetId = null;
                        _availableCommonWidgets = {};
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建公共小组件区域
  Widget _buildCommonWidgetsSection() {
    if (_selectedData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_upward, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '请先在上方选择数据',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_availableCommonWidgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              '当前数据没有可用的公共组件',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedCommonWidgetId != null ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '选择组件样式 (${_availableCommonWidgets.length}个可用)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _availableCommonWidgets.length,
              itemBuilder: (context, index) {
                final widgetId = _availableCommonWidgets.keys.elementAt(index);
                final metadata = CommonWidgetsRegistry.getMetadata(
                  CommonWidgetId.values.firstWhere((e) => e.name == widgetId),
                );
                final isSelected = _selectedCommonWidgetId == widgetId;

                return _buildCommonWidgetCard(metadata, widgetId, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建公共小组件卡片
  Widget _buildCommonWidgetCard(
    CommonWidgetMetadata metadata,
    String widgetId,
    bool isSelected,
  ) {
    final props = _availableCommonWidgets[widgetId]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCommonWidgetId = widgetId;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.white,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // 预览小组件
            Expanded(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  child: CommonWidgetBuilder.build(
                    context,
                    CommonWidgetId.values.firstWhere((e) => e.name == widgetId),
                    props,
                    metadata.defaultSize,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 名称
            Text(
              metadata.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _selectedCommonWidgetId != null ? _confirmSelection : null,
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 数据选择完成回调
  void _onDataSelected(SelectorResult? result) {
    if (result == null) return;

    // 转换数据格式
    Map<String, dynamic> data;
    if (result.data is Map) {
      data = (result.data as Map).cast<String, dynamic>();
    } else if (widget.pluginWidget.dataSelector != null && result.data is List) {
      data = widget.pluginWidget.dataSelector!(result.data as List<dynamic>);
    } else {
      data = {'data': result.data};
    }

    setState(() {
      _selectedData = data;
      _selectedCommonWidgetId = null;

      // 调用 commonWidgetsProvider 获取可用组件
      if (widget.pluginWidget.commonWidgetsProvider != null) {
        _availableCommonWidgets =
            widget.pluginWidget.commonWidgetsProvider!(data);
      }
    });
  }

  /// 打开数据选择器
  Future<void> _openDataSelector() async {
    final selectorId = widget.pluginWidget.selectorId;
    if (selectorId == null) return;

    try {
      final result = await pluginDataSelectorService.showSelector(
        context,
        selectorId,
      );
      _onDataSelected(result);
    } catch (e) {
      debugPrint('[CommonWidgetSelectorDialog] 数据选择失败: $e');
    }
  }

  /// 确认选择
  void _confirmSelection() {
    if (_selectedCommonWidgetId == null || _selectedData == null) return;

    final layoutManager = HomeLayoutManager();

    // 生成 selectorWidgetConfig
    final selectorConfig = SelectorWidgetConfig(
      selectedData: {'data': _selectedData},
      lastUpdated: DateTime.now(),
      commonWidgetId: _selectedCommonWidgetId,
      commonWidgetProps: _availableCommonWidgets[_selectedCommonWidgetId],
    );

    // 创建小组件实例
    final widgetItem = HomeWidgetItem(
      id: widget.replaceWidgetItemId ?? layoutManager.generateId(),
      widgetId: widget.pluginWidget.id,
      size: widget.pluginWidget.defaultSize,
      config: {
        'selectorWidgetConfig': selectorConfig.toJson(),
      },
    );

    // 替换或添加
    if (widget.replaceWidgetItemId != null) {
      layoutManager.updateItem(widget.replaceWidgetItemId!, widgetItem);
    } else if (widget.folderId != null) {
      layoutManager.addItemToFolder(widgetItem, widget.folderId!);
    } else {
      layoutManager.addItem(widgetItem);
    }

    layoutManager.saveLayout();
    Navigator.of(context).pop();

    final action = widget.replaceWidgetItemId != null ? '替换' : '添加';
    Toast.success('已$action小组件');
  }
}
