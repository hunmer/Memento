/// 纪念日插件 - 纪念日选择器组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import '../day_plugin.dart';
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
    try {
      final selectorConfig =
          config['selectorWidgetConfig'] as Map<String, dynamic>?;
      if (selectorConfig != null) {
        final selectedData =
            selectorConfig['selectedData'] as Map<String, dynamic>?;
        if (selectedData != null && selectedData.containsKey('data')) {
          final dataArray = selectedData['data'] as List<dynamic>?;
          if (dataArray != null && dataArray.isNotEmpty) {
            // 从 dataArray 中获取纪念日的 ID
            final firstItem = dataArray[0];
            String? memorialDayId;

            if (firstItem is Map<String, dynamic>) {
              memorialDayId = firstItem['id'] as String?;
            } else if (firstItem is Map) {
              memorialDayId = firstItem['id'] as String?;
            }

            // 从 plugin 重新获取最新的纪念日数据
            if (memorialDayId != null) {
              final plugin = PluginManager.instance.getPlugin('day') as DayPlugin?;
              debugPrint('[${widgetTag}] Plugin instance hash: ${plugin.hashCode}');
              if (plugin != null) {
                final memorialDay = plugin.getMemorialDayById(memorialDayId);
                if (memorialDay != null) {
                  // 将最新的 MemorialDay 对象转换为 Map 数据格式
                  final data = {
                    'id': memorialDay.id,
                    'title': memorialDay.title,
                    'targetDate': memorialDay.targetDate.toIso8601String(),
                    'backgroundImageUrl': memorialDay.backgroundImageUrl,
                    'backgroundColor': memorialDay.backgroundColor.value,
                    'daysRemaining': memorialDay.daysRemaining,
                    'daysPassed': memorialDay.daysPassed,
                    'isToday': memorialDay.isToday,
                    'isExpired': memorialDay.isExpired,
                  };
                  debugPrint('[${widgetTag}] Refreshed memorial day: ${memorialDay.title}, daysRemaining: ${memorialDay.daysRemaining}');
                  return await provideMemorialDayCommonWidgets(data);
                } else {
                  debugPrint('[${widgetTag}] Memorial day not found: $memorialDayId (may have been deleted)');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[${widgetTag}] getLiveData error: $e');
    }
    return {};
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
