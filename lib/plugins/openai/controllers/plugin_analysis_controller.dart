import 'package:Memento/plugins/openai/widgets/plugin_analysis_dialog.dart';
import 'package:flutter/material.dart';

class PluginAnalysisController {
  // 单例模式
  static final PluginAnalysisController _instance = PluginAnalysisController._internal();
  
  factory PluginAnalysisController() => _instance;
  
  PluginAnalysisController._internal();

  // 显示插件分析对话框
  void showPluginAnalysisDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PluginAnalysisDialog(),
    );
  }
}