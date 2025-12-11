/// Bill 插件 - 服务端 Repository 实现
///
/// 通过 PluginDataService 访问用户的加密数据文件
/// 账单嵌套在账户的 bills 数组中存储

import 'package:shared_models/shared_models.dart';

import '../services/plugin_data_service.dart';

/// 服务端 Bill Repository 实现
class ServerBillRepository implements IBillRepository {
  final PluginDataService dataService;
  final String userId;

  static const String _pluginId = 'bill';

  ServerBillRepository({
    required this.dataService,
    required this.userId,
  });

  // ============ 内部方法 ============

  /// 读取所有账户（包含嵌套的账单）
  Future<List<_AccountWithBills>> _readAllAccounts() async {
    final accountsData = await dataService.readPluginData(
      userId,
      _pluginId,
      'accounts.json',
    );
    if (accountsData == null) return [];

    final accounts = accountsData['accounts'] as List<dynamic>? ?? [];
    return accounts.map((a) => _AccountWithBills.fromJson(a as Map<String, dynamic>)).toList();
  }

  /// 保存所有账户（包含嵌套的账单）
  Future<void> _saveAllAccounts(List<_AccountWithBills> accounts) async {
    await dataService.writePluginData(
      userId,
      _pluginId,
      'accounts.json',
      {'accounts': accounts.map((a) => a.toJson()).toList()},
    );
  }

  // ============ 账户操作 ============

  @override
  Future<Result<List<AccountDto>>> getAccounts({PaginationParams? pagination}) async {
    try {
      var accounts = await _readAllAccounts();

      // 转换为 AccountDto（不包含账单列表）
      var accountDtos = accounts.map((a) => a.toAccountDto()).toList();

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          accountDtos,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(accountDtos);
    } catch (e) {
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto?>> getAccountById(String id) async {
    try {
      final accounts = await _readAllAccounts();
      final account = accounts.where((a) => a.id == id).firstOrNull;
      return Result.success(account?.toAccountDto());
    } catch (e) {
      return Result.failure('获取账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto>> createAccount(AccountDto account) async {
    try {
      final accounts = await _readAllAccounts();
      final newAccount = _AccountWithBills.fromAccountDto(account);
      accounts.add(newAccount);
      await _saveAllAccounts(accounts);
      return Result.success(account);
    } catch (e) {
      return Result.failure('创建账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<AccountDto>> updateAccount(String id, AccountDto account) async {
    try {
      final accounts = await _readAllAccounts();
      final index = accounts.indexWhere((a) => a.id == id);

      if (index == -1) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      // 保留现有的账单列表
      final existingBills = accounts[index].bills;
      final updated = _AccountWithBills.fromAccountDto(account, bills: existingBills);
      accounts[index] = updated;
      await _saveAllAccounts(accounts);
      return Result.success(account);
    } catch (e) {
      return Result.failure('更新账户失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteAccount(String id) async {
    try {
      final accounts = await _readAllAccounts();
      final initialLength = accounts.length;
      accounts.removeWhere((a) => a.id == id);

      if (accounts.length == initialLength) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      await _saveAllAccounts(accounts);
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
      final accounts = await _readAllAccounts();
      var allBills = <BillDto>[];

      for (final account in accounts) {
        if (accountId != null && account.id != accountId) continue;
        allBills.addAll(account.bills);
      }

      // 按日期排序（最新在前）
      allBills.sort((a, b) => b.date.compareTo(a.date));

      // 应用分页
      if (pagination != null && pagination.hasPagination) {
        final paginated = PaginationUtils.paginate(
          allBills,
          offset: pagination.offset,
          count: pagination.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(allBills);
    } catch (e) {
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto?>> getBillById(String id) async {
    try {
      final accounts = await _readAllAccounts();
      for (final account in accounts) {
        final bill = account.bills.where((b) => b.id == id).firstOrNull;
        if (bill != null) {
          return Result.success(bill);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure('获取账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto>> createBill(BillDto bill) async {
    try {
      final accounts = await _readAllAccounts();
      final accountIndex = accounts.indexWhere((a) => a.id == bill.accountId);

      if (accountIndex == -1) {
        return Result.failure('账户不存在', code: ErrorCodes.notFound);
      }

      // 添加账单到账户
      final account = accounts[accountIndex];
      account.bills.add(bill);

      // 更新账户余额
      account.balance += bill.amount;
      account.updatedAt = DateTime.now();

      await _saveAllAccounts(accounts);
      return Result.success(bill);
    } catch (e) {
      return Result.failure('创建账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<BillDto>> updateBill(String id, BillDto bill) async {
    try {
      final accounts = await _readAllAccounts();
      int? accountIndex;
      int? billIndex;

      // 找到账单所在的账户
      for (int i = 0; i < accounts.length; i++) {
        final idx = accounts[i].bills.indexWhere((b) => b.id == id);
        if (idx != -1) {
          accountIndex = i;
          billIndex = idx;
          break;
        }
      }

      if (accountIndex == null || billIndex == null) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      final account = accounts[accountIndex];
      final oldBill = account.bills[billIndex];

      // 如果账单移动到其他账户
      if (oldBill.accountId != bill.accountId) {
        // 从旧账户移除
        account.bills.removeAt(billIndex);
        account.balance -= oldBill.amount;
        account.updatedAt = DateTime.now();

        // 添加到新账户
        final newAccountIndex = accounts.indexWhere((a) => a.id == bill.accountId);
        if (newAccountIndex == -1) {
          return Result.failure('目标账户不存在', code: ErrorCodes.notFound);
        }

        final newAccount = accounts[newAccountIndex];
        newAccount.bills.add(bill);
        newAccount.balance += bill.amount;
        newAccount.updatedAt = DateTime.now();
      } else {
        // 在同一账户内更新
        account.bills[billIndex] = bill;
        // 更新账户余额（先减去旧金额，再加上新金额）
        account.balance = account.balance - oldBill.amount + bill.amount;
        account.updatedAt = DateTime.now();
      }

      await _saveAllAccounts(accounts);
      return Result.success(bill);
    } catch (e) {
      return Result.failure('更新账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<bool>> deleteBill(String id) async {
    try {
      final accounts = await _readAllAccounts();
      int? accountIndex;
      int? billIndex;

      // 找到账单所在的账户
      for (int i = 0; i < accounts.length; i++) {
        final idx = accounts[i].bills.indexWhere((b) => b.id == id);
        if (idx != -1) {
          accountIndex = i;
          billIndex = idx;
          break;
        }
      }

      if (accountIndex == null || billIndex == null) {
        return Result.failure('账单不存在', code: ErrorCodes.notFound);
      }

      final account = accounts[accountIndex];
      final bill = account.bills[billIndex];

      // 更新账户余额
      account.balance -= bill.amount;
      account.updatedAt = DateTime.now();

      // 删除账单
      account.bills.removeAt(billIndex);

      await _saveAllAccounts(accounts);
      return Result.success(true);
    } catch (e) {
      return Result.failure('删除账单失败: $e', code: ErrorCodes.serverError);
    }
  }

  @override
  Future<Result<List<BillDto>>> searchBills(BillQuery query) async {
    try {
      final accounts = await _readAllAccounts();
      var allBills = <BillDto>[];

      for (final account in accounts) {
        if (query.accountId != null && account.id != query.accountId) continue;
        allBills.addAll(account.bills);
      }

      // 按类型过滤
      if (query.type != null) {
        allBills = allBills.where((b) => b.type == query.type).toList();
      }

      // 按分类过滤
      if (query.category != null) {
        allBills = allBills.where((b) => b.category == query.category).toList();
      }

      // 按日期范围过滤
      if (query.startDate != null) {
        allBills = allBills.where((b) => !b.date.isBefore(query.startDate!)).toList();
      }
      if (query.endDate != null) {
        allBills = allBills.where((b) => !b.date.isAfter(query.endDate!)).toList();
      }

      // 按关键词过滤
      if (query.keyword != null && query.keyword!.isNotEmpty) {
        final lowerKeyword = query.keyword!.toLowerCase();
        allBills = allBills.where((b) {
          final description = b.description?.toLowerCase() ?? '';
          return description.contains(lowerKeyword);
        }).toList();
      }

      // 按日期排序（最新在前）
      allBills.sort((a, b) => b.date.compareTo(a.date));

      // 应用分页
      if (query.pagination != null && query.pagination!.hasPagination) {
        final paginated = PaginationUtils.paginate(
          allBills,
          offset: query.pagination!.offset,
          count: query.pagination!.count,
        );
        return Result.success(paginated.data);
      }

      return Result.success(allBills);
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
      final accounts = await _readAllAccounts();
      var totalIncome = 0.0;
      var totalExpense = 0.0;
      var billCount = 0;

      for (final account in accounts) {
        for (final bill in account.bills) {
          // 按日期范围过滤
          if (startDate != null && bill.date.isBefore(startDate)) continue;
          if (endDate != null && bill.date.isAfter(endDate)) continue;

          if (bill.amount > 0) {
            totalIncome += bill.amount;
          } else {
            totalExpense += bill.amount.abs();
          }
          billCount++;
        }
      }

      return Result.success(BillStatsDto(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        billCount: billCount,
      ));
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
      final accounts = await _readAllAccounts();
      final categoryMap = <String, _CategoryStats>{};

      for (final account in accounts) {
        for (final bill in account.bills) {
          // 按类型过滤
          if (type != null && bill.type != type) continue;

          // 按日期范围过滤
          if (startDate != null && bill.date.isBefore(startDate)) continue;
          if (endDate != null && bill.date.isAfter(endDate)) continue;

          final category = bill.category;
          if (!categoryMap.containsKey(category)) {
            categoryMap[category] = _CategoryStats(category: category);
          }

          final stats = categoryMap[category]!;
          stats.amount += bill.amount.abs();
          stats.count += 1;
        }
      }

      // 计算百分比
      final totalAmount = categoryMap.values.fold<double>(0, (sum, s) => sum + s.amount);
      final result = categoryMap.values.map((s) {
        return CategoryStatsDto(
          category: s.category,
          amount: s.amount,
          count: s.count,
          percentage: totalAmount > 0 ? (s.amount / totalAmount * 100) : 0,
        );
      }).toList();

      // 按金额降序排序
      result.sort((a, b) => b.amount.compareTo(a.amount));

      return Result.success(result);
    } catch (e) {
      return Result.failure('获取分类统计失败: $e', code: ErrorCodes.serverError);
    }
  }
}

// ============ 内部数据类 ============

/// 账户（包含嵌套的账单列表）
class _AccountWithBills {
  String id;
  String name;
  double balance;
  String? icon;
  String? color;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic>? metadata;
  List<BillDto> bills;

  _AccountWithBills({
    required this.id,
    required this.name,
    required this.balance,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    required this.bills,
  });

  factory _AccountWithBills.fromJson(Map<String, dynamic> json) {
    final billsList = json['bills'] as List<dynamic>? ?? [];
    return _AccountWithBills(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      bills: billsList.map((b) => BillDto.fromJson(b as Map<String, dynamic>)).toList(),
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
      'bills': bills.map((b) => b.toJson()).toList(),
    };
  }

  factory _AccountWithBills.fromAccountDto(AccountDto dto, {List<BillDto>? bills}) {
    return _AccountWithBills(
      id: dto.id,
      name: dto.name,
      balance: dto.balance,
      icon: dto.icon,
      color: dto.color,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      metadata: dto.metadata,
      bills: bills ?? [],
    );
  }

  AccountDto toAccountDto() {
    return AccountDto(
      id: id,
      name: name,
      balance: balance,
      icon: icon,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }
}

/// 分类统计（内部使用）
class _CategoryStats {
  final String category;
  double amount = 0.0;
  int count = 0;

  _CategoryStats({required this.category});
}
