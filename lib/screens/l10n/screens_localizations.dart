import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens_localizations_en.dart';
import 'screens_localizations_zh.dart';

class ScreensLocalizations {
  const ScreensLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<ScreensLocalizations> delegate =
      _ScreensLocalizationsDelegate();

  static ScreensLocalizations of(BuildContext context) {
    return Localizations.of<ScreensLocalizations>(context, ScreensLocalizations)!;
  }

  // route.dart
  String get error => '错误';
  String get errorWidgetIdMissing => '错误: widgetId 参数缺失';
  String get errorHabitIdRequired => 'Error: habitId is required';
  String get errorHabitsPluginNotFound => 'Error: HabitsPlugin not found';
  String errorHabitNotFound(String id) => 'Error: Habit not found with id: $id';

  // floating_widget_screen
  String get floatingBallSettings => '悬浮球设置';
  String get requestPermission => '申请权限';
  String get floatingBallConfig => '悬浮球配置';
  String get customizeFloatingBallAppearanceBehavior => '自定义悬浮球的外观和行为';
  String get selectImageAsFloatingBall => '选择图片作为悬浮球';
  String get sizeColon => '大小: ';
  String ballSizeDp(int size) => '${size}dp';
  String get snapThresholdColon => '吸附阈值: ';
  String snapThresholdPx(int threshold) => '${threshold}px';
  String get autoRestoreFloatingBallState => '自动恢复悬浮球状态';
  String get buttonCountColon => '按钮数量: ';
  String buttonCount(int count) => '$count 个';
  String get manageFloatingButtons => '管理悬浮按钮';
  String get currentPosition => '当前位置';

  // home_screen
  String get createNewFolder => '新建文件夹';
  String get addWidget => '添加组件';
  String get saveCurrentLayout => '保存当前布局';
  String get manageLayouts => '管理布局';
  String get themeSettings => '主题设置';
  String get gridSettings => '网格设置';
  String get clearLayout => '清空布局';
  String get confirmClear => '确认清空';
  String get confirmClearAllWidgets => '确定要清空所有小组件吗？此操作不可恢复。';
  String get cancel => '取消';
  String get confirm => '确定';
  String get adjustSize => '调整大小';
  String get delete => '删除';
  String get selectWidgetSize => '选择组件大小';
  String get confirmDelete => '确认删除';
  String confirmDeleteItem(String itemName) => '确定要删除 "$itemName" 吗？';
  String get moveToFolder => '移动到文件夹';
  String get topDisplay => '顶部显示';
  String get centerDisplay => '居中显示';
  String get complete => '完成';
  String get clearFilterConditions => '清除筛选条件';

  // background_settings_page
  String get globalBackgroundSettings => '全局背景设置';
  String get selectImage => '选择图片';
  String get fillMode => '填充方式';
  String get cover => '覆盖 (Cover)';
  String get contain => '包含 (Contain)';
  String get fill => '填充 (Fill)';
  String get fitWidth => '适应宽度 (Fit Width)';
  String get fitHeight => '适应高度 (Fit Height)';
  String get none => '无缩放 (None)';
  String get scaleDown => '缩小 (Scale Down)';
  String get blurLevel => '模糊程度';
  String get save => '保存';
  String get globalBackgroundImage => '全局背景图';

  // create_folder_dialog
  String get selectIcon => '选择图标';
  String get selectColor => '选择颜色';
  String get create => '创建';

  // folder_dialog
  String get folderHasBeenDeleted => '文件夹已被删除';
  String get moveOutOfFolder => '移出文件夹';
  String get confirmDeleteThisItem => '确定要删除这个项目吗？';
  String get moveFromHomePage => '从主页移入';
  String moveIn(int count) => '移入 ($count)';
  String get editFolder => '编辑文件夹';

  // home_card
  String get cannotOpenPlugin => '无法打开插件';

  // home_grid
  String get quickCreateLayout => '快速创建布局';
  String get selectLayoutTemplate => '选择一个布局模板快速开始：';
  String get dragToFolder => '拖拽到文件夹';
  String dragItemToFolder(String item, String folder) => '将 "$item" 拖拽到文件夹 "$folder"';
  String get pleaseSelectAction => '请选择操作：';
  String get replacePosition => '替换位置';
  String get addToFolder => '添加到文件夹';

  // layout_manager_dialog
  String get renameLayout => '重命名布局';
  String confirmDeleteLayout(String layoutName) => '确定要删除布局"$layoutName"吗？此操作不可恢复。';
  String get layoutManagement => '布局管理';
  String layoutInfo(int items, int columns) => '$items 个组件 · $columns 列网格';
  String get switchToThisLayout => '切换到此布局';
  String get rename => '重命名';
  String get close => '关闭';

  // layout_type_selector
  String get emptyLayout => '空白布局';
  String get emptyLayoutDescription => '不包含任何小组件的空白布局';
  String get all1x1Widgets => '所有 1x1 小组件';
  String get all1x1WidgetsDescription => '添加所有支持 1x1 尺寸的小组件';
  String get all2x2Widgets => '所有 2x2 小组件';
  String get all2x2WidgetsDescription => '添加所有支持 2x2 尺寸的小组件';

  // widget_settings_dialog
  String get oneColumn => '一列';
  String get twoColumns => '两列';
  String get backgroundImage => '背景图片';
  String get alreadySet => '已设置';
  String get notSet => '未设置';
  String get iconColor => '图标颜色';
  String get customized => '已自定义';
  String get useDefault => '使用默认';
  String get backgroundColor => '背景颜色';
  String get effectWhenNoBackgroundImage => '无背景图片时生效';
  String get customColorWithTransparency => '自定义颜色（支持透明度）';

  // intent_test_screen
  String get quickRegisterIntent => '快速注册 Intent';
  String get selectPresetIntentType => '选择一个预设的 Intent 类型进行快速注册';
  String get mementoTest => 'Memento 测试 (memento:///test)';
  String get mementoComplete => 'Memento 完整 (memento://app.example.com/open)';
  String get customApp => '自定义应用 (myapp://custom.host)';
  String get intentTest => 'Intent 测试';
  String get quickRegister => '快速注册';
  String bulletScheme(String scheme) => '• $scheme';

  // js_console
  String get jsConsole => 'JS Console';
  String get loadingExamples => '加载示例中...';
  String get noAvailableExamples => '没有可用示例';
  String get selectExampleFile => '选择示例文件: ';
  String get allExamples => '全部示例';

  // json_dynamic_test
  String get jsonDynamicUITest => 'JSON 动态 UI 测试';
  String get loadFile => '加载文件';
  String get previewEffect => '预览效果';
  String get uiPreview => 'UI 预览';

  // notification_test
  String get notificationTestPage => '通知测试页面';
  String get test => '测试';

  // settings_screen
  String get testJavaScriptAPI => '测试 JavaScript API 功能';
  String get jsonDynamicWidgetTest => 'JSON Dynamic Widget 测试';
  String get testAndPreviewDynamicUI => '测试和预览动态 UI 组件';
  String get superCupertinoNavigationTest => 'Super Cupertino Navigation 测试';
  String get testIOSStyleNavigation => '测试 iOS 风格导航栏组件';
  String get notificationTest => '通知测试';
  String get manageSystemFloatingBall => '管理系统级悬浮球功能';
  String get intentTest => 'Intent 测试';
  String get testDynamicIntentAndDeepLink => '测试动态 Intent 注册和深度链接';

  // base_settings_controller
  String get selectLanguage => 'Select Language';
  String get chinese => '中文';
  String get english => 'English';

  // super_cupertino_test_screen
  String get superCupertinoTest => 'Super Cupertino 测试';
  String get fruitList => '水果列表';
  String fruitIndex(int index) => '这是第 ${index + 1} 个水果';

  // Additional messages
  String get floatingBallStarted => '悬浮球已启动';
  String get floatingBallStopped => '悬浮球已停止';
  String get pleaseEnterLayoutName => '请输入布局名称';
  String get notificationPermissionGranted => '通知权限已授权';
  String get notificationPermissionDenied => '通知权限被拒绝';
  String get saveSuccess => '保存成功';
  String get allWidgetsCleared => '已清空所有小组件';
  String get layoutSaved => '布局已保存';
  String get noImage => '没有图片';
  String get imageLoadFailed => '图片加载失败';
  String get pleaseSelectImage => '请选择图片';
  String get copySuccess => '复制成功';
  String get copiedToClipboard => '已复制到剪贴板';
  String get sendNotification => '发送通知';
  String get notificationSent => '通知已发送';
  String get noTestSchemeAvailable => '没有可用的测试方案';
  String get widgetSettings => '小组件设置';
  String itemCount(int count) => '$count 个项目';
  String layoutBackgroundSettings(String layoutName) => '${layoutName} - 背景设置';
  String get addWidgets => '添加小组件';
  String get clear => '清除';
  String get newLayout => '新建布局';

  // Additional floating ball messages
  String get permissionGranted => '权限已授予';
  String get permissionDenied => '权限被拒绝';
  String get floatingBallStatus => '悬浮球状态';
  String get running => '运行中';
  String get stopped => '已停止';
  String get floatingWindowPermission => '悬浮窗权限';
  String get granted => '已授予';
  String get notGranted => '未授予';
  String get floatingBallSwitch => '悬浮球开关';
  String get clickToStop => '点击停止';
  String get clickToStart => '点击开启';
  String get autoHideInApp => '应用内自动隐藏';
  String get autoHideInAppDescription => '在应用内自动隐藏overlay悬浮球';
  String clickedButton(String buttonName) => '点击了: $buttonName';
  String xPositionYPosition(double x, double y) => 'X: ${x.toStringAsFixed(0)}, Y: ${y.toStringAsFixed(0)}';

  // Additional home screen messages
  String confirmDeleteSelectedItems(int count) => '确定要删除选中的 $count 个项目吗？';
  String widgetSize(int width, int height) => '${width}x${height}';
  String confirmDeleteLayout(String layoutName) => '确定要删除布局"$layoutName"吗？此操作不可恢复。';
  String get noLayoutName => '没有布局名称';
  String get quickCreateLayoutDescription => '选择一个布局模板快速开始：';
  String get createNewLayout => '新建布局';
  String get inputLayoutName => '请输入布局名称';
}

class _ScreensLocalizationsDelegate
    extends LocalizationsDelegate<ScreensLocalizations> {
  const _ScreensLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<ScreensLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return ScreensLocalizationsEn();
      case 'zh':
        return ScreensLocalizationsZh();
      default:
        return ScreensLocalizations(locale);
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<ScreensLocalizations> old) => false;
}