/// 聊天插件 - 频道选择器组件注册
///
/// 注册频道选择器组件，支持快速访问指定频道和公共小组件
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'builders.dart';
import 'providers.dart';

/// 注册聊天频道选择器组件
///
/// 支持快速访问指定频道，并提供公共小组件功能
void registerChannelSelector(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'chat_channel_selector',
      pluginId: 'chat',
      name: 'chat_channelQuickAccess'.tr,
      description: 'chat_channelQuickAccessDesc'.tr,
      icon: Icons.chat,
      color: Colors.indigoAccent,
      defaultSize: const LargeSize(),
      category: 'home_categoryCommunication'.tr,

      selectorId: 'chat.channel',
      dataRenderer: renderChannelData,
      navigationHandler: navigateToChannel,
      dataSelector: extractChannelData,

      // 公共小组件提供者
      commonWidgetsProvider: provideCommonWidgets,

      builder: (context, config) {
        // 解析选择器配置
        SelectorWidgetConfig? selectorConfig;
        try {
          if (config.containsKey('selectorWidgetConfig')) {
            selectorConfig = SelectorWidgetConfig.fromJson(
              config['selectorWidgetConfig'] as Map<String, dynamic>,
            );
          }
        } catch (e) {
          debugPrint('[ChatHomeWidgets] 解析配置失败: $e');
        }

        // 未配置状态
        if (selectorConfig == null || !selectorConfig.isConfigured) {
          return buildUnconfiguredWidget(context);
        }

        // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'chat_message_sent',
                'chat_message_updated',
              ],
              onEvent: () => setState(() {}),
              child: buildSelectorContent(context, config, selectorConfig!),
            );
          },
        );
      },
    ),
  );
}
