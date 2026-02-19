/// 纪念日插件 - 纪念日选择器组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'providers.dart';

/// 注册纪念日快捷入口 - 选择纪念日后显示倒计时
void registerMemorialSelectorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'day_memorial_selector',
      pluginId: 'day',
      name: 'day_memorialSelectorName'.tr,
      description: 'day_memorialSelectorDescription'.tr,
      icon: Icons.celebration,
      color: Colors.black87,
      defaultSize: const LargeSize(),
      supportedSizes: [const LargeSize()],
      category: 'home_categoryRecord'.tr,
      selectorId: 'day.memorial',
      dataSelector: extractMemorialDayData,
      navigationHandler: navigateToMemorialDay,
      // 使用公共小组件提供者
      commonWidgetsProvider: provideMemorialDayCommonWidgets,
      builder: (context, config) {
        // 使用 LiveSelectorWidget 实现实时数据获取
        return _MemorialSelectorWidget(
          config: config,
          widgetDefinition: registry.getWidget('day_memorial_selector')!,
        );
      },
    ),
  );
}

/// 内部 StatefulWidget 使用 LiveSelectorWidget 实现实时数据获取
class _MemorialSelectorWidget extends LiveSelectorWidget {
  const _MemorialSelectorWidget({
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'memorial_day_added',
    'memorial_day_updated',
    'memorial_day_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    // 从配置中提取纪念日数据
    final data = _extractMemorialDayData(config);
    return await provideMemorialDayCommonWidgets(data);
  }

  @override
  String get widgetTag => 'MemorialSelector';

  /// 从配置中提取纪念日数据
  Map<String, dynamic> _extractMemorialDayData(Map<String, dynamic> config) {
    try {
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData =
            selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            // 使用 extractMemorialDayData 处理 MemorialDay 对象和 Map 的转换
            return extractMemorialDayData(dataArray);
          }
        }
      }
    } catch (e) {
      debugPrint('[MemorialSelector] 提取数据失败: $e');
    }
    return {};
  }

  /// 自定义空状态（显示"暂无纪念日"）
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
              Icons.celebration,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无纪念日',
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
