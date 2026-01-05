part of 'webview_plugin.dart';

// ==================== 数据选择器注册 ====================

/// 注册数据选择器
void _registerDataSelectors() {
  PluginDataSelectorService.instance.registerSelector(
    SelectorDefinition(
      id: 'webview.card',
      pluginId: 'webview',
      name: 'webview_cardSelectorName'.tr,
      description: 'webview_cardSelectorDesc'.tr,
      icon: Icons.link,
      color: WebviewPlugin.instance.color,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'select_card',
          title: 'webview_selectCard'.tr,
          viewType: SelectorViewType.list,
          dataLoader: (previousSelections) async {
            // 加载所有卡片
            final cards = WebviewPlugin.instance.cardManager.getAllCards();
            return cards.map((card) => SelectableItem(
              id: card.id,
              title: card.title,
              subtitle: card.url,
              icon: Icons.language,
              color: card.type == CardType.localFile ? Colors.green : null,
              rawData: card.toJson(),
            )).toList();
          },
          isFinalStep: true,
        ),
      ],
    ),
  );
}
