import 'package:flutter/material.dart';
import '../../core/plugin_base.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_bar_widget.dart';
import '../../main.dart';
import 'card_size.dart';
import 'card_size_manager.dart';
import 'plugin_order_manager.dart';
import 'plugin_grid.dart';
import 'dart:math';

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

  // 显示卡片大小调整对话框
  void _showCardSizeDialog(BuildContext context, PluginBase plugin) {
    if (_isReorderMode) return;

    final currentSize = _cardSizeManager.getCardSize(plugin.id);
    int currentWidth = currentSize.width;
    int currentHeight = currentSize.height;
    final int maxColumns = (MediaQuery.of(context).size.width / 150).floor(); // 假设每列最小宽度为150

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('调整卡片大小'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('宽度: '),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: maxColumns.toDouble(),
                          divisions: maxColumns - 1,
                          value: currentWidth.toDouble(),
                          label: currentWidth.toString(),
                          onChanged: (double value) {
                            setState(() {
                              currentWidth = value.round();
                            });
                          },
                        ),
                      ),
                      Text('$currentWidth'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('高度: '),
                      Expanded(
                        child: Slider(
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
                      ),
                      Text('$currentHeight'),
                    ],
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
                    setState(() {
                      _cardSizeManager.cardSizes[plugin.id] = CardSize(
                        width: currentWidth,
                        height: currentHeight,
                      );
                      _cardSizeManager.saveCardSizes();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
    ]);
    return globalPluginManager.allPlugins;
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
            onShowCardSizeMenu: _showCardSizeDialog,
          );
        },
      ),
    );
  }
}