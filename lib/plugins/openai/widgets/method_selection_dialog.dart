import 'package:flutter/material.dart';
import '../models/plugin_analysis_method.dart';

class MethodSelectionDialog extends StatelessWidget {
  final Function(PluginAnalysisMethod) onMethodSelected;

  const MethodSelectionDialog({
    Key? key,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final methods = PluginAnalysisMethod.predefinedMethods;

    return AlertDialog(
      title: const Text('选择分析方法'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: methods.length,
          itemBuilder: (context, index) {
            final method = methods[index];
            return ListTile(
              title: Text(method.name),
              onTap: () {
                Navigator.pop(context);
                onMethodSelected(method);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}