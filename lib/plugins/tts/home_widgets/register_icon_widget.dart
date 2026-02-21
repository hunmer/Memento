/// TTS 插件 - 图标组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_plugin_widget.dart';

/// 注册 TTS 图标小组件（1x1）
void registerTTSIconWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'tts_icon',
      pluginId: 'tts',
      name: 'tts_widgetName'.tr,
      description: 'tts_widgetDescription'.tr,
      icon: Icons.record_voice_over,
      color: Colors.purple,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize()],
      category: 'home_categoryTools'.tr,
      builder: (context, config) => GenericIconWidget(
        icon: Icons.record_voice_over,
        color: Colors.purple,
        name: 'tts_name'.tr,
      ),
    ),
  );
}
