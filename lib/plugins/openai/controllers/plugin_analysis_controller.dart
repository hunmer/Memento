import 'package:flutter/material.dart';
import '../models/plugin_analysis_method.dart';
import '../widgets/method_selection_dialog.dart';
import '../widgets/plugin_analysis_form.dart';

class PluginAnalysisController {
  // 单例模式
  static final PluginAnalysisController _instance = PluginAnalysisController._internal();
  
  factory PluginAnalysisController() => _instance;
  
  PluginAnalysisController._internal();

  // 显示方法选择对话框
  void showMethodSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MethodSelectionDialog(
        onMethodSelected: (method) {
          _showPluginAnalysisForm(context, method);
        },
      ),
    );
  }

  // 显示插件分析表单
  void _showPluginAnalysisForm(BuildContext context, PluginAnalysisMethod method) {
    showDialog(
      context: context,
      builder: (context) => PluginAnalysisForm(method: method),
    );
  }
}