import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
      title: Text('选择要导入的插件 (${widget.isMergeMode ? "合并模式" : "覆盖模式"})'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children:
              widget.pluginDataMap.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(entry.key),
                  subtitle: Text('数据大小: ${_formatFileSize(entry.value)}'),
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedPlugins);
          },
          child: const Text('导入'),
        ),
      ],
    );
  }
}
