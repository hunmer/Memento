import 'package:flutter/material.dart';
import '../../../plugins/contact/contact_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// 联系人插件同步器
class ContactSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('contact', () async {
      final plugin = PluginManager.instance.getPlugin('contact') as ContactPlugin?;
      if (plugin == null) return;

      final allContacts = await plugin.controller.getAllContacts();
      final totalContacts = allContacts.length;
      final todayInteractionCount = await plugin.controller.getTodayInteractionCount();
      final recentContactsCount = await plugin.controller.getRecentlyContactedCount();

      await updateWidget(
        pluginId: 'contact',
        pluginName: '联系人',
        iconCodePoint: Icons.contacts.codePoint,
        colorValue: Colors.lightBlue.value,
        stats: [
          WidgetStatItem(
            id: 'total',
            label: '总联系人数',
            value: '$totalContacts',
          ),
          WidgetStatItem(
            id: 'today_interaction',
            label: '今日互动次数',
            value: '$todayInteractionCount',
            highlight: todayInteractionCount > 0,
            colorValue: todayInteractionCount > 0 ? Colors.orange.value : null,
          ),
          WidgetStatItem(
            id: 'recent',
            label: '最近联系人数',
            value: '$recentContactsCount',
          ),
        ],
      );
    });
  }
}
