import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'provider_settings_screen.dart';
import 'model_list_screen.dart';
import 'prompt_preset_screen.dart';

class PluginSettingsScreen extends StatelessWidget {
  const PluginSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('openai_pluginSettingsTitle'.tr),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text('openai_providerSettingsTitle'.tr),
            subtitle: Text('openai_pluginDescription'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.push(
                context,
                const ProviderSettingsScreen(),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: Text('openai_modelManagement'.tr),
            subtitle: Text(
              'openai_modelManagementDescription'.tr,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.push(
                context,
                const ModelListScreen(),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.text_snippet),
            title: Text('openai_promptPresetManagement'.tr),
            subtitle: Text(
              'openai_promptPresetManagementDescription'.tr,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              NavigationHelper.push(
                context,
                const PromptPresetScreen(),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
