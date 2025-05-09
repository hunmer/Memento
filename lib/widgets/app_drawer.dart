import 'package:flutter/material.dart';
import '../core/plugin_base.dart';
import '../screens/settings_screen/settings_screen.dart';
import '../main.dart'; // 导入全局实例

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 FutureBuilder 安全地访问 globalPluginManager
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<PluginBase>>(
              future: Future.microtask(() => globalPluginManager.allPlugins),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('加载插件失败: ${snapshot.error}'));
                }

                final plugins = snapshot.data ?? [];

                return SingleChildScrollView(
                  child: ExpansionPanelList.radio(
                    elevation: 0,
                    expandedHeaderPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    children:
                        plugins.map((plugin) {
                          return ExpansionPanelRadio(
                            value: plugin, // 使用插件对象作为唯一标识
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                leading: const Icon(Icons.extension),
                                title: Text(
                                  plugin is PluginBase
                                      ? plugin.name
                                      : plugin.toString(),
                                ),
                              );
                            },
                            body: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.settings),
                                  title: const Text('插件设置'),
                                  onTap: () {
                                  // 添加安全检查，防止黑屏
                                  if (context.mounted) {
                                    Navigator.pop(context); // 关闭抽屉
                                    // 添加加载状态管理
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                    // 延迟确保加载动画显示
                                    Future.microtask(() {
                                      if (context.mounted) {
                                        Navigator.of(context).pop(); // 关闭加载
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Scaffold(
                                              appBar: AppBar(
                                                title: Text('${plugin.name}设置'),
                                              ),
                                              body: plugin.buildSettingsView(context),
                                            ),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
            },
          ),
        ],
      ),
    );
  }
}
