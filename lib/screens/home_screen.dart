import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../core/plugin_base.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bar_widget.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// 卡片尺寸枚举
enum CardSize { small, wide }

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PluginBase>> _pluginsFuture;
  // 存储每个插件卡片的大小
  final Map<String, CardSize> _cardSizes = {};

  // 字符串转换为卡片大小枚举
  CardSize _stringToCardSize(String sizeStr) {
    return sizeStr.toLowerCase() == 'wide' ? CardSize.wide : CardSize.small;
  }
  
  // 获取插件的卡片大小，如果没有设置则返回默认值
  CardSize _getCardSize(String pluginId) {
    return _cardSizes[pluginId] ?? CardSize.small;
  }
  
  // 加载插件卡片大小设置
  Future<void> _loadCardSizes() async {
    try {
      final cardSizesConfig = await globalConfigManager.getPluginConfig('card_sizes');
      if (cardSizesConfig != null) {
        final sizes = cardSizesConfig['sizes'] as Map<dynamic, dynamic>?;
        if (sizes != null) {
          sizes.forEach((key, value) {
            final pluginId = key.toString();
            final sizeStr = value.toString();
            _cardSizes[pluginId] = _stringToCardSize(sizeStr);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading card sizes: $e');
    }
  }

  // 保存插件卡片大小设置
  Future<void> _saveCardSizes() async {
    try {
      final Map<String, String> sizes = {};
      _cardSizes.forEach((key, value) {
        sizes[key] = value.toString().split('.').last;
      });
      
      await globalConfigManager.savePluginConfig('card_sizes', {'sizes': sizes});
    } catch (e) {
      debugPrint('Error saving card sizes: $e');
    }
  }
  
  // 在指定位置显示卡片大小调整菜单
  void _showCardSizeMenu(BuildContext context, PluginBase plugin) {
    try {
      // 获取卡片的位置信息
      final RenderBox button = context.findRenderObject() as RenderBox;
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
      
      // 计算弹出菜单的位置
      final Offset buttonPosition = button.localToGlobal(Offset.zero);
      final RelativeRect position = RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy + button.size.height,
        buttonPosition.dx + button.size.width,
        buttonPosition.dy + button.size.height * 2,
      );
      
      showMenu<CardSize>(
        context: context,
        position: position,
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        items: [
          PopupMenuItem<CardSize>(
            value: CardSize.wide,
            child: Row(
              children: [
                Icon(
                  Icons.crop_landscape,
                  color: _getCardSize(plugin.id) == CardSize.wide
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '宽卡片',
                  style: TextStyle(
                    fontWeight: _getCardSize(plugin.id) == CardSize.wide
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _getCardSize(plugin.id) == CardSize.wide
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<CardSize>(
            value: CardSize.small,
            child: Row(
              children: [
                Icon(
                  Icons.crop_square,
                  color: _getCardSize(plugin.id) == CardSize.small
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '小卡片',
                  style: TextStyle(
                    fontWeight: _getCardSize(plugin.id) == CardSize.small
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _getCardSize(plugin.id) == CardSize.small
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).then((CardSize? value) {
        if (value != null && mounted) {
          setState(() {
            _cardSizes[plugin.id] = value;
          });
          _saveCardSizes();
        }
      });
    } catch (e) {
      debugPrint('Error showing card size menu: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // 延迟获取插件列表，确保插件管理器已经完成初始化
    _pluginsFuture = Future.delayed(
      const Duration(milliseconds: 500),
      () => globalPluginManager.allPlugins,
    ).then((plugins) async {
      // 加载插件卡片大小设置
      await _loadCardSizes();
      // 检查是否有最后打开的插件
      if (!mounted) return plugins;
      
      final config = await globalConfigManager.getPluginConfig(
        'last_opened_plugin',
      );
      final lastPluginId = config?['pluginId'] as String?;

      if (lastPluginId != null && plugins.isNotEmpty && mounted) {
        final lastPlugin = plugins.firstWhere(
          (p) => p.id == lastPluginId,
          orElse: () => plugins.first,
        );
        Future.microtask(() {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => lastPlugin.buildMainView(context),
            ),
          );
        });
      }
      return plugins;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(titleKey: 'pluginManager'),
      drawer: const AppDrawer(),
      floatingActionButton: null,
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
                  int crossAxisCount = 2;
                  // 创建布局模式
                  final List<QuiltedGridTile> pattern = [];
                  for (var plugin in plugins) {
                    final cardSize = _getCardSize(plugin.id);
                    if (cardSize == CardSize.wide) {
                      pattern.add(QuiltedGridTile(1, crossAxisCount)); // 宽卡片占据整行
                    } else {
                      pattern.add(QuiltedGridTile(1, 1)); // 小卡片占据1x1
                    }
                  }

                  return GridView.custom(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      pattern: pattern,
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final plugin = plugins[index];
                        // 获取插件自定义卡片视图或使用默认卡片
                        final customCardView = plugin.buildCardView(context);

                      // 使用Builder来获取卡片自己的context
                      Widget cardContent = Builder(
                        builder: (cardContext) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onLongPress: () {
                              _showCardSizeMenu(cardContext, plugin);
                            },
                            child: Card(
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
                                child: customCardView ?? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
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
                                          plugin.icon ?? Icons.extension,
                                          size: 36,
                                          color: plugin.color ?? Theme.of(context).primaryColor,
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
                            ),
                          ),
                        ),
                      );
                      // 直接返回卡片内容，QuiltedGridView会根据pattern参数处理布局
                      return cardContent;
                      },
                      childCount: plugins.length,
                    ),
                  );
                },
              );
        },
      ),
    );
  }
}