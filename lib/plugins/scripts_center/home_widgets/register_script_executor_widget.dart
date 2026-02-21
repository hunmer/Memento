/// 脚本中心插件 - 脚本执行器组件注册
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/services/plugin_data_selector/models/selector_result.dart';
import 'package:Memento/screens/home_screen/managers/home_widget_registry.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/home_screen/widgets/home_widget.dart';
import 'package:Memento/screens/home_screen/widgets/generic_selector_widget.dart';
import '../models/script_info.dart';
import '../scripts_center_plugin.dart';
import '../widgets/script_run_dialog.dart';
import 'providers.dart';
import 'utils.dart';

/// 注册脚本执行器组件（脚本快速执行小组件 - 选择器）
void registerScriptExecutorWidget(HomeWidgetRegistry registry) {
  registry.register(
    HomeWidget(
      id: 'scripts_center_script_executor',
      pluginId: 'scripts_center',
      name: 'scripts_center_scriptExecutorName'.tr,
      description: 'scripts_center_scriptExecutorDescription'.tr,
      icon: Icons.play_circle_outline,
      color: Colors.deepPurple,
      defaultSize: const SmallSize(),
      supportedSizes: [const SmallSize(), const MediumSize()],
      category: 'home_categoryTools'.tr,
      selectorId: 'scripts_center.script',
      dataSelector: extractScriptData,
      dataRenderer: renderScriptData,
      navigationHandler: executeScript,
      builder: (context, config) {
        return GenericSelectorWidget(
          widgetDefinition: registry.getWidget('scripts_center_script_executor')!,
          config: config,
        );
      },
    ),
  );
}

/// 渲染脚本数据（选择器小组件）
Widget renderScriptData(
  BuildContext context,
  SelectorResult result,
  Map<String, dynamic> config,
) {
  final savedData = result.data is Map<String, dynamic>
      ? result.data as Map<String, dynamic>
      : {};
  final scriptId = savedData['id'] as String? ?? '';
  final scriptName = savedData['name'] as String? ?? 'scripts_center_script'.tr;
  final scriptIconString = savedData['icon'] as String?;
  final hasInputs = savedData['hasInputs'] as bool? ?? false;

  return FutureBuilder<ScriptInfo?>(
    future: loadLatestScript(scriptId),
    builder: (context, snapshot) {
      final script = snapshot.data;
      final displayName = script?.name ?? scriptName;
      final needsInputs = script?.hasInputs ?? hasInputs;
      final iconString = script?.icon ?? scriptIconString;
      final icon = parseIcon(iconString);

      return _buildScriptWidget(
        context,
        displayName,
        needsInputs,
        icon,
      );
    },
  );
}

/// 构建脚本执行小组件 UI
Widget _buildScriptWidget(
  BuildContext context,
  String scriptName,
  bool needsInputs,
  IconData icon,
) {
  final theme = Theme.of(context);

  return LayoutBuilder(
    builder: (context, constraints) {
      // 根据可用空间计算图标和文字大小
      final size = constraints.maxWidth.clamp(0.0, constraints.maxHeight);
      final iconSize = size * 0.4;
      final fontSize = (size * 0.12).clamp(10.0, 14.0);
      final inputIconSize = iconSize * 0.3;

      return Center(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // 主内容：图标 + 名称
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: size * 0.05),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    scriptName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 需要参数的提示图标
            if (needsInputs)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.input,
                    size: inputIconSize,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// 执行脚本（点击处理器）
Future<void> executeScript(
  BuildContext context,
  SelectorResult result,
) async {
  final data = result.data is Map<String, dynamic>
      ? result.data as Map<String, dynamic>
      : {};

  final scriptId = data['id'] as String?;

  if (scriptId == null || scriptId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('scripts_center_scriptNotFound'.tr)),
    );
    return;
  }

  try {
    final plugin = PluginManager.instance.getPlugin('scripts_center') as ScriptsCenterPlugin?;
    if (plugin == null) return;

    // 加载脚本信息
    final scripts = await plugin.scriptManager.loadAllScripts();
    final script = scripts.firstWhere(
      (s) => s.id == scriptId,
      orElse: () => plugin.scriptManager.getScriptById(scriptId)!,
    );

    if (script.hasInputs) {
      // 显示参数输入对话框
      final navContext = navigatorKey.currentContext ?? context;
      final params = await showDialog<Map<String, dynamic>>(
        context: navContext,
        builder: (dialogContext) => ScriptRunDialog(
          script: script,
        ),
      );

      // 如果用户点击了取消，不执行脚本
      if (params == null) return;

      // 执行脚本并传递参数
      final execResult = await plugin.scriptExecutor.execute(
        script.id,
        args: params,
      );

      if (context.mounted) {
        if (execResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('scripts_center_scriptExecuted'.tr),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'scripts_center_scriptExecuteFailed'.tr}: ${execResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // 直接执行脚本
      final execResult = await plugin.scriptExecutor.execute(script.id);

      if (context.mounted) {
        if (execResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('scripts_center_scriptExecuted'.tr),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'scripts_center_scriptExecuteFailed'.tr}: ${execResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'scripts_center_scriptExecuteError'.tr}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
