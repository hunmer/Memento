import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_bar_widget.dart';
import '../../main.dart';
import 'card_size.dart';
import 'card_size_manager.dart';
import 'plugin_order_manager.dart';
import 'plugin_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<PluginBase>> _pluginsFuture;
  final CardSizeManager _cardSizeManager = CardSizeManager();
  final PluginOrderManager _pluginOrderManager = PluginOrderManager();
  bool _isReorderMode = false;
  final Map<String, int> _tallCardHeights = {};

  // 显示列高度选择对话框
  void _showHeightSelectionDialog(BuildContext context, PluginBase plugin) {
    int currentHeight = _tallCardHeights[plugin.id] ?? 2;  // 默认高度为2

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('调整卡片高度'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('当前高度: $currentHeight'),
                  Slider(
                    min: 1,
                    max: 4,
                    divisions: 3,
                    value: currentHeight.toDouble(),
                    label: currentHeight.toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentHeight = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('确定'),
                  onPressed: () {
                    _tallCardHeights[plugin.id] = currentHeight;
                    _saveCardHeights();
                    Navigator.of(context).pop();
                    // 刷新UI
                    this.setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 保存卡片高度设置
  Future<void> _saveCardHeights() async {
    try {
      await globalConfigManager.savePluginConfig('tall_card_heights', {
        'heights': _tallCardHeights,
      });
    } catch (e) {
      debugPrint('Error saving card heights: $e');
    }
  }

  // 加载卡片高度设置
  Future<void> _loadCardHeights() async {
    try {
      final heightsConfig = await globalConfigManager.getPluginConfig('tall_card_heights');
      if (heightsConfig != null) {
        final heights = heightsConfig['heights'] as Map<dynamic, dynamic>?;
        if (heights != null) {
          _tallCardHeights.clear();
          heights.forEach((key, value) {
            _tallCardHeights[key.toString()] = (value as num).toInt();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading card heights: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _pluginsFuture = _initializePlugins();
  }

  Future<List<PluginBase>> _initializePlugins() async {
    await Future.wait([
      _cardSizeManager.loadCardSizes(),
      _pluginOrderManager.loadPluginOrder(),
      _loadCardHeights(),
    ]);
    return globalPluginManager.allPlugins;
  }

  // 在指定位置显示卡片大小调整菜单
  void _showCardSizeMenu(BuildContext cardContext, PluginBase plugin) {
    if (_isReorderMode) return;

    final RenderBox button = cardContext.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 100,
      ),
      items: [
        PopupMenuItem(
          value: CardSize.small,
          child: Row(
            children: [
              Icon(
                Icons.crop_square,
                color: _cardSizeManager.getCardSize(plugin.id) == CardSize.small
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('小卡片'),
            ],
          ),
        ),
        PopupMenuItem(
          value: CardSize.wide,
          child: Row(
            children: [
              Icon(
                Icons.crop_7_5,
                color: _cardSizeManager.getCardSize(plugin.id) == CardSize.wide
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('宽卡片'),
            ],
          ),
        ),
        PopupMenuItem(
          value: CardSize.tall,
          child: Row(
            children: [
              Icon(
                Icons.crop_portrait,
                color: _cardSizeManager.getCardSize(plugin.id) == CardSize.tall
                    ? Theme.of(context).primaryColor
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('长卡片'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _cardSizeManager.cardSizes[plugin.id] = value;
        });
        _cardSizeManager.saveCardSizes();
        
        // 如果选择了长卡片，显示高度选择对话框
        if (value == CardSize.tall) {
          _showHeightSelectionDialog(context, plugin);
        }
      }
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
          final List<PluginBase> plugins = globalPluginManager.allPlugins;
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final plugin = plugins[oldIndex];
      plugins.removeAt(oldIndex);
      plugins.insert(newIndex, plugin);

      // 更新插件顺序
      _pluginOrderManager.pluginOrder = plugins.map((p) => p.id).toList();
      _pluginOrderManager.savePluginOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.done : Icons.sort),
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<PluginBase>>(
        future: _pluginsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No plugins available'),
            );
          }

          return PluginGrid(
            plugins: snapshot.data!,
            isReorderMode: _isReorderMode,
            cardSizes: _cardSizeManager.cardSizes,
            pluginOrder: _pluginOrderManager.pluginOrder,
            onReorder: _handleReorder,
            onShowCardSizeMenu: _showCardSizeMenu,
            tallCardHeights: _tallCardHeights,
          );
        },
      ),
    );
  }
}