import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/core/route/route_history_manager.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/plugins/goods/goods_plugin.dart';
import 'warehouse_detail_screen.dart';
import 'package:Memento/plugins/goods/widgets/warehouse_card.dart';
import 'package:Memento/plugins/goods/widgets/warehouse_form.dart';

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

    // 设置路由上下文
    _updateRouteContext();
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前页面状态
  void _updateRouteContext() {
    RouteHistoryManager.updateCurrentContext(
      pageId: "/goods/warehouses",
      title: '物品 - 所有仓库',
      params: {},
    );
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
                  onEdit: () {
                    _showEditWarehouse(context, warehouse);
                  },
                  onDelete: () {
                    _showDeleteWarehouseDialog(context, warehouse);
                  },
                );
              },
            ),
      enableLargeTitle: true,
      enableSearchBar: true,
      searchPlaceholder: 'goods_searchWarehouse'.tr,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
    );
  }

  /// 显示编辑仓库表单
  void _showEditWarehouse(BuildContext context, dynamic warehouse) {
    NavigationHelper.push(
      context,
      WarehouseForm(
        warehouse: warehouse,
        onSave: (updatedWarehouse) async {
          await GoodsPlugin.instance.saveWarehouse(updatedWarehouse);
          if (context.mounted) {
            setState(() {});
          }
        },
        onDelete: () async {
          await GoodsPlugin.instance.deleteWarehouse(warehouse.id);
          if (context.mounted) {
            Navigator.pop(context); // 关闭表单
            setState(() {});
          }
        },
      ),
    );
  }

  /// 显示删除仓库确认对话框
  void _showDeleteWarehouseDialog(BuildContext context, dynamic warehouse) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('goods_confirmDelete'.tr),
        content: Text(
          'goods_confirmDeleteWarehouseMessage'.trParams(
            {'warehouseName': warehouse.title},
          ),
        ),
        actions: [
          TextButton(
            child: Text('goods_cancel'.tr),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context, true);
              await GoodsPlugin.instance.deleteWarehouse(warehouse.id);
              if (context.mounted) {
                setState(() {});
              }
            },
            child: Text('goods_delete'.tr),
          ),
        ],
      ),
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
