import 'package:get/get.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/controllers/provider_controller.dart';

class FilterDialog extends StatefulWidget {
  final Set<String> selectedProviders;
  final Set<String> selectedTags;
  final Function(Set<String> providers, Set<String> tags) onApply;

  const FilterDialog({
    super.key,
    required this.selectedProviders,
    required this.selectedTags,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<String> _selectedProviders;
  late Set<String> _selectedTags;
  late final OpenAIPlugin _plugin;
  // ignore: prefer_typing_uninitialized_variables
  late final _controller;
  final ProviderController _providerController = ProviderController();
  List<String> _allTags = [];
  List<String> _allProviders = [];

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
    _controller = _plugin.controller;
    _selectedProviders = Set.from(widget.selectedProviders);
    _selectedTags = Set.from(widget.selectedTags);
    _loadData();
  }

  Future<void> _loadData() async {
    _allTags = await _controller.getAllTags();
    final providers = await _providerController.getProviders();
    _allProviders = providers.map((p) => p.id).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('openai_filterAgents'.tr),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'openai_serviceProvider'.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _allProviders.map((provider) {
                    return FilterChip(
                      label: Text(provider),
                      selected: _selectedProviders.contains(provider),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedProviders.add(provider);
                          } else {
                            _selectedProviders.remove(provider);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'openai_tags'.tr,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _allTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('openai_cancel'.tr),
        ),
        TextButton(
          onPressed: () {
            widget.onApply(_selectedProviders, _selectedTags);
            Navigator.pop(context);
          },
          child: Text('openai_apply'.tr),
        ),
      ],
    );
  }
}
