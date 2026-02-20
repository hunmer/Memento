import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/plugin_base.dart';

class PluginSelectionDialog extends StatefulWidget {
  final List<PluginBase> plugins;

  const PluginSelectionDialog({super.key, required this.plugins});

  @override
  // ignore: library_private_types_in_public_api
  _PluginSelectionDialogState createState() => _PluginSelectionDialogState();
}

class _PluginSelectionDialogState extends State<PluginSelectionDialog> {
  final Set<String> _selectedPlugins = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('app_selectPluginToExport'.tr),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.plugins.map((plugin) {
                return CheckboxListTile(
                  title: Text(plugin.getPluginName(context) ?? plugin.id),
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
          child: Text('app_cancel'.tr),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text('app_ok'.tr),
          onPressed: () => Navigator.of(context).pop(_selectedPlugins.toList()),
        ),
      ],
    );
  }
}
