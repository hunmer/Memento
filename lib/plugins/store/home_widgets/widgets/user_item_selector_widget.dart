/// 用户物品选择器小组件 - 使用事件携带数据模式
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/utils/image_utils.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import '../events/store_cache_updated_event_args.dart';

/// 用户物品选择器小组件
class UserItemSelectorWidget extends StatefulWidget {
  final Map<String, dynamic> config;

  const UserItemSelectorWidget({required this.config, super.key});

  @override
  State<UserItemSelectorWidget> createState() =>
      _UserItemSelectorWidgetState();
}

class _UserItemSelectorWidgetState extends State<UserItemSelectorWidget> {
  // 缓存的最新数据
  List<Map<String, dynamic>> _userItems = [];

  @override
  Widget build(BuildContext context) {
    return EventListenerContainer(
      events: const ['store_cache_updated'],
      onEventWithData: (EventArgs args) {
        if (args is StoreCacheUpdatedEventArgs) {
          setState(() {
            _userItems = args.userItems;
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final itemId = widget.config['id'] as String?;
    if (itemId == null || itemId.isEmpty) {
      return HomeWidget.buildErrorWidget(context, '物品ID不存在');
    }

    // 查找对应的用户物品
    final itemData = _userItems.firstWhere(
      (item) => item['id'] == itemId,
      orElse: () => {},
    );

    if (itemData.isEmpty) {
      return HomeWidget.buildErrorWidget(context, '物品未找到');
    }

    final productSnapshot =
        itemData['product_snapshot'] as Map<String, dynamic>?;
    final productName = productSnapshot?['name'] as String? ?? '';
    final productImage = productSnapshot?['image'] as String?;
    final purchasePrice = itemData['purchase_price'] as int? ?? 0;
    final remaining = itemData['remaining'] as int? ?? 0;
    final expireDate = DateTime.parse(itemData['expire_date'] as String);

    final remainingDays = expireDate.difference(DateTime.now()).inDays;
    final isExpired = remainingDays < 0;
    final isExpiringSoon = remainingDays >= 0 && remainingDays <= 7;

    final theme = Theme.of(context);

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
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Row(
                          children: [
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

  Future<String?> _getProductImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
      return imagePath;
    }
    return ImageUtils.getAbsolutePath(imagePath);
  }
}
