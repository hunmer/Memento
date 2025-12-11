/// Diary 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:shared_models/repositories/diary/diary_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Diary UseCase - 封装所有业务逻辑
class DiaryUseCase {
  final IDiaryRepository repository;

  DiaryUseCase(this.repository);

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

  // ============ 日记条目操作 ============

  /// 获取日记列表
  ///
  /// [params] 可选参数:
  /// - `startDate`: 开始日期 (YYYY-MM-DD)
  /// - `endDate`: 结束日期 (YYYY-MM-DD)
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getEntries(Map<String, dynamic> params) async {
    try {
      final startDate = params['startDate'] as String?;
      final endDate = params['endDate'] as String?;
      final pagination = _extractPagination(params);

      final result = await repository.getEntries(
        startDate: startDate,
        endDate: endDate,
        pagination: pagination,
      );

      return result.map((entries) {
        final jsonList = entries.map((e) => e.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取日记列表失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据日期获取日记
  ///
  /// [params] 必需参数:
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  Future<Result<Map<String, dynamic>?>> getEntryByDate(
      Map<String, dynamic> params) async {
    final date = params['date'] as String?;

    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getEntryByDate(date);
      return result.map((e) => e?.toJson());
    } catch (e) {
      return Result.failure('获取日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建日记
  ///
  /// [params] 必需参数:
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  /// - `content`: 日记内容
  /// 可选参数:
  /// - `title`: 标题
  /// - `mood`: 心情
  Future<Result<Map<String, dynamic>>> createEntry(
      Map<String, dynamic> params) async {
    // 验证必需参数
    final dateValidation = ParamValidator.requireString(params, 'date');
    if (!dateValidation.isValid) {
      return Result.failure(dateValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final contentValidation = ParamValidator.requireString(params, 'content');
    if (!contentValidation.isValid) {
      return Result.failure(contentValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();

      final entry = DiaryEntryDto(
        date: params['date'] as String,
        title: params['title'] as String? ?? '',
        content: params['content'] as String,
        createdAt: now,
        updatedAt: now,
        mood: params['mood'] as String?,
      );

      final result = await repository.createEntry(entry);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('创建日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新日记
  ///
  /// [params] 必需参数:
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  /// 可选参数（至少提供一个）:
  /// - `title`: 标题
  /// - `content`: 内容
  /// - `mood`: 心情
  Future<Result<Map<String, dynamic>>> updateEntry(
      Map<String, dynamic> params) async {
    final date = params['date'] as String?;
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有日记
      final existingResult = await repository.getEntryByDate(date);
      if (existingResult.isFailure) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('日记不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        title: params['title'] as String? ?? existing.title,
        content: params['content'] as String? ?? existing.content,
        mood: params['mood'] as String? ?? existing.mood,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateEntry(date, updated);
      return result.map((e) => e.toJson());
    } catch (e) {
      return Result.failure('更新日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除日记
  ///
  /// [params] 必需参数:
  /// - `date`: 日期字符串 (YYYY-MM-DD)
  Future<Result<Map<String, dynamic>>> deleteEntry(
      Map<String, dynamic> params) async {
    final date = params['date'] as String?;
    if (date == null || date.isEmpty) {
      return Result.failure('缺少必需参数: date', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.deleteEntry(date);
      return result.map((success) => {
            'deleted': success,
            'date': date,
          });
    } catch (e) {
      return Result.failure('删除日记失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索日记
  ///
  /// [params] 可选参数:
  /// - `startDate`: 开始日期
  /// - `endDate`: 结束日期
  /// - `keyword`: 关键词
  /// - `mood`: 心情过滤
  Future<Result<List<dynamic>>> searchEntries(
      Map<String, dynamic> params) async {
    try {
      final query = DiaryQuery(
        startDate: params['startDate'] as String?,
        endDate: params['endDate'] as String?,
        keyword: params['keyword'] as String?,
        mood: params['mood'] as String?,
        pagination: _extractPagination(params),
      );

      final result = await repository.searchEntries(query);
      return result.map((entries) => entries.map((e) => e.toJson()).toList());
    } catch (e) {
      return Result.failure('搜索日记失败: $e', code: ErrorCodes.serverError);
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

  /// 获取今日字数
  Future<Result<int>> getTodayWordCount(Map<String, dynamic> params) async {
    try {
      return repository.getTodayWordCount();
    } catch (e) {
      return Result.failure('获取今日字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取本月字数
  Future<Result<int>> getMonthWordCount(Map<String, dynamic> params) async {
    try {
      return repository.getMonthWordCount();
    } catch (e) {
      return Result.failure('获取本月字数失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取本月进度
  Future<Result<Map<String, int>>> getMonthProgress(
      Map<String, dynamic> params) async {
    try {
      return repository.getMonthProgress();
    } catch (e) {
      return Result.failure('获取本月进度失败: $e', code: ErrorCodes.serverError);
    }
  }
}
