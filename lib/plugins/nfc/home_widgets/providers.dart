// NFC 插件主页小组件数据提供者

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/screens/home_screen/models/plugin_widget_config.dart';

/// 获取可用的统计项
/// NFC 状态需要在运行时检查，这里只显示基本信息
List<StatItemData> getAvailableStats(BuildContext context) {
  return [
    StatItemData(
      id: 'nfc_status',
      label: 'NFC',
      value: 'nfc_pluginName'.tr,
      highlight: true,
      color: Colors.orange,
    ),
  ];
}
