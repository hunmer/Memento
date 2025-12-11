import 'package:shared_models/shared_models.dart';
import 'package:Memento/plugins/goods/models/warehouse.dart';
import 'package:Memento/plugins/goods/models/goods_item.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart';
import 'package:flutter/material.dart';

/// Goods 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 GoodsPlugin 方法来实现 IGoodsRepository 接口
class ClientGoodsRepository extends IGoodsRepository {
  final dynamic plugin; // GoodsPlugin 实例
  final Color pluginColor;

  ClientGoodsRepository({
    required this.plugin,
    required this.pluginColor,
  });

  // ============ 仓库操作 ============

  @override
  Future<Result<List<WarehouseDto>>> getWarehouses({
    PaginationParams? pagination,
  }) async {
    try {
      final warehouses = plugin.warehouses as List<Warehouse>;
      final dtos = warehouses.map(_warehouseToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto?>> getWarehouseById(String id) async {
    try {
      final warehouse = plugin.getWarehouse(id);
      if (warehouse == null) {
        return Result.success(null);
      }
      return Result.success(_warehouseToDto(warehouse));
    } catch (e) {
      return Result.failure('获取仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto>> createWarehouse(WarehouseDto dto) async {
    try {
      final warehouse = Warehouse(
        id: dto.id,
        title: dto.name,
        icon: dto.icon != null
            ? IconData(
                int.parse(dto.icon!.replaceAll('0x', ''), radix: 16),
                fontFamily: 'MaterialIcons',
              )
            : Icons.inventory_2,
        iconColor: dto.color != null
            ? Color(int.parse(dto.color!.replaceAll('#', ''), radix: 16) | 0xFF000000)
            : pluginColor,
        imageUrl: dto.description, // 使用 description 字段存储 imageUrl
        items: [],
      );

      await plugin.saveWarehouse(warehouse);
      return Result.success(_warehouseToDto(warehouse));
    } catch (e) {
      return Result.failure('创建仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<WarehouseDto>> updateWarehouse(String id, WarehouseDto dto) async {
    try {
      // 获取现有仓库
      final existingWarehouse = plugin.getWarehouse(id);
      if (existingWarehouse == null) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      // 创建更新后的仓库
      final updatedWarehouse = existingWarehouse.copyWith(
        title: dto.name,
        icon: dto.icon != null
            ? IconData(
                int.parse(dto.icon!.replaceAll('0x', ''), radix: 16),
                fontFamily: 'MaterialIcons',
              )
            : null,
        iconColor: dto.color != null
            ? Color(int.parse(dto.color!.replaceAll('#', ''), radix: 16) | 0xFF000000)
            : null,
        imageUrl: dto.description, // 临时使用 description 字段存储 imageUrl
      );

      await plugin.saveWarehouse(updatedWarehouse);
      return Result.success(_warehouseToDto(updatedWarehouse));
    } catch (e) {
      return Result.failure('更新仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteWarehouse(String id) async {
    try {
      await plugin.deleteWarehouse(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除仓库失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 物品操作 ============

  @override
  Future<Result<List<GoodsItemDto>>> getItems({
    String? warehouseId,
    PaginationParams? pagination,
  }) async {
    try {
      List<GoodsItem> items = [];

      if (warehouseId != null && warehouseId.isNotEmpty) {
        // 获取指定仓库的物品
        final warehouse = plugin.getWarehouse(warehouseId);
        if (warehouse != null) {
          items = warehouse.items;
        }
      } else {
        // 获取所有仓库的所有物品
        for (var warehouse in plugin.warehouses) {
          items.addAll(_getAllItemsRecursively(warehouse.items));
        }
      }

      final dtos = items.map(_goodsItemToDto).toList();

      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto?>> getItemById(String id) async {
    try {
      final result = plugin.findGoodsItemById(id);
      if (result == null) {
        return Result.success(null);
      }
      return Result.success(_goodsItemToDto(result.item));
    } catch (e) {
      return Result.failure('获取物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto>> createItem(String warehouseId, GoodsItemDto dto) async {
    try {
      // 检查仓库是否存在
      final warehouse = plugin.getWarehouse(warehouseId);
      if (warehouse == null) {
        return Result.failure('仓库不存在', code: ErrorCodes.notFound);
      }

      // 检查ID是否已存在
      final existingItem = plugin.findGoodsItemById(dto.id);
      if (existingItem != null) {
        return Result.failure('物品ID已存在: ${dto.id}', code: ErrorCodes.conflict);
      }

      // 将 DTO 转换为 GoodsItem
      final item = _dtoToGoodsItem(dto);
      await plugin.saveGoodsItem(warehouseId, item);

      return Result.success(dto);
    } catch (e) {
      return Result.failure('创建物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<GoodsItemDto>> updateItem(String warehouseId, String id, GoodsItemDto dto) async {
    try {
      // 查找物品
      final result = plugin.findGoodsItemById(id);
      if (result == null) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      // 检查仓库ID是否匹配
      if (result.warehouseId != warehouseId) {
        return Result.failure('物品不在指定仓库中', code: ErrorCodes.invalidParams);
      }

      // 将 DTO 转换为 GoodsItem
      final item = _dtoToGoodsItem(dto);
      await plugin.saveGoodsItem(warehouseId, item);

      return Result.success(dto);
    } catch (e) {
      return Result.failure('更新物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteItem(String warehouseId, String id) async {
    try {
      // 查找物品
      final result = plugin.findGoodsItemById(id);
      if (result == null) {
        return Result.failure('物品不存在', code: ErrorCodes.notFound);
      }

      // 检查仓库ID是否匹配
      if (result.warehouseId != warehouseId) {
        return Result.failure('物品不在指定仓库中', code: ErrorCodes.invalidParams);
      }

      await plugin.deleteGoodsItem(warehouseId, id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<GoodsItemDto>>> searchItems(GoodsItemQuery query) async {
    try {
      List<GoodsItem> allItems = [];

      // 获取所有物品
      if (query.warehouseId != null && query.warehouseId!.isNotEmpty) {
        final warehouse = plugin.getWarehouse(query.warehouseId!);
        if (warehouse != null) {
          allItems = _getAllItemsRecursively(warehouse.items);
        }
      } else {
        for (var warehouse in plugin.warehouses) {
          allItems.addAll(_getAllItemsRecursively(warehouse.items));
        }
      }

      // 应用过滤条件
      final matches = <GoodsItem>[];

      for (final item in allItems) {
        bool isMatch = true;

        // 按关键词搜索（名称和描述）
        if (query.keyword != null && query.keyword!.isNotEmpty) {
          final keyword = query.keyword!.toLowerCase();
          final nameMatch = item.title.toLowerCase().contains(keyword);
          final descMatch = (item.notes ?? '').toLowerCase().contains(keyword);
          isMatch = nameMatch || descMatch;
        }

        // 按分类过滤
        if (isMatch && query.category != null && query.category!.isNotEmpty) {
          // GoodsItem 没有 category 字段，暂时跳过
        }

        // 按标签过滤
        if (isMatch && query.tags != null && query.tags!.isNotEmpty) {
          for (final tag in query.tags!) {
            if (!item.tags.contains(tag)) {
              isMatch = false;
              break;
            }
          }
        }

        // 按字段过滤
        if (isMatch && query.field != null && query.field!.isNotEmpty) {
          final itemJson = item.toJson();
          final fieldValue = itemJson[query.field!]?.toString() ?? '';
          if (query.fuzzy) {
            isMatch = fieldValue.toLowerCase().contains((query.value ?? '').toLowerCase());
          } else {
            isMatch = fieldValue == (query.value ?? '');
          }
        }

        if (isMatch) {
          matches.add(item);
          if (!query.findAll) break;
        }
      }

      final dtos = matches.map(_goodsItemToDto).toList();

      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          dtos,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(dtos);
    } catch (e) {
      return Result.failure('搜索物品失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<Map<String, dynamic>>> getStats() async {
    try {
      final totalCount = plugin.getTotalItemsCount();
      final totalValue = plugin.getTotalItemsValue();
      final unusedCount = plugin.getUnusedItemsCount();
      final warehouseCount = plugin.warehouses.length;

      return Result.success({
        'totalCount': totalCount,
        'totalValue': totalValue,
        'unusedCount': unusedCount,
        'warehouseCount': warehouseCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  WarehouseDto _warehouseToDto(Warehouse warehouse) {
    return WarehouseDto(
      id: warehouse.id,
      name: warehouse.title,
      description: warehouse.imageUrl, // 映射 imageUrl 到 description
      icon: '0x${warehouse.icon.codePoint.toRadixString(16)}',
      color: '#${warehouse.iconColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      createdAt: DateTime.now(), // Warehouse 没有 createdAt 字段，使用当前时间
      updatedAt: DateTime.now(), // Warehouse 没有 updatedAt 字段，使用当前时间
    );
  }

  GoodsItemDto _goodsItemToDto(GoodsItem item) {
    return GoodsItemDto(
      id: item.id,
      name: item.title,
      description: item.notes,
      quantity: 1, // GoodsItem 没有 quantity 字段，默认1
      category: null, // GoodsItem 没有 category 字段
      tags: item.tags,
      customFields: item.customFields.isNotEmpty
          ? {
              for (var field in item.customFields)
                field.key: field.value,
            }
          : null,
      createdAt: DateTime.now(), // GoodsItem 没有 createdAt 字段
      updatedAt: DateTime.now(), // GoodsItem 没有 updatedAt 字段
    );
  }

  GoodsItem _dtoToGoodsItem(GoodsItemDto dto) {
    return GoodsItem(
      id: dto.id,
      title: dto.name,
      imageUrl: dto.description, // 临时使用 description 字段存储 imageUrl
      icon: null,
      iconColor: null,
      tags: dto.tags,
      purchaseDate: null, // GoodsItem 没有 purchaseDate 字段
      purchasePrice: null, // GoodsItem 没有 purchasePrice 字段
      usageRecords: [],
      customFields: dto.customFields != null
          ? dto.customFields!.entries
              .map((e) => CustomField(key: e.key, value: e.value.toString()))
              .toList()
          : [],
      notes: dto.description,
      subItems: [],
    );
  }

  /// 递归获取所有物品（包含子物品）
  List<GoodsItem> _getAllItemsRecursively(List<GoodsItem> items) {
    List<GoodsItem> result = [];
    for (var item in items) {
      result.add(item);
      if (item.subItems.isNotEmpty) {
        result.addAll(_getAllItemsRecursively(item.subItems));
      }
    }
    return result;
  }
}
