part of 'bill_plugin.dart';

// ==================== JS API 定义 ====================

@override
Map<String, Function> defineJSAPI() {
  return {
    // 账户相关
    'getAccounts': _jsGetAccounts,
    'createAccount': _jsCreateAccount,
    'updateAccount': _jsUpdateAccount,
    'deleteAccount': _jsDeleteAccount,

    // 账单相关
    'getBills': _jsGetBills,
    'createBill': _jsCreateBill,
    'updateBill': _jsUpdateBill,
    'deleteBill': _jsDeleteBill,

    // 统计相关
    'getStats': _jsGetStats,
    'getCategoryStats': _jsGetCategoryStats,

    // 账户查找方法
    'findAccountBy': _jsFindAccountBy,
    'findAccountById': _jsFindAccountById,
    'findAccountByName': _jsFindAccountByName,

    // 账单查找方法
    'findBillBy': _jsFindBillBy,
    'findBillById': _jsFindBillById,
    'findBillByTitle': _jsFindBillByTitle,
    'findBillsByCategory': _jsFindBillsByCategory,
  };
}

// ==================== 辅助方法 ====================

/// 分页控制器 - 对列表进行分页处理
/// @param list 原始数据列表
/// @param offset 起始位置（默认 0）
/// @param count 返回数量（默认 100）
/// @return 分页后的数据，包含 data、total、offset、count、hasMore
Map<String, dynamic> _paginate<T>(
  List<T> list, {
  int offset = 0,
  int count = 100,
}) {
  final total = list.length;
  final start = offset.clamp(0, total);
  final end = (start + count).clamp(start, total);
  final data = list.sublist(start, end);

  return {
    'data': data,
    'total': total,
    'offset': start,
    'count': data.length,
    'hasMore': end < total,
  };
}

// ==================== JS API 实现 ====================

/// 获取所有账户(不包含账单数据)
/// 支持分页参数: offset, count
Future<String> _jsGetAccounts(Map<String, dynamic> params) async {
  final result = await _billUseCase.getAccounts(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '获取账户失败'});
  }

  return jsonEncode(result.dataOrNull);
}

/// 创建账户
/// @param params.title 账户名称 (必需)
/// @param params.id 账户ID (可选，不传则自动生成 UUID)
/// @param params.iconCodePoint 图标代码点 (可选，默认 Icons.account_balance_wallet)
/// @param params.backgroundColor 背景颜色值 (可选，默认绿色)
Future<String> _jsCreateAccount(Map<String, dynamic> params) async {
  final result = await _billUseCase.createAccount(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '创建账户失败'});
  }

  return jsonEncode(result.dataOrNull);
}

/// 更新账户
/// @param params.accountId 账户ID (必需)
/// @param params.title 新账户名称 (可选)
/// @param params.iconCodePoint 新图标代码点 (可选)
/// @param params.backgroundColor 新背景颜色值 (可选)
Future<String> _jsUpdateAccount(Map<String, dynamic> params) async {
  final result = await _billUseCase.updateAccount(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '更新账户失败'});
  }

  return jsonEncode(result.dataOrNull);
}

/// 删除账户
/// @param params.accountId 账户ID (必需)
Future<String> _jsDeleteAccount(Map<String, dynamic> params) async {
  final result = await _billUseCase.deleteAccount(params);

  if (result.isFailure) {
    return jsonEncode({
      'success': false,
      'error': result.errorOrNull?.message ?? '删除账户失败',
    });
  }

  return jsonEncode({'success': true, 'accountId': params['accountId']});
}

/// 获取账单列表
/// @param params.accountId 账户ID (可选，不传则返回所有账户的账单)
/// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
/// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
/// @param params.offset 分页起始位置 (可选，默认 0)
/// @param params.count 返回数量 (可选，默认 100)
Future<String> _jsGetBills(Map<String, dynamic> params) async {
  final result = await _billUseCase.getBills(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '获取账单失败'});
  }

  return jsonEncode({
    'success': true,
    'data': result.dataOrNull ?? [],
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
}

/// 创建账单
/// @param params.amount 金额 (必需)
/// @param params.type 类型 (必需，'income' 或 'expense')
/// @param params.category 分类 (必需)
/// @param params.accountId 账户ID (可选，不传则使用第一个账户)
/// @param params.description 描述 (可选)
/// @param params.date 日期 (可选，ISO8601格式，默认今天)
/// @param params.tags 标签列表 (可选)
/// @param params.metadata 元数据 (可选)
Future<String> _jsCreateBill(Map<String, dynamic> params) async {
  final result = await _billUseCase.createBill(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '创建账单失败'});
  }

  return jsonEncode(result.dataOrNull);
}

/// 更新账单
/// @param params.billId 账单ID (必需)
/// @param params.accountId 账户ID (必需)
/// @param params.amount 新金额 (可选)
/// @param params.category 新分类 (可选)
/// @param params.title 新标题 (可选)
/// @param params.date 新日期 (可选，格式: YYYY-MM-DD)
/// @param params.note 新备注 (可选)
/// @param params.tag 新标签 (可选)
Future<String> _jsUpdateBill(Map<String, dynamic> params) async {
  final result = await _billUseCase.updateBill(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '更新账单失败'});
  }

  return jsonEncode(result.dataOrNull);
}

/// 删除账单
/// @param params.accountId 账户ID (必需)
/// @param params.billId 账单ID (必需)
Future<String> _jsDeleteBill(Map<String, dynamic> params) async {
  final result = await _billUseCase.deleteBill(params);

  if (result.isFailure) {
    return jsonEncode({
      'success': false,
      'error': result.errorOrNull?.message ?? '删除账单失败',
    });
  }

  return jsonEncode({
    'success': true,
    'accountId': params['accountId'],
    'billId': params['billId'],
  });
}

/// 获取统计信息
/// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
/// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
/// @param params.accountId 账户ID (可选，不传则统计所有账户)
Future<String> _jsGetStats(Map<String, dynamic> params) async {
  final result = await _billUseCase.getStats(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '获取统计失败'});
  }

  // result.dataOrNull 返回的是 Map<String, dynamic>
  final stats = result.dataOrNull as Map<String, dynamic>;
  return jsonEncode({
    'totalIncome': stats['totalIncome'],
    'totalExpense': stats['totalExpense'],
    'balance': stats['balance'],
    'billCount': stats['billCount'],
    'todayFinance': _billController.getTodayFinance(),
    'monthFinance': _billController.getMonthFinance(),
    'monthBillCount': _billController.getMonthBillCount(),
  });
}

/// 获取分类统计
/// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
/// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
/// @param params.accountId 账户ID (可选，不传则统计所有账户)
Future<String> _jsGetCategoryStats(Map<String, dynamic> params) async {
  final result = await _billUseCase.getCategoryStats(params);

  if (result.isFailure) {
    return jsonEncode({'error': result.errorOrNull?.message ?? '获取分类统计失败'});
  }

  // result.dataOrNull 返回的是 List<Map<String, dynamic>>
  final categoryStats = result.dataOrNull as List<Map<String, dynamic>>;
  final statsMap = <String, double>{};
  for (final stat in categoryStats) {
    statsMap[stat['category'] as String] = stat['amount'] as double;
  }

  return jsonEncode(statsMap);
}

// ==================== 账户查找方法 ====================

/// 通用账户查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindAccountBy(Map<String, dynamic> params) async {
  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: field'});
  }

  final dynamic value = params['value'];
  if (value == null) {
    return jsonEncode({'error': '缺少必需参数: value'});
  }

  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final accounts = _billController.accounts;
  final List<Account> matchedAccounts = [];

  for (final account in accounts) {
    final accountJson = account.toJson();
    accountJson.remove('bills'); // 移除 bills 字段

    // 检查字段是否匹配
    if (accountJson.containsKey(field) && accountJson[field] == value) {
      matchedAccounts.add(account);
      if (!findAll) break; // 只找第一个
    }
  }

  if (findAll) {
    final accountsJson =
        matchedAccounts.map((a) {
          final json = a.toJson();
          json.remove('bills');
          return json;
        }).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        accountsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(accountsJson);
  } else {
    if (matchedAccounts.isEmpty) {
      return jsonEncode(null);
    }
    final json = matchedAccounts.first.toJson();
    json.remove('bills');
    return jsonEncode(json);
  }
}

/// 根据ID查找账户
/// @param params.id 账户ID (必需)
Future<String> _jsFindAccountById(Map<String, dynamic> params) async {
  final String? id = params['id'];
  if (id == null || id.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: id'});
  }

  final account = _billController.accounts.firstWhere(
    (a) => a.id == id,
    orElse:
        () => Account(
      id: '',
      title: '',
      icon: Icons.error,
      backgroundColor: Colors.transparent,
    ),
  );

  if (account.id.isEmpty) {
    return jsonEncode(null);
  }

  final json = account.toJson();
  json.remove('bills');
  return jsonEncode(json);
}

/// 根据名称查找账户
/// @param params.name 账户名称 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindAccountByName(Map<String, dynamic> params) async {
  final String? name = params['name'];
  if (name == null || name.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: name'});
  }

  final bool fuzzy = params['fuzzy'] ?? false;
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final accounts = _billController.accounts;
  final List<Account> matchedAccounts = [];

  for (final account in accounts) {
    bool matches = false;
    if (fuzzy) {
      matches = account.title.contains(name);
    } else {
      matches = account.title == name;
    }

    if (matches) {
      matchedAccounts.add(account);
      if (!findAll) break;
    }
  }

  if (findAll) {
    final accountsJson =
        matchedAccounts.map((a) {
          final json = a.toJson();
          json.remove('bills');
          return json;
        }).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        accountsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(accountsJson);
  } else {
    if (matchedAccounts.isEmpty) {
      return jsonEncode(null);
    }
    final json = matchedAccounts.first.toJson();
    json.remove('bills');
    return jsonEncode(json);
  }
}

// ==================== 账单查找方法 ====================

/// 通用账单查找
/// @param params.field 要匹配的字段名 (必需)
/// @param params.value 要匹配的值 (必需)
/// @param params.accountId 限定在特定账户内查找 (可选)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindBillBy(Map<String, dynamic> params) async {
  final String? field = params['field'];
  if (field == null || field.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: field'});
  }

  final dynamic value = params['value'];
  if (value == null) {
    return jsonEncode({'error': '缺少必需参数: value'});
  }

  final String? accountId = params['accountId'];
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  // 获取所有账单
  final allBills = await _billController.getBills();
  final List<Bill> matchedBills = [];

  for (final bill in allBills) {
    // 如果指定了 accountId，先过滤账户
    if (accountId != null &&
        accountId.isNotEmpty &&
        bill.accountId != accountId) {
      continue;
    }

    final billJson = bill.toJson();

    // 检查字段是否匹配
    if (billJson.containsKey(field) && billJson[field] == value) {
      matchedBills.add(bill);
      if (!findAll) break;
    }
  }

  if (findAll) {
    final billsJson = matchedBills.map((b) => b.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        billsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(billsJson);
  } else {
    if (matchedBills.isEmpty) {
      return jsonEncode(null);
    }
    return jsonEncode(matchedBills.first.toJson());
  }
}

/// 根据ID查找账单
/// @param params.id 账单ID (必需)
/// @param params.accountId 限定在特定账户内查找 (可选)
Future<String> _jsFindBillById(Map<String, dynamic> params) async {
  final String? id = params['id'];
  if (id == null || id.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: id'});
  }

  final String? accountId = params['accountId'];
  final allBills = await _billController.getBills();

  Bill? foundBill;
  for (final bill in allBills) {
    if (bill.id == id) {
      if (accountId == null ||
          accountId.isEmpty ||
          bill.accountId == accountId) {
        foundBill = bill;
        break;
      }
    }
  }

  if (foundBill == null) {
    return jsonEncode(null);
  }

  return jsonEncode(foundBill.toJson());
}

/// 根据标题查找账单
/// @param params.title 账单标题 (必需)
/// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
/// @param params.accountId 限定在特定账户内查找 (可选)
/// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
/// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
/// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
Future<String> _jsFindBillByTitle(Map<String, dynamic> params) async {
  final String? title = params['title'];
  if (title == null || title.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: title'});
  }

  final bool fuzzy = params['fuzzy'] ?? false;
  final String? accountId = params['accountId'];
  final bool findAll = params['findAll'] ?? false;
  final int? offset = params['offset'];
  final int? count = params['count'];

  final allBills = await _billController.getBills();
  final List<Bill> matchedBills = [];

  for (final bill in allBills) {
    // 如果指定了 accountId，先过滤账户
    if (accountId != null &&
        accountId.isNotEmpty &&
        bill.accountId != accountId) {
      continue;
    }

    bool matches = false;
    if (fuzzy) {
      matches = bill.title.contains(title);
    } else {
      matches = bill.title == title;
    }

    if (matches) {
      matchedBills.add(bill);
      if (!findAll) break;
    }
  }

  if (findAll) {
    final billsJson = matchedBills.map((b) => b.toJson()).toList();

    // 检查是否需要分页
    if (offset != null || count != null) {
      final paginated = _paginate(
        billsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    return jsonEncode(billsJson);
  } else {
    if (matchedBills.isEmpty) {
      return jsonEncode(null);
    }
    return jsonEncode(matchedBills.first.toJson());
  }
}

/// 根据分类查找账单
/// @param params.category 分类名称 (必需)
/// @param params.accountId 限定在特定账户内查找 (可选)
/// @param params.startDate 开始日期 (可选，格式: YYYY-MM-DD)
/// @param params.endDate 结束日期 (可选，格式: YYYY-MM-DD)
/// @param params.offset 分页起始位置 (可选，默认 0)
/// @param params.count 返回数量 (可选，默认 100)
Future<String> _jsFindBillsByCategory(Map<String, dynamic> params) async {
  final String? category = params['category'];
  if (category == null || category.isEmpty) {
    return jsonEncode({'error': '缺少必需参数: category'});
  }

  final String? accountId = params['accountId'];
  final String? startDate = params['startDate'];
  final String? endDate = params['endDate'];
  final int? offset = params['offset'];
  final int? count = params['count'];

  // 解析日期参数
  DateTime? start;
  DateTime? end;

  if (startDate != null && startDate.isNotEmpty) {
    try {
      start = DateTime.parse(startDate);
    } catch (e) {
      return jsonEncode({'error': '日期格式错误: $startDate，应为 YYYY-MM-DD 格式'});
    }
  }

  if (endDate != null && endDate.isNotEmpty) {
    try {
      end = DateTime.parse(endDate);
    } catch (e) {
      return jsonEncode({'error': '日期格式错误: $endDate，应为 YYYY-MM-DD 格式'});
    }
  }

  // 获取账单列表
  final allBills = await _billController.getBills(
    startDate: start,
    endDate: end,
  );

  // 过滤账单
  final matchedBills =
      allBills.where((bill) {
        // 匹配分类
        if (bill.category != category) return false;

        // 如果指定了 accountId，过滤账户
        if (accountId != null &&
            accountId.isNotEmpty &&
            bill.accountId != accountId) {
          return false;
        }

        return true;
      }).toList();

  final billsJson = matchedBills.map((b) => b.toJson()).toList();

  // 检查是否需要分页
  if (offset != null || count != null) {
    final paginated = _paginate(
      billsJson,
      offset: offset ?? 0,
      count: count ?? 100,
    );
    return jsonEncode(paginated);
  }

  return jsonEncode(billsJson);
}
