import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 商品数据模型
///
/// 表示单个商品的信息，包含名称、描述、图片、库存、价格、兑换时间和有效期。
/// 支持从 JSON 创建和转换为 JSON，便于数据持久化。
class ProductCardData {
  /// 商品 ID
  final String id;

  /// 商品名称
  final String name;

  /// 商品描述
  final String description;

  /// 商品图片路径
  final String? image;

  /// 库存数量
  final int stock;

  /// 价格（积分）
  final int price;

  /// 兑换开始时间
  final DateTime exchangeStart;

  /// 兑换结束时间
  final DateTime exchangeEnd;

  /// 使用期限（天）
  final int useDuration;

  const ProductCardData({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.stock,
    required this.price,
    required this.exchangeStart,
    required this.exchangeEnd,
    required this.useDuration,
  });

  /// 从 JSON 创建
  factory ProductCardData.fromJson(Map<String, dynamic> json) {
    return ProductCardData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String?,
      stock: json['stock'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      exchangeStart: json['exchange_start'] != null
          ? DateTime.parse(json['exchange_start'] as String)
          : DateTime.now(),
      exchangeEnd: json['exchange_end'] != null
          ? DateTime.parse(json['exchange_end'] as String)
          : DateTime.now().add(const Duration(days: 365)),
      useDuration: json['use_duration'] as int? ?? 30,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'stock': stock,
      'price': price,
      'exchange_start': exchangeStart.toIso8601String(),
      'exchange_end': exchangeEnd.toIso8601String(),
      'use_duration': useDuration,
    };
  }
}

/// 商品卡片组件
///
/// 显示单个商品的详细信息，包括名称、图片、库存状态、价格、兑换时间和有效期。
/// 支持根据 HomeWidgetSize 自动调整尺寸。
///
/// 特性：
/// - 自动适配不同尺寸的 HomeWidgetSize
/// - 显示库存状态（已过期/未开始/可兑换）
/// - 显示价格（积分）
/// - 显示兑换有效期
/// - 点击弹出兑换确认对话框
///
/// 示例用法：
/// ```dart
/// ProductCardWidget(
///   data: ProductCardData(
///     id: '1',
///     name: '免作业卡',
///     description: '可免除一次作业',
///     image: 'assets/card.png',
///     stock: 10,
///     price: 50,
///     exchangeStart: DateTime(2025, 1, 1),
///     exchangeEnd: DateTime(2025, 12, 31),
///     useDuration: 30,
///   ),
///   size: HomeWidgetSize.large,
///   onExchange: () {
///     print('兑换商品');
///   },
/// )
/// ```
class ProductCardWidget extends StatelessWidget {
  /// 商品数据
  final ProductCardData data;

  /// 小组件尺寸
  final HomeWidgetSize size;

  /// 兑换回调
  final VoidCallback? onExchange;

  /// 长按回调
  final VoidCallback? onLongPress;

  const ProductCardWidget({
    super.key,
    required this.data,
    this.size = const LargeSize(),
    this.onExchange,
    this.onLongPress,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ProductCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final productData = props['data'] != null
        ? ProductCardData.fromJson(props['data'] as Map<String, dynamic>)
        : null;

    return ProductCardWidget(
      data: productData ??
          ProductCardData(
            id: '',
            name: props['name'] as String? ?? '',
            description: props['description'] as String? ?? '',
            image: props['image'] as String?,
            stock: props['stock'] as int? ?? 0,
            price: props['price'] as int? ?? 0,
            exchangeStart: props['exchange_start'] != null
                ? DateTime.parse(props['exchange_start'] as String)
                : DateTime.now(),
            exchangeEnd: props['exchange_end'] != null
                ? DateTime.parse(props['exchange_end'] as String)
                : DateTime.now().add(const Duration(days: 365)),
            useDuration: props['use_duration'] as int? ?? 30,
          ),
      size: size,
      onExchange: props['onExchange'] as VoidCallback?,
      onLongPress: props['onLongPress'] as VoidCallback?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isExpired = now.isAfter(data.exchangeEnd);
    final notStarted = now.isBefore(data.exchangeStart);

    // 根据 size 计算尺寸
    final padding = size.getPadding();
    final borderRadius = size.getSmallSpacing() * 3;
    final smallSpacing = size.getSmallSpacing();
    final titleFontSize = size.getSubtitleFontSize();
    final legendFontSize = size.getLegendFontSize();

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
            blurRadius: size.getSmallSpacing(),
            offset: Offset(0, smallSpacing * 0.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onLongPress: onLongPress,
          onTap: onExchange != null
              ? () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('store_redeemConfirmation'.tr),
                      content: Text(
                        '${'store_confirmUseItem'.tr}\n${data.name} 需要消耗 ${data.price} 积分',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('app_cancel'.tr),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onExchange!();
                          },
                          child: Text('app_confirm'.tr),
                        ),
                      ],
                    ),
                  );
                }
              : null,
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
                // Image Section - 高度自适应
                _buildImage(isDark),
                SizedBox(height: smallSpacing * 2),

                // Title
                Text(
                  data.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: smallSpacing),

                // Stock Status
                _buildStockStatus(isDark, isExpired, notStarted, legendFontSize),
                SizedBox(height: smallSpacing),

                // Price
                _buildPrice(legendFontSize),
                SizedBox(height: smallSpacing * 1.5),

                // Divider
                Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),
                SizedBox(height: smallSpacing * 1.5),

                // Exchange Period & Status
                _buildExchangePeriod(legendFontSize),
                SizedBox(height: smallSpacing),

                // Exchange Duration
                _buildExchangeDuration(legendFontSize, isExpired, notStarted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建图片区域
  Widget _buildImage(bool isDark) {
    final imageHeight = size.getFeaturedImageSize() * 0.6;

    if (data.image == null || data.image!.isEmpty) {
      return Container(
        height: imageHeight,
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
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size.getSmallSpacing() * 1.5),
      child: Image.network(
        data.image!,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: imageHeight,
            width: double.infinity,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: size.getIconSize() * 1.5,
              color: isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93),
            ),
          );
        },
      ),
    );
  }

  /// 构建库存状态
  Widget _buildStockStatus(
    bool isDark,
    bool isExpired,
    bool notStarted,
    double legendFontSize,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '库存状态',
          style: TextStyle(
            fontSize: legendFontSize,
            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.getSmallSpacing() * 2,
            vertical: size.getSmallSpacing() * 0.5,
          ),
          decoration: BoxDecoration(
            color: isExpired
                ? Colors.grey
                : notStarted
                    ? Colors.orange
                    : Theme.of(Get.context!).colorScheme.primary,
            borderRadius: BorderRadius.circular(legendFontSize * 1.5),
          ),
          child: Text(
            isExpired
                ? '已过期'
                : notStarted
                    ? '未开始'
                    : '库存: ${data.stock}',
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

  /// 构建价格
  Widget _buildPrice(double legendFontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '\u{1FA99}',
              style: TextStyle(
                fontSize: legendFontSize,
              ),
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              '价格',
              style: TextStyle(
                fontSize: legendFontSize,
                color: Get.isDarkMode
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6C6C70),
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
            color: Colors.green,
            borderRadius: BorderRadius.circular(legendFontSize * 1.5),
          ),
          child: Text(
            '${data.price}积分',
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

  /// 构建兑换期限
  Widget _buildExchangePeriod(double legendFontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: legendFontSize * 1.2,
              color: Colors.blue,
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              _formatDate(data.exchangeStart),
              style: TextStyle(
                fontSize: legendFontSize,
                color: Get.isDarkMode
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6C6C70),
              ),
            ),
          ],
        ),
        Text(
          _formatDate(data.exchangeEnd),
          style: TextStyle(
            fontSize: legendFontSize,
            color: Get.isDarkMode
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6C6C70),
          ),
        ),
      ],
    );
  }

  /// 构建兑换时长
  Widget _buildExchangeDuration(
    double legendFontSize,
    bool isExpired,
    bool notStarted,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '有效期：${data.useDuration}天',
          style: TextStyle(
            fontSize: legendFontSize,
            color: Get.isDarkMode
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6C6C70),
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
                    : notStarted
                        ? Colors.orange
                        : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: size.getSmallSpacing() * 0.5),
            Text(
              isExpired
                  ? '已过期'
                  : notStarted
                      ? '未开始'
                      : '可兑换',
              style: TextStyle(
                fontSize: legendFontSize,
                color: Get.isDarkMode
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
