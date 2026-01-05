part of 'openai_plugin.dart';

/// 注册数据选择器
void _registerDataSelectors() {
  final agentController = AgentController();
  final presetService = PromptPresetService();

  // 1. AI 助手选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'openai.agent',
      pluginId: id,
      name: '选择 AI 助手',
      description: '选择一个 AI 助手',
      icon: Icons.smart_toy,
      color: color,
      steps: [
        SelectorStep(
          id: 'agent',
          title: 'AI 助手列表',
          viewType: SelectorViewType.grid,
          gridCrossAxisCount: 2,
          gridChildAspectRatio: 0.85,
          isFinalStep: true,
          emptyText: '暂无 AI 助手',
          dataLoader: (_) async {
            final agents = await agentController.loadAgents();
            return agents
                .map(
                  (agent) => SelectableItem(
                    id: agent.id,
                    title: agent.name,
                    subtitle:
                        agent.description.isEmpty
                            ? agent.model
                            : agent.description,
                    icon: agent.icon,
                    color: agent.iconColor,
                    avatarPath: agent.avatarUrl,
                    rawData: agent,
                    metadata: {'model': agent.model},
                  ),
                )
                .toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(lowerQuery) ||
                      (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                          false),
                )
                .toList();
          },
        ),
      ],
    ),
  );

  // 2. Prompt 预设选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'openai.prompt',
      pluginId: id,
      name: '选择 Prompt 预设',
      description: '选择一个提示词预设',
      icon: Icons.description,
      color: color,
      steps: [
        SelectorStep(
          id: 'prompt',
          title: 'Prompt 列表',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          emptyText: '暂无 Prompt 预设',
          dataLoader: (_) async {
            await presetService.loadPresets();
            return presetService.presets
                .map(
                  (preset) => SelectableItem(
                    id: preset.id,
                    title: preset.name,
                    subtitle:
                        preset.description.isEmpty
                            ? (preset.content.length > 50
                                ? '${preset.content.substring(0, 50)}...'
                                : preset.content)
                            : preset.description,
                    icon: Icons.text_snippet,
                    rawData: preset,
                    metadata: {'category': preset.category},
                  ),
                )
                .toList();
          },
          searchFilter: (items, query) {
            final lowerQuery = query.toLowerCase();
            return items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(lowerQuery) ||
                      (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                          false),
                )
                .toList();
          },
        ),
      ],
    ),
  );
}
