import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/plugin_base.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bar_widget.dart';
import '../main.dart'; // 导入全局实例

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PluginBase>> _pluginsFuture;
  // 用于缓存插件配置
  final Map<String, Map<String, dynamic>> _pluginConfigs = {};

  @override
  void initState() {
    super.initState();
    // 延迟获取插件列表，确保插件管理器已经完成初始化
    _pluginsFuture = Future.delayed(
      const Duration(milliseconds: 500),
      () => globalPluginManager.allPlugins,
    ).then((plugins) async {
      // 检查是否有最后打开的插件
      final config = await globalConfigManager.getPluginConfig(
        'last_opened_plugin',
      );
      final lastPluginId = config?['pluginId'] as String?;

      if (lastPluginId != null && plugins.isNotEmpty) {
        final lastPlugin = plugins.firstWhere(
          (p) => p.id == lastPluginId,
          orElse: () => plugins.first,
        );
        // 延迟打开插件，确保界面已经构建完成
        if (mounted) {
          // 添加 mounted 检查
          Future.microtask(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => lastPlugin.buildMainView(context),
              ),
            );
          });
        }
      }
      return plugins;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(title: '插件管理器'),
      drawer: const AppDrawer(),
      floatingActionButton:
          kIsWeb
              ? FloatingActionButton(
                onPressed: () async {
                  // 测试Web存储
                  final testKey = 'test_data';
                  final testContent = DateTime.now().toString();
                  await globalStorage.writeString(testKey, testContent);

                  final readContent = await globalStorage.readString(testKey);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('存储测试: $readContent'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                tooltip: '测试Web存储',
                child: const Icon(Icons.storage),
              )
              : null,
      body: FutureBuilder<List<PluginBase>>(
        future: _pluginsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('加载插件失败: ${snapshot.error}'));
          }

          final plugins = snapshot.data ?? [];

          return plugins.isEmpty
              ? const Center(child: Text('没有已安装的插件'))
              : LayoutBuilder(
                builder: (context, constraints) {
                  // 计算每行显示的卡片数量
                  // 在小屏幕手机上一行只显示1个插件
                  int crossAxisCount = 1;

                  // 只有在较宽的设备上才增加每行卡片数
                  if (constraints.maxWidth >= 600) {
                    crossAxisCount = 2;
                  }
                  if (constraints.maxWidth >= 900) {
                    crossAxisCount = 3;
                  }
                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 4;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1.0, // 正方形卡片
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                    ),
                    itemCount: plugins.length,
                    itemBuilder: (context, index) {
                      final plugin = plugins[index];
                      return Card(
                        elevation: 2.0,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            globalConfigManager.savePluginConfig(
                              'last_opened_plugin',
                              {'pluginId': plugin.id},
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => plugin.buildMainView(context),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 插件图标
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.extension,
                                    size: 36,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 插件名称
                                Text(
                                  plugin.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }
}
