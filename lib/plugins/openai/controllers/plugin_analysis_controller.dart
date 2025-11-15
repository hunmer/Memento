import 'package:Memento/plugins/openai/widgets/basic_info_dialog.dart';
import 'package:flutter/material.dart';

class PluginAnalysisController {
  // 单例模式
  static final PluginAnalysisController _instance = PluginAnalysisController._internal();

  factory PluginAnalysisController() => _instance;

  PluginAnalysisController._internal();

  // 显示插件分析预设创建对话框（新建模式）
  void showPluginAnalysisDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BasicInfoDialog(preset: null),
    );
  }

  // 显示插件分析预设编辑对话框（编辑模式）
  // 注意：此方法已弃用，请直接使用 BasicInfoDialog
  @Deprecated('Use BasicInfoDialog directly instead')
  void showPluginAnalysisDialogWithPreset(
    BuildContext context,
    String presetId,
  ) {
    // 此方法需要从 presetId 加载预设对象，暂时不实现
    // 建议外部直接使用 BasicInfoDialog 并传入预设对象
    throw UnimplementedError('Please use BasicInfoDialog with preset object directly');
  }
}