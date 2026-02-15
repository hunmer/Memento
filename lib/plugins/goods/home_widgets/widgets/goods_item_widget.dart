/// 物品小组件组件
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 物品小组件
class GoodsItemWidget extends StatelessWidget {
  const GoodsItemWidget({
    super.key,
    required this.itemId,
    required this.config,
  });

  final String itemId;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的物品数据
    final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
    if (plugin == null) {
      return HomeWidget.buildErrorWidget(context, '插件不可用');
    }

    final findResult = plugin.findGoodsItemById(itemId);
    final item = findResult?.item;

    if (item == null) {
      return HomeWidget.buildErrorWidget(context, '物品不存在');
    }

    final title = item.title;
    final price = item.purchasePrice;

    // 获取 widget size
    final widgetSize = config['widgetSize'] as HomeWidgetSize?;

    return FutureBuilder<String?>(
      future: item.getImageUrl(),
      builder: (context, snapshot) {
        final hasImage =
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        // 判断是否为 large 模式
        final isLarge = widgetSize == const LargeSize();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToItemDetail(
              context,
              itemId,
              findResult?.warehouseId,
              title,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image:
                    hasImage
                        ? DecorationImage(
                          image: ImageUtils.createImageProvider(snapshot.data),
                          fit: BoxFit.cover,
                        )
                        : null,
                gradient:
                    hasImage
                        ? null
                        : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _goodsColor.withAlpha(30),
                            _goodsColor.withAlpha(10),
                          ],
                        ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: hasImage ? Colors.black.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: isLarge
                    ? _buildLargeLayout(item, title, price, hasImage, theme)
                    : _buildMediumLayout(item, title, price, hasImage, theme),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建大尺寸布局（图标居中，标题和价格在下方）
  Widget _buildLargeLayout(
    GoodsItem item,
    String title,
    double? price,
    bool hasImage,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 物品图片或图标（居中）
        Center(child: _buildItemImageWidget(item, hasImage: hasImage)),
        const SizedBox(height: 16),
        // 标题（居中）
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: hasImage ? Colors.white : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (price != null) ...[
          const SizedBox(height: 8),
          // 价格（居中）
          Text(
            '¥${price.toStringAsFixed(2)}',
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

  /// 构建中等尺寸布局（图标和标题价格横向排列）
  Widget _buildMediumLayout(
    GoodsItem item,
    String title,
    double? price,
    bool hasImage,
    ThemeData theme,
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
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasImage ? Colors.white : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '¥${price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            hasImage
                                ? Colors.white
                                : theme.colorScheme.primary,
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

  /// 构建物品图片组件（支持图片背景）
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

  /// 导航到物品详情页面（通过ID）
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
