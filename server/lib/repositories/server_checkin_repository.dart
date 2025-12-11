/// Checkin 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Checkin Repository 实现
class ServerCheckinRepository implements ICheckinRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'checkin';

  ServerCheckinRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有打卡项目
  Future<List<CheckinItemDto>> _readAllItems() async {
    final itemsData = await dataService.readPluginData(
      userId,
      _pluginId,
      'items.json',
    );
    if (itemsData == null) return [];

    final items = itemsData['items'] as List<dynamic>? ?? [];
    return items.map((i) => CheckinItemDto.fromJson(i as Map<String, dynamic>)).toList();
  }

  /// 保存所有打卡项目
  Future<void> _saveAllItems(List<CheckinItemDto> items) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'items.json',
      {'items': items.map((i) => i.toJson()).toList()},
    );
  }

  // ============ Repository 实现 ============

  @override
  Future<Result<List<CheckinItemDto>>> getItems({
    PaginationParams? pagination,
  }) async {
    try {
      var items = await _readAllItems();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          items,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(items);
    } catch (e) {
      return Result.failure('获取打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinItemDto?>> getItemById(String id) async {
    try {
      final items = await _readAllItems();
      final item = items.where((i) => i.id == id).firstOrNull;
      return Result.success(item);
    } catch (e) {
      return Result.failure('获取打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinItemDto>> createItem(CheckinItemDto item) async {
    try {
      final items = await _readAllItems();
      items.add(item);
      await _saveAllItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('创建打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinItemDto>> updateItem(String id, CheckinItemDto item) async {
    try {
      final items = await _readAllItems();
      final index = items.indexWhere((i) => i.id == id);

      if (index == -1) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      items[index] = item;
      await _saveAllItems(items);
      return Result.success(item);
    } catch (e) {
      return Result.failure('更新打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteItem(String id) async {
    try {
      final items = await _readAllItems();
      final initialLength = items.length;
      items.removeWhere((i) => i.id == id);

      if (items.length == initialLength) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      await _saveAllItems(items);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinItemDto>> addCheckinRecord(
    String itemId,
    CheckinRecordDto record,
  ) async {
    try {
      final items = await _readAllItems();
      final index = items.indexWhere((i) => i.id == itemId);

      if (index == -1) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      final item = items[index];
      final dateKey = '${record.checkinTime.year}-${record.checkinTime.month.toString().padLeft(2, '0')}-${record.checkinTime.day.toString().padLeft(2, '0')}';

      final updatedRecords = Map<String, List<CheckinRecordDto>>.from(item.checkInRecords);
      if (!updatedRecords.containsKey(dateKey)) {
        updatedRecords[dateKey] = [];
      }
      updatedRecords[dateKey]!.add(record);

      final updatedItem = item.copyWith(checkInRecords: updatedRecords);
      items[index] = updatedItem;
      await _saveAllItems(items);

      return Result.success(updatedItem);
    } catch (e) {
      return Result.failure('添加打卡记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinItemDto>> deleteCheckinRecord(
    String itemId,
    String date,
    int recordIndex,
  ) async {
    try {
      final items = await _readAllItems();
      final index = items.indexWhere((i) => i.id == itemId);

      if (index == -1) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      final item = items[index];
      final updatedRecords = Map<String, List<CheckinRecordDto>>.from(item.checkInRecords);

      if (!updatedRecords.containsKey(date) || updatedRecords[date]!.isEmpty) {
        return Result.failure('打卡记录不存在', code: ErrorCodes.notFound);
      }

      if (recordIndex < 0 || recordIndex >= updatedRecords[date]!.length) {
        return Result.failure('记录索引无效', code: ErrorCodes.invalidParams);
      }

      updatedRecords[date]!.removeAt(recordIndex);
      if (updatedRecords[date]!.isEmpty) {
        updatedRecords.remove(date);
      }

      final updatedItem = item.copyWith(checkInRecords: updatedRecords);
      items[index] = updatedItem;
      await _saveAllItems(items);

      return Result.success(updatedItem);
    } catch (e) {
      return Result.failure('删除打卡记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<CheckinStatsDto>> getStats() async {
    try {
      final items = await _readAllItems();
      final totalItems = items.length;
      final totalCheckins = items.fold<int>(0, (sum, item) {
        return sum + item.checkInRecords.values.fold<int>(0, (itemSum, records) => itemSum + records.length);
      });

      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayCheckins = items.fold<int>(0, (sum, item) {
        final todayRecords = item.checkInRecords[todayStr];
        return sum + (todayRecords?.length ?? 0);
      });

      final todayCompletedItems = items.where((item) {
        final todayRecords = item.checkInRecords[todayStr];
        return todayRecords != null && todayRecords.isNotEmpty;
      }).length;

      final completionRate = totalItems > 0 ? todayCompletedItems / totalItems : 0.0;

      // 按分组统计
      final groupStats = <String, int>{};
      for (final item in items) {
        groupStats[item.group] = (groupStats[item.group] ?? 0) + 1;
      }

      return Result.success(CheckinStatsDto(
        totalCheckins: totalCheckins,
        todayCheckins: todayCheckins,
        totalItems: totalItems,
        todayCompletedItems: todayCompletedItems,
        completionRate: completionRate,
        groupStats: groupStats,
      ));
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
