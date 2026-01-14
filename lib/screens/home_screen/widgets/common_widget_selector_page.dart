import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/services/toast_service.dart';
import 'package:Memento/core/services/plugin_data_selector/plugin_data_selector_service.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_layout_manager.dart';
import 'package:Memento/screens/home_screen/models/home_widget_item.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

/// 公共小组件选择页面
///
/// 用于让用户选择插件数据，然后选择一个公共小组件样式
class CommonWidgetSelectorPage extends StatefulWidget {
  /// 插件小组件定义
  final HomeWidget pluginWidget;

  /// 可选的文件夹ID，如果提供则将组件添加到该文件夹
  final String? folderId;

  /// 可选的要替换的小组件ID，如果提供则为替换模式
  final String? replaceWidgetItemId;

  const CommonWidgetSelectorPage({
    super.key,
    required this.pluginWidget,
    this.folderId,
    this.replaceWidgetItemId,
  });

  @override
  State<CommonWidgetSelectorPage> createState() =>
      _CommonWidgetSelectorPageState();
}

class _CommonWidgetSelectorPageState extends State<CommonWidgetSelectorPage>
    with TickerProviderStateMixin {
  /// Tab控制器
  late TabController _tabController;

  /// 当前选择的数据（经过 dataSelector 转换后的）
  Map<String, dynamic>? _selectedData;

  /// 原始的 SelectorResult（用于保存完整的配置信息）
  SelectorResult? _originalSelectorResult;

  /// 可用的公共小组件列表
  Map<String, Map<String, dynamic>> _availableCommonWidgets = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择公共组件样式'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 数据选择器区域
          _buildDataSelectorSection(),

          const Divider(height: 1),

          // 公共小组件预览区域 - 占据剩余空间
          Expanded(
            child: _buildCommonWidgetsSection(),
          ),

          // 底部操作按钮
          _buildActions(),
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
        mainAxisSize: MainAxisSize.min,
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
          Center(
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
          if (_selectedData != null) ...[
            const SizedBox(height: 12),
            Container(
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
                        _originalSelectorResult = null;
                        _availableCommonWidgets = {};
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
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
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
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
            child: Column(
              children: [
                // 顶部水平 TabBar
                ExtendedTabBar(
                  controller: _tabController,
                  scrollDirection: Axis.horizontal,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: _availableCommonWidgets.keys.map((widgetId) {
                    final metadata = CommonWidgetsRegistry.getMetadata(
                      CommonWidgetId.values.firstWhere(
                        (e) => e.name == widgetId,
                      ),
                    );
                    return Tab(
                      text: metadata.name,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // 下方 TabBarView 展示预览
                Expanded(
                  child: ExtendedTabBarView(
                    controller: _tabController,
                    scrollDirection: Axis.horizontal,
                    children: _availableCommonWidgets.keys.map((widgetId) {
                      final metadata = CommonWidgetsRegistry.getMetadata(
                        CommonWidgetId.values.firstWhere(
                          (e) => e.name == widgetId,
                        ),
                      );
                      return _buildCommonWidgetPreview(metadata, widgetId);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建公共小组件预览
  Widget _buildCommonWidgetPreview(
    CommonWidgetMetadata metadata,
    String widgetId,
  ) {
    final props = _availableCommonWidgets[widgetId]!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CommonWidgetBuilder.build(
          context,
          CommonWidgetId.values.firstWhere((e) => e.name == widgetId),
          props,
          metadata.defaultSize,
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
            onPressed: _availableCommonWidgets.isNotEmpty ? _confirmSelection : null,
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 数据选择完成回调
  void _onDataSelected(SelectorResult? result) {
    if (result == null) return;

    // 保存原始的 SelectorResult
    _originalSelectorResult = result;

    // 转换数据格式
    Map<String, dynamic> data;
    if (result.data is Map) {
      // 安全地转换 Map，确保键为 String 类型
      final rawMap = result.data as Map;
      data = {};
      rawMap.forEach((key, value) {
        data[key.toString()] = value;
      });
    } else if (widget.pluginWidget.dataSelector != null && result.data is List) {
      data = widget.pluginWidget.dataSelector!(result.data as List<dynamic>);
    } else {
      data = {'data': result.data};
    }

    // 调用 commonWidgetsProvider 获取可用组件
    Map<String, Map<String, dynamic>> availableWidgets = {};
    if (widget.pluginWidget.commonWidgetsProvider != null) {
      availableWidgets = widget.pluginWidget.commonWidgetsProvider!(data);
    }

    // 更新 TabController 长度
    if (_tabController.length != availableWidgets.length) {
      _tabController.dispose();
      _tabController = TabController(
        length: availableWidgets.length,
        vsync: this,
      );
    }

    setState(() {
      _selectedData = data;
      _availableCommonWidgets = availableWidgets;
      // 自动选中第一个组件
      if (availableWidgets.isNotEmpty) {
        _tabController.animateTo(0);
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
      debugPrint('[CommonWidgetSelectorPage] 数据选择失败: $e');
    }
  }

  /// 确认选择
  void _confirmSelection() {
    if (_selectedData == null || _availableCommonWidgets.isEmpty || _originalSelectorResult == null) return;

    // 从当前激活的 tab 获取选中的 widgetId
    final index = _tabController.index;
    final widgetId = _availableCommonWidgets.keys.elementAt(index);

    final layoutManager = HomeLayoutManager();

    // 使用原始 SelectorResult 的 toMap() 来保存完整的配置信息
    // 这样可以保留 plugin、selector、path 等信息，确保导航功能正常
    final selectorConfig = SelectorWidgetConfig(
      selectedData: _originalSelectorResult!.toMap(),
      lastUpdated: DateTime.now(),
      commonWidgetId: widgetId,
      commonWidgetProps: _availableCommonWidgets[widgetId],
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
