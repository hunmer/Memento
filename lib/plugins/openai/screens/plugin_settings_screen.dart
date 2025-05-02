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
            title: const Text('服务商设置'),
            subtitle: const Text('配置 AI 服务提供商'),
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
            title: const Text('模型管理'),
            subtitle: const Text('管理大语言模型列表'),
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
