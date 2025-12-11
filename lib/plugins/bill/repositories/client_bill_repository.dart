/// Bill 插件 - 客户端 Repository 实现
///
/// 通过适配现有的 BillController 来实现 IBillRepository 接口

import 'package:flutter/material.dart';
import 'package:shared_models/repositories/bill/bill_repository.dart';
import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';
import 'package:Memento/plugins/bill/controls/bill_controller.dart';
import 'package:Memento/plugins/bill/models/account.dart';
import 'package:Memento/plugins/bill/models/bill.dart';

/// 客户端 Bill Repository 实现
class ClientBillRepository implements IBillRepository {
  final BillController billController;
  final Color pluginColor;

  ClientBillRepository({
    required this.billController,
    required this.pluginColor,
  });

  // ============ 账户操作 ============

  @override
  Future<Result<List<AccountDto>>> getAccounts({
    PaginationParams? pagination,
  }) async {
    try {
      final accounts = billController.accounts;
      final dtos = accounts.map(_accountToDto).toList();

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
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto?>> getAccountById(String id) async {
    try {
      final account = billController.accounts
          .where((a) => a.id == id)
          .firstOrNull;
      if (account == null) {
        return Result.success(null);
      }
      return Result.success(_accountToDto(account));
    } catch (e) {
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto>> createAccount(AccountDto dto) async {
    try {
      // 将 DTO 转换为 Account
      final account = Account(
        id: dto.id,
        title: dto.name,
        icon: Icons.account_balance_wallet,
        backgroundColor: dto.color != null
            ? Color(int.parse(dto.color!))
            : pluginColor,
      );

      await billController.createAccount(account);
      return Result.success(_accountToDto(account));
    } catch (e) {
      return Result.failure('创建账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto>> updateAccount(String id, AccountDto dto) async {
    try {
      // 获取现有账户
      final existingAccount = billController.accounts
          .where((a) => a.id == id)
          .firstOrNull;
      if (existingAccount == null) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      // 更新账户信息
      final updatedAccount = existingAccount.copyWith(
        title: dto.name,
        backgroundColor: dto.color != null
            ? Color(int.parse(dto.color!))
            : existingAccount.backgroundColor,
      );

      await billController.saveAccount(updatedAccount);
      return Result.success(_accountToDto(updatedAccount));
    } catch (e) {
      return Result.failure('更新账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteAccount(String id) async {
    try {
      await billController.deleteAccount(id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 账单操作 ============

  @override
  Future<Result<List<BillDto>>> getBills({
    String? accountId,
    PaginationParams? pagination,
  }) async {
    try {
      final bills = await billController.getBills();
      final filteredBills = accountId != null && accountId.isNotEmpty
          ? bills.where((b) => b.accountId == accountId).toList()
          : bills;

      final dtos = filteredBills.map(_billToDto).toList();

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
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto?>> getBillById(String id) async {
    try {
      final bills = await billController.getBills();
      final bill = bills.where((b) => b.id == id).firstOrNull;
      if (bill == null) {
        return Result.success(null);
      }
      return Result.success(_billToDto(bill));
    } catch (e) {
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto>> createBill(BillDto dto) async {
    try {
      // 将 DTO 转换为 Bill
      final bill = Bill(
        id: dto.id,
        title: dto.description ?? dto.category,
        amount: dto.amount,
        category: dto.category,
        date: dto.date,
        accountId: dto.accountId,
        note: dto.description ?? '',
        tag: dto.tags.isNotEmpty ? dto.tags.first : null,
        icon: dto.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
        iconColor: dto.amount >= 0 ? Colors.green : Colors.red,
        createdAt: dto.createdAt,
        updatedAt: dto.updatedAt,
      );

      await billController.saveBill(bill);
      return Result.success(_billToDto(bill));
    } catch (e) {
      return Result.failure('创建账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto>> updateBill(String id, BillDto dto) async {
    try {
      // 获取现有账单
      final bills = await billController.getBills();
      final existingBill = bills.where((b) => b.id == id).firstOrNull;
      if (existingBill == null) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      // 更新账单信息
      final updatedBill = existingBill.copyWith(
        title: dto.description ?? existingBill.title,
        amount: dto.amount,
        category: dto.category,
        date: dto.date,
        note: dto.description ?? existingBill.note,
        tag: dto.tags.isNotEmpty ? dto.tags.first : existingBill.tag,
        accountId: dto.accountId,
        icon: dto.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
        iconColor: dto.amount >= 0 ? Colors.green : Colors.red,
        updatedAt: DateTime.now(),
      );

      await billController.saveBill(updatedBill);
      return Result.success(_billToDto(updatedBill));
    } catch (e) {
      return Result.failure('更新账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteBill(String id) async {
    try {
      // 获取账单以找到账户ID
      final bills = await billController.getBills();
      final bill = bills.where((b) => b.id == id).firstOrNull;
      if (bill == null) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      await billController.deleteBill(bill.accountId, id);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<BillDto>>> searchBills(BillQuery query) async {
    try {
      final bills = await billController.getBills(
        startDate: query.startDate,
        endDate: query.endDate,
      );

      final List<Bill> filteredBills = [];
      for (final bill in bills) {
        bool matches = true;

        // 过滤账户ID
        if (query.accountId != null && query.accountId!.isNotEmpty) {
          matches = matches && bill.accountId == query.accountId;
        }

        // 过滤类型
        if (query.type != null && query.type!.isNotEmpty) {
          final isIncome = bill.amount > 0;
          matches = matches && ((query.type == 'income' && isIncome) ||
              (query.type == 'expense' && !isIncome));
        }

        // 过滤分类
        if (query.category != null && query.category!.isNotEmpty) {
          matches = matches && bill.category == query.category;
        }

        // 过滤关键词
        if (query.keyword != null && query.keyword!.isNotEmpty) {
          final keyword = query.keyword!.toLowerCase();
          matches = matches &&
              (bill.title.toLowerCase().contains(keyword) ||
                  bill.note.toLowerCase().contains(keyword));
        }

        if (matches) {
          filteredBills.add(bill);
          if (query.pagination == null || !query.pagination!.hasPagination) {
            // 如果不需要分页，找到一个就停止
            // Note: BillQuery 没有 findAll 字段，所以这里总是返回所有匹配项
            break;
          }
        }
      }

      final dtos = filteredBills.map(_billToDto).toList();

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
      return Result.failure('搜索账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 统计操作 ============

  @override
  Future<Result<BillStatsDto>> getStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final totalIncome = await billController.getTotalIncome(
        startDate: startDate,
        endDate: endDate,
      );
      final totalExpense = await billController.getTotalExpense(
        startDate: startDate,
        endDate: endDate,
      );

      final stats = BillStatsDto(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        billCount: (await billController.getBills(
          startDate: startDate,
          endDate: endDate,
        )).length,
      );

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<CategoryStatsDto>>> getCategoryStats({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final categoryStats = await billController.getCategoryStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      // 计算总金额以计算百分比
      double totalAmount = 0;
      if (type == 'income') {
        totalAmount = await billController.getTotalIncome(
          startDate: startDate,
          endDate: endDate,
        );
      } else if (type == 'expense') {
        totalAmount = await billController.getTotalExpense(
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        // 所有类型，取绝对值总和
        final income = await billController.getTotalIncome(
          startDate: startDate,
          endDate: endDate,
        );
        final expense = await billController.getTotalExpense(
          startDate: startDate,
          endDate: endDate,
        );
        totalAmount = income + expense;
      }

      final stats = categoryStats.entries.map((entry) {
        final amount = entry.value.abs().toDouble(); // 确保为正数并转为 double
        final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;
        return CategoryStatsDto(
          category: entry.key,
          amount: amount,
          count: 0, // 账单数量需要额外计算
          percentage: percentage,
        );
      }).toList();

      return Result.success(stats);
    } catch (e) {
      return Result.failure('获取分类统计失败: $e', code: ErrorCodes.serverError);
    }
  }

  // ============ 转换方法 ============

  AccountDto _accountToDto(Account account) {
    return AccountDto(
      id: account.id,
      name: account.title,
      balance: account.totalAmount,
      icon: null, // Account 模型没有存储 icon 字符串
      color: account.backgroundColor.value.toString(),
      createdAt: DateTime.now(), // Account 模型没有 createdAt
      updatedAt: DateTime.now(), // Account 模型没有 updatedAt
      metadata: null,
    );
  }

  BillDto _billToDto(Bill bill) {
    return BillDto(
      id: bill.id,
      accountId: bill.accountId,
      amount: bill.amount,
      type: bill.amount >= 0 ? 'income' : 'expense',
      category: bill.category,
      description: bill.note.isNotEmpty ? bill.note : bill.title,
      date: bill.date,
      createdAt: bill.createdAt,
      updatedAt: bill.updatedAt,
      tags: bill.tag != null ? [bill.tag!] : [],
      metadata: null,
    );
  }
}

/// 扩展方法 - 获取列表中的第一个元素或返回 null
extension _IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }
}
