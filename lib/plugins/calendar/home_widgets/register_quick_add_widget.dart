/// 日历插件 - 快速添加事件组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import '../calendar_plugin.dart';

/// 日历插件颜色
const Color _calendarColor = Color.fromARGB(255, 211, 91, 91);

/// 注册快速添加事件组件
void registerQuickAddWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'calendar_quick_add',
      pluginId: 'calendar',
      name: 'calendar_quickAddEvent'.tr,
      description: 'calendar_quickAddEventDesc'.tr,
      icon: Icons.add_circle_outline,
      color: _calendarColor,
      defaultSize: HomeWidgetSize.small,
      supportedSizes: [HomeWidgetSize.small],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => _buildQuickAddWidget(context),
    ),
  );
}

/// 构建 1x1 快速添加事件组件
Widget _buildQuickAddWidget(BuildContext context) {
  final theme = Theme.of(context);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _navigateToAddEvent(context),
      child: SizedBox.expand(
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标在中间，标题在下边，图标右上角带加号 badge
                Stack(
                  alignment: Alignment.topRight,
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.event, size: 40, color: _calendarColor),
                    // 图标右上角加号 badge
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _calendarColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primaryContainer,
                            width: 2,
                          ),
                        ),
                        child: Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'calendar_quickAddEvent'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 跳转到添加事件页面
void _navigateToAddEvent(BuildContext context) {
  try {
    final calendarPlugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
    if (calendarPlugin != null) {
      calendarPlugin.showEventEditPage(context);
    }
  } catch (e) {
    debugPrint('[CalendarHomeWidgets] 跳转添加事件失败: $e');
  }
}
