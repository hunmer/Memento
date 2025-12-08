import 'dart:ui';

import 'screens_localizations.dart';

class ScreensLocalizationsZh extends ScreensLocalizations {
  const ScreensLocalizationsZh() : super(const Locale('zh'));

  // route.dart
  @override
  String get error => '错误';
  @override
  String get errorWidgetIdMissing => '错误: widgetId 参数缺失';
  @override
  String get errorHabitIdRequired => 'Error: habitId is required';
  @override
  String get errorHabitsPluginNotFound => 'Error: HabitsPlugin not found';
  @override
  String errorHabitNotFound(String id) => 'Error: Habit not found with id: $id';

  // floating_widget_screen
  @override
  String get floatingBallSettings => '悬浮球设置';
  @override
  String get requestPermission => '申请权限';
  @override
  String get floatingBallConfig => '悬浮球配置';
  @override
  String get customizeFloatingBallAppearanceBehavior => '自定义悬浮球的外观和行为';
  @override
  String get selectImageAsFloatingBall => '选择图片作为悬浮球';
  @override
  String get sizeColon => '大小: ';
  @override
  String ballSizeDp(int size) => '${size}dp';
  @override
  String get snapThresholdColon => '吸附阈值: ';
  @override
  String snapThresholdPx(int threshold) => '${threshold}px';
  @override
  String get autoRestoreFloatingBallState => '自动恢复悬浮球状态';
  @override
  String get buttonCountColon => '按钮数量: ';
  @override
  String buttonCount(int count) => '$count 个';
  @override
  String get manageFloatingButtons => '管理悬浮按钮';
  @override
  String get currentPosition => '当前位置';

  // home_screen
  @override
  String get createNewFolder => '新建文件夹';
  @override
  String get addWidget => '添加组件';
  @override
  String get saveCurrentLayout => '保存当前布局';
  @override
  String get manageLayouts => '管理布局';
  @override
  String get themeSettings => '主题设置';
  @override
  String get gridSettings => '网格设置';
  @override
  String get clearLayout => '清空布局';
  @override
  String get confirmClear => '确认清空';
  @override
  String get confirmClearAllWidgets => '确定要清空所有小组件吗？此操作不可恢复。';
  @override
  String get cancel => '取消';
  @override
  String get confirm => '确定';
  @override
  String get adjustSize => '调整大小';
  @override
  String get delete => '删除';
  @override
  String get selectWidgetSize => '选择组件大小';
  @override
  String get confirmDelete => '确认删除';
  @override
  String confirmDeleteItem(String itemName) => '确定要删除 "$itemName" 吗？';
  @override
  String get moveToFolder => '移动到文件夹';
  @override
  String get topDisplay => '顶部显示';
  @override
  String get centerDisplay => '居中显示';
  @override
  String get complete => '完成';
  @override
  String get clearFilterConditions => '清除筛选条件';

  // background_settings_page
  @override
  String get globalBackgroundSettings => '全局背景设置';
  @override
  String get selectImage => '选择图片';
  @override
  String get fillMode => '填充方式';
  @override
  String get cover => '覆盖 (Cover)';
  @override
  String get contain => '包含 (Contain)';
  @override
  String get fill => '填充 (Fill)';
  @override
  String get fitWidth => '适应宽度 (Fit Width)';
  @override
  String get fitHeight => '适应高度 (Fit Height)';
  @override
  String get none => '无缩放 (None)';
  @override
  String get scaleDown => '缩小 (Scale Down)';
  @override
  String get blurLevel => '模糊程度';
  @override
  String get save => '保存';
  @override
  String get globalBackgroundImage => '全局背景图';

  // create_folder_dialog
  @override
  String get selectIcon => '选择图标';
  @override
  String get selectColor => '选择颜色';
  @override
  String get create => '创建';

  // folder_dialog
  @override
  String get folderHasBeenDeleted => '文件夹已被删除';
  @override
  String get moveOutOfFolder => '移出文件夹';
  @override
  String get confirmDeleteThisItem => '确定要删除这个项目吗？';
  @override
  String get moveFromHomePage => '从主页移入';
  @override
  String moveIn(int count) => '移入 ($count)';
  @override
  String get editFolder => '编辑文件夹';

  // home_card
  @override
  String get cannotOpenPlugin => '无法打开插件';

  // home_grid
  @override
  String get quickCreateLayout => '快速创建布局';
  @override
  String get selectLayoutTemplate => '选择一个布局模板快速开始：';
  @override
  String get dragToFolder => '拖拽到文件夹';
  @override
  String dragItemToFolder(String item, String folder) => '将 "$item" 拖拽到文件夹 "$folder"';
  @override
  String get pleaseSelectAction => '请选择操作：';
  @override
  String get replacePosition => '替换位置';
  @override
  String get addToFolder => '添加到文件夹';

  // layout_manager_dialog
  @override
  String get renameLayout => '重命名布局';
  @override
  String confirmDeleteLayout(String layoutName) => '确定要删除布局"$layoutName"吗？此操作不可恢复。';
  @override
  String get layoutManagement => '布局管理';
  @override
  String layoutInfo(int items, int columns) => '$items 个组件 · $columns 列网格';
  @override
  String get switchToThisLayout => '切换到此布局';
  @override
  String get rename => '重命名';
  @override
  String get close => '关闭';

  // layout_type_selector
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

  // widget_settings_dialog
  @override
  String get oneColumn => '一列';
  @override
  String get twoColumns => '两列';
  @override
  String get backgroundImage => '背景图片';
  @override
  String get alreadySet => '已设置';
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
  String get effectWhenNoBackgroundImage => '无背景图片时生效';
  @override
  String get customColorWithTransparency => '自定义颜色（支持透明度）';

  // intent_test_screen
  @override
  String get quickRegisterIntent => '快速注册 Intent';
  @override
  String get selectPresetIntentType => '选择一个预设的 Intent 类型进行快速注册';
  @override
  String get mementoTest => 'Memento 测试 (memento:///test)';
  @override
  String get mementoComplete => 'Memento 完整 (memento://app.example.com/open)';
  @override
  String get customApp => '自定义应用 (myapp://custom.host)';
  @override
  String get intentTest => 'Intent 测试';
  @override
  String get quickRegister => '快速注册';
  @override
  String bulletScheme(String scheme) => '• $scheme';

  // js_console
  @override
  String get jsConsole => 'JS Console';
  @override
  String get loadingExamples => '加载示例中...';
  @override
  String get noAvailableExamples => '没有可用示例';
  @override
  String get selectExampleFile => '选择示例文件: ';
  @override
  String get allExamples => '全部示例';

  // json_dynamic_test
  @override
  String get jsonDynamicUITest => 'JSON 动态 UI 测试';
  @override
  String get loadFile => '加载文件';
  @override
  String get previewEffect => '预览效果';
  @override
  String get uiPreview => 'UI 预览';

  // notification_test
  @override
  String get notificationTestPage => '通知测试页面';
  @override
  String get test => '测试';

  // settings_screen
  @override
  String get testJavaScriptAPI => '测试 JavaScript API 功能';
  @override
  String get jsonDynamicWidgetTest => 'JSON Dynamic Widget 测试';
  @override
  String get testAndPreviewDynamicUI => '测试和预览动态 UI 组件';
  @override
  String get superCupertinoNavigationTest => 'Super Cupertino Navigation 测试';
  @override
  String get testIOSStyleNavigation => '测试 iOS 风格导航栏组件';
  @override
  String get notificationTest => '通知测试';
  @override
  String get manageSystemFloatingBall => '管理系统级悬浮球功能';
  @override
  String get intentTest => 'Intent 测试';
  @override
  String get testDynamicIntentAndDeepLink => '测试动态 Intent 注册和深度链接';

  // base_settings_controller
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get chinese => '中文';
  @override
  String get english => 'English';

  // super_cupertino_test_screen
  @override
  String get superCupertinoTest => 'Super Cupertino 测试';
  @override
  String get fruitList => '水果列表';
  @override
  String fruitIndex(int index) => '这是第 ${index + 1} 个水果';

  // Additional messages
  @override
  String get floatingBallStarted => '悬浮球已启动';
  @override
  String get floatingBallStopped => '悬浮球已停止';
  @override
  String get pleaseEnterLayoutName => '请输入布局名称';
  @override
  String get notificationPermissionGranted => '通知权限已授权';
  @override
  String get notificationPermissionDenied => '通知权限被拒绝';
  @override
  String get saveSuccess => '保存成功';
  @override
  String get allWidgetsCleared => '已清空所有小组件';
  @override
  String get layoutSaved => '布局已保存';
  @override
  String get noImage => '没有图片';
  @override
  String get imageLoadFailed => '图片加载失败';
  @override
  String get pleaseSelectImage => '请选择图片';
  @override
  String get copySuccess => '复制成功';
  @override
  String get copiedToClipboard => '已复制到剪贴板';
  @override
  String get sendNotification => '发送通知';
  @override
  String get notificationSent => '通知已发送';
  @override
  String get noTestSchemeAvailable => '没有可用的测试方案';
  @override
  String get widgetSettings => '小组件设置';
  @override
  String itemCount(int count) => '$count 个项目';
  @override
  String layoutBackgroundSettings(String layoutName) => '${layoutName} - 背景设置';
  @override
  String get addWidgets => '添加小组件';
  @override
  String get clear => '清除';
  @override
  String get newLayout => '新建布局';

  // Additional floating ball messages
  @override
  String get permissionGranted => '权限已授予';
  @override
  String get permissionDenied => '权限被拒绝';
  @override
  String get floatingBallStatus => '悬浮球状态';
  @override
  String get running => '运行中';
  @override
  String get stopped => '已停止';
  @override
  String get floatingWindowPermission => '悬浮窗权限';
  @override
  String get granted => '已授予';
  @override
  String get notGranted => '未授予';
  @override
  String get floatingBallSwitch => '悬浮球开关';
  @override
  String get clickToStop => '点击停止';
  @override
  String get clickToStart => '点击开启';
  @override
  String get autoHideInApp => '应用内自动隐藏';
  @override
  String get autoHideInAppDescription => '在应用内自动隐藏overlay悬浮球';
  @override
  String clickedButton(String buttonName) => '点击了: $buttonName';
  @override
  String xPositionYPosition(double x, double y) => 'X: ${x.toStringAsFixed(0)}, Y: ${y.toStringAsFixed(0)}';

  // Additional home screen messages
  @override
  String confirmDeleteSelectedItems(int count) => '确定要删除选中的 $count 个项目吗？';
  @override
  String widgetSize(int width, int height) => '${width}x${height}';
  @override
  String confirmDeleteLayout(String layoutName) => '确定要删除布局"$layoutName"吗？此操作不可恢复。';
  @override
  String get noLayoutName => '没有布局名称';
  @override
  String get quickCreateLayoutDescription => '选择一个布局模板快速开始：';
  @override
  String get createNewLayout => '新建布局';
  @override
  String get inputLayoutName => '请输入布局名称';
}