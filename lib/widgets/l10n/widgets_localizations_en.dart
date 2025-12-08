import 'dart:ui';

import 'widgets_localizations.dart';

class WidgetsLocalizationsEn extends WidgetsLocalizations {
  const WidgetsLocalizationsEn() : super(const Locale('en'));

  @override
  String get selectColor => 'Select Color';
  @override
  String get selectIcon => 'Select Icon';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get enableAutoRead => 'Enable Auto Read';
  @override
  String get enableAutoReadDescription =>
      'Automatically read message content after AI reply is complete';
  @override
  String get jsConsole => 'JS Console';
  @override
  String get jsConsoleDescription => 'Test JavaScript API functionality';
  @override
  String get jsonDynamicWidget => 'JSON Dynamic Widget Test';
  @override
  String get jsonDynamicWidgetDescription =>
      'Test and preview dynamic UI components';
  @override
  String get superCupertinoNavigation => 'Super Cupertino Navigation Test';
  @override
  String get superCupertinoNavigationDescription =>
      'Test iOS style navigation bar component';
  @override
  String get notificationTest => 'Notification Test';
  @override
  String get floatingBallSettings => 'Floating Ball Settings';
  @override
  String get floatingBallSettingsDescription =>
      'Manage system-level floating ball functionality';
  @override
  String get intentTest => 'Intent Test';
  @override
  String get intentTestDescription =>
      'Test dynamic Intent registration and deep linking';
  @override
  String get error => 'Error';
  @override
  String get widgetSettings => 'Widget Settings';
  @override
  String get backgroundImage => 'Background Image';
  @override
  String get set => 'Set';
  @override
  String get notSet => 'Not Set';
  @override
  String get iconColor => 'Icon Color';
  @override
  String get customized => 'Customized';
  @override
  String get useDefault => 'Use Default';
  @override
  String get backgroundColor => 'Background Color';
  @override
  String get backgroundWithoutImage => 'Effective when no background image';
  @override
  String get customColorWithTransparency =>
      'Custom color (with transparency support)';
  @override
  String get emptyLayout => 'Empty Layout';
  @override
  String get emptyLayoutDescription => 'Blank layout without any widgets';
  @override
  String get all1x1Widgets => 'All 1x1 Widgets';
  @override
  String get all1x1WidgetsDescription => 'Add all widgets supporting 1x1 size';
  @override
  String get all2x2Widgets => 'All 2x2 Widgets';
  @override
  String get all2x2WidgetsDescription => 'Add all widgets supporting 2x2 size';
  @override
  String get renameLayout => 'Rename Layout';
  @override
  String get confirmDelete => 'Confirm Delete';
  @override
  String get delete => 'Delete';
  @override
  String get confirmEmptyHistory =>
      'Are you sure you want to clear all route history?';
  @override
  String get iconToImage => 'Icon to Image';
  @override
  String get superCupertinoTest => 'Super Cupertino Test';

  // 新增 widgets 模块所需的国际化文本
  @override
  String get voiceBroadcastSettings => 'Voice Broadcast Settings';
  @override
  String get autoReadAIMessage => 'Automatically read message content after AI reply is complete';
  @override
  String get convertIconToImage => 'Convert icon to image';
  @override
  String get noDataAvailable => 'No data available';
  @override
  String get noDataPoints => 'No data points';
  @override
  String get noData => 'No data';

  // 时间相关文本
  @override
  String get time0000 => '00:00';
  @override
  String get time0600 => '06:00';
  @override
  String get time1200 => '12:00';
  @override
  String get time1800 => '18:00';
  @override
  String get time2400 => '24:00';

  // 确认操作文本
  @override
  String get confirmClear => 'Confirm Clear';
  @override
  String get confirmClearRouteHistory => 'Are you sure you want to clear all route history?';

  // TTS 相关文本
  @override
  String get selectTTSService => 'Select TTS Service';
  @override
  String get defaultLabel => 'Default';
  @override
  String get noTTSServiceAvailable => 'No TTS services available, please configure in TTS plugin first';
  @override
  String get disabled => ' (Disabled)';

  // 路由历史相关文本
  @override
  String get routeHistory => 'Route History';
  @override
  String get clearHistory => 'Clear History';
  @override
  String get noHistory => 'No history records';
  @override
  String get visitPageAutoRecord => 'Pages visited will be automatically recorded';
  @override
  String visits(int count) => 'Visited ${count} time${count != 1 ? 's' : ''}';

  // 图标转图片说明
  @override
  String get iconToImageDescription => 'When this option is enabled, the selected icon will be converted to a PNG image. '
      'This is useful for environments that do not support icon display (such as certain desktop applications). '
      'The converted image can provide better visual effects and compatibility.';
  @override
  String get searchIcons => 'Search icons...';
  @override
  String get whatIsIconToImage => 'What is icon to image?';

  // 应用启动文本
  @override
  String get starting => 'Starting...';
}
