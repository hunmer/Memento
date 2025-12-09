import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/models/plugin_analysis_method.dart';

class MethodSelectionDialog extends StatelessWidget {
  final Function(PluginAnalysisMethod) onMethodSelected;

  const MethodSelectionDialog({super.key, required this.onMethodSelected});

  @override
  Widget build(BuildContext context) {
    final methods = PluginAnalysisMethod.predefinedMethods;

    return AlertDialog(
      title: Text('openai_selectAnalysisMethod'.tr),
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
          child: Text('app_cancel'.tr),
        ),
      ],
    );
  }
}
