/// Calendar 插件 - UseCase 业务逻辑层

import 'package:uuid/uuid.dart';
import 'package:shared_models/repositories/calendar/calendar_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Calendar 插件 UseCase - 封装所有业务逻辑
class CalendarUseCase {
  final ICalendarRepository repository;
  final Uuid _uuid = const Uuid();

  CalendarUseCase(this.repository);

  // ============ 事件 CRUD 操作 ============

  /// 获取事件列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getEvents(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getEvents(pagination: pagination);

      return result.map((events) {
        final jsonList = events.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取事件列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取事件
  Future<Result<Map<String, dynamic>?>> getEventById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getEventById(id);
      return result.map((event) => event?.toJson());
    } catch (e) {
      return Result.failure('获取事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建事件
  ///
  /// [params] 必需参数:
  /// - `title`: 事件标题
  /// - `startTime`: 开始时间
  /// - `icon`: 图标 codePoint
  /// - `color`: 颜色值
  Future<Result<Map<String, dynamic>>> createEvent(
    Map<String, dynamic> params,
  ) async {
    // 参数验证
    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(
        titleValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final startTime = params['startTime'] as DateTime?;
    if (startTime == null) {
      return Result.failure(
        '缺少必需参数: startTime',
        code: ErrorCodes.invalidParams,
      );
    }

    final iconValidation = ParamValidator.requireInt(params, 'icon');
    if (!iconValidation.isValid) {
      return Result.failure(
        iconValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    final colorValidation = ParamValidator.requireInt(params, 'color');
    if (!colorValidation.isValid) {
      return Result.failure(
        colorValidation.errorMessage!,
        code: ErrorCodes.invalidParams,
      );
    }

    try {
      final now = DateTime.now();
      final event = CalendarEventDto(
        id: params['id'] as String? ?? _uuid.v4(),
        title: params['title'] as String,
        description: params['description'] as String? ?? '',
        startTime: params['startTime'] as DateTime,
        endTime: params['endTime'] as DateTime?,
        icon: params['icon'] as int,
        color: params['color'] as int,
        source: params['source'] as String? ?? 'default',
        reminderMinutes: params['reminderMinutes'] as int?,
        createdAt: now,
        updatedAt: now,
      );

      final result = await repository.createEvent(event);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('创建事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新事件
  Future<Result<Map<String, dynamic>>> updateEvent(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有数据
      final existingResult = await repository.getEventById(id);
      if (existingResult.isFailure) {
        return Result.failure('事件不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('事件不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        description: params['description'] as String?,
        startTime: params['startTime'] as DateTime? ?? existing.startTime,
        endTime: params['endTime'] as DateTime?,
        icon: params['icon'] as int? ?? existing.icon,
        color: params['color'] as int? ?? existing.color,
        reminderMinutes: params['reminderMinutes'] as int?,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateEvent(id, updated);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('更新事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除事件
  Future<Result<bool>> deleteEvent(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteEvent(id);
    } catch (e) {
      return Result.failure('删除事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 完成事件
  Future<Result<Map<String, dynamic>>> completeEvent(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final completedTime = params['completedTime'] as DateTime? ?? DateTime.now();
      final result = await repository.completeEvent(id, completedTime);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索事件
  Future<Result<dynamic>> searchEvents(Map<String, dynamic> params) async {
    try {
      final query = CalendarEventQuery(
        startDate: params['startDate'] as DateTime?,
        endDate: params['endDate'] as DateTime?,
        source: params['source'] as String?,
        titleKeyword: params['titleKeyword'] as String?,
        includeCompleted: params['includeCompleted'] as bool?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchEvents(query);
      return result.map((events) {
        final jsonList = events.map((e) => e.toJson()).toList();

        if (query.pagination != null && query.pagination!.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: query.pagination!.offset,
            count: query.pagination!.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 已完成事件操作 ============

  /// 获取已完成事件列表
  Future<Result<dynamic>> getCompletedEvents(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getCompletedEvents(pagination: pagination);

      return result.map((events) {
        final jsonList = events.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(
            jsonList,
            offset: pagination.offset,
            count: pagination.count,
          );
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取已完成事件列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取已完成事件
  Future<Result<Map<String, dynamic>?>> getCompletedEventById(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getCompletedEventById(id);
      return result.map((event) => event?.toJson());
    } catch (e) {
      return Result.failure('获取已完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 恢复已完成事件
  Future<Result<Map<String, dynamic>>> restoreCompletedEvent(
    Map<String, dynamic> params,
  ) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.restoreCompletedEvent(id);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('恢复事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除已完成事件
  Future<Result<bool>> deleteCompletedEvent(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteCompletedEvent(id);
    } catch (e) {
      return Result.failure('删除已完成事件失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 辅助方法 ============

  PaginationParams? _extractPagination(Map<String, dynamic> params) {
    final offset = params['offset'] as int?;
    final count = params['count'] as int?;

    if (offset == null && count == null) return null;

    return PaginationParams(
      offset: offset ?? 0,
      count: count ?? 100,
    );
  }
}
