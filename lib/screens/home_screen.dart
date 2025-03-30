import 'package:flutter/material.dart';
import '../core/plugin_manager.dart';
import '../core/config_manager.dart';
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
                      childAspectRatio:
                          constraints.maxWidth < 600 ? 2.2 : 1.6, // 在小屏幕上调整卡片比例
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                    ),
                    itemCount: plugins.length,
                    itemBuilder: (context, index) {
                      final plugin = plugins[index];
                      // 获取插件配置
                      final pluginConfig =
                          globalConfigManager.getPluginConfig(plugin.id) ??
                          {'enabled': true};
                      final bool isEnabled =
                          (pluginConfig is Map<String, dynamic>
                                  ? pluginConfig['enabled']
                                  : true)
                              as bool? ??
                          true;

                      return Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.all(4.0), // 添加外边距
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 卡片内容部分
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                                top: 16.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                children: [
                                  // 左侧图标
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withAlpha((0.1 * 255).toInt()),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.extension,
                                            size: 36,
                                            color:
                                                isEnabled
                                                    ? Theme.of(
                                                      context,
                                                    ).primaryColor
                                                    : Theme.of(
                                                      context,
                                                    ).disabledColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 中间的标题和描述
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          plugin.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            color:
                                                isEnabled
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.color
                                                    : Theme.of(
                                                      context,
                                                    ).disabledColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          plugin.description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            color:
                                                isEnabled
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color
                                                    : Theme.of(
                                                      context,
                                                    ).disabledColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 底部操作栏
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 左侧开关
                                  Switch(
                                    value: isEnabled,
                                    onChanged: (value) async {
                                      await globalConfigManager
                                          .savePluginConfig(plugin.id, {
                                            ...(pluginConfig
                                                as Map<String, dynamic>),
                                            'enabled': value,
                                          });
                                      setState(() {});
                                    },
                                  ),
                                  // 右侧进入按钮
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Material(
                                      color:
                                          isEnabled
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(context).disabledColor,
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap:
                                            isEnabled
                                                ? () {
                                                  globalConfigManager
                                                      .savePluginConfig(
                                                        'last_opened_plugin',
                                                        {'pluginId': plugin.id},
                                                      );
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) => plugin
                                                              .buildMainView(
                                                                context,
                                                              ),
                                                    ),
                                                  );
                                                }
                                                : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '进入',
                                                style: TextStyle(
                                                  color:
                                                      isEnabled
                                                          ? Colors.white
                                                          : Colors.white70,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 18,
                                                color:
                                                    isEnabled
                                                        ? Colors.white
                                                        : Colors.white70,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
