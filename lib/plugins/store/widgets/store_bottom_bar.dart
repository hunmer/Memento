import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:Memento/plugins/store/widgets/store_view/badge_icon.dart';
import 'package:Memento/plugins/store/widgets/store_view/archived_products.dart';
import 'package:Memento/plugins/store/widgets/add_product_page.dart';
import 'package:Memento/plugins/store/store_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// Store 插件的底部栏组件
/// 提供 flutter_floating_bottom_bar 原生样式的 Tab 切换功能
class StoreBottomBar extends StatefulWidget {
  final StorePlugin plugin;

  const StoreBottomBar({
    super.key,
    required this.plugin,
  });

  @override
  State<StoreBottomBar> createState() => _StoreBottomBarState();
}

class _StoreBottomBarState extends State<StoreBottomBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentPage;

  // 使用插件主题色和辅助色
  final List<Color> _colors = [
    Colors.pinkAccent,        // Tab0 - 商品列表 (插件主色)
    Colors.deepPurpleAccent,  // Tab1 - 我的物品
    Colors.greenAccent,       // Tab2 - 积分历史
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.animation?.addListener(() {
      final value = _tabController.animation!.value.round();
      if (value != _currentPage && mounted) {
        setState(() {
          _currentPage = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color unselectedColor = isDark
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.6);
    final l10n = StoreLocalizations.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: BottomBar(
        fit: StackFit.expand,
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              if (_tabController.indexIsChanging) return;
              if (_currentPage != 0) {
                _tabController.animateTo(0);
              }
            },
            icon: Icon(
              Icons.keyboard_arrow_up,
              color: _colors[_currentPage],
              size: width,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(25),
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        showIcon: true,
        width: MediaQuery.of(context).size.width * 0.85,
        barColor: Theme.of(context).scaffoldBackgroundColor,
        start: 2,
        end: 0,
        offset: 12,
        barAlignment: Alignment.bottomCenter,
        iconHeight: 35,
        iconWidth: 35,
        reverse: false,
        barDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _colors[_currentPage].withOpacity(0.3),
            width: 1,
          ),
        ),
        iconDecoration: BoxDecoration(
          color: _colors[_currentPage].withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _colors[_currentPage].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        hideOnScroll: !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS && defaultTargetPlatform != TargetPlatform.windows && defaultTargetPlatform != TargetPlatform.linux,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body: (context, controller) => TabBarView(
          controller: _tabController,
          dragStartBehavior: DragStartBehavior.start,
          physics: const BouncingScrollPhysics(),
          children: [
            // Tab0: 商品列表内容
            _buildProductListContent(),
            // Tab1: 我的物品内容
            _buildUserItemsContent(),
            // Tab2: 积分历史内容
            _buildPointsHistoryContent(),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              labelColor: _currentPage < 3 ? _colors[_currentPage] : unselectedColor,
              unselectedLabelColor: unselectedColor,
              tabs: [
                Tab(
                  icon: StreamBuilder<int>(
                    stream: widget.plugin.controller.productsStream,
                    initialData: widget.plugin.controller.products.length,
                    builder: (context, snapshot) {
                      return BadgeIcon(
                        icon: const Icon(Icons.shopping_bag),
                        count: snapshot.data ?? 0,
                      );
                    },
                  ),
                  text: l10n.productList,
                ),
                Tab(
                  icon: StreamBuilder<int>(
                    stream: widget.plugin.controller.userItemsStream,
                    initialData: widget.plugin.controller.userItems.length,
                    builder: (context, snapshot) {
                      return BadgeIcon(
                        icon: const Icon(Icons.inventory),
                        count: snapshot.data ?? 0,
                      );
                    },
                  ),
                  text: l10n.myItems,
                ),
                Tab(
                  icon: StreamBuilder<int>(
                    stream: widget.plugin.controller.pointsStream,
                    initialData: widget.plugin.controller.currentPoints,
                    builder: (context, snapshot) {
                      return BadgeIcon(
                        icon: const Icon(Icons.history),
                        count: snapshot.data ?? 0,
                        isPoints: true,
                      );
                    },
                  ),
                  text: l10n.pointsHistory,
                ),
              ],
            ),
            Positioned(
              top: -25,
              child: FloatingActionButton(
                heroTag: 'store_fab',
                backgroundColor: widget.plugin.color,
                elevation: 4,
                shape: const CircleBorder(),
                child: Icon(
                  _currentPage == 0 ? Icons.add_shopping_cart :
                  _currentPage == 1 ? Icons.receipt_long :
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  if (_currentPage == 0) {
                    _navigateToAddProduct(context);
                  } else if (_currentPage == 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.viewRedeemHistory),
                      ),
                    );
                  } else {
                    _showAddPointsDialog(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据当前页面构建 AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context, StoreLocalizations l10n) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => PluginManager.toHomeScreen(context),
      ),
      title: Text(
        _currentPage == 0
            ? l10n.storeTitle
            : _currentPage == 1
                ? l10n.myItems
                : l10n.pointsHistory,
      ),
      actions: _buildAppBarActions(context, l10n),
    );
  }

  /// 根据当前页面构建 AppBar 操作按钮
  List<Widget> _buildAppBarActions(BuildContext context, StoreLocalizations l10n) {
    if (_currentPage == 0) {
      // 商品列表页面的操作按钮
      return [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortDialog(context, l10n),
          tooltip: l10n.sortAndFilter,
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.archive),
              if (widget.plugin.controller.archivedProducts.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${widget.plugin.controller.archivedProducts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArchivedProductsPage(
                  controller: widget.plugin.controller,
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          tooltip: l10n.viewArchivedProducts,
        ),
      ];
    } else if (_currentPage == 1) {
      // 我的物品页面的操作按钮
      return [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: () => _showFilterDialog(context, l10n),
          tooltip: l10n.itemFilter,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showClearItemsConfirmation(context, l10n),
          tooltip: l10n.clear,
        ),
      ];
    } else {
      // 积分历史页面的操作按钮
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: StreamBuilder<int>(
              stream: widget.plugin.controller.pointsStream,
              initialData: widget.plugin.controller.currentPoints,
              builder: (context, snapshot) {
                return Chip(
                  avatar: const Icon(Icons.stars, size: 18),
                  label: Text('${snapshot.data ?? 0}'),
                );
              },
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showClearPointsLogsConfirmation(context, l10n),
          tooltip: l10n.clear,
        ),
      ];
    }
  }

  /// 构建商品列表内容
  Widget _buildProductListContent() {
    // 去重处理
    final uniqueProducts = widget.plugin.controller.products
        .fold<Map<String, dynamic>>({}, (map, product) {
          if (!map.containsKey(product.id)) {
            map[product.id] = product;
          }
          return map;
        })
        .values
        .toList();

    if (uniqueProducts.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noProducts),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: uniqueProducts.length,
      itemBuilder: (context, index) {
        final product = uniqueProducts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductPage(
                  controller: widget.plugin.controller,
                  product: product,
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: product.image.isNotEmpty
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 48);
                            },
                          )
                        : const Icon(Icons.image, size: 48),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.price} 积分',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('库存: ${product.stock}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建我的物品内容
  Widget _buildUserItemsContent() {
    if (widget.plugin.controller.userItems.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noItems),
      );
    }

    final items = widget.plugin.controller.userItems;
    final now = DateTime.now();
    final groupedItems = <String, dynamic>{};

    for (final item in items) {
      final key = '${item.productId}_${item.purchasePrice}';
      if (groupedItems.containsKey(key)) {
        groupedItems[key]['count']++;
      } else {
        groupedItems[key] = {'item': item, 'count': 1};
      }
    }

    final groups = groupedItems.values.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final item = group['item'];
        final count = group['count'];
        final isExpired = item.expireDate.isBefore(now);

        return Card(
          color: isExpired ? Colors.grey[300] : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey[400] : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: isExpired ? Colors.grey[600] : Theme.of(context).primaryColor,
                        ),
                      ),
                      if (count > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['item'].productName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (isExpired)
                      const Text(
                        '已过期',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      Text(
                        '剩余: ${group['item'].remaining}',
                        style: const TextStyle(color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建积分历史内容
  Widget _buildPointsHistoryContent() {
    if (widget.plugin.controller.pointsLogs.isEmpty) {
      return Center(
        child: Text(StoreLocalizations.of(context).noRecords),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.plugin.controller.pointsLogs.length,
      itemBuilder: (context, index) {
        final log = widget.plugin.controller.pointsLogs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              log.type == '获得' ? Icons.add : Icons.remove,
              color: log.type == '获得' ? Colors.green : Colors.red,
            ),
            title: Text(
              StoreLocalizations.of(context)
                  .pointsHistoryEntry
                  .replaceFirst('{value}', log.value.toString())
                  .replaceFirst('{type}', log.type),
            ),
            subtitle: Text(log.reason),
            trailing: Text(
              '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      },
    );
  }

  /// 添加商品
  void _navigateToAddProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProductPage(
          controller: widget.plugin.controller,
        ),
      ),
    );
  }

  /// 显示添加积分对话框
  void _showAddPointsDialog(BuildContext context) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    final l10n = StoreLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPointsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.pointsAmount,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.pointsReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final points = int.tryParse(controller.text);
              final reason = reasonController.text.trim();

              if (points != null && reason.isNotEmpty) {
                await widget.plugin.controller.addPoints(points, reason);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pointsAdded)),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入有效的积分数量和原因'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  /// 显示排序对话框
  void _showSortDialog(BuildContext context, StoreLocalizations l10n) {
    String? selectedSort;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.sortAndFilter),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sortMethod,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.byStock),
                    value: 'stock',
                    groupValue: selectedSort,
                    onChanged: (value) =>
                        setDialogState(() => selectedSort = value),
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.byPrice),
                    value: 'price',
                    groupValue: selectedSort,
                    onChanged: (value) =>
                        setDialogState(() => selectedSort = value),
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.byExpiry),
                    value: 'exchangeEnd',
                    groupValue: selectedSort,
                    onChanged: (value) =>
                        setDialogState(() => selectedSort = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedSort != null) {
                      widget.plugin.controller.sortProducts(selectedSort!);
                      setState(() {});
                    }
                    Navigator.pop(context);
                  },
                  child: Text(l10n.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog(BuildContext context, StoreLocalizations l10n) {
    int statusIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.itemFilter),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.itemStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<int>(
                    title: Text(l10n.all),
                    value: 0,
                    groupValue: statusIndex,
                    onChanged: (value) {
                      setDialogState(() => statusIndex = value!);
                    },
                  ),
                  RadioListTile<int>(
                    title: Text(l10n.usable),
                    value: 1,
                    groupValue: statusIndex,
                    onChanged: (value) {
                      setDialogState(() => statusIndex = value!);
                    },
                  ),
                  RadioListTile<int>(
                    title: Text(l10n.expired),
                    value: 2,
                    groupValue: statusIndex,
                    onChanged: (value) {
                      setDialogState(() => statusIndex = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Text(l10n.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示清空物品确认对话框
  void _showClearItemsConfirmation(BuildContext context, StoreLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmClearTitle),
        content: Text(l10n.confirmClearItemsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await widget.plugin.controller.clearUserItems();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.itemsCleared)),
              );
            },
            child: Text(
              l10n.clear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示清空积分记录确认对话框
  void _showClearPointsLogsConfirmation(BuildContext context, StoreLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmClearTitle),
        content: Text(l10n.confirmClearPointsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              await widget.plugin.controller.clearPointsLogs();
              if (mounted) setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.pointsCleared)),
              );
            },
            child: Text(
              l10n.clear,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}