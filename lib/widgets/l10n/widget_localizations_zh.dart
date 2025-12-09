import 'dart:ui';

import 'widget_localizations.dart';

class WidgetLocalizationsZh extends WidgetLocalizations {
  const WidgetLocalizationsZh() : super(const Locale('zh'));

  @override
  String get selectColor => '选择颜色';
  @override
  String get selectIcon => '选择图标';
  @override
  String get cancel => '取消';
  @override
  String get confirm => '确定';
  @override
  String get enableAutoRead => '启用自动朗读';
  @override
  String get enableAutoReadDescription => 'AI回复完成后自动朗读消息内容';
  @override
  String get jsConsole => 'JS Console';
  @override
  String get jsConsoleDescription => '测试 JavaScript API 功能';
  @override
  String get jsonDynamicWidget => 'JSON Dynamic Widget 测试';
  @override
  String get jsonDynamicWidgetDescription => '测试和预览动态 UI 组件';
  @override
  String get superCupertinoNavigation => 'Super Cupertino Navigation 测试';
  @override
  String get superCupertinoNavigationDescription => '测试 iOS 风格导航栏组件';
  @override
  String get notificationTest => '通知测试';
  @override
  String get floatingBallSettings => '悬浮球设置';
  @override
  String get floatingBallSettingsDescription => '管理系统级悬浮球功能';
  @override
  String get intentTest => 'Intent 测试';
  @override
  String get intentTestDescription => '测试动态 Intent 注册和深度链接';
  @override
  String get error => '错误';
  @override
  String get widgetSettings => '小组件设置';
  @override
  String get backgroundImage => '背景图片';
  @override
  String get set => '已设置';
  @override
  String get notSet => '未设置';
  @override
  String get iconColor => '图标颜色';
  @override
  String get customized => '已自定义';
  @override
  String get useDefault => '使用默认';
  @override
  String get backgroundColor => '背景颜色';
  @override
  String get backgroundWithoutImage => '无背景图片时生效';
  @override
  String get customColorWithTransparency => '自定义颜色（支持透明度）';
  @override
  String get emptyLayout => '空白布局';
  @override
  String get emptyLayoutDescription => '不包含任何小组件的空白布局';
  @override
  String get all1x1Widgets => '所有 1x1 小组件';
  @override
  String get all1x1WidgetsDescription => '添加所有支持 1x1 尺寸的小组件';
  @override
  String get all2x2Widgets => '所有 2x2 小组件';
  @override
  String get all2x2WidgetsDescription => '添加所有支持 2x2 尺寸的小组件';
  @override
  String get renameLayout => '重命名布局';
  @override
  String get confirmDelete => '确认删除';
  @override
  String get delete => '删除';
  @override
  String get confirmEmptyHistory => '确定要清空所有路由历史记录吗？';
  @override
  String get iconToImage => '图标转图片';
  @override
  String get superCupertinoTest => 'Super Cupertino 测试';

  // 新增 widgets 模块所需的国际化文本
  @override
  String get voiceBroadcastSettings => '语音播报设置';
  @override
  String get autoReadAIMessage => 'AI回复完成后自动朗读消息内容';
  @override
  String get convertIconToImage => '将图标转换为图片';
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
  String get confirmClear => '确认清空';
  @override
  String get confirmClearRouteHistory => '确定要清空所有路由历史记录吗？';

  // TTS 相关文本
  @override
  String get selectTTSService => '选择TTS服务';
  @override
  String get defaultLabel => '默认';
  @override
  String get noTTSServiceAvailable => '暂无可用的TTS服务，请先在TTS插件中配置';
  @override
  String get disabled => ' (已禁用)';

  // 路由历史相关文本
  @override
  String get routeHistory => '路由历史记录';
  @override
  String get clearHistory => '清空历史';
  @override
  String get noHistory => '暂无历史记录';
  @override
  String get visitPageAutoRecord => '访问页面后会自动记录';
  @override
  String visits(int count) => '访问${count}次';

  // 图标转图片说明
  @override
  String get iconToImageDescription =>
      '启用此选项后，选择的图标将被转换为 PNG 图片。'
      '这对于不支持图标显示的环境（如某些桌面应用）很有用。'
      '转换后的图片可以提供更好的视觉效果和兼容性。';
  @override
  String get searchIcons => '搜索图标...';
  @override
  String get whatIsIconToImage => '什么是图标转图片？';

  // 应用启动文本
  @override
  String get starting => '正在启动...';
}
