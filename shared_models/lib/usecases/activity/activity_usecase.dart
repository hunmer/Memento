/// Activity 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/activity/activity_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Activity UseCase - 封装所有业务逻辑
class ActivityUseCase {
  final IActivityRepository repository;
  final Uuid _uuid = const Uuid();

  ActivityUseCase(this.repository);

  // ============ 辅助方法 ============

  /// 格式化日期为文件名格式 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

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

  /// 检查时间重叠
  bool _hasTimeOverlap(ActivityDto a, ActivityDto b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  // ============ 活动操作 ============

  /// 获取活动列表
  ///
  /// [params] 可选参数:
  /// - `date`: 日期字符串 (YYYY-MM-DD)，默认为今天
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getActivities(Map<String, dynamic> params) async {
    try {
      final dateParam = params['date'] as String?;
      final date = dateParam ?? _formatDate(DateTime.now());
      final pagination = _extractPagination(params);

      final result = await repository.getActivities(
        date: date,
        pagination: pagination,
      );

      return result.map((activities) {
        final jsonList = activities.map((a) => a.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取活动
  ///
  /// [params] 必需参数:
  /// - `id`: 活动 ID
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  Future<Result<Map<String, dynamic>?>> getActivityById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    final date = params['date'] as String?;

    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getActivityById(id: id, date: date);
      return result.map((a) => a?.toJson());
    } catch (e) {
      return Result.failure('获取活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建活动
  ///
  /// [params] 必需参数:
  /// - `startTime`: 开始时间 (ISO8601 字符串)
  /// - `endTime`: 结束时间 (ISO8601 字符串)
  /// - `title`: 活动标题
  /// 可选参数:
  /// - `id`: 活动 ID（如未提供则自动生成）
  /// - `tags`: 标签列表
  /// - `description`: 描述
  /// - `mood`: 心情值
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> createActivity(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final startTimeValidation =
        ParamValidator.requireString(params, 'startTime');
    if (!startTimeValidation.isValid) {
      return Result.failure(startTimeValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final endTimeValidation = ParamValidator.requireString(params, 'endTime');
    if (!endTimeValidation.isValid) {
      return Result.failure(endTimeValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final titleValidation = ParamValidator.requireString(params, 'title');
    if (!titleValidation.isValid) {
      return Result.failure(titleValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final startTime = DateTime.parse(params['startTime'] as String);
      final endTime = DateTime.parse(params['endTime'] as String);

      // 验证时间逻辑
      if (endTime.isBefore(startTime) || endTime.isAtSameMomentAs(startTime)) {
        return Result.failure('结束时间必须晚于开始时间', code: ErrorCodes.validationError);
      }

      final activity = ActivityDto(
        id: params['id'] as String? ?? _uuid.v4(),
        startTime: startTime,
        endTime: endTime,
        title: params['title'] as String,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        description: params['description'] as String?,
        mood: params['mood'] as int?,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      // 检查时间重叠
      final dateStr = _formatDate(startTime);
      final existingResult = await repository.getActivities(date: dateStr);

      if (existingResult.isSuccess) {
        final existingActivities = existingResult.dataOrNull ?? [];
        for (final existing in existingActivities) {
          if (_hasTimeOverlap(activity, existing)) {
            // 如果有重叠且不是同一个活动，返回冲突错误
            if (existing.id != activity.id) {
              return Result.failure(
                '时间与已有活动重叠: ${existing.title}',
                code: ErrorCodes.conflict,
              );
            }
          }
        }
      }

      final result = await repository.createActivity(activity);
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('创建活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新活动
  ///
  /// [params] 必需参数:
  /// - `id`: 活动 ID
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  /// 可选参数（至少提供一个）:
  /// - `startTime`: 开始时间
  /// - `endTime`: 结束时间
  /// - `title`: 标题
  /// - `tags`: 标签列表
  /// - `description`: 描述
  /// - `mood`: 心情值
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> updateActivity(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    final date = params['date'] as String?;
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有活动
      final existingResult =
          await repository.getActivityById(id: id, date: date);
      if (existingResult.isFailure) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('活动不存在', code: ErrorCodes.notFound);
      }

      // 解析可选的时间参数
      DateTime? startTime;
      DateTime? endTime;

      if (params.containsKey('startTime')) {
        final startTimeStr = params['startTime'] as String?;
        if (startTimeStr != null && startTimeStr.isNotEmpty) {
          startTime = DateTime.parse(startTimeStr);
        }
      }

      if (params.containsKey('endTime')) {
        final endTimeStr = params['endTime'] as String?;
        if (endTimeStr != null && endTimeStr.isNotEmpty) {
          endTime = DateTime.parse(endTimeStr);
        }
      }

      // 合并更新
      final updated = existing.copyWith(
        startTime: startTime ?? existing.startTime,
        endTime: endTime ?? existing.endTime,
        title: params['title'] as String? ?? existing.title,
        tags: params.containsKey('tags')
            ? (params['tags'] as List<dynamic>?)?.cast<String>() ?? []
            : existing.tags,
        description: params.containsKey('description')
            ? params['description'] as String?
            : existing.description,
        mood:
            params.containsKey('mood') ? params['mood'] as int? : existing.mood,
        metadata: params.containsKey('metadata')
            ? params['metadata'] as Map<String, dynamic>?
            : existing.metadata,
      );

      // 验证时间逻辑
      if (updated.endTime.isBefore(updated.startTime) ||
          updated.endTime.isAtSameMomentAs(updated.startTime)) {
        return Result.failure('结束时间必须晚于开始时间', code: ErrorCodes.validationError);
      }

      final result = await repository.updateActivity(
        id: id,
        date: date,
        activity: updated,
      );
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('更新活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除活动
  ///
  /// [params] 必需参数:
  /// - `id`: 活动 ID
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  Future<Result<Map<String, dynamic>>> deleteActivity(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    final date = params['date'] as String?;
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteActivity(id: id, date: date);
      return result.map((success) => {
            'deleted': success,
            'id': id,
          });
    } catch (e) {
      return Result.failure('删除活动失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取今日统计
  Future<Result<Map<String, dynamic>>> getTodayStats(
      Map<String, dynamic> params) async {
    try {
      final result = await repository.getTodayStats();
      return result.map((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取今日统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取日期范围统计
  ///
  /// [params] 必需参数:
  /// - `startDate`: 开始日期 (YYYY-MM-DD)
  /// - `endDate`: 结束日期 (YYYY-MM-DD)
  Future<Result<Map<String, dynamic>>> getRangeStats(
      Map<String, dynamic> params) async {
    final startDate = params['startDate'] as String?;
    final endDate = params['endDate'] as String?;

    if (startDate == null || startDate.isEmpty) {
      return Result.failure('缺少必需参数: startDate',
          code: ErrorCodes.invalidParams);
    }
    if (endDate == null || endDate.isEmpty) {
      return Result.failure('缺少必需参数: endDate', code: ErrorCodes.invalidParams);
    }

    try {
      // 验证日期格式
      DateTime.parse(startDate);
      DateTime.parse(endDate);

      final result = await repository.getRangeStats(
        startDate: startDate,
        endDate: endDate,
      );
      return result.map((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取范围统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 标签操作 ============

  /// 获取标签分组
  Future<Result<List<dynamic>>> getTagGroups(
      Map<String, dynamic> params) async {
    try {
      final result = await repository.getTagGroups();
      return result.map((groups) => groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return Result.failure('获取标签分组失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取最近使用的标签
  Future<Result<List<String>>> getRecentTags(
      Map<String, dynamic> params) async {
    try {
      return repository.getRecentTags();
    } catch (e) {
      return Result.failure('获取最近标签失败: $e', code: ErrorCodes.serverError);
    }
  }
}
