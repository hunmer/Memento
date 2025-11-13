import 'package:flutter/material.dart';
import '../managers/home_widget_registry.dart';
import '../managers/home_layout_manager.dart';
import '../widgets/home_widget.dart';
import '../models/home_widget_item.dart';
import '../models/home_widget_size.dart';

/// 添加小组件对话框
class AddWidgetDialog extends StatefulWidget {
  const AddWidgetDialog({Key? key}) : super(key: key);

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<HomeWidget>> _widgetsByCategory = {};
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();

    // 获取所有小组件并按分类分组
    _widgetsByCategory = HomeWidgetRegistry().getWidgetsByCategory();
    _categories = _widgetsByCategory.keys.toList()..sort();

    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // 标题栏
            AppBar(
              title: const Text('添加组件'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              bottom: _categories.isNotEmpty
                  ? TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: _categories
                          .map((category) => Tab(text: category))
                          .toList(),
                    )
                  : null,
            ),

            // 小组件列表
            Expanded(
              child: _categories.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: _categories
                          .map((category) =>
                              _buildCategoryView(_widgetsByCategory[category]!))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分类视图
  Widget _buildCategoryView(List<HomeWidget> widgets) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => _buildWidgetPreviewCard(widgets[index]),
    );
  }

  /// 构建小组件预览卡片
  Widget _buildWidgetPreviewCard(HomeWidget widget) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addWidget(widget),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图标和标题
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.color?.withOpacity(0.1),
              child: Column(
                children: [
                  Icon(
                    widget.icon,
                    size: 48,
                    color: widget.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 描述
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.description != null)
                      Text(
                        widget.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // 尺寸标签
                    Wrap(
                      spacing: 4,
                      children: widget.supportedSizes
                          .map((size) => Chip(
                                label: Text(
                                  '${size.width}x${size.height}',
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加小组件
  void _addWidget(HomeWidget widget) {
    final layoutManager = HomeLayoutManager();

    // 创建小组件实例
    final widgetItem = HomeWidgetItem(
      id: layoutManager.generateId(),
      widgetId: widget.id,
      size: widget.defaultSize,
    );

    // 添加到布局
    layoutManager.addItem(widgetItem);

    // 关闭对话框
    Navigator.of(context).pop();

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${widget.name}')),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            '没有可用的小组件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}
