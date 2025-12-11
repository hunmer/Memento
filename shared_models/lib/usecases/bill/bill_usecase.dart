/// Bill 插件 - UseCase 业务逻辑层
///
/// 此文件包含共享的业务逻辑，客户端和服务端都使用此层
library;

import 'package:uuid/uuid.dart';

import 'package:shared_models/repositories/bill/bill_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:shared_models/utils/validation.dart';

/// Bill UseCase - 封装所有业务逻辑
class BillUseCase {
  final IBillRepository repository;
  final Uuid _uuid = const Uuid();

  BillUseCase(this.repository);

  // ============ 账户操作 ============

  /// 获取账户列表
  ///
  /// [params] 可选参数:
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getAccounts(Map<String, dynamic> params) async {
    try {
      final pagination = _extractPagination(params);
      final result = await repository.getAccounts(pagination: pagination);

      return result.map((accounts) {
        final jsonList = accounts.map((a) => a.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取账户
  Future<Result<Map<String, dynamic>?>> getAccountById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getAccountById(id);
      return result.map((a) => a?.toJson());
    } catch (e) {
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建账户
  ///
  /// [params] 必需参数:
  /// - `name`: 账户名称
  /// 可选参数:
  /// - `balance`: 账户余额（默认 0.0）
  /// - `icon`: 图标
  /// - `color`: 颜色
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> createAccount(
      Map<String, dynamic> params) async {
    final nameValidation = ParamValidator.requireString(params, 'name');
    if (!nameValidation.isValid) {
      return Result.failure(nameValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();
      final account = AccountDto(
        id: params['id'] as String? ?? _uuid.v4(),
        name: params['name'] as String,
        balance: (params['balance'] as num?)?.toDouble() ?? 0.0,
        icon: params['icon'] as String?,
        color: params['color'] as String?,
        createdAt: now,
        updatedAt: now,
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createAccount(account);
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('创建账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新账户
  Future<Result<Map<String, dynamic>>> updateAccount(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有账户
      final existingResult = await repository.getAccountById(id);
      if (existingResult.isFailure) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final updated = existing.copyWith(
        name: params['name'] as String? ?? existing.name,
        balance: params.containsKey('balance')
            ? (params['balance'] as num?)?.toDouble()
            : existing.balance,
        icon: params['icon'] as String? ?? existing.icon,
        color: params['color'] as String? ?? existing.color,
        metadata:
            params['metadata'] as Map<String, dynamic>? ?? existing.metadata,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateAccount(id, updated);
      return result.map((a) => a.toJson());
    } catch (e) {
      return Result.failure('更新账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除账户
  Future<Result<bool>> deleteAccount(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteAccount(id);
    } catch (e) {
      return Result.failure('删除账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 账单操作 ============

  /// 获取账单列表
  ///
  /// [params] 可选参数:
  /// - `accountId`: 按账户过滤
  /// - `startDate`: 起始日期（ISO8601 格式）
  /// - `endDate`: 结束日期（ISO8601 格式）
  /// - `offset`: 起始偏移量
  /// - `count`: 返回数量
  Future<Result<dynamic>> getBills(Map<String, dynamic> params) async {
    try {
      final accountId = params['accountId'] as String?;
      final pagination = _extractPagination(params);
      final result = await repository.getBills(
        accountId: accountId,
        pagination: pagination,
      );

      return result.map((bills) {
        final jsonList = bills.map((b) => b.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 根据 ID 获取账单
  Future<Result<Map<String, dynamic>?>> getBillById(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      final result = await repository.getBillById(id);
      return result.map((b) => b?.toJson());
    } catch (e) {
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 创建账单
  ///
  /// [params] 必需参数:
  /// - `accountId`: 账户 ID
  /// - `amount`: 金额（正数为收入，负数为支出）
  /// - `type`: 类型（'income' or 'expense'）
  /// - `category`: 分类
  /// 可选参数:
  /// - `description`: 描述
  /// - `date`: 日期（ISO8601 格式，默认当前日期）
  /// - `tags`: 标签列表
  /// - `metadata`: 元数据
  Future<Result<Map<String, dynamic>>> createBill(
      Map<String, dynamic> params) async {
    final accountIdValidation =
        ParamValidator.requireString(params, 'accountId');
    if (!accountIdValidation.isValid) {
      return Result.failure(accountIdValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    if (!params.containsKey('amount') || params['amount'] == null) {
      return Result.failure('缺少必需参数: amount', code: ErrorCodes.invalidParams);
    }

    final typeValidation = ParamValidator.requireString(params, 'type');
    if (!typeValidation.isValid) {
      return Result.failure(typeValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    final categoryValidation = ParamValidator.requireString(params, 'category');
    if (!categoryValidation.isValid) {
      return Result.failure(categoryValidation.errorMessage!,
          code: ErrorCodes.invalidParams);
    }

    try {
      final now = DateTime.now();
      final dateStr = params['date'] as String?;
      final date = dateStr != null ? DateTime.parse(dateStr) : now;

      final bill = BillDto(
        id: params['id'] as String? ?? _uuid.v4(),
        accountId: params['accountId'] as String,
        amount: (params['amount'] as num).toDouble(),
        type: params['type'] as String,
        category: params['category'] as String,
        description: params['description'] as String?,
        date: date,
        createdAt: now,
        updatedAt: now,
        tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        metadata: params['metadata'] as Map<String, dynamic>?,
      );

      final result = await repository.createBill(bill);
      return result.map((b) => b.toJson());
    } catch (e) {
      return Result.failure('创建账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 更新账单
  Future<Result<Map<String, dynamic>>> updateBill(
      Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      // 获取现有账单
      final existingResult = await repository.getBillById(id);
      if (existingResult.isFailure) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      final existing = existingResult.dataOrNull;
      if (existing == null) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      // 合并更新
      final dateStr = params['date'] as String?;
      final updated = existing.copyWith(
        accountId: params['accountId'] as String? ?? existing.accountId,
        amount: params.containsKey('amount')
            ? (params['amount'] as num?)?.toDouble()
            : existing.amount,
        type: params['type'] as String? ?? existing.type,
        category: params['category'] as String? ?? existing.category,
        description: params.containsKey('description')
            ? params['description'] as String?
            : existing.description,
        date: dateStr != null ? DateTime.parse(dateStr) : existing.date,
        tags: params['tags'] != null
            ? (params['tags'] as List<dynamic>).cast<String>()
            : existing.tags,
        metadata:
            params['metadata'] as Map<String, dynamic>? ?? existing.metadata,
        updatedAt: DateTime.now(),
      );

      final result = await repository.updateBill(id, updated);
      return result.map((b) => b.toJson());
    } catch (e) {
      return Result.failure('更新账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 删除账单
  Future<Result<bool>> deleteBill(Map<String, dynamic> params) async {
    final id = params['id'] as String?;
    if (id == null || id.isEmpty) {
      return Result.failure('缺少必需参数: id', code: ErrorCodes.invalidParams);
    }

    try {
      return repository.deleteBill(id);
    } catch (e) {
      return Result.failure('删除账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 搜索账单
  ///
  /// [params] 可选参数:
  /// - `accountId`: 按账户过滤
  /// - `type`: 按类型过滤（'income' or 'expense'）
  /// - `category`: 按分类过滤
  /// - `startDate`: 起始日期（ISO8601 格式）
  /// - `endDate`: 结束日期（ISO8601 格式）
  /// - `keyword`: 搜索关键词（描述）
  /// - `offset`: 分页偏移
  /// - `count`: 分页数量
  Future<Result<dynamic>> searchBills(Map<String, dynamic> params) async {
    try {
      final startDateStr = params['startDate'] as String?;
      final endDateStr = params['endDate'] as String?;
      final pagination = _extractPagination(params);

      final query = BillQuery(
        accountId: params['accountId'] as String?,
        type: params['type'] as String?,
        category: params['category'] as String?,
        startDate: startDateStr != null ? DateTime.parse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.parse(endDateStr) : null,
        keyword: params['keyword'] as String?,
        pagination: pagination,
      );

      final result = await repository.searchBills(query);

      return result.map((bills) {
        final jsonList = bills.map((b) => b.toJson()).toList();

        if (pagination != null && pagination.hasPagination) {
          return PaginationUtils.toMap(jsonList,
              offset: pagination.offset, count: pagination.count);
        }
        return jsonList;
      });
    } catch (e) {
      return Result.failure('搜索账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  /// 获取总体统计
  ///
  /// [params] 可选参数:
  /// - `startDate`: 起始日期（ISO8601 格式）
  /// - `endDate`: 结束日期（ISO8601 格式）
  Future<Result<Map<String, dynamic>>> getStats(
      Map<String, dynamic> params) async {
    try {
      final startDateStr = params['startDate'] as String?;
      final endDateStr = params['endDate'] as String?;

      final result = await repository.getStats(
        startDate: startDateStr != null ? DateTime.parse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.parse(endDateStr) : null,
      );

      return result.map((stats) => stats.toJson());
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  /// 获取分类统计
  ///
  /// [params] 可选参数:
  /// - `type`: 按类型过滤（'income' or 'expense'）
  /// - `startDate`: 起始日期（ISO8601 格式）
  /// - `endDate`: 结束日期（ISO8601 格式）
  Future<Result<List<Map<String, dynamic>>>> getCategoryStats(
      Map<String, dynamic> params) async {
    try {
      final startDateStr = params['startDate'] as String?;
      final endDateStr = params['endDate'] as String?;

      final result = await repository.getCategoryStats(
        type: params['type'] as String?,
        startDate: startDateStr != null ? DateTime.parse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.parse(endDateStr) : null,
      );

      return result
          .map((statsList) => statsList.map((s) => s.toJson()).toList());
    } catch (e) {
      return Result.failure('获取分类统计失败: $e', code: ErrorCodes.serverError);
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
