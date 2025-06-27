import 'package:Memento/l10n/app_localizations.dart';
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
                  return Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.failedToLoadPlugins(snapshot.error.toString()),
                    ),
                  );
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
                                leading: Icon(plugin.icon),
                                title: Text(
                                  plugin.getPluginName(context) ?? plugin.id,
                                ),
                              );
                            },
                            body: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.settings),
                                  title: Text(
                                    AppLocalizations.of(context)!.settings,
                                  ),
                                  onTap: () {
                                    if (context.mounted) {
                                      Navigator.pop(context); // 关闭抽屉
                                      // 添加加载状态管理
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (context) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      );
                                      // 延迟确保加载动画显示
                                      Future.microtask(() {
                                        if (context.mounted) {
                                          Navigator.of(context).pop(); // 关闭加载
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => Scaffold(
                                                    appBar: AppBar(
                                                      title: Text(
                                                        plugin.getPluginName(
                                                              context,
                                                            ) ??
                                                            plugin.id,
                                                      ),
                                                    ),
                                                    body: plugin
                                                        .buildSettingsView(
                                                          context,
                                                        ),
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
            title: Text(AppLocalizations.of(context)!.settings),
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
