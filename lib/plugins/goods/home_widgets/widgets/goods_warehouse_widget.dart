/// 仓库小组件组件
library;

import 'package:flutter/material.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';

/// 仓库小组件
class GoodsWarehouseWidget extends StatelessWidget {
  const GoodsWarehouseWidget({
    super.key,
    required this.warehouseId,
  });

  final String warehouseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 从 PluginManager 获取最新的仓库数据
    final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
    if (plugin == null) {
      return HomeWidget.buildErrorWidget(context, '插件不可用');
    }

    final warehouse = plugin.getWarehouse(warehouseId);
    if (warehouse == null) {
      return HomeWidget.buildErrorWidget(context, '仓库不存在');
    }

    final title = warehouse.title;
    final itemCount = warehouse.items.length;
    final icon = warehouse.icon;
    final color = warehouse.iconColor;

    return FutureBuilder<String?>(
      future: warehouse.getImageUrl(),
      builder: (context, snapshot) {
        final hasImage =
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToWarehouseDetail(context, warehouseId, title),
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
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: hasImage ? Colors.black.withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部图标和标题
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (hasImage ? Colors.white : color).withAlpha(
                              hasImage ? 200 : 50,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: hasImage ? color : color,
                          ),
                        ),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$itemCount 件物品',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      (hasImage
                                          ? Colors.white70
                                          : theme.colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 导航到仓库详情页面（通过ID）
  void _navigateToWarehouseDetail(
    BuildContext context,
    String warehouseId,
    String warehouseName,
  ) {
    NavigationHelper.pushNamed(
      context,
      '/goods/warehouse_detail',
      arguments: {'warehouseId': warehouseId, 'warehouseName': warehouseName},
    );
  }
}
