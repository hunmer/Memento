import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'checkin_plugin.dart';
import 'models/checkin_item.dart';

/// 打卡插件的主页小组件注册
class CheckinHomeWidgets {
  /// 注册所有打卡插件的小组件
  static void register() {
    final registry = HomeWidgetRegistry();

    // 1x1 简单图标组件 - 快速访问
    registry.register(
      HomeWidget(
        id: 'checkin_icon',
        pluginId: 'checkin',
        name: 'checkin_widgetName'.tr,
        description: 'checkin_widgetDescription'.tr,
        icon: Icons.checklist,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.small,
        supportedSizes: [HomeWidgetSize.small],
        category: 'home_categoryRecord'.tr,
        builder:
            (context, config) => GenericIconWidget(
              icon: Icons.checklist,
              color: Colors.teal,
              name: 'checkin_widgetName'.tr,
            ),
      ),
    );

    // 2x2 详细卡片 - 显示统计信息
    registry.register(
      HomeWidget(
        id: 'checkin_overview',
        pluginId: 'checkin',
        name: 'checkin_overviewName'.tr,
        description: 'checkin_overviewDescription'.tr,
        icon: Icons.checklist_rtl,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.large,
        supportedSizes: [HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        builder: (context, config) => _buildOverviewWidget(context, config),
        availableStatsProvider: _getAvailableStats,
      ),
    );

    // 签到项目选择器小组件 - 快速访问指定签到项目
    registry.register(
      HomeWidget(
        id: 'checkin_item_selector',
        pluginId: 'checkin',
        name: 'checkin_quickAccess'.tr,
        description: 'checkin_quickAccessDesc'.tr,
        icon: Icons.access_time,
        color: Colors.teal,
        defaultSize: HomeWidgetSize.medium,
        supportedSizes: [HomeWidgetSize.medium, HomeWidgetSize.large],
        category: 'home_categoryRecord'.tr,
        selectorId: 'checkin.item',
        dataRenderer: _renderCheckinItemData,
        navigationHandler: _navigateToCheckinItem,
        dataSelector: _extractCheckinItemData,
        builder:
            (context, config) => GenericSelectorWidget(
              widgetDefinition: registry.getWidget('checkin_item_selector')!,
              config: config,
            ),
      ),
    );
  }

  /// 从选择器数据数组中提取小组件需要的数据
  static Map<String, dynamic> _extractCheckinItemData(List<dynamic> dataArray) {
    // 处理 CheckinItem 对象或 Map
    Map<String, dynamic> itemData;
    final rawData = dataArray[0];

    if (rawData is Map<String, dynamic>) {
      itemData = rawData;
    } else if (rawData is dynamic && rawData.toJson != null) {
      // CheckinItem 等对象通过 toJson() 转换
      itemData = rawData.toJson() as Map<String, dynamic>;
    } else {
      itemData = {};
    }

    return {
      'id': itemData['id'] as String?,
      'name': itemData['name'] as String?,
      'group': itemData['group'] as String?,
      'icon': itemData['icon'] as int?,
      'color': itemData['color'] as int?,
    };
  }

  /// 获取可用的统计项
  static List<StatItemData> _getAvailableStats(BuildContext context) {
    try {
      final plugin =
          PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
      if (plugin == null) return [];

      final todayCheckins = plugin.getTodayCheckins();
      final totalItems = plugin.checkinItems.length;
      final totalCheckins = plugin.getTotalCheckins();

      return [
        StatItemData(
          id: 'today_checkin',
          label: 'checkin_todayCheckin'.tr,
          value: '$todayCheckins/$totalItems',
          highlight: todayCheckins > 0,
          color: Colors.teal,
        ),
        StatItemData(
          id: 'total_count',
          label: 'checkin_totalCheckinCount'.tr,
          value: '$totalCheckins',
          highlight: false,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  /// 构建 2x2 详细卡片组件
  static Widget _buildOverviewWidget(
    BuildContext context,
    Map<String, dynamic> config,
  ) {
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
      final availableItems = _getAvailableStats(context);

      // 使用通用小组件
      return GenericPluginWidget(
        pluginId: 'checkin',
        pluginName: 'checkin_name'.tr,
        pluginIcon: Icons.checklist,
        pluginDefaultColor: Colors.teal,
        availableItems: availableItems,
        config: widgetConfig,
      );
    } catch (e) {
      return _buildErrorWidget(context, e.toString());
    }
  }

  /// 构建错误提示组件
  static Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'home_loadFailed'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ===== 签到项目选择器小组件相关方法 =====

  /// 渲染签到项目数据
  static Widget _renderCheckinItemData(
    BuildContext context,
    SelectorResult result,
    Map<String, dynamic> config,
  ) {
    final theme = Theme.of(context);

    if (result.data == null) {
      return _buildErrorWidget(context, '数据不存在');
    }

    // 处理 CheckinItem 对象或 Map
    Map<String, dynamic> itemData;
    if (result.data is Map<String, dynamic>) {
      itemData = result.data as Map<String, dynamic>;
    } else if (result.data is dynamic && result.data.toJson != null) {
      itemData = result.data.toJson() as Map<String, dynamic>;
    } else {
      return _buildErrorWidget(context, '数据类型错误');
    }

    final name = itemData['name'] as String? ?? '未知项目';
    final group = itemData['group'] as String?;
    final iconCode = itemData['icon'] as int? ?? 57455;
    final colorValue = itemData['color'] as int? ?? 4280391411;
    final itemId = itemData['id'] as String?;

    // 获取今日打卡状态
    bool isCheckedToday = false;
    CheckinItem? checkinItem;
    if (itemId != null) {
      try {
        final plugin =
            PluginManager.instance.getPlugin('checkin') as CheckinPlugin?;
        if (plugin != null) {
          final items = plugin.checkinItems;
          checkinItem = items.firstWhere(
            (i) => i.id == itemId,
            orElse: () => throw Exception('not found'),
          );
          isCheckedToday = checkinItem.isCheckedToday();
        }
      } catch (e) {
        isCheckedToday = false;
      }
    }

    final itemColor = Color(colorValue);

    // 获取卡片大小
    final widgetSize = config['widgetSize'] as HomeWidgetSize?;
    final showHeatmap = widgetSize == HomeWidgetSize.medium ||
        widgetSize == HomeWidgetSize.large;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 习惯图标和标题（占据左上角）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconData(iconCode, fontFamily: 'MaterialIcons'),
                  color: itemColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (group != null)
                      Text(
                        group,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 右上角打卡状态
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      isCheckedToday
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isCheckedToday
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedToday ? Icons.check_circle : Icons.circle_outlined,
                      size: 14,
                      color: isCheckedToday ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCheckedToday ? '已打卡' : '未打卡',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCheckedToday ? Colors.green : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 热力图（根据卡片大小显示不同范围）
          if (showHeatmap && checkinItem != null) ...[
            const SizedBox(height: 12),
            _buildHeatmapGrid(context, checkinItem, itemColor, widgetSize!),
          ],
        ],
      ),
    );
  }

  /// 构建热力图网格
  static Widget _buildHeatmapGrid(
    BuildContext context,
    CheckinItem item,
    Color itemColor,
    HomeWidgetSize size,
  ) {
    final days = size == HomeWidgetSize.medium ? 7 : 30;
    final today = DateTime.now();
    final List<bool> checkStatus = [];

    // 获取过去N天的打卡状态
    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      checkStatus.add(
        item.checkInRecords.containsKey(dateStr) &&
            item.checkInRecords[dateStr]!.isNotEmpty,
      );
    }

    final cellSize = size == HomeWidgetSize.medium ? 18.0 : 12.0;
    final spacing = size == HomeWidgetSize.medium ? 4.0 : 3.0;

    // 对于medium(7天)，一行显示；对于large(30天)，每行7个
    final crossAxisCount = size == HomeWidgetSize.medium ? 7 : 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final totalSpacing = (crossAxisCount - 1) * spacing;
        final availableWidth = maxWidth - totalSpacing;
        final calculatedCellSize = (availableWidth / crossAxisCount).clamp(8.0, cellSize);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: checkStatus.map((checked) {
            return Container(
              width: calculatedCellSize,
              height: calculatedCellSize,
              decoration: BoxDecoration(
                color: checked
                    ? itemColor.withOpacity(0.6)
                    : itemColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(calculatedCellSize / 3),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 导航到签到项目详情
  static void _navigateToCheckinItem(
    BuildContext context,
    SelectorResult result,
  ) {
    // 从 result.data 获取已转换的数据（由 dataSelector 处理）
    final data =
        result.data is Map<String, dynamic>
            ? result.data as Map<String, dynamic>
            : {};
    final itemId = data['id'] as String?;

    if (itemId != null) {
      NavigationHelper.pushNamed(
        context,
        '/checkin',
        arguments: {'itemId': itemId},
      );
    }
  }
}
