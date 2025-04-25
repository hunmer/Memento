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
              : LayoutBuilder(
                builder: (context, constraints) {
                  // 根据屏幕宽度计算列数
                  final screenWidth = constraints.maxWidth;
                  // 每个卡片最小宽度为120，计算可以放置的列数
                  int columns = (screenWidth / 120).floor();
                  // 确保列数在2-6之间
                  columns = columns.clamp(2, 6);

                  return GridView.builder(
                    padding: const EdgeInsets.all(4.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.95, // 增加高宽比，使卡片更方正
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: plugins.length,
                    itemBuilder: (context, index) {
                      final plugin = plugins[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            // 使用PluginManager的openPlugin方法
                            PluginManager.instance.openPlugin(context, plugin);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 插件图标
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    plugin.icon ?? Icons.extension,
                                    size: 28,
                                    color: plugin.color ?? Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 插件名称
                                Text(
                                  plugin.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // 版本信息
                                Text(
                                  '版本: ${plugin.version}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // 进入指示器
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
