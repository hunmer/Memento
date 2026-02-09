/// 物品管理插件主页小组件数据提供者
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/models/warehouse.dart';
import 'utils.dart' show goodsColor;

const Color _goodsColor = Color.fromARGB(255, 207, 77, 116);

/// 获取可用的统计项
List<StatItemData> getAvailableStats(BuildContext context) {
  try {
    final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
    if (plugin == null) return [];

    final totalItems = plugin.getTotalItemsCount();
    final totalValue = plugin.getTotalItemsValue();
    final unusedItems = plugin.getUnusedItemsCount();

    return [
      StatItemData(
        id: 'total_quantity',
        label: 'goods_totalGoods'.tr,
        value: '$totalItems',
        highlight: false,
      ),
      StatItemData(
        id: 'total_value',
        label: '物品总价值',
        value: '¥${totalValue.toStringAsFixed(0)}',
        highlight: false,
      ),
      StatItemData(
        id: 'one_month_unused',
        label: '一个月未使用',
        value: '$unusedItems',
        highlight: unusedItems > 0,
        color: Colors.red,
      ),
    ];
  } catch (e) {
    return [];
  }
}

/// 构建概览小组件
Widget buildOverviewWidget(BuildContext context, Map<String, dynamic> config) {
  try {
    // 解析插件配置
    PluginWidgetConfig widgetConfig;
    try {
      if (config.containsKey('pluginWidgetConfig')) {
        widgetConfig = PluginWidgetConfig.fromJson(
          config['pluginWidgetConfig'] as Map<String, dynamic>,
        );
      } else {
        widgetConfig = PluginWidgetConfig();
      }
    } catch (e) {
      widgetConfig = PluginWidgetConfig();
    }

    // 获取可用的统计项数据
    final availableItems = getAvailableStats(context);

    // 使用通用小组件
    return GenericPluginWidget(
      pluginId: 'goods',
      pluginName: 'goods_name'.tr,
      pluginIcon: Icons.dashboard,
      pluginDefaultColor: _goodsColor,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 物品列表小组件数据提供者
///
/// 支持过滤器：仓库、标签、购入日期、过期日期
Future<Map<String, Map<String, dynamic>>> provideGoodsListWidgets(
  Map<String, dynamic> config,
) async {
  final plugin = PluginManager.instance.getPlugin('goods') as GoodsPlugin?;
  if (plugin == null) return {};

  // 解析过滤器参数
  final warehouseId = config['warehouseId'] as String?;
  final tags = config['tags'] as List<dynamic>?;
  final startDateStr = config['startDate'] as String?;
  final endDateStr = config['endDate'] as String?;
  final title = config['title'] as String?;

  // 解析日期
  DateTime? startDate;
  DateTime? endDate;
  if (startDateStr != null) {
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (e) {
      debugPrint('[GoodsListWidgets] 解析 startDate 失败: $e');
    }
  }
  if (endDateStr != null) {
    try {
      endDate = DateTime.parse(endDateStr);
    } catch (e) {
      debugPrint('[GoodsListWidgets] 解析 endDate 失败: $e');
    }
  }

  // 获取所有物品（递归包含子物品）
  List<GoodsItem> allItems = [];
  if (warehouseId != null) {
    final warehouse = plugin.getWarehouse(warehouseId);
    if (warehouse != null) {
      allItems = _getAllItemsRecursively(warehouse.items);
    }
  } else {
    // 获取所有仓库的物品
    for (final warehouse in plugin.warehouses) {
      allItems.addAll(_getAllItemsRecursively(warehouse.items));
    }
  }

  // 应用过滤器
  List<GoodsItem> filteredItems =
      allItems.where((item) {
        // 标签过滤
        if (tags != null && tags.isNotEmpty) {
          final hasMatchingTag = tags.any(
            (tag) => item.tags.contains(tag as String),
          );
          if (!hasMatchingTag) return false;
        }

        // 购入日期过滤（使用 startDate 作为购入日期的开始，endDate 作为购入日期的结束）
        if (startDate != null &&
            item.purchaseDate != null &&
            item.purchaseDate!.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && item.purchaseDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (item.purchaseDate!.isAfter(endOfDay)) return false;
        }

        // 过期日期过滤（使用 expirationDate 字段）
        if (startDate != null &&
            item.expirationDate != null &&
            item.expirationDate!.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && item.expirationDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (item.expirationDate!.isAfter(endOfDay)) return false;
        }

        return true;
      }).toList();

  // 按购入日期降序排序
  filteredItems.sort((a, b) {
    final aDate = a.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.purchaseDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });

  final now = DateTime.now();
  final itemsCount = filteredItems.length;

  // 获取仓库名称
  Warehouse? warehouse;
  String warehouseName = title ?? 'goods_allItems'.tr;
  if (warehouseId != null) {
    warehouse = plugin.getWarehouse(warehouseId);
    warehouseName = warehouse?.title ?? 'goods_unknownWarehouse'.tr;
  }

  // 获取标签颜色映射
  final tagColors = <String, Color>{};
  for (final item in filteredItems) {
    for (final tag in item.tags) {
      if (!tagColors.containsKey(tag)) {
        tagColors[tag] = _getColorFromTag(tag);
      }
    }
  }

  // 最多显示 5 条物品
  final displayItems = filteredItems.take(5).toList();
  final moreCount =
      itemsCount > displayItems.length ? itemsCount - displayItems.length : 0;

  // 构建 InboxMessageCard 数据（重点展示物品图片）
  final inboxMessageCardData = {
    'messages': await Future.wait(
      displayItems.map((item) async {
        final imageUrl = await item.getImageUrl();
        final primaryTag = item.tags.isNotEmpty ? item.tags.first : '';
        final tagColor =
            primaryTag.isNotEmpty ? tagColors[primaryTag] : goodsColor;
        return {
          'name': item.title,
          'avatarUrl': imageUrl ?? '',
          'preview': _getItemPreview(item),
          'timeAgo': _formatTimeAgo(item.purchaseDate ?? now, now),
          'iconCodePoint':
              imageUrl != null && imageUrl.isNotEmpty
                  ? null
                  : Icons.inventory_2_outlined.codePoint,
          'iconBackgroundColor': tagColor?.value ?? goodsColor.value,
        };
      }),
    ),
    'totalCount': itemsCount,
    'remainingCount': moreCount,
    'title': warehouseName,
    'primaryColor': goodsColor.value,
  };

  // 构建 NewsCard 数据（重点展示物品图片）
  final featuredItem = displayItems.isNotEmpty ? displayItems.first : null;
  final imageUrl = featuredItem != null ? await featuredItem.getImageUrl() : '';
  final newsCardData =
      featuredItem != null
          ? {
            'featuredNews': {
              'imageUrl': imageUrl ?? '',
              'title': featuredItem.title,
            },
            'category': warehouseName,
            'newsItems': await Future.wait(
              displayItems.skip(1).take(3).map((item) async {
                final itemImageUrl = await item.getImageUrl();
                return {
                  'title': item.title,
                  'time': _formatTimeAgo(item.purchaseDate ?? now, now),
                  'imageUrl': itemImageUrl ?? '',
                };
              }),
            ),
          }
          : {
            'featuredNews': {'imageUrl': '', 'title': 'goods_noItems'.tr},
            'category': warehouseName,
            'newsItems': [],
          };

  // 构建 ArticleListCard 数据（重点展示物品图片，替代 notesListCard）
  final featuredArticle = displayItems.isNotEmpty ? displayItems.first : null;
  final articleImageUrl = featuredArticle != null ? await featuredArticle.getImageUrl() : '';
  final articleListCardData = featuredArticle != null
      ? {
          'featuredArticle': {
            'author': warehouseName,
            'title': featuredArticle.title,
            'summary': _getItemPreview(featuredArticle),
            'imageUrl': articleImageUrl ?? '',
          },
          'articles': await Future.wait(
            displayItems.skip(1).take(3).map((item) async {
              final itemImageUrl = await item.getImageUrl();
              return {
                'title': item.title,
                'author': warehouseName,
                'publication': _formatTimeAgo(item.purchaseDate ?? now, now),
                'imageUrl': itemImageUrl ?? '',
              };
            }),
          ),
        }
      : {
          'featuredArticle': {
            'author': '',
            'title': 'goods_noItems'.tr,
            'summary': '',
            'imageUrl': '',
          },
          'articles': [],
        };

  return {
    'inboxMessageCard': inboxMessageCardData,
    'newsCard': newsCardData,
    'articleListCard': articleListCardData,
  };
}

/// 递归获取所有物品（包含子物品）
List<GoodsItem> _getAllItemsRecursively(List<GoodsItem> items) {
  List<GoodsItem> result = [];
  for (var item in items) {
    result.add(item);
    if (item.subItems.isNotEmpty) {
      result.addAll(_getAllItemsRecursively(item.subItems));
    }
  }
  return result;
}

/// 从标签获取颜色
Color _getColorFromTag(String tag) {
  final hashCode = tag.hashCode;
  final hue = (hashCode % 360).abs();
  return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
}

/// 获取物品预览文本
String _getItemPreview(GoodsItem item) {
  final parts = <String>[];

  if (item.purchasePrice != null) {
    parts.add('¥${item.purchasePrice!.toStringAsFixed(2)}');
  }

  if (item.tags.isNotEmpty) {
    parts.add(item.tags.join(', '));
  }

  if (item.notes != null && item.notes!.isNotEmpty) {
    String note = item.notes!;
    if (note.length > 30) {
      note = note.substring(0, 30);
      final lastSpace = note.lastIndexOf(' ');
      if (lastSpace > 15) note = note.substring(0, lastSpace);
      note += '...';
    }
    parts.add(note);
  }

  return parts.isEmpty ? 'goods_noItems'.tr : parts.join(' • ');
}

/// 格式化相对时间
String _formatTimeAgo(DateTime dateTime, DateTime now) {
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'justNow'.tr;
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return 'minutesAgo'.trParams({'count': '$minutes'});
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return 'hoursAgo'.trParams({'count': '$hours'});
  } else if (difference.inDays < 7) {
    final days = difference.inDays;
    return 'daysAgo'.trParams({'count': '$days'});
  } else {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }
}
