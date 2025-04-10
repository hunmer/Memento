import 'package:flutter/material.dart';
import '../../../core/plugin_base.dart';

class PluginSelectionDialog extends StatefulWidget {
  final List<PluginBase> plugins;

  const PluginSelectionDialog({super.key, required this.plugins});

  @override
  _PluginSelectionDialogState createState() => _PluginSelectionDialogState();
}

class _PluginSelectionDialogState extends State<PluginSelectionDialog> {
  final Set<String> _selectedPlugins = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择要导出的插件'),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.plugins.map((plugin) {
                return CheckboxListTile(
                  title: Text(plugin.name),
                  value: _selectedPlugins.contains(plugin.id),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedPlugins.add(plugin.id);
                      } else {
                        _selectedPlugins.remove(plugin.id);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () => Navigator.of(context).pop(_selectedPlugins.toList()),
        ),
      ],
    );
  }
}