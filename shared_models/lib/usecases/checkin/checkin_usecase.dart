/// Checkin 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/checkin/checkin_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Checkin UseCase - 封装所有业务逻辑
class CheckinUseCase {
  final ICheckinRepository repository;
  final Uuid _uuid = const Uuid();

  CheckinUseCase(this.repository);

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

  // ============ 打卡项目操作 ============

  /// 获取所有打卡项目
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getItems(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);

      final result = await repository.getItems(pagination: pagination);

      return result.map<dynamic>((items) {
        final jsonList = items.map((i) => i.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取打卡项目
  ///
  /// [params] 必需参数:
  /// - `id`: 项目 ID
  Future<Result<Map<String, dynamic>?>> getItemById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;

    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getItemById(id);
      return result.map<Map<String, dynamic>?>((i) => i?.toJson());
    } catch (e) {
      return Result.failure('获取打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建打卡项目
  ///
  /// [params] 必需参数:
  /// - `name`: 项目名称
  /// - `icon`: 图标代码点
  /// - `color`: 颜色值
  /// 可选参数:
  /// - `group`: 分组名称
  /// - `description`: 描述
  /// - `cardStyle`: 卡片样式
  /// - `reminderSettings`: 提醒设置
  Future<Result<Map<String, dynamic>>> createItem(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final iconValidation = ParamValidator.requireInt(params, 'icon');
    if (!iconValidation.isValid) {
      return Result.failure(iconValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final colorValidation = ParamValidator.requireInt(params, 'color');
    if (!colorValidation.isValid) {
      return Result.failure(colorValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final item = CheckinItemDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        icon: params['icon'] as int,
        color: params['color'] as int,
        group: params['group'] as String? ?? '默认分组',
        description: params['description'] as String? ?? '',
        cardStyle: params['cardStyle'] as int? ?? 0,
        reminderSettings: params['reminderSettings'] != null
            ? ReminderSettingsDto.fromJson(
                params['reminderSettings'] as Map<String, dynamic>)
            : null,
      );

      final result = await repository.createItem(item);
      return result.map<Map<String, dynamic>>((i) => i.toJson());
    } catch (e) {
      return Result.failure('创建打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新打卡项目
  ///
  /// [params] 必需参数:
  /// - `id`: 项目 ID
  /// 可选参数（至少提供一个）:
  /// - `name`: 名称
  /// - `icon`: 图标
  /// - `color`: 颜色
  /// - `group`: 分组
  /// - `description`: 描述
  /// - `cardStyle`: 卡片样式
  /// - `reminderSettings`: 提醒设置
  Future<Result<Map<String, dynamic>>> updateItem(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有项目
      final existingResult = await repository.getItemById(id);
      if (existingResult.isFailure) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('打卡项目不存在', code: ErrorCodes.notFound);
      }

      // 解析提醒设置
      ReminderSettingsDto? reminderSettings;
      if (params.containsKey('reminderSettings')) {
        final rs = params['reminderSettings'] as Map<String, dynamic>?;
        if (rs != null) {
          reminderSettings = ReminderSettingsDto.fromJson(rs);
        }
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        icon: params['icon'] as int? ?? existing.icon,
        color: params['color'] as int? ?? existing.color,
        group: params['group'] as String? ?? existing.group,
        description: params['description'] as String? ?? existing.description,
        cardStyle: params['cardStyle'] as int? ?? existing.cardStyle,
        reminderSettings: params.containsKey('reminderSettings')
            ? reminderSettings
            : existing.reminderSettings,
      );

      final result = await repository.updateItem(id, updated);
      return result.map<Map<String, dynamic>>((i) => i.toJson());
    } catch (e) {
      return Result.failure('更新打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除打卡项目
  ///
  /// [params] 必需参数:
  /// - `id`: 项目 ID
  Future<Result<Map<String, dynamic>>> deleteItem(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteItem(id);
      return result.map<Map<String, dynamic>>((success) => {
            'deleted': success,
            'id': id,
          });
    } catch (e) {
      return Result.failure('删除打卡项目失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 打卡记录操作 ============

  /// 添加打卡记录
  ///
  /// [params] 必需参数:
  /// - `itemId`: 项目 ID
  /// - `startTime`: 开始时间 (ISO8601 字符串)
  /// - `endTime`: 结束时间 (ISO8601 字符串)
  /// - `checkinTime`: 打卡时间 (ISO8601 字符串)
  /// 可选参数:
  /// - `note`: 备注
  Future<Result<Map<String, dynamic>>> addCheckinRecord(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final itemIdValidation = ParamValidator.requireString(params, 'itemId');
    if (!itemIdValidation.isValid) {
      return Result.failure(itemIdValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

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

    final checkinTimeValidation =
        ParamValidator.requireString(params, 'checkinTime');
    if (!checkinTimeValidation.isValid) {
      return Result.failure(checkinTimeValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final startTime = DateTime.parse(params['startTime'] as String);
      final endTime = DateTime.parse(params['endTime'] as String);
      final checkinTime = DateTime.parse(params['checkinTime'] as String);

      // 验证时间逻辑 - 使用毫秒精度比较
      if (endTime.isBefore(startTime)) {
        return Result.failure('结束时间必须晚于开始时间', code: ErrorCodes.validationError);
      }

      if (startTime != endTime && checkinTime.isBefore(startTime) ||
          checkinTime.isAfter(endTime)) {
        return Result.failure('打卡时间必须在开始和结束时间之间',
            code: ErrorCodes.validationError);
      }

      final record = CheckinRecordDto(
        startTime: startTime,
        endTime: endTime,
        checkinTime: checkinTime,
        note: params['note'] as String?,
      );

      final result = await repository.addCheckinRecord(
        params['itemId'] as String,
        record,
      );
      return result.map<Map<String, dynamic>>((i) => i.toJson());
    } catch (e) {
      return Result.failure('添加打卡记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除打卡记录
  ///
  /// [params] 必需参数:
  /// - `itemId`: 项目 ID
  /// - `date`: 日期 (YYYY-MM-DD)
  /// - `recordIndex`: 记录索引
  Future<Result<Map<String, dynamic>>> deleteCheckinRecord(
      Map<String, dynamic> params) async {
    final itemId = params['itemId'] as String?;
    final date = params['date'] as String?;
    final recordIndex = params['recordIndex'] as int?;

    if (itemId == null || itemId.isEmpty) {
      return Result.failure('缺少必需参数: itemId', code: ErrorCodes.invalidParams);
    }
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }
    if (recordIndex == null) {
      return Result.failure('缺少必需参数: recordIndex',
          code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteCheckinRecord(
        itemId,
        date,
        recordIndex,
      );
      return result.map<Map<String, dynamic>>((i) => i.toJson());
    } catch (e) {
      return Result.failure('删除打卡记录失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<Map<String, dynamic>>> getStats(
      Map<String, dynamic> params) async {
    try {
      final result = await repository.getStats();
      return result.map<Map<String, dynamic>>((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取统计信息失败: $e', code: ErrorCodes.serverError);
    }
  }
}
