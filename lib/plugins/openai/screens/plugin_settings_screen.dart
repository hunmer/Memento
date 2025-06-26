import 'package:Memento/plugins/openai/l10n/openai_localizations.dart';
import 'package:flutter/material.dart';
import 'provider_settings_screen.dart';
import 'model_list_screen.dart';

class PluginSettingsScreen extends StatelessWidget {
  const PluginSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text(OpenAILocalizations.of(context).providerSettingsTitle),
            subtitle: Text(OpenAILocalizations.of(context).pluginDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProviderSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.model_training),
            title: Text(OpenAILocalizations.of(context).modelManagement),
            subtitle: Text(
              OpenAILocalizations.of(context).modelManagementDescription,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModelListScreen(),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
