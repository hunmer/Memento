/// Tracker 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/tracker/tracker_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Tracker UseCase - 封装所有业务逻辑
class TrackerUseCase {
  final ITrackerRepository repository;
  final Uuid _uuid = const Uuid();

  TrackerUseCase(this.repository);

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

  // ============ 目标操作 ============

  /// 获取所有目标
  ///
  /// [params] 可选参数:
  /// - `status`: 状态 (active, completed, null)
  /// - `group`: 分组
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getGoals(Map<String, dynamic> params) async {
    try {
      final status = params['status'] as String?;
      final group = params['group'] as String?;
      final pagination = _extractPagination(params);

      final result = await repository.getGoals(
        status: status,
        group: group,
        pagination: pagination,
      );

      return result.map((goals) {
        final jsonList = goals.map((g) => g.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取目标列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取目标
  ///
  /// [params] 必需参数:
  /// - `id`: 目标 ID
  Future<Result<Map<String, dynamic>?>> getGoalById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;

    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getGoalById(id);
      return result.map((g) => g?.toJson());
    } catch (e) {
      return Result.failure('获取目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建目标
  ///
  /// [params] 必需参数:
  /// - `name`: 目标名称
  /// - `icon`: 图标
  /// - `unitType`: 单位类型
  /// - `targetValue`: 目标值
  /// - `dateSettings`: 日期设置
  /// 可选参数:
  /// - `iconColor`: 图标颜色
  /// - `group`: 分组
  /// - `imagePath`: 图片路径
  /// - `progressColor`: 进度颜色
  /// - `reminderTime`: 提醒时间
  /// - `isLoopReset`: 是否循环重置
  Future<Result<Map<String, dynamic>>> createGoal(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final iconValidation = ParamValidator.requireString(params, 'icon');
    if (!iconValidation.isValid) {
      return Result.failure(iconValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final unitTypeValidation = ParamValidator.requireString(params, 'unitType');
    if (!unitTypeValidation.isValid) {
      return Result.failure(unitTypeValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final targetValueValidation =
        ParamValidator.requireInt(params, 'targetValue');
    if (!targetValueValidation.isValid) {
      return Result.failure(targetValueValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    if (params['dateSettings'] == null) {
      return Result.failure('缺少必需参数: dateSettings',
          code: ErrorCodes.invalidParams);
    }

    try {
      final dateSettingsMap = params['dateSettings'] as Map<String, dynamic>;
      final dateSettings = DateSettingsDto.fromJson(dateSettingsMap);

      final goal = GoalDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        icon: params['icon'] as String,
        iconColor: params['iconColor'] as int?,
        unitType: params['unitType'] as String,
        group: params['group'] as String? ?? '默认',
        imagePath: params['imagePath'] as String?,
        progressColor: params['progressColor'] as int?,
        targetValue: (params['targetValue'] as num).toDouble(),
        currentValue: 0.0,
        dateSettings: dateSettings,
        reminderTime: params['reminderTime'] as String?,
        isLoopReset: params['isLoopReset'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      final result = await repository.createGoal(goal);
      return result.map((g) => g.toJson());
    } catch (e) {
      return Result.failure('创建目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新目标
  ///
  /// [params] 必需参数:
  /// - `id`: 目标 ID
  /// 可选参数（至少提供一个）:
  /// - `name`: 名称
  /// - `icon`: 图标
  /// - `iconColor`: 图标颜色
  /// - `unitType`: 单位类型
  /// - `group`: 分组
  /// - `imagePath`: 图片路径
  /// - `progressColor`: 进度颜色
  /// - `targetValue`: 目标值
  /// - `dateSettings`: 日期设置
  /// - `reminderTime`: 提醒时间
  /// - `isLoopReset`: 是否循环重置
  Future<Result<Map<String, dynamic>>> updateGoal(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有目标
      final existingResult = await repository.getGoalById(id);
      if (existingResult.isFailure) {
        return Result.failure('目标不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('目标不存在', code: ErrorCodes.notFound);
      }

      // 解析日期设置
      DateSettingsDto? dateSettings;
      if (params.containsKey('dateSettings')) {
        final ds = params['dateSettings'] as Map<String, dynamic>?;
        if (ds != null) {
          dateSettings = DateSettingsDto.fromJson(ds);
        }
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        icon: params['icon'] as String? ?? existing.icon,
        iconColor: params['iconColor'] as int? ?? existing.iconColor,
        unitType: params['unitType'] as String? ?? existing.unitType,
        group: params['group'] as String? ?? existing.group,
        imagePath: params['imagePath'] as String? ?? existing.imagePath,
        progressColor:
            params['progressColor'] as int? ?? existing.progressColor,
        targetValue: params['targetValue'] != null
            ? (params['targetValue'] as num).toDouble()
            : existing.targetValue,
        dateSettings: params.containsKey('dateSettings')
            ? dateSettings
            : existing.dateSettings,
        reminderTime:
            params['reminderTime'] as String? ?? existing.reminderTime,
        isLoopReset: params['isLoopReset'] as bool? ?? existing.isLoopReset,
      );

      final result = await repository.updateGoal(id, updated);
      return result.map((g) => g.toJson());
    } catch (e) {
      return Result.failure('更新目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除目标
  ///
  /// [params] 必需参数:
  /// - `id`: 目标 ID
  Future<Result<Map<String, dynamic>>> deleteGoal(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteGoal(id);
      return result.map((success) => {
            'deleted': success,
            'id': id,
          });
    } catch (e) {
      return Result.failure('删除目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索目标
  ///
  /// [params] 可选参数:
  /// - `status`: 状态
  /// - `group`: 分组
  /// - `field`: 字段名
  /// - `value`: 字段值
  /// - `fuzzy`: 是否模糊搜索
  Future<Result<List<dynamic>>> searchGoals(Map<String, dynamic> params) async {
    try {
      final query = GoalQuery(
        status: params['status'] as String?,
        group: params['group'] as String?,
        field: params['field'] as String?,
        value: params['value'] as String?,
        fuzzy: params['fuzzy'] as bool? ?? false,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchGoals(query);
      return result.map((goals) => goals.map((g) => g.toJson()).toList());
    } catch (e) {
      return Result.failure('搜索目标失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取所有分组
  Future<Result<List<String>>> getAllGroups(Map<String, dynamic> params) async {
    try {
      return repository.getAllGroups();
    } catch (e) {
      return Result.failure('获取分组列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 记录操作 ============

  /// 获取目标的记录列表
  ///
  /// [params] 必需参数:
  /// - `goalId`: 目标 ID
  /// 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getRecordsForGoal(Map<String, dynamic> params) async {
    final goalId = params['goalId'] as String?;

    if (goalId == null || goalId.isEmpty) {
      return Result.failure('缺少必需参数: goalId', code: ErrorCodes.invalidParams);
    }

    try {
      final pagination = _extractPagination(params);

      final result = await repository.getRecordsForGoal(
        goalId,
        pagination: pagination,
      );

      return result.map((records) {
        final jsonList = records.map((r) => r.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取记录列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 添加记录
  ///
  /// [params] 必需参数:
  /// - `goalId`: 目标 ID
  /// - `value`: 记录值
  /// - `recordedAt`: 记录时间 (ISO8601 字符串)
  /// 可选参数:
  /// - `note`: 备注
  /// - `durationSeconds`: 持续时间（秒）
  Future<Result<Map<String, dynamic>>> addRecord(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final goalIdValidation = ParamValidator.requireString(params, 'goalId');
    if (!goalIdValidation.isValid) {
      return Result.failure(goalIdValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final valueValidation = ParamValidator.requireInt(params, 'value');
    if (!valueValidation.isValid) {
      return Result.failure(valueValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final recordedAtValidation =
        ParamValidator.requireString(params, 'recordedAt');
    if (!recordedAtValidation.isValid) {
      return Result.failure(recordedAtValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final recordedAt = DateTime.parse(params['recordedAt'] as String);

      final record = RecordDto(
        id: params['id'] as String? ?? _uuid.v4(),
        goalId: params['goalId'] as String,
        value: (params['value'] as num).toDouble(),
        note: params['note'] as String?,
        recordedAt: recordedAt,
        durationSeconds: params['durationSeconds'] as int?,
      );

      final result = await repository.addRecord(record);
      return result.map((r) => r.toJson());
    } catch (e) {
      return Result.failure('添加记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除记录
  ///
  /// [params] 必需参数:
  /// - `recordId`: 记录 ID
  Future<Result<Map<String, dynamic>>> deleteRecord(
      Map<String, dynamic> params) async {
    final recordId = params['recordId'] as String?;
    if (recordId == null || recordId.isEmpty) {
      return Result.failure('缺少必需参数: recordId', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteRecord(recordId);
      return result.map((success) => {
            'deleted': success,
            'id': recordId,
          });
    } catch (e) {
      return Result.failure('删除记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 清空目标的所有记录
  ///
  /// [params] 必需参数:
  /// - `goalId`: 目标 ID
  Future<Result<Map<String, dynamic>>> clearRecordsForGoal(
      Map<String, dynamic> params) async {
    final goalId = params['goalId'] as String?;
    if (goalId == null || goalId.isEmpty) {
      return Result.failure('缺少必需参数: goalId', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.clearRecordsForGoal(goalId);
      return result.map((success) => {
            'cleared': success,
            'goalId': goalId,
          });
    } catch (e) {
      return Result.failure('清空记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索记录
  ///
  /// [params] 可选参数:
  /// - `goalId`: 目标 ID
  /// - `startDate`: 开始日期
  /// - `endDate`: 结束日期
  /// - `field`: 字段名
  /// - `value`: 字段值
  /// - `fuzzy`: 是否模糊搜索
  Future<Result<List<dynamic>>> searchRecords(
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

      final query = RecordQuery(
        goalId: params['goalId'] as String?,
        startDate: startDate,
        endDate: endDate,
        field: params['field'] as String?,
        value: params['value'] as String?,
        fuzzy: params['fuzzy'] as bool? ?? false,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchRecords(query);
      return result.map((records) => records.map((r) => r.toJson()).toList());
    } catch (e) {
      return Result.failure('搜索记录失败: $e', code: ErrorCodes.serverError);
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
