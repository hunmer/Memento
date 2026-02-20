/// 聊天插件 - 主页小组件构建函数
///
/// 提供各种小组件的构建器函数
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'package:Memento/plugins/chat/chat_plugin.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'providers.dart';
import 'utils.dart';

/// 构建未配置状态的占位小组件
Widget buildUnconfiguredWidget(BuildContext context) {
  final theme = Theme.of(context);
  return SizedBox.expand(
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            '点击配置频道',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 构建选择器内容（实时获取最新数据）
Widget buildSelectorContent(
  BuildContext context,
  Map<String, dynamic> config,
  SelectorWidgetConfig selectorConfig,
) {
  // 从配置中获取频道ID
  final selectedData = selectorConfig.selectedData;
  if (selectedData == null) {
    return HomeWidget.buildErrorWidget(context, '配置数据无效');
  }

  // 获取频道ID
  final data = selectedData['data'];
  String? channelId;
  if (data is Map<String, dynamic>) {
    channelId = data['id'] as String?;
  } else if (data is List && data.isNotEmpty) {
    final firstItem = data[0];
    if (firstItem is Map<String, dynamic>) {
      channelId = firstItem['id'] as String?;
    }
  }

  if (channelId == null) {
    return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
  }

  // 检查是否使用公共小组件
  if (selectorConfig.usesCommonWidget) {
    return _buildCommonWidgetWithLiveData(
      context,
      config,
      channelId,
      selectorConfig.commonWidgetId!,
      selectorConfig.commonWidgetProps ?? {},
    );
  }

  // 使用自定义渲染器
  final widgetDef = HomeWidgetRegistry().getWidget('chat_channel_selector');
  if (widgetDef?.dataRenderer != null) {
    // 构建一个包含最新数据的 SelectorResult
    final liveData = getLiveChannelData(channelId);
    if (liveData == null) {
      return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
    }

    final result = SelectorResult(
      pluginId: 'chat',
      selectorId: 'chat.channel',
      path: [],
      data: liveData,
    );

    return widgetDef!.dataRenderer!(context, result, config);
  }

  return _buildChannelWidget(context, channelId);
}

/// 使用实时数据构建公共小组件
Widget _buildCommonWidgetWithLiveData(
  BuildContext context,
  Map<String, dynamic> config,
  String channelId,
  String commonWidgetId,
  Map<String, dynamic> savedProps,
) {
  // 获取实时频道数据
  final liveData = getLiveChannelData(channelId);
  if (liveData == null) {
    return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
  }

  // 转换为枚举
  final widgetIdEnum = CommonWidgetsRegistry.fromString(commonWidgetId);
  if (widgetIdEnum == null) {
    return HomeWidget.buildErrorWidget(context, '未知的公共组件: $commonWidgetId');
  }

  // 获取元数据
  final metadata = CommonWidgetsRegistry.getMetadata(widgetIdEnum);
  final size = config['widgetSize'] as HomeWidgetSize? ?? metadata.defaultSize;

  // 使用实时数据更新 props
  final liveProps = getLiveCommonWidgetProps(
    commonWidgetId,
    liveData,
    savedProps,
  );

  // 添加 custom 尺寸的实际宽高到 props 中
  if (size == const CustomSize(width: -1, height: -1)) {
    liveProps['customWidth'] = config['customWidth'] as int?;
    liveProps['customHeight'] = config['customHeight'] as int?;
  }

  return CommonWidgetBuilder.build(
    context,
    widgetIdEnum,
    liveProps,
    size,
    inline: true,
  );
}

/// 构建 2x2 详细卡片组件
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
      pluginId: 'chat',
      pluginName: 'chat_widgetName'.tr,
      pluginIcon: Icons.chat_bubble,
      pluginDefaultColor: Colors.indigoAccent,
      availableItems: availableItems,
      config: widgetConfig,
    );
  } catch (e) {
    return HomeWidget.buildErrorWidget(context, e.toString());
  }
}

/// 渲染选中的频道数据
Widget renderChannelData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  // 从初始化数据中获取频道ID
  final channelData = result.data as Map<String, dynamic>;
  final channelId = channelData['id'] as String?;

  if (channelId == null) {
    return HomeWidget.buildErrorWidget(context, 'chat_channelNotFound'.tr);
  }

  // 使用 StatefulBuilder 和 EventListenerContainer 实现动态更新
  return StatefulBuilder(
    builder: (context, setState) {
      return EventListenerContainer(
        events: const ['chat_message_sent', 'chat_message_updated'],
        onEvent: () => setState(() {}),
        child: _buildChannelWidget(context, channelId),
      );
    },
  );
}

/// 构建频道小组件内容（获取最新数据）
Widget _buildChannelWidget(BuildContext context, String channelId) {
  // 从 PluginManager 获取最新的频道数据
  final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
  if (plugin == null) {
    return HomeWidget.buildErrorWidget(context, 'chat_pluginNotAvailable'.tr);
  }

  // 查找对应频道
  final channel = plugin.channelService.channels.firstWhere(
    (c) => c.id == channelId,
    orElse: () => throw Exception('频道不存在'),
  );

  // 使用最新的频道数据
  final title = channel.title;
  final lastMessage = channel.lastMessage?.content ?? '';
  final lastMessageTime = channel.lastMessage?.date ?? DateTime.now();
  final messageCount = channel.messages.length;
  final channelIcon = channel.icon;
  final channelColor = channel.backgroundColor;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: channelColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(channelIcon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 最后一条消息预览
            if (lastMessage.isNotEmpty)
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lastMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'chat_noMessages'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // 底部信息栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧：消息数
                Text(
                  'chat_messageCount'.trParams({'count': '$messageCount'}),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                // 右侧：时间
                Text(
                  formatDateTime(lastMessageTime),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// 导航到选中的频道
void navigateToChannel(BuildContext context, SelectorResult result) {
  final channelData = result.data as Map<String, dynamic>;
  final channelId = channelData['id'] as String;

  NavigationHelper.pushNamed(
    context,
    '/chat/channel',
    arguments: {'channelId': channelId},
  );
}
