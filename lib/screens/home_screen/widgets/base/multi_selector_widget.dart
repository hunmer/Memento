/// 多选选择器小组件基类
///
/// 继承自 BaseSelectorWidget，专门处理多选场景
library;

import 'package:Memento/screens/home_screen/widgets/base/base_selector_widget.dart';

/// 多选选择器小组件基类
abstract class MultiSelectorWidget extends BaseSelectorWidget {
  const MultiSelectorWidget({
    super.key,
    required super.config,
    required super.widgetDefinition,
  });

  @override
  SelectionMode get selectionMode => SelectionMode.multiple;
}
