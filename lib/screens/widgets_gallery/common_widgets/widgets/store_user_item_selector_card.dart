/// 用户物品选择器公共小组件
///
/// 显示用户物品列表，支持单个或多个物品展示
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/utils/image_utils.dart';

/// 用户物品数据模型
class UserItemData {
  final String id;
  final String productName;
  final String? productImage;
  final int purchasePrice;
  final int remaining;
  final String expireDate;
  final int remainingDays;
  final bool isExpired;
  final bool isExpiringSoon;

  UserItemData({
    required this.id,
    required this.productName,
    this.productImage,
    required this.purchasePrice,
    required this.remaining,
    required this.expireDate,
    required this.remainingDays,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  factory UserItemData.fromJson(Map<String, dynamic> json) {
    return UserItemData(
      id: json['id'] as String,
      productName: json['productName'] as String,
      productImage: json['productImage'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      expireDate: json['expireDate'] as String,
      remainingDays: (json['remainingDays'] as num?)?.toInt() ?? 0,
      isExpired: json['isExpired'] as bool? ?? false,
      isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'productImage': productImage,
      'purchasePrice': purchasePrice,
      'remaining': remaining,
      'expireDate': expireDate,
      'remainingDays': remainingDays,
      'isExpired': isExpired,
      'isExpiringSoon': isExpiringSoon,
    };
  }
}

/// 用户物品选择器小组件
class StoreUserItemSelectorCardWidget extends StatefulWidget {
  /// 物品列表
  final List<UserItemData> items;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const StoreUserItemSelectorCardWidget({
    super.key,
    required this.items,
    required this.size,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory StoreUserItemSelectorCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemsList = (props['items'] as List<dynamic>?)
            ?.map((e) => UserItemData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return StoreUserItemSelectorCardWidget(
      items: itemsList,
      size: size,
    );
  }

  @override
  State<StoreUserItemSelectorCardWidget> createState() =>
      _StoreUserItemSelectorCardWidgetState();
}

class _StoreUserItemSelectorCardWidgetState extends State<StoreUserItemSelectorCardWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.items;

    if (items.isEmpty) {
      return _buildEmptyWidget(context, theme);
    }

    // 单个物品显示详情，多个物品显示列表
    if (items.length == 1) {
      return _buildSingleItem(context, theme, items.first);
    } else {
      return _buildItemList(context, theme, items);
    }
  }

  /// 构建单个物品布局
  Widget _buildSingleItem(
    BuildContext context,
    ThemeData theme,
    UserItemData item,
  ) {
    final expireColor = _getExpireColor(item);

    return FutureBuilder<String?>(
      future: _getImagePath(item.productImage),
      builder: (context, imageSnapshot) {
        final hasImage =
            imageSnapshot.hasData &&
            imageSnapshot.data != null &&
            imageSnapshot.data!.isNotEmpty;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              image: hasImage
                  ? DecorationImage(
                      image: ImageUtils.createImageProvider(imageSnapshot.data),
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
                              item.productName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasImage ? Colors.white : theme.colorScheme.onSurface,
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
                              color: (hasImage
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.pinkAccent.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.remaining} ${'store_times'.tr}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasImage ? Colors.white : Colors.pinkAccent,
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
                              Icon(Icons.monetization_on, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '${item.purchasePrice} ${'store_points'.tr}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // 过期信息（右下角）
                          Text(
                            item.isExpired
                                ? 'store_itemExpired'.tr
                                : '${'store_expireIn'.tr} ${item.remainingDays} ${'store_days'.tr}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: expireColor,
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
        );
      },
    );
  }

  /// 构建物品列表布局
  Widget _buildItemList(
    BuildContext context,
    ThemeData theme,
    List<UserItemData> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.inventory_2, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '我的物品',
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
              return _buildItemListItem(context, theme, items[index]);
            },
          ),
        ),
      ],
    ),
    );
  }

  /// 构建物品列表项
  Widget _buildItemListItem(
    BuildContext context,
    ThemeData theme,
    UserItemData item,
  ) {
    final expireColor = _getExpireColor(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 物品图标/图片
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          // 物品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.remaining}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${item.purchasePrice} ${'store_points'.tr}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.isExpired
                          ? 'store_itemExpired'.tr
                          : '${item.remainingDays} ${'store_days'.tr}',
                      style: theme.textTheme.bodySmall?.copyWith(color: expireColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              '暂无物品',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取过期颜色
  Color _getExpireColor(UserItemData item) {
    if (item.isExpired) {
      return Colors.red;
    } else if (item.isExpiringSoon) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// 获取图片路径
  Future<String?> _getImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('/') || imagePath.startsWith('http')) {
      return imagePath;
    }
    return ImageUtils.getAbsolutePath(imagePath);
  }
}
