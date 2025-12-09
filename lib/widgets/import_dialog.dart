
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ImportDialog extends StatefulWidget {
  final Map<String, int> pluginDataMap;
  final bool isMergeMode;

  const ImportDialog({
    super.key,
    required this.pluginDataMap,
    required this.isMergeMode,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final Map<String, bool> _selectedPlugins = {};

  @override
  void initState() {
    super.initState();
    for (final pluginName in widget.pluginDataMap.keys) {
      _selectedPlugins[pluginName] = false;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${'app_selectPluginsToImport'.tr} (${widget.isMergeMode ? 'app_mergeMode'.tr : 'app_overwriteMode'.tr})',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children:
              widget.pluginDataMap.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  subtitle: Text(
                    '${'app_dataSize'.tr}: ${_formatFileSize(entry.value)}',
                  ),
                  value: _selectedPlugins[entry.key],
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedPlugins[entry.key] = value ?? false;
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('app_cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedPlugins);
          },
          child: Text('app_import'.tr),
        ),
      ],
    );
  }
}
