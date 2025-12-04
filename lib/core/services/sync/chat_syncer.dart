import 'package:flutter/material.dart';
import '../../../plugins/chat/chat_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 聊天插件同步器
class ChatSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    if (!isWidgetSupported()) {
      return;
    }

    await syncSafely('chat', () async {
      final plugin = PluginManager.instance.getPlugin('chat') as ChatPlugin?;
      if (plugin == null) return;

      final channels = plugin.channelService.channels;
      final channelCount = channels.length;

      int totalMessageCount = 0;
      for (final channel in channels) {
        totalMessageCount += channel.messages.length;
      }

      await updateWidget(
        pluginId: 'chat',
        pluginName: '聊天',
        iconCodePoint: Icons.chat.codePoint,
        colorValue: Colors.lightGreen.value,
        stats: [
          WidgetStatItem(id: 'channels', label: '频道数', value: '$channelCount'),
          WidgetStatItem(
            id: 'messages',
            label: '消息数',
            value: '$totalMessageCount',
          ),
        ],
      );
    });
  }
}
