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
              : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: plugins.length,
                itemBuilder: (context, index) {
                  final plugin = plugins[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => plugin.buildMainView(context),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 插件图标
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.extension,
                                size: 36,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 插件名称
                            Text(
                              plugin.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 版本信息
                            Text(
                              '版本: ${plugin.version}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            // 进入指示器
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
