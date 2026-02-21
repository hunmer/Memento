/// 联系人插件 - 最近联系人卡片组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';

// 导入 CommandWidgetsProvider
import 'package:Memento/plugins/contact/home_widgets/providers/command_widgets_provider.dart'
    as cmd;

/// 默认显示的公共小组件类型（私有）
const CommonWidgetId _defaultWidgetType = CommonWidgetId.recentContactCard;

/// 最近联系人卡片小组件（基于 LiveSelectorWidget）
///
/// 使用 recentContactCard 公共小组件，显示最近30天内的联系人列表
/// 不需要选择器，直接显示数据
class _RecentContactLiveWidget extends LiveSelectorWidget {
  const _RecentContactLiveWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  List<String> get eventListeners => const [
    'contact_created',
    'contact_updated',
    'contact_deleted',
  ];

  @override
  Future<Map<String, dynamic>> getLiveData(Map<String, dynamic> config) async {
    return cmd.ContactCommandWidgetsProvider.provideRecentContactCardData();
  }

  @override
  String get widgetTag => 'RecentContactWidget';

  @override
  Widget buildCommonWidget(
    BuildContext context,
    CommonWidgetId widgetId,
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CommonWidgetBuilder.build(
      context,
      widgetId,
      props,
      size,
      inline: true,
    );
  }
}

/// 注册 2x2 最近联系人卡片 - 显示最近30天内的联系人列表
void registerRecentContactCard(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'contact_recent',
      pluginId: 'contact',
      name: 'contact_recentCardName'.tr,
      description: 'contact_recentCardDescription'.tr,
      icon: Icons.people,
      color: Colors.deepPurple,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryTools'.tr,
      // 不需要选择器，直接使用公共小组件
      commonWidgetsProvider: (data) async {
        return cmd.ContactCommandWidgetsProvider.provideRecentContactCardData();
      },
      builder: (context, config) {
        return _RecentContactLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('contact_recent')!,
        );
      },
    ),
  );
}

/// 确保 config 包含默认的公共小组件配置
Map<String, dynamic> _ensureConfigHasCommonWidget(
  Map<String, dynamic> config,
) {
  final newConfig = Map<String, dynamic>.from(config);
  if (!newConfig.containsKey('selectorWidgetConfig')) {
    newConfig['selectorWidgetConfig'] = {
      'commonWidgetId': _defaultWidgetType.name,
      'usesCommonWidget': true,
      'commonWidgetProps': {},
    };
  }
  return newConfig;
}
