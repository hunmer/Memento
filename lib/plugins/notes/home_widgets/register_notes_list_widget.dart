/// 笔记插件 - 笔记列表组件注册
///
/// 注册笔记列表小组件，支持文件夹、标签、日期过滤
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import 'package:Memento/widgets/event_listener_container.dart';
import 'utils.dart' show notesColor;
import 'providers.dart';

/// 注册笔记列表小组件
void registerNotesListWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'notes_list_widget',
      pluginId: 'notes',
      name: 'notes_listWidgetName'.tr,
      description: 'notes_listWidgetDescription'.tr,
      icon: Icons.view_list,
      color: notesColor,
      defaultSize: const LargeSize(),
      supportedSizes: [const MediumSize(), const LargeSize()],
      category: 'home_categoryRecord'.tr,

      // 选择器配置
      selectorId: 'notes.list.config',

      // 公共组件提供者
      commonWidgetsProvider: provideNotesListWidgets,

      builder: (context, config) {
        return StatefulBuilder(
          builder: (context, setState) {
            return EventListenerContainer(
              events: const [
                'note_added',
                'note_updated',
                'note_deleted',
              ],
              onEvent: () => setState(() {}),
              child: GenericSelectorWidget(
                widgetDefinition: registry.getWidget('notes_list_widget')!,
                config: config,
              ),
            );
          },
        );
      },
    ),
  );
}
