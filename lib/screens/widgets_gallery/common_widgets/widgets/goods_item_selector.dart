/// 物品选择器公共小组件
///
/// 支持单个或多个物品展示，响应不同尺寸
library;

import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 物品选择器公共小组件
///
/// 支持通过 props 配置单个或多个物品
/// 支持点击导航到物品详情
class GoodsItemSelectorWidget extends StatefulWidget {
  /// 物品 ID 列表
  final List<String> itemIds;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 自定义标题（可选）
  final String? title;

  /// 是否显示列表模式（默认为 false，显示网格模式）
  final bool showListMode;

  /// 仓库 ID（用于导航）
  final List<String>? warehouseIds;

  const GoodsItemSelectorWidget({
    super.key,
    required this.itemIds,
    required this.size,
    this.title,
    this.showListMode = false,
    this.warehouseIds,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory GoodsItemSelectorWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemIds =
        (props['itemIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final warehouseIds =
        (props['warehouseIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
    final showListMode = props['showListMode'] as bool? ?? false;

    return GoodsItemSelectorWidget(
      itemIds: itemIds,
      size: size,
      title: props['title'] as String?,
      showListMode: showListMode,
      warehouseIds: warehouseIds,
    );
  }

  @override
  State<GoodsItemSelectorWidget> createState() =>
      _GoodsItemSelectorWidgetState();
}

class _GoodsItemSelectorWidgetState extends State<GoodsItemSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 获取插件
    final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
    if (plugin == null) {
      return _buildErrorWidget(context, '插件不可用');
    }

    // 获取物品数据
    final List<GoodsItemData> items = [];

    if (widget.itemIds.isNotEmpty) {
      // 模式1：指定了具体的物品ID
      for (var i = 0; i < widget.itemIds.length; i++) {
        final itemId = widget.itemIds[i];
        final findResult = plugin.findGoodsItemById(itemId);

        if (findResult != null) {
          items.add(
            GoodsItemData(
              item: findResult.item,
              warehouseId: findResult.warehouseId,
            ),
          );
        }
      }
    } else if (widget.warehouseIds != null && widget.warehouseIds!.isNotEmpty) {
      // 模式2：未指定物品ID，但有仓库ID，显示仓库中的所有物品
      for (final warehouseId in widget.warehouseIds!) {
        final warehouse = plugin.getWarehouse(warehouseId);
        if (warehouse != null) {
          // 递归获取仓库中的所有物品（包括子物品）
          _collectAllItems(warehouse.items, warehouse.id, items);
        }
      }
    }

    if (items.isEmpty) {
      return _buildErrorWidget(context, '未找到物品');
    }

    // 根据显示模式和数量选择布局
    if (widget.showListMode || items.length > 1) {
      return _buildListLayout(context, theme, items);
    } else {
      return _buildSingleItemLayout(context, theme, items.first);
    }
  }

  /// 递归收集所有物品（包括子物品）
  void _collectAllItems(
    List<GoodsItem> itemList,
    String warehouseId,
    List<GoodsItemData> result,
  ) {
    for (final item in itemList) {
      result.add(GoodsItemData(item: item, warehouseId: warehouseId));
      if (item.subItems.isNotEmpty) {
        _collectAllItems(item.subItems, warehouseId, result);
      }
    }
  }

  /// 构建单个物品布局
  Widget _buildSingleItemLayout(
    BuildContext context,
    ThemeData theme,
    GoodsItemData itemData,
  ) {
    final item = itemData.item;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final isLarge = widget.size is LargeSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            () => _navigateToItemDetail(
              context,
              item.id,
              itemData.warehouseId,
              item.title,
            ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image:
                hasImage
                    ? DecorationImage(
                      image: ImageUtils.createImageProvider(item.imageUrl),
                      fit: BoxFit.cover,
                    )
                    : null,
            gradient:
                !hasImage
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _goodsColor.withAlpha(30),
                        _goodsColor.withAlpha(10),
                      ],
                    )
                    : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: hasImage ? Colors.black.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child:
                isLarge
                    ? _buildLargeItemContent(context, theme, item, hasImage)
                    : _buildMediumItemContent(context, theme, item, hasImage),
          ),
        ),
      ),
    );
  }

  /// 构建大尺寸物品内容
  Widget _buildLargeItemContent(
    BuildContext context,
    ThemeData theme,
    GoodsItem item,
    bool hasImage,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 物品图片或图标（居中）
        Center(child: _buildItemImageWidget(item, hasImage: hasImage)),
        const SizedBox(height: 16),
        // 标题（居中）
        Text(
          item.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasImage ? Colors.white : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (item.purchasePrice != null) ...[
          const SizedBox(height: 8),
          // 价格（居中）
          Text(
            '¥${item.purchasePrice!.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasImage ? Colors.white : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// 构建中等尺寸物品内容
  Widget _buildMediumItemContent(
    BuildContext context,
    ThemeData theme,
    GoodsItem item,
    bool hasImage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 物品图片或图标
            _buildItemImageWidget(item, hasImage: hasImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasImage ? Colors.white : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.purchasePrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '¥${item.purchasePrice!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            hasImage ? Colors.white : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建物品图片组件
  Widget _buildItemImageWidget(GoodsItem item, {bool hasImage = false}) {
    final effectiveColor = item.iconColor ?? _goodsColor;
    final icon = item.icon ?? Icons.inventory_2;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (hasImage ? Colors.white : effectiveColor).withAlpha(
          hasImage ? 200 : 50,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 32, color: effectiveColor),
    );
  }

  /// 构建列表布局（多个物品）
  Widget _buildListLayout(
    BuildContext context,
    ThemeData theme,
    List<GoodsItemData> items,
  ) {
    final title = widget.title ?? '物品列表';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}个物品',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 物品列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final itemData = items[index];
              return _buildListItem(context, theme, itemData);
            },
          ),
        ),
      ],
    );
  }

  /// 构建列表项
  Widget _buildListItem(
    BuildContext context,
    ThemeData theme,
    GoodsItemData itemData,
  ) {
    final item = itemData.item;

    return InkWell(
      onTap:
          () => _navigateToItemDetail(
            context,
            item.id,
            itemData.warehouseId,
            item.title,
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (item.iconColor ?? _goodsColor).withAlpha(50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon ?? Icons.inventory_2,
                color: item.iconColor ?? _goodsColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // 标题和价格
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.purchasePrice != null)
                    Text(
                      '¥${item.purchasePrice!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误小组件
  Widget _buildErrorWidget(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  /// 导航到物品详情页面
  void _navigateToItemDetail(
    BuildContext context,
    String itemId,
    String? warehouseId,
    String itemTitle,
  ) {
    if (warehouseId == null) {
      debugPrint('仓库ID为空');
      return;
    }

    NavigationHelper.pushNamed(
      context,
      '/goods/item_detail',
      arguments: {
        'itemId': itemId,
        'warehouseId': warehouseId,
        'itemTitle': itemTitle,
      },
    );
  }
}

/// 物品数据包装类
class GoodsItemData {
  final GoodsItem item;
  final String warehouseId;

  GoodsItemData({required this.item, required this.warehouseId});
}
