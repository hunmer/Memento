import 'package:flutter/material.dart';
import 'provider_settings_screen.dart';

class PluginSettingsScreen extends StatelessWidget {
  const PluginSettingsScreen({Key? key}) : super(key: key);

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
          // 这里可以添加更多设置项
        ],
      ),
    );
  }
}
