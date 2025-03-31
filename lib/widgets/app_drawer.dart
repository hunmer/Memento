import 'package:flutter/material.dart';
import '../core/plugin_base.dart';
import '../main.dart'; // 导入全局实例

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 FutureBuilder 安全地访问 globalPluginManager
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person),
            ),
            accountName: Text('用户名'),
            accountEmail: Text('user@example.com'),
          ),
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
                                  title: Text(
                                    '版本: ${plugin is PluginBase ? plugin.version : "未知"}',
                                  ),
                                  subtitle: Text(
                                    plugin is PluginBase
                                        ? plugin.description
                                        : "无描述",
                                  ),
                                  onTap: () {
                                    Navigator.pop(context); // 关闭抽屉
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                plugin is PluginBase
                                                    ? plugin.buildMainView(
                                                      context,
                                                    )
                                                    : const Center(
                                                      child: Text('插件未提供视图'),
                                                    ),
                                      ),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.settings),
                                  title: const Text('插件设置'),
                                  onTap: () {
                                    if (plugin is PluginBase) {
                                      Navigator.pop(context); // 关闭抽屉
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => Scaffold(
                                                appBar: AppBar(
                                                  title: Text(
                                                    '${plugin.name}设置',
                                                  ),
                                                ),
                                                body: plugin.buildSettingsView(
                                                  context,
                                                ),
                                              ),
                                        ),
                                      );
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
              // TODO: 导航到设置页面
            },
          ),
        ],
      ),
    );
  }
}
