/// 小组件配置编辑器模块
///
/// 提供通用的 Android 小组件配置界面组件，
/// 支持颜色配置、透明度调节和实时预览。
///
/// ## 使用示例
///
/// ```dart
/// import 'package:Memento/widgets/widget_config_editor/index.dart';
///
/// WidgetConfigEditor(
///   widgetSize: WidgetSize.large,
///   initialConfig: WidgetConfig(
///     colors: [
///       ColorConfig(
///         key: 'primary',
///         label: '主色调',
///         defaultValue: Colors.purple,
///         currentValue: Colors.purple,
///       ),
///     ],
///     opacity: 0.95,
///   ),
///   previewBuilder: (context, config) {
///     return Container(
///       color: config.getColor('primary'),
///       child: Text('预览'),
///     );
///   },
///   onConfigChanged: (config) {
///     // 保存配置
///   },
/// )
/// ```
library;

export 'models/widget_size.dart';
export 'models/color_config.dart';
export 'models/widget_config.dart';
export 'widget_config_editor.dart';
