import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'warehouse_detail_screen.dart';
import 'package:Memento/plugins/goods/widgets/warehouse_card.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key, this.onWarehouseTap});

  final Function(String warehouseId)? onWarehouseTap;

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    GoodsPlugin.instance.addListener(_onWarehousesChanged);
  }

  @override
  void dispose() {
    GoodsPlugin.instance.removeListener(_onWarehousesChanged);
    super.dispose();
  }

  void _onWarehousesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 根据搜索关键词过滤仓库列表
  List<dynamic> _filterWarehouses(List<dynamic> warehouses) {
    if (_searchQuery.isEmpty) {
      return warehouses;
    }

    return warehouses.where((warehouse) {
      return warehouse.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = GoodsPlugin.instance.warehouses;
    final filteredWarehouses = _filterWarehouses(warehouses);

    return SuperCupertinoNavigationWrapper(
      title: Text('goods_allWarehouses'.tr),
      largeTitle: 'goods_allWarehouses'.tr,
      body: filteredWarehouses.isEmpty && _searchQuery.isNotEmpty
          ? _buildEmptySearchView()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              itemCount: filteredWarehouses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final warehouse = filteredWarehouses[index];
                return WarehouseCard(
                  warehouse: warehouse,
                  onTap: () {
                    if (widget.onWarehouseTap != null) {
                      widget.onWarehouseTap!(warehouse.id);
                    } else {
                      NavigationHelper.push(
                        context,
                        WarehouseDetailScreen(warehouse: warehouse),
                      );
                    }
                  },
                );
              },
            ),
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: '搜索仓库名称',
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
    );
  }

  /// 构建空搜索结果视图
  Widget _buildEmptySearchView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的仓库',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试其他搜索关键词',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
