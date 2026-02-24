import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 用户物品数据模型
///
/// 表示用户已兑换的物品信息，包含商品名称、图片、购买价格、剩余次数、过期时间等。
/// 支持从 JSON 创建和转换为 JSON，便于数据持久化。
class UserItemCardData {
  /// 物品 ID
  final String id;

  /// 商品 ID
  final String productId;

  /// 剩余使用次数
  final int remaining;

  /// 过期时间
  final DateTime expireDate;

  /// 购买时间
  final DateTime purchaseDate;

  /// 购买价格（积分）
  final int purchasePrice;

  /// 商品快照（包含商品名称、图片等信息）
  final Map<String, dynamic> productSnapshot;

  const UserItemCardData({
    required this.id,
    required this.productId,
    required this.remaining,
    required this.expireDate,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.productSnapshot,
  });

  /// 从 JSON 创建
  factory UserItemCardData.fromJson(Map<String, dynamic> json) {
    return UserItemCardData(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      remaining: json['remaining'] as int? ?? 0,
      expireDate: json['expire_date'] != null
          ? DateTime.parse(json['expire_date'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'] as String)
          : DateTime.now(),
      purchasePrice: json['purchase_price'] as int? ?? 0,
      productSnapshot: json['product_snapshot'] != null
          ? Map<String, dynamic>.from(json['product_snapshot'] as Map)
          : <String, dynamic>{},
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'remaining': remaining,
      'expire_date': expireDate.toIso8601String(),
      'purchase_date': purchaseDate.toIso8601String(),
      'purchase_price': purchasePrice,
      'product_snapshot': productSnapshot,
    };
  }

  /// 获取商品名称
  String get productName => productSnapshot['name'] as String? ?? '';

  /// 获取商品图片
  String get productImage => productSnapshot['image'] as String? ?? '';
}

/// 用户物品卡片组件
///
/// 显示用户已兑换的物品信息，包括商品名称、图片、购买价格、剩余次数、过期状态等。
/// 支持根据 HomeWidgetSize 自动调整尺寸。
///
/// 特性：
/// - 自动适配不同尺寸的 HomeWidgetSize
/// - 显示过期状态（已过期/即将过期/有效）
/// - 显示剩余使用次数
/// - 显示购买日期和过期日期
/// - 显示剩余天数
/// - 点击弹出使用确认对话框
///
/// 示例用法：
/// ```dart
/// UserItemCardWidget(
///   data: UserItemCardData(
///     id: '1',
///     productId: 'p1',
///     remaining: 1,
///     expireDate: DateTime(2025, 12, 31),
///     purchaseDate: DateTime(2025, 1, 1),
///     purchasePrice: 50,
///     productSnapshot: {'name': '免作业卡', 'image': 'assets/card.png'},
///   ),
///   size: HomeWidgetSize.large,
///   onUse: () {
///     print('使用物品');
///   },
/// )
/// ```
class UserItemCardWidget extends StatelessWidget {
  /// 物品数据
  final UserItemCardData data;

  /// 物品数量（用于显示徽章）
  final int count;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 使用回调
  final VoidCallback? onUse;

  /// 删除回调
  final VoidCallback? onDelete;

  /// 查看商品信息回调
  final VoidCallback? onViewProduct;

  /// 计算小间距
  double get smallSpacing => size.getSmallSpacing();

  const UserItemCardWidget({
    super.key,
    required this.data,
    this.count = 1,
    this.size = const LargeSize(),
    this.onUse,
    this.onDelete,
    this.onViewProduct,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory UserItemCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final itemData = props['data'] != null
        ? UserItemCardData.fromJson(props['data'] as Map<String, dynamic>)
        : null;

    return UserItemCardWidget(
      data: itemData ??
          UserItemCardData(
            id: props['id'] as String? ?? '',
            productId: props['product_id'] as String? ?? '',
            remaining: props['remaining'] as int? ?? 0,
            expireDate: props['expire_date'] != null
                ? DateTime.parse(props['expire_date'] as String)
                : DateTime.now().add(const Duration(days: 30)),
            purchaseDate: props['purchase_date'] != null
                ? DateTime.parse(props['purchase_date'] as String)
                : DateTime.now(),
            purchasePrice: props['purchase_price'] as int? ?? 0,
            productSnapshot: props['product_snapshot'] != null
                ? Map<String, dynamic>.from(props['product_snapshot'] as Map)
                : <String, dynamic>{},
          ),
      count: props['count'] as int? ?? 1,
      size: size,
      onUse: props['onUse'] as VoidCallback?,
      onDelete: props['onDelete'] as VoidCallback?,
      onViewProduct: props['onViewProduct'] as VoidCallback?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isExpired = now.isAfter(data.expireDate);
    final daysUntilExpire = data.expireDate.difference(now).inDays;
    final isExpiringSoon = daysUntilExpire <= 7 && daysUntilExpire >= 0;

    // 根据 size 计算尺寸
    final padding = size.getPadding();
    final borderRadius = size.getSmallSpacing() * 3;
    final smallSpacing = size.getSmallSpacing();
    final titleFontSize = size.getSubtitleFontSize();
    final legendFontSize = size.getLegendFontSize();
    final imageHeight = size.getFeaturedImageSize() * 1.2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: size.getStrokeWidth() * 0.125,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: smallSpacing,
            offset: Offset(0, smallSpacing * 0.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            if (!isExpired && onUse != null) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('store_confirmUse'.tr),
                  content: Text(
                    'store_confirmUseMessage'.tr
                        .replaceFirst('@productName', data.productName),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('app_cancel'.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onUse!();
                      },
                      child: Text('app_confirm'.tr),
                    ),
                  ],
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              top: padding.top,
              bottom: padding.bottom * 0.8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Badge
                _buildImageSection(isDark, imageHeight, legendFontSize),
                SizedBox(height: smallSpacing * 2),

                // Title
                Text(
                  data.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: smallSpacing),

                // Purchase Price
                _buildPurchasePrice(legendFontSize, isDark),
                SizedBox(height: smallSpacing),

                // Remaining Uses
                _buildRemainingUses(legendFontSize, isDark, isExpired),
                SizedBox(height: smallSpacing * 1.5),

                // Divider
                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),
                SizedBox(height: smallSpacing * 1.5),

                // Purchase Date & Expiry Date
                _buildDateInfo(legendFontSize, isDark, isExpired, isExpiringSoon),
                SizedBox(height: smallSpacing),

                // Days Until Expiry
                _buildDaysUntilExpire(
                  legendFontSize,
                  isDark,
                  isExpired,
                  isExpiringSoon,
                  daysUntilExpire,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImageSection(bool isDark, double imageHeight, double legendFontSize) {
    final isExpired = DateTime.now().isAfter(data.expireDate);
    final daysUntilExpire = data.expireDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpire <= 7 && daysUntilExpire >= 0;

    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: imageHeight),
          child: data.productImage.isEmpty
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(size.getSmallSpacing() * 1.5),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: size.getIconSize() * 1.5,
                    color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(size.getSmallSpacing() * 1.5),
                  child: Image.network(
                    data.productImage,
                    width: double.infinity,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: imageHeight,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: size.getIconSize() * 1.5,
                          color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
                        ),
                      );
                    },
                  ),
                ),
        ),
        // Badge showing count
        if (count > 1)
          Positioned(
            top: smallSpacing * 1.5,
            right: smallSpacing * 1.5,
            child: Container(
              width: legendFontSize * 2,
              height: legendFontSize * 2,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: legendFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Expiry Status Badge
        Positioned(
          top: smallSpacing * 1.5,
          left: smallSpacing * 1.5,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: legendFontSize * 0.8,
              vertical: legendFontSize * 0.3,
            ),
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.red
                  : isExpiringSoon
                      ? Colors.orange
                      : Colors.green,
              borderRadius: BorderRadius.circular(legendFontSize * 1.5),
            ),
            child: Text(
              isExpired
                  ? '已过期'
                  : isExpiringSoon
                      ? '即将过期'
                      : '有效',
              style: TextStyle(
                color: Colors.white,
                fontSize: legendFontSize * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建购买价格
  Widget _buildPurchasePrice(double legendFontSize, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '\u{1FA99}',
              style: TextStyle(fontSize: legendFontSize),
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              '购买价格',
              style: TextStyle(
                fontSize: legendFontSize,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
        Text(
          '${data.purchasePrice}积分',
          style: TextStyle(
            fontSize: legendFontSize,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
          ),
        ),
      ],
    );
  }

  /// 构建剩余次数
  Widget _buildRemainingUses(double legendFontSize, bool isDark, bool isExpired) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '\u{1FA99}',
              style: TextStyle(fontSize: legendFontSize),
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              '剩余次数',
              style: TextStyle(
                fontSize: legendFontSize,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.getSmallSpacing() * 2,
            vertical: size.getSmallSpacing() * 0.5,
          ),
          decoration: BoxDecoration(
            color: isExpired ? Colors.grey : Theme.of(Get.context!).colorScheme.primary,
            borderRadius: BorderRadius.circular(legendFontSize * 1.5),
          ),
          child: Text(
            '${data.remaining}',
            style: TextStyle(
              color: Colors.white,
              fontSize: legendFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建日期信息
  Widget _buildDateInfo(
    double legendFontSize,
    bool isDark,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '购买日期',
              style: TextStyle(
                fontSize: legendFontSize,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
            Text(
              _formatDate(data.purchaseDate),
              style: TextStyle(
                fontSize: legendFontSize,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
        SizedBox(height: smallSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '过期日期',
              style: TextStyle(
                fontSize: legendFontSize,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              ),
            ),
            Text(
              _formatDate(data.expireDate),
              style: TextStyle(
                fontSize: legendFontSize,
                color: isExpired
                    ? Colors.red
                    : isExpiringSoon
                        ? Colors.orange
                        : isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建剩余天数
  Widget _buildDaysUntilExpire(
    double legendFontSize,
    bool isDark,
    bool isExpired,
    bool isExpiringSoon,
    int daysUntilExpire,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '剩余天数',
          style: TextStyle(
            fontSize: legendFontSize,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
          ),
        ),
        Row(
          children: [
            Container(
              width: legendFontSize * 0.6,
              height: legendFontSize * 0.6,
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.grey
                    : isExpiringSoon
                        ? Colors.orange
                        : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              isExpired ? '已过期' : '$daysUntilExpire天',
              style: TextStyle(
                fontSize: legendFontSize,
                color: isExpired
                    ? Colors.grey
                    : isExpiringSoon
                        ? Colors.orange
                        : isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year.toString().substring(2)}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
