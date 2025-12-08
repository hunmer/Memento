import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WidgetsLocalizations {
  const WidgetsLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _WidgetsLocalizationsDelegate();

  static WidgetsLocalizations of(BuildContext context) {
    return Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations)!;
  }

  // 通用组件文本
  String get selectColor => '选择颜色';
  String get selectIcon => '选择图标';
  String get cancel => '取消';
  String get confirm => '确定';
  String get enableAutoRead => '启用自动朗读';
  String get enableAutoReadDescription => 'AI回复完成后自动朗读消息内容';
  String get jsConsole => 'JS Console';
  String get jsConsoleDescription => '测试 JavaScript API 功能';
  String get jsonDynamicWidget => 'JSON Dynamic Widget 测试';
  String get jsonDynamicWidgetDescription => '测试和预览动态 UI 组件';
  String get superCupertinoNavigation => 'Super Cupertino Navigation 测试';
  String get superCupertinoNavigationDescription => '测试 iOS 风格导航栏组件';
  String get notificationTest => '通知测试';
  String get floatingBallSettings => '悬浮球设置';
  String get floatingBallSettingsDescription => '管理系统级悬浮球功能';
  String get intentTest => 'Intent 测试';
  String get intentTestDescription => '测试动态 Intent 注册和深度链接';
  String get error => '错误';
  String get widgetSettings => '小组件设置';
  String get backgroundImage => '背景图片';
  String get set => '已设置';
  String get notSet => '未设置';
  String get iconColor => '图标颜色';
  String get customized => '已自定义';
  String get useDefault => '使用默认';
  String get backgroundColor => '背景颜色';
  String get backgroundWithoutImage => '无背景图片时生效';
  String get customColorWithTransparency => '自定义颜色（支持透明度）';
  String get emptyLayout => '空白布局';
  String get emptyLayoutDescription => '不包含任何小组件的空白布局';
  String get all1x1Widgets => '所有 1x1 小组件';
  String get all1x1WidgetsDescription => '添加所有支持 1x1 尺寸的小组件';
  String get all2x2Widgets => '所有 2x2 小组件';
  String get all2x2WidgetsDescription => '添加所有支持 2x2 尺寸的小组件';
  String get renameLayout => '重命名布局';
  String get confirmDelete => '确认删除';
  String get delete => '删除';
  String get confirmEmptyHistory => '确定要清空所有路由历史记录吗？';
  String get iconToImage => '图标转图片';
  String get superCupertinoTest => 'Super Cupertino 测试';

  // 新增 widgets 模块所需的国际化文本
  String get voiceBroadcastSettings => '语音播报设置';
  String get autoReadAIMessage => 'AI回复完成后自动朗读消息内容';
  String get convertIconToImage => '将图标转换为图片';
  String get noDataAvailable => 'No data available';
  String get noDataPoints => 'No data points';
  String get noData => 'No data';

  // 时间相关文本
  String get time0000 => '00:00';
  String get time0600 => '06:00';
  String get time1200 => '12:00';
  String get time1800 => '18:00';
  String get time2400 => '24:00';

  // 确认操作文本
  String get confirmClear => '确认清空';
  String get confirmClearRouteHistory => '确定要清空所有路由历史记录吗？';

  // TTS 相关文本
  String get selectTTSService => '选择TTS服务';
  String get defaultLabel => '默认';
  String get noTTSServiceAvailable => '暂无可用的TTS服务，请先在TTS插件中配置';
  String get disabled => ' (已禁用)';

  // 路由历史相关文本
  String get routeHistory => '路由历史记录';
  String get clearHistory => '清空历史';
  String get noHistory => '暂无历史记录';
  String get visitPageAutoRecord => '访问页面后会自动记录';
  String visits(int count) => '访问${count}次';

  // 图标转图片说明
  String get iconToImageDescription => '启用此选项后，选择的图标将被转换为 PNG 图片。'
      '这对于不支持图标显示的环境（如某些桌面应用）很有用。'
      '转换后的图片可以提供更好的视觉效果和兼容性。';
  String get searchIcons => '搜索图标...';
  String get whatIsIconToImage => '什么是图标转图片？';

  // 应用启动文本
  String get starting => '正在启动...';
}

class _WidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return WidgetsLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<WidgetsLocalizations> old) => false;
}