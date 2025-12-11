/// Bill 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 账户 DTO
class AccountDto {
  final String id;
  final String name;
  final double balance;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const AccountDto({
    required this.id,
    required this.name,
    this.balance = 0.0,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) {
    return AccountDto(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  AccountDto copyWith({
    String? id,
    String? name,
    double? balance,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AccountDto(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 账单 DTO
class BillDto {
  final String id;
  final String accountId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const BillDto({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.metadata,
  });

  factory BillDto.fromJson(Map<String, dynamic> json) {
    return BillDto(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  BillDto copyWith({
    String? id,
    String? accountId,
    double? amount,
    String? type,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return BillDto(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 账单统计 DTO
class BillStatsDto {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int billCount;

  const BillStatsDto({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.billCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'billCount': billCount,
    };
  }
}

/// 分类统计 DTO
class CategoryStatsDto {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  const CategoryStatsDto({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'count': count,
      'percentage': percentage,
    };
  }
}

// ============ Query Objects ============

/// 账单查询参数
class BillQuery {
  final String? accountId;
  final String? type;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? keyword;
  final PaginationParams? pagination;

  const BillQuery({
    this.accountId,
    this.type,
    this.category,
    this.startDate,
    this.endDate,
    this.keyword,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Bill Repository 接口
abstract class IBillRepository {
  // ============ 账户操作 ============

  /// 获取所有账户
  Future<Result<List<AccountDto>>> getAccounts({PaginationParams? pagination});

  /// 根据 ID 获取账户
  Future<Result<AccountDto?>> getAccountById(String id);

  /// 创建账户
  Future<Result<AccountDto>> createAccount(AccountDto account);

  /// 更新账户
  Future<Result<AccountDto>> updateAccount(String id, AccountDto account);

  /// 删除账户
  Future<Result<bool>> deleteAccount(String id);

  // ============ 账单操作 ============

  /// 获取所有账单
  Future<Result<List<BillDto>>> getBills({
    String? accountId,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取账单
  Future<Result<BillDto?>> getBillById(String id);

  /// 创建账单
  Future<Result<BillDto>> createBill(BillDto bill);

  /// 更新账单
  Future<Result<BillDto>> updateBill(String id, BillDto bill);

  /// 删除账单
  Future<Result<bool>> deleteBill(String id);

  /// 搜索账单
  Future<Result<List<BillDto>>> searchBills(BillQuery query);

  // ============ 统计操作 ============

  /// 获取总体统计
  Future<Result<BillStatsDto>> getStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 获取分类统计
  Future<Result<List<CategoryStatsDto>>> getCategoryStats({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  });
}
