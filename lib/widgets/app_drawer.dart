import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import '../core/plugin_base.dart';
import '../screens/settings_screen/settings_screen.dart';
// 导入全局实例

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

                return ListView.builder(
                  itemCount: plugins.length,
                  itemBuilder: (context, index) {
                    final plugin = plugins[index];
                    return ListTile(
                      leading: Icon(plugin.icon),
                      title: Text(
                        plugin.getPluginName(context) ?? plugin.id,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        tooltip: AppLocalizations.of(context)!.settings,
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context); // 关闭抽屉
                            // 导航到插件设置页面
                            NavigationHelper.push(context, Scaffold(
                                  appBar: AppBar(
                                    title: Text(
                                      plugin.getPluginName(context) ??
                                          plugin.id,),
                                  body: plugin.buildSettingsView(context),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      onTap: () {
                        if (context.mounted) {
                          Navigator.pop(context); // 关闭抽屉
                          // 使用 PluginManager 统一的打开插件方法
                          globalPluginManager.openPlugin(context, plugin);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {
              Navigator.pop(context); // 先关闭抽屉
              NavigationHelper.push(context, const SettingsScreen(),
              );
            },
          ),
        ],
      ),
    );
  }
}
