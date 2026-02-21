/// 联系人插件 - 联系人卡片组件注册（公共小组件）
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/base/live_selector_widget.dart';
import 'package:Memento/screens/home_screen/widgets/selector_widget_types.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import '../home_widgets/providers/command_widgets_provider.dart' as cmd;

/// 默认显示的公共小组件类型（私有）
const CommonWidgetId _defaultWidgetType = CommonWidgetId.contactCard;

/// 联系人卡片小组件（基于 LiveSelectorWidget）
///
/// 默认显示 contactNotFoundCard 公共小组件，支持实时更新
class _ContactPersonLiveWidget extends LiveSelectorWidget {
  const _ContactPersonLiveWidget({
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
    // 解析选择器配置，获取用户选择的联系人数据
    String contactId = '';
    try {
      if (config.containsKey('selectorWidgetConfig')) {
        final selectorConfig = SelectorWidgetConfig.fromJson(
          config['selectorWidgetConfig'] as Map<String, dynamic>,
        );
        // 从 selectedData 中提取联系人 ID
        // selectedData 结构来自 SelectorResult.toMap()，包含 data 字段
        if (selectorConfig.selectedData != null) {
          final selectedData = selectorConfig.selectedData!;
          final data = selectedData['data'];

          // data 可能是列表（多选）或单个对象
          if (data is List && data.isNotEmpty) {
            final contactJson = data[0] as Map<String, dynamic>;
            contactId = contactJson['id'] as String? ?? '';
          } else if (data is Map<String, dynamic>) {
            contactId = data['id'] as String? ?? '';
          }
        }
      }
    } catch (e) {
      debugPrint('[ContactPersonWidget] 解析选择器数据失败: $e');
    }

    // 使用联系人 ID 获取实时数据
    return cmd.ContactCommandWidgetsProvider.provideContactCardData(contactId);
  }

  @override
  String get widgetTag => 'ContactPersonWidget';

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

/// 注册 2x1 联系人卡片 - 选择一个联系人显示（公共小组件，无配置）
void registerPersonCardWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'contact_person',
      pluginId: 'contact',
      name: 'contact_personCardName'.tr,
      description: 'contact_personCardDescription'.tr,
      icon: Icons.person,
      color: Colors.deepPurple,
      defaultSize: const MediumSize(),
      supportedSizes: [const MediumSize()],
      category: 'home_categoryTools'.tr,
      // 配置使用联系人选择器
      selectorId: 'contact.person',
      commonWidgetsProvider: (data) async {
        final contactId = data['id'] as String? ?? '';
        return cmd.ContactCommandWidgetsProvider.provideContactCardData(contactId);
      },
      dataSelector: (dataArray) {
        final contactJson = dataArray[0] as Map<String, dynamic>;
        return {
          'id': contactJson['id'] as String,
          'name': contactJson['name'] as String?,
          'phone': contactJson['phone'] as String?,
        };
      },
      navigationHandler: navigateToContactDetail,
      builder: (context, config) {
        return _ContactPersonLiveWidget(
          config: _ensureConfigHasCommonWidget(config),
          widgetDefinition: registry.getWidget('contact_person')!,
        );
      },
    ),
  );
}

/// 导航到联系人详情页
void navigateToContactDetail(BuildContext context, SelectorResult result) {
  final data =
      result.data is Map<String, dynamic>
          ? result.data as Map<String, dynamic>
          : {};
  final contactId = data['id'] as String?;

  if (contactId == null || contactId.isEmpty) {
    debugPrint('联系人 ID 为空，无法导航');
    return;
  }

  NavigationHelper.pushNamed(
    context,
    '/contact/detail',
    arguments: {'contactId': contactId},
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
