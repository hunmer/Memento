import 'package:flutter/material.dart';
import '../../../plugins/openai/openai_plugin.dart';
import '../../plugin_manager.dart';
import 'plugin_widget_syncer.dart';
import 'package:memento_widgets/memento_widgets.dart';

/// OpenAI插件同步器
class OpenaiSyncer extends PluginWidgetSyncer {
  @override
  Future<void> sync() async {
    await syncSafely('openai', () async {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin?;
      if (plugin == null) return;

      final totalAgents = await plugin.getTotalAgentsCount();
      final todayRequests = await plugin.getTodayRequestCount();
      final availableModels = await plugin.getAvailableModelsCount();

      await updateWidget(
        pluginId: 'openai',
        pluginName: 'AI助手',
        iconCodePoint: Icons.psychology.codePoint,
        colorValue: Colors.deepPurple.value,
        stats: [
          WidgetStatItem(
            id: 'assistants',
            label: '总助手',
            value: '$totalAgents',
            highlight: totalAgents > 0,
            colorValue: totalAgents > 0 ? Colors.deepPurple.value : null,
          ),
          WidgetStatItem(
            id: 'requests',
            label: '今日请求',
            value: '$todayRequests',
            highlight: todayRequests > 0,
            colorValue: todayRequests > 0 ? Colors.green.value : null,
          ),
          WidgetStatItem(
            id: 'models',
            label: '可用模型',
            value: '$availableModels',
          ),
        ],
      );
    });
  }
}
