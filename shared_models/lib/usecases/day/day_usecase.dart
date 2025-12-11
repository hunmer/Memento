/// Day 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/day/day_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Day UseCase - 封装所有业务逻辑
class DayUseCase {
  final IDayRepository repository;
  final Uuid _uuid = const Uuid();

  DayUseCase(this.repository);

  // ============ 辅助方法 ============

  /// 从参数提取分页配置
  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }

  // ============ 纪念日操作 ============

  /// 获取所有纪念日
  ///
  /// [params] 可选参数:
  /// - `sortMode`: 排序模式 (upcoming, recent, manual)
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getMemorialDays(Map<String, dynamic> params) async {
    try {
      final sortMode = params['sortMode'] as String?;
      final pagination = _extractPagination(params);

      final result = await repository.getMemorialDays(
        sortMode: sortMode,
        pagination: pagination,
      );

      return result.map((days) {
        final jsonList = days.map((d) => d.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取纪念日列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取纪念日
  ///
  /// [params] 必需参数:
  /// - `id`: 纪念日 ID
  Future<Result<Map<String, dynamic>?>> getMemorialDayById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;

    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getMemorialDayById(id);
      return result.map((d) => d?.toJson());
    } catch (e) {
      return Result.failure('获取纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建纪念日
  ///
  /// [params] 必需参数:
  /// - `title`: 标题
  /// - `targetDate`: 目标日期 (ISO8601 字符串)
  /// - `backgroundColor`: 背景颜色
  /// 可选参数:
  /// - `notes`: 备注列表
  /// - `backgroundImageUrl`: 背景图片 URL
  /// - `sortIndex`: 排序索引
  Future<Result<Map<String, dynamic>>> createMemorialDay(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(titleValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final targetDateValidation =
        ParamValidator.requireString(params, 'targetDate');
    if (!targetDateValidation.isValid) {
      return Result.failure(targetDateValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final backgroundColorValidation =
        ParamValidator.requireInt(params, 'backgroundColor');
    if (!backgroundColorValidation.isValid) {
      return Result.failure(backgroundColorValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final targetDate = DateTime.parse(params['targetDate'] as String);

      final memorialDay = MemorialDayDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        creationDate: DateTime.now(),
        targetDate: targetDate,
        notes: (params['notes'] as List<dynamic>?)?.cast<String>() ?? [],
        backgroundColor: params['backgroundColor'] as int,
        backgroundImageUrl: params['backgroundImageUrl'] as String?,
        sortIndex: params['sortIndex'] as int? ?? 0,
      );

      final result = await repository.createMemorialDay(memorialDay);
      return result.map((d) => d.toJson());
    } catch (e) {
      return Result.failure('创建纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新纪念日
  ///
  /// [params] 必需参数:
  /// - `id`: 纪念日 ID
  /// 可选参数（至少提供一个）:
  /// - `title`: 标题
  /// - `targetDate`: 目标日期
  /// - `notes`: 备注列表
  /// - `backgroundColor`: 背景颜色
  /// - `backgroundImageUrl`: 背景图片 URL
  /// - `sortIndex`: 排序索引
  Future<Result<Map<String, dynamic>>> updateMemorialDay(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有纪念日
      final existingResult = await repository.getMemorialDayById(id);
      if (existingResult.isFailure) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('纪念日不存在', code: ErrorCodes.notFound);
      }

      // 解析日期
      DateTime? targetDate;
      if (params.containsKey('targetDate')) {
        final targetDateStr = params['targetDate'] as String?;
        if (targetDateStr != null && targetDateStr.isNotEmpty) {
          targetDate = DateTime.parse(targetDateStr);
        }
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        targetDate: targetDate ?? existing.targetDate,
        notes: params.containsKey('notes')
            ? (params['notes'] as List<dynamic>?)?.cast<String>() ?? []
            : existing.notes,
        backgroundColor:
            params['backgroundColor'] as int? ?? existing.backgroundColor,
        backgroundImageUrl: params['backgroundImageUrl'] as String? ??
            existing.backgroundImageUrl,
        sortIndex: params['sortIndex'] as int? ?? existing.sortIndex,
      );

      final result = await repository.updateMemorialDay(id, updated);
      return result.map((d) => d.toJson());
    } catch (e) {
      return Result.failure('更新纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除纪念日
  ///
  /// [params] 必需参数:
  /// - `id`: 纪念日 ID
  Future<Result<Map<String, dynamic>>> deleteMemorialDay(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteMemorialDay(id);
      return result.map((success) => {
            'deleted': success,
            'id': id,
          });
    } catch (e) {
      return Result.failure('删除纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 重新排序纪念日
  ///
  /// [params] 必需参数:
  /// - `orderedIds`: 有序的 ID 列表
  Future<Result<Map<String, dynamic>>> reorderMemorialDays(
      Map<String, dynamic> params) async {
    final orderedIds = params['orderedIds'] as List<dynamic>?;

    if (orderedIds == null || orderedIds.isEmpty) {
      return Result.failure('缺少必需参数: orderedIds',
          code: ErrorCodes.invalidParams);
    }

    try {
      final ids = orderedIds.cast<String>();
      final result = await repository.reorderMemorialDays(ids);
      return result.map((success) => {
            'reordered': success,
            'count': ids.length,
          });
    } catch (e) {
      return Result.failure('重新排序纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索纪念日
  ///
  /// [params] 可选参数:
  /// - `sortMode`: 排序模式
  /// - `startDate`: 开始日期
  /// - `endDate`: 结束日期
  /// - `includeExpired`: 是否包含过期的
  Future<Result<List<dynamic>>> searchMemorialDays(
      Map<String, dynamic> params) async {
    try {
      DateTime? startDate;
      DateTime? endDate;

      if (params.containsKey('startDate')) {
        final startDateStr = params['startDate'] as String?;
        if (startDateStr != null && startDateStr.isNotEmpty) {
          startDate = DateTime.parse(startDateStr);
        }
      }

      if (params.containsKey('endDate')) {
        final endDateStr = params['endDate'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          endDate = DateTime.parse(endDateStr);
        }
      }

      final query = MemorialDayQuery(
        sortMode: params['sortMode'] as String?,
        startDate: startDate,
        endDate: endDate,
        includeExpired: params['includeExpired'] as bool?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchMemorialDays(query);
      return result.map((days) => days.map((d) => d.toJson()).toList());
    } catch (e) {
      return Result.failure('搜索纪念日失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats(
      Map<String, dynamic> params) async {
    try {
      final result = await repository.getStats();
      return result.map((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
