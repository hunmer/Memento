/// 打卡插件 - 多选签到项目小组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册多选签到项目小组件 - 显示多个签到项目的打卡状态
void registerItemsSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'checkin_items_selector',
      pluginId: 'checkin',
      name: 'checkin_multiQuickAccess'.tr,
      description: 'checkin_multiQuickAccessDesc'.tr,
      icon: Icons.dashboard,
      color: Colors.teal,
      defaultSize: const LargeSize(),
      supportedSizes: [
        const LargeSize(),
        const CustomSize(width: -1, height: -1),
      ],
      category: 'home_categoryRecord'.tr,
      selectorId: 'checkin.items',
      navigationHandler: _navigateToCheckinItems,
      dataSelector: extractCheckinsData,
      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgetsForMultiple,
      builder: (context, config) {
        // 使用自定义 StatefulWidget 实现实时数据获取
        return _CheckinItemsSelectorWidget(
          config: config,
          widgetDefinition: registry.getWidget('checkin_items_selector')!,
        );
      },
    ),
  );
}

/// 导航到签到项目列表（多选模式）
void _navigateToCheckinItems(BuildContext context, dynamic result) {
  // 多选模式默认导航到签到主列表
  NavigationHelper.pushNamed(context, '/checkin');
}

/// 内部 StatefulWidget 使用 LiveSelectorWidget 实现实时数据获取
class _CheckinItemsSelectorWidget extends LiveSelectorWidget {
  const _CheckinItemsSelectorWidget({
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
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    // 从配置中提取多个签到项目数据
    final data = _extractCheckinsData(config);
    return await provideCommonWidgetsForMultiple(data);
  }

  @override
  String get widgetTag => 'CheckinItemsSelector';

  /// 从配置中提取多个签到项目数据
  Map<String, dynamic> _extractCheckinsData(Map<String, dynamic> config) {
    try {
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData =
            selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            // 使用 extractCheckinsData 处理 CheckinItem 对象和 Map 的转换
            return extractCheckinsData(dataArray);
          }
        }
      }
    } catch (e) {
      debugPrint('[CheckinItemsSelector] 提取数据失败: $e');
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
              Icons.dashboard,
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
