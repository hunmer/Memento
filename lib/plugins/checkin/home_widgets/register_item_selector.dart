/// 打卡插件 - 签到项目选择器小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册签到项目选择器小组件 - 快速访问指定签到项目
void registerItemSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_item_selector',
      pluginId: 'checkin',
      name: 'checkin_quickAccess'.tr,
      description: 'checkin_quickAccessDesc'.tr,
      icon: Icons.access_time,
      color: Colors.teal,
      defaultSize: const MediumSize(),
      supportedSizes: [
        const MediumSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.item',
      navigationHandler: _navigateToCheckinItem,
      dataSelector: extractCheckinItemData,
      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,
      builder: (context, config) {
        // 使用自定义 StatefulWidget 实现实时数据获取
        return _CheckinItemSelectorWidget(
          config: config,
          widgetDefinition: registry.getWidget('checkin_item_selector')!,
        );
      },
    ),
  );
}

/// 导航到签到项目详情
void _navigateToCheckinItem(
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
      '/checkin/item',
      arguments: {'itemId': itemId},
    );
  }
}

/// 内部 StatefulWidget 使用 LiveSelectorWidget 实现实时数据获取
class _CheckinItemSelectorWidget extends LiveSelectorWidget {
  const _CheckinItemSelectorWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'checkin_completed',
    'checkin_cancelled',
    'checkin_reset',
    'checkin_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) {
    // 从配置中提取项目数据
    final data = _extractCheckinItemData(config);
    return provideCommonWidgets(data);
  }

  @override
  String get widgetTag => 'CheckinItemSelector';

  /// 从配置中提取签到项目数据
  Map<String, dynamic> _extractCheckinItemData(Map<String, dynamic> config) {
    try {
      final selectorConfig = config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData = selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            return dataArray[0] as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      debugPrint('[CheckinItemSelector] 提取数据失败: $e');
    }
    return {};
  }

  /// 自定义空状态（显示"暂无签到项目"）
  @override
  Widget buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无签到项目',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
