import 'package:Memento/l10n/app_localizations.dart';
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
      title: Text(AppLocalizations.of(context)!.selectPluginToExport),
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
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.ok),
          onPressed: () => Navigator.of(context).pop(_selectedPlugins.toList()),
        ),
      ],
    );
  }
}
