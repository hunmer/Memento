import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:Memento/plugins/openai/widgets/plugin_analysis_form.dart';
import 'package:flutter/material.dart';
import '../models/plugin_analysis_method.dart';

class PluginMethodSelectionDialog extends StatelessWidget {
  const PluginMethodSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.category),
                const SizedBox(width: 8),
                Text(
                  OpenAILocalizations.of(context).selectAnalysisMethod,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // 方法列表
            ListView(
              shrinkWrap: true,
              children: [
                for (final method in PluginAnalysisMethod.predefinedMethods)
                  ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: Text(method.name),
                    subtitle: Text(method.title),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => PluginAnalysisForm(
                              method: method,
                              onConfirm: (jsonString) {
                                Navigator.pop(context); // 关闭表单对话框
                                Navigator.pop(context, {
                                  'methodName': method.name,
                                  'jsonString': jsonString,
                                }); // 关闭方法选择对话框并返回结果
                              },
                            ),
                      );
                    },
                  ),
              ],
            ),

            // 底部按钮
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(OpenAILocalizations.of(context).cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
