#!/bin/bash

# 更新核心模块国际化文件

echo "处理 core/l10n/ 目录下的国际化文件..."

# 确保目录存在
mkdir -p lib/core/l10n

# 创建核心模块国际化文件
cat > lib/core/l10n/core_localizations.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'core_localizations_zh.dart';
import 'core_localizations_en.dart';

/// 核心模块国际化代理
class CoreLocalizationsDelegate extends LocalizationsDelegate<CoreLocalizations> {
  const CoreLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<CoreLocalizations> load(Locale locale) {
    return SynchronousFuture<CoreLocalizations>(
      _getLocalizedValues(locale),
    );
  }

  @override
  bool shouldReload(LocalizationsDelegate<CoreLocalizations> old) => false;

  CoreLocalizations _getLocalizedValues(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return CoreLocalizationsEn();
      case 'zh':
      default:
        return CoreLocalizationsZh();
    }
  }
}

/// 核心模块国际化接口
abstract class CoreLocalizations {
  // Action Executor
  String get inputJavaScriptCode;
  String get cancel;
  String get execute;

  // Custom Action Examples
  String get save;
  String get executionResult;
  String executionStatus(bool success);
  String get outputData;
  String get errorMessage;
  String get close;
  String get inputFloatingBallJavaScriptCode;

  // Migration Tool
  String get configMigration;
  String get migrating;
  String get startMigration;

  // Action Config Form
  String get notSelected;
  String get selectColor;
  String get iconSelectorNotImplemented;

  // Action Group Editor
  String get sequentialExecution;
  String get parallelExecution;
  String get conditionalExecution;
  String get executeAllActions;
  String get executeAnyAction;
  String get executeFirstOnly;
  String get executeLastOnly;
  String get addAction;
  String get edit;
  String get moveUp;
  String get moveDown;
  String get delete;

  // Action Selector Dialog
  String get clearSettings;
  String get confirm;

  // Floating Button Manager
  String get confirmDelete;
  String confirmDeleteButton(String title);
  String get floatingButtonManager;
  String get addFirstButton;

  // Floating Button Edit Dialog
  String get clearIconImage;
  String confirmClearIconImage();
  String get clear;
  String get selectIcon;

  // Plugin Overlay Widget
  String get routeError;
  String routeNotFound(String routeName);

  // Create Action Group
  String get createActionGroup;

  static CoreLocalizations? of(BuildContext context) {
    return Localizations.of<CoreLocalizations>(context, CoreLocalizations);
  }
}
EOF

cat > lib/core/l10n/core_localizations_zh.dart << 'EOF'
import 'core_localizations.dart';

/// 核心模块中文国际化
class CoreLocalizationsZh extends CoreLocalizations {
  @override
  String get inputJavaScriptCode => '输入JavaScript代码';

  @override
  String get cancel => '取消';

  @override
  String get execute => '执行';

  @override
  String get save => '保存';

  @override
  String get executionResult => '执行结果';

  @override
  String executionStatus(bool success) => '执行状态: ${success ? "成功" : "失败"}';

  @override
  String get outputData => '输出数据:';

  @override
  String get errorMessage => '错误信息:';

  @override
  String get close => '关闭';

  @override
  String get inputFloatingBallJavaScriptCode => '输入悬浮球JavaScript代码';

  @override
  String get configMigration => '配置迁移';

  @override
  String get migrating => '迁移中...';

  @override
  String get startMigration => '开始迁移';

  @override
  String get notSelected => '未选择';

  @override
  String get selectColor => '选择颜色';

  @override
  String get iconSelectorNotImplemented => '图标选择器（暂未实现）';

  @override
  String get sequentialExecution => '顺序执行';

  @override
  String get parallelExecution => '并行执行';

  @override
  String get conditionalExecution => '条件执行';

  @override
  String get executeAllActions => '执行所有动作';

  @override
  String get executeAnyAction => '执行任一动作';

  @override
  String get executeFirstOnly => '只执行第一个';

  @override
  String get executeLastOnly => '只执行最后一个';

  @override
  String get addAction => '添加动作';

  @override
  String get edit => '编辑';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get delete => '删除';

  @override
  String get clearSettings => '清除已设置';

  @override
  String get confirm => '确认';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteButton(String title) => '确定要删除按钮"$title"吗？';

  @override
  String get floatingButtonManager => '悬浮按钮管理';

  @override
  String get addFirstButton => '添加第一个按钮';

  @override
  String get clearIconImage => '清空图标/图片';

  @override
  String confirmClearIconImage() => '确定要清空当前设置的图标和图片吗？';

  @override
  String get clear => '清空';

  @override
  String get selectIcon => '选择图标';

  @override
  String get routeError => '路由错误';

  @override
  String routeNotFound(String routeName) => '未找到路由: $routeName';

  @override
  String get createActionGroup => '创建动作组';
}
EOF

cat > lib/core/l10n/core_localizations_en.dart << 'EOF'
import 'core_localizations.dart';

/// Core module English localization
class CoreLocalizationsEn extends CoreLocalizations {
  @override
  String get inputJavaScriptCode => 'Input JavaScript Code';

  @override
  String get cancel => 'Cancel';

  @override
  String get execute => 'Execute';

  @override
  String get save => 'Save';

  @override
  String get executionResult => 'Execution Result';

  @override
  String executionStatus(bool success) => 'Execution Status: ${success ? "Success" : "Failed"}';

  @override
  String get outputData => 'Output Data:';

  @override
  String get errorMessage => 'Error Message:';

  @override
  String get close => 'Close';

  @override
  String get inputFloatingBallJavaScriptCode => 'Input Floating Ball JavaScript Code';

  @override
  String get configMigration => 'Configuration Migration';

  @override
  String get migrating => 'Migrating...';

  @override
  String get startMigration => 'Start Migration';

  @override
  String get notSelected => 'Not Selected';

  @override
  String get selectColor => 'Select Color';

  @override
  String get iconSelectorNotImplemented => 'Icon Selector (Not Implemented)';

  @override
  String get sequentialExecution => 'Sequential Execution';

  @override
  String get parallelExecution => 'Parallel Execution';

  @override
  String get conditionalExecution => 'Conditional Execution';

  @override
  String get executeAllActions => 'Execute All Actions';

  @override
  String get executeAnyAction => 'Execute Any Action';

  @override
  String get executeFirstOnly => 'Execute First Only';

  @override
  String get executeLastOnly => 'Execute Last Only';

  @override
  String get addAction => 'Add Action';

  @override
  String get edit => 'Edit';

  @override
  String get moveUp => 'Move Up';

  @override
  String get moveDown => 'Move Down';

  @override
  String get delete => 'Delete';

  @override
  String get clearSettings => 'Clear Settings';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteButton(String title) => 'Are you sure to delete button "$title"?';

  @override
  String get floatingButtonManager => 'Floating Button Manager';

  @override
  String get addFirstButton => 'Add First Button';

  @override
  String get clearIconImage => 'Clear Icon/Image';

  @override
  String confirmClearIconImage() => 'Are you sure to clear the current icon and image settings?';

  @override
  String get clear => 'Clear';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get routeError => 'Route Error';

  @override
  String routeNotFound(String routeName) => 'Route not found: $routeName';

  @override
  String get createActionGroup => 'Create Action Group';
}
EOF

echo "核心模块国际化文件创建完成！"
echo "文件列表："
echo "  - lib/core/l10n/core_localizations.dart"
echo "  - lib/core/l10n/core_localizations_zh.dart"
echo "  - lib/core/l10n/core_localizations_en.dart"