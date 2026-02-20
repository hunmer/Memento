/// 积分商店插件 - 用户物品选择器注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'widgets/user_item_selector_widget.dart';
import '../store_plugin.dart';

/// 注册用户物品选择器小组件
void registerUserItemSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'store_user_item_selector',
      pluginId: 'store',
      name: 'store_userItemQuickAccess'.tr,
      description: 'store_userItemQuickAccessDesc'.tr,
      icon: Icons.inventory_2,
      color: Colors.pinkAccent,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryTools'.tr,

      // 选择器配置
      selectorId: 'store.userItem',
      dataRenderer: _renderUserItemData,
      dataSelector: (dataArray) {
        final itemData = dataArray[0] as Map<String, dynamic>;
        return {
          'id': itemData['id'] as String,
          'purchase_price': itemData['purchase_price'] as int?,
          'remaining': itemData['remaining'] as int?,
          'expire_date': itemData['expire_date'] as String?,
          'product_snapshot':
              itemData['product_snapshot'] as Map<String, dynamic>?,
        };
      },

      builder: (context, config) {
        final dataMap = config['selectedData'] as Map<String, dynamic>? ?? {};
        return UserItemSelectorWidget(config: dataMap);
      },
    ),
  );
}

/// 渲染用户物品数据
Widget _renderUserItemData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从 result.data 获取保存的物品 ID
  final savedData = result.data as Map<String, dynamic>?;
  if (savedData == null) {
    return HomeWidget.buildErrorWidget(context, '数据不存在');
  }

  final itemId = savedData['id'] as String? ?? '';
  if (itemId.isEmpty) {
    return HomeWidget.buildErrorWidget(context, '物品ID不存在');
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const [
          'store_user_item_added',
          'store_user_item_used',
          'store_user_item_deleted',
          'store_points_changed',
        ],
        onEvent: () => setState(() {}),
        child: _buildUserItemWidget(context, itemId),
      );
    },
  );
}

/// 构建用户物品小组件内容（获取最新数据）
Widget _buildUserItemWidget(BuildContext context, String itemId) {
  final theme = Theme.of(context);

  // 从 PluginManager 获取最新的用户物品数据
  final plugin = PluginManager.instance.getPlugin('store') as StorePlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(
      context,
      'store_pluginNotAvailable'.tr,
    );
  }

  // 查找对应的用户物品
  final item = plugin.controller.userItems.firstWhereOrNull(
    (item) => item.id == itemId,
  );

  if (item == null) {
    return HomeWidget.buildErrorWidget(context, 'store_itemNotFound'.tr);
  }

  final productName = item.productName;
  final productImage = item.productImage;
  final purchasePrice = item.purchasePrice;
  final remaining = item.remaining;
  final expireDate = item.expireDate;

  // 计算剩余天数
  final remainingDays = expireDate.difference(DateTime.now()).inDays;

  // 检查是否已过期
  final isExpired = remainingDays < 0;
  final isExpiringSoon = remainingDays >= 0 && remainingDays <= 7;

  return FutureBuilder<String?>(
    future: _getProductImagePath(productImage),
    builder: (context, imageSnapshot) {
      final hasImage =
          imageSnapshot.hasData &&
          imageSnapshot.data != null &&
          imageSnapshot.data!.isNotEmpty;

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // 导航到用户物品详情
            NavigationHelper.pushNamed(
              context,
              '/store/user_item',
              arguments: {'itemId': itemId, 'autoUse': true},
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image:
                  hasImage
                      ? DecorationImage(
                        image: ImageUtils.createImageProvider(
                          imageSnapshot.data,
                        ),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child: Stack(
              children: [
                // 半透明遮罩
                if (hasImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 物品名称和剩余次数（在同一行）
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasImage ? Colors.white : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 剩余次数（标题右侧）
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (hasImage
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.pinkAccent.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$remaining ${'store_times'.tr}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    hasImage
                                        ? Colors.white
                                        : Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // 底部区域：价格（左）和过期信息（右）
                      Row(
                        children: [
                          // 价格信息
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$purchasePrice ${'store_points'.tr}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // 过期信息（右下角）
                          Text(
                            isExpired
                                ? 'store_itemExpired'.tr
                                : '${'store_expireIn'.tr} $remainingDays ${'store_days'.tr}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  hasImage
                                      ? (isExpired
                                          ? Colors.red.shade300
                                          : (isExpiringSoon
                                              ? Colors.orange.shade300
                                              : Colors.green.shade300))
                                      : (isExpired
                                          ? Colors.red
                                          : (isExpiringSoon
                                              ? Colors.orange
                                              : Colors.green)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 获取商品的图片绝对路径
Future<String?> _getProductImagePath(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) return null;

  // 如果是绝对路径，直接返回
  if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
    return imagePath;
  }

  // 如果是相对路径，使用 ImageUtils 转换
  return ImageUtils.getAbsolutePath(imagePath);
}
