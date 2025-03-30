import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';

class PluginManagerScreen extends StatelessWidget {
  const PluginManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pluginManager = PluginManager();
    final plugins = pluginManager.allPlugins;

    return Scaffold(
      appBar: AppBar(title: const Text('插件管理器'), centerTitle: true),
      body:
          plugins.isEmpty
              ? const Center(child: Text('没有已安装的插件'))
              : ListView.builder(
                itemCount: plugins.length,
                itemBuilder: (context, index) {
                  final plugin = plugins[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // 插件图标
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.extension,
                                  size: 32,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 插件名称和版本信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plugin.name,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '版本: ${plugin.version} | 作者: ${plugin.author}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 启动按钮
                              IconButton(
                                icon: const Icon(Icons.launch, size: 28),
                                color: Theme.of(context).primaryColor,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              plugin.buildMainView(context),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          // 插件描述
                          if (plugin.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              plugin.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
