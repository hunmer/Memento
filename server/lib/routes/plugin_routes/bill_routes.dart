import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../../services/plugin_data_service.dart';

/// Bill 插件 HTTP 路由
class BillRoutes {
  final PluginDataService _dataService;
  final _uuid = const Uuid();

  BillRoutes(this._dataService);

  Router get router {
    final router = Router();

    // ==================== 账户 API ====================
    router.get('/accounts', _getAccounts);
    router.get('/accounts/<id>', _getAccount);
    router.post('/accounts', _createAccount);
    router.put('/accounts/<id>', _updateAccount);
    router.delete('/accounts/<id>', _deleteAccount);

    // ==================== 账单 API ====================
    router.get('/bills', _getBills);
    router.get('/bills/<id>', _getBill);
    router.post('/bills', _createBill);
    router.put('/bills/<id>', _updateBill);
    router.delete('/bills/<id>', _deleteBill);

    // ==================== 统计 API ====================
    router.get('/stats', _getStats);
    router.get('/stats/category', _getCategoryStats);

    return router;
  }

  // ==================== 辅助方法 ====================

  String? _getUserId(Request request) {
    return request.context['userId'] as String?;
  }

  Response _successResponse(dynamic data) {
    return Response.ok(
      jsonEncode({
        'success': true,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _paginatedResponse(List<dynamic> data, {int offset = 0, int count = 100}) {
    final paginated = _dataService.paginate(data, offset: offset, count: count);
    return Response.ok(
      jsonEncode({
        'success': true,
        ...paginated,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _errorResponse(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// 读取账户数据 (账单嵌套在账户中)
  Future<Map<String, dynamic>> _readAccountsData(String userId) async {
    final data = await _dataService.readPluginData(userId, 'bill', 'accounts.json');
    return data ?? {'accounts': []};
  }

  /// 解析账户列表，支持两种存储格式
  /// 1. JSON字符串数组 (Flutter客户端格式)
  /// 2. Map对象数组 (直接格式)
  List<Map<String, dynamic>> _parseAccountsList(List<dynamic> accountsList) {
    return accountsList.map((item) {
      if (item is String) {
        // Flutter客户端存储格式：JSON字符串
        return jsonDecode(item) as Map<String, dynamic>;
      } else if (item is Map<String, dynamic>) {
        // 直接Map格式
        return item;
      } else {
        throw Exception('无效的账户数据格式: ${item.runtimeType}');
      }
    }).toList();
  }

  /// 保存账户数据
  Future<void> _saveAccountsData(String userId, Map<String, dynamic> data) async {
    await _dataService.writePluginData(userId, 'bill', 'accounts.json', data);
  }

  // ==================== 账户处理方法 ====================

  Future<Response> _getAccounts(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      // 不返回嵌套的账单，只返回账户概要
      final accountsSummary = accounts.map((account) {
        final bills = (account['bills'] as List<dynamic>? ?? []);
        final totalIncome = bills.fold<double>(0, (sum, bill) {
          final amount = (bill['amount'] as num? ?? 0).toDouble();
          return sum + (amount > 0 ? amount : 0);
        });
        final totalExpense = bills.fold<double>(0, (sum, bill) {
          final amount = (bill['amount'] as num? ?? 0).toDouble();
          return sum + (amount < 0 ? amount.abs() : 0);
        });

        return {
          'id': account['id'],
          'name': account['name'],
          'balance': account['balance'],
          'icon': account['icon'],
          'color': account['color'],
          'billCount': bills.length,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
        };
      }).toList();

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(accountsSummary, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(accountsSummary);
    } catch (e) {
      return _errorResponse(500, '获取账户失败: $e');
    }
  }

  Future<Response> _getAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      final account = accounts.firstWhere((a) => a['id'] == id, orElse: () => <String, dynamic>{});

      if (account.isEmpty) return _errorResponse(404, '账户不存在');
      return _successResponse(account);
    } catch (e) {
      return _errorResponse(500, '获取账户失败: $e');
    }
  }

  Future<Response> _createAccount(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final reqData = jsonDecode(body) as Map<String, dynamic>;

      final name = reqData['name'] as String?;
      if (name == null || name.isEmpty) return _errorResponse(400, '缺少必需参数: name');

      final accountId = reqData['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final account = {
        'id': accountId,
        'name': name,
        'balance': reqData['balance'] ?? 0.0,
        'icon': reqData['icon'],
        'color': reqData['color'],
        'bills': <Map<String, dynamic>>[],
        'createdAt': now,
        'updatedAt': now,
      };

      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      accounts.add(account);
      data['accounts'] = accounts;

      await _saveAccountsData(userId, data);
      return _successResponse(account);
    } catch (e) {
      return _errorResponse(500, '创建账户失败: $e');
    }
  }

  Future<Response> _updateAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      final index = accounts.indexWhere((a) => (a as Map)['id'] == id);

      if (index == -1) return _errorResponse(404, '账户不存在');

      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      final account = Map<String, dynamic>.from(accounts[index] as Map);

      if (updates.containsKey('name')) account['name'] = updates['name'];
      if (updates.containsKey('balance')) account['balance'] = updates['balance'];
      if (updates.containsKey('icon')) account['icon'] = updates['icon'];
      if (updates.containsKey('color')) account['color'] = updates['color'];
      account['updatedAt'] = DateTime.now().toIso8601String();

      accounts[index] = account;
      data['accounts'] = accounts;
      await _saveAccountsData(userId, data);
      return _successResponse(account);
    } catch (e) {
      return _errorResponse(500, '更新账户失败: $e');
    }
  }

  Future<Response> _deleteAccount(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      final initialLength = accounts.length;
      accounts.removeWhere((a) => (a as Map)['id'] == id);

      if (accounts.length == initialLength) return _errorResponse(404, '账户不存在');

      data['accounts'] = accounts;
      await _saveAccountsData(userId, data);
      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除账户失败: $e');
    }
  }

  // ==================== 账单处理方法 ====================

  Future<Response> _getBills(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final accountId = request.url.queryParameters['accountId'];
    final startDate = request.url.queryParameters['startDate'];
    final endDate = request.url.queryParameters['endDate'];

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      List<Map<String, dynamic>> allBills = [];

      for (final account in accounts) {
        if (accountId != null && account['id'] != accountId) continue;

        final bills = (account['bills'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        for (final bill in bills) {
          bill['accountId'] = account['id'];
          bill['accountName'] = account['name'];
          allBills.add(bill);
        }
      }

      // 按日期过滤
      if (startDate != null) {
        final start = DateTime.parse(startDate);
        allBills = allBills.where((bill) {
          final date = DateTime.parse(bill['date'] as String);
          return !date.isBefore(start);
        }).toList();
      }

      if (endDate != null) {
        final end = DateTime.parse(endDate);
        allBills = allBills.where((bill) {
          final date = DateTime.parse(bill['date'] as String);
          return !date.isAfter(end);
        }).toList();
      }

      // 按日期排序（最新在前）
      allBills.sort((a, b) {
        final aDate = DateTime.parse(a['date'] as String);
        final bDate = DateTime.parse(b['date'] as String);
        return bDate.compareTo(aDate);
      });

      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '');
      final count = int.tryParse(request.url.queryParameters['count'] ?? '');

      if (offset != null || count != null) {
        return _paginatedResponse(allBills, offset: offset ?? 0, count: count ?? 100);
      }
      return _successResponse(allBills);
    } catch (e) {
      return _errorResponse(500, '获取账单失败: $e');
    }
  }

  Future<Response> _getBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      for (final account in accounts) {
        final bills = (account['bills'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final bill = bills.firstWhere((b) => b['id'] == id, orElse: () => <String, dynamic>{});
        if (bill.isNotEmpty) {
          bill['accountId'] = account['id'];
          return _successResponse(bill);
        }
      }
      return _errorResponse(404, '账单不存在');
    } catch (e) {
      return _errorResponse(500, '获取账单失败: $e');
    }
  }

  Future<Response> _createBill(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final reqData = jsonDecode(body) as Map<String, dynamic>;

      final accountId = reqData['accountId'] as String?;
      final amount = reqData['amount'] as num?;

      if (accountId == null || amount == null) {
        return _errorResponse(400, '缺少必需参数: accountId, amount');
      }

      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      final accountIndex = accounts.indexWhere((a) => (a as Map)['id'] == accountId);

      if (accountIndex == -1) return _errorResponse(404, '账户不存在');

      final billId = reqData['id'] as String? ?? _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final bill = {
        'id': billId,
        'amount': amount, // 正数为收入，负数为支出
        'category': reqData['category'],
        'note': reqData['note'],
        'date': reqData['date'] ?? now.split('T')[0],
        'tags': reqData['tags'] ?? <String>[],
        'createdAt': now,
        'updatedAt': now,
      };

      final account = Map<String, dynamic>.from(accounts[accountIndex] as Map);
      final bills = (account['bills'] as List<dynamic>? ?? []).toList();
      bills.add(bill);
      account['bills'] = bills;

      // 更新账户余额
      account['balance'] = (account['balance'] as num? ?? 0) + amount;
      account['updatedAt'] = now;

      accounts[accountIndex] = account;
      data['accounts'] = accounts;
      await _saveAccountsData(userId, data);

      return _successResponse(bill);
    } catch (e) {
      return _errorResponse(500, '创建账单失败: $e');
    }
  }

  Future<Response> _updateBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final body = await request.readAsString();
      final updates = jsonDecode(body) as Map<String, dynamic>;
      final accountId = updates['accountId'] as String?;

      if (accountId == null) return _errorResponse(400, '缺少参数: accountId');

      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      final accountIndex = accounts.indexWhere((a) => (a as Map)['id'] == accountId);

      if (accountIndex == -1) return _errorResponse(404, '账户不存在');

      final account = Map<String, dynamic>.from(accounts[accountIndex] as Map);
      final bills = (account['bills'] as List<dynamic>? ?? []).toList();
      final billIndex = bills.indexWhere((b) => (b as Map)['id'] == id);

      if (billIndex == -1) return _errorResponse(404, '账单不存在');

      final bill = Map<String, dynamic>.from(bills[billIndex] as Map);
      final oldAmount = bill['amount'] as num? ?? 0;

      if (updates.containsKey('amount')) bill['amount'] = updates['amount'];
      if (updates.containsKey('category')) bill['category'] = updates['category'];
      if (updates.containsKey('note')) bill['note'] = updates['note'];
      if (updates.containsKey('date')) bill['date'] = updates['date'];
      if (updates.containsKey('tags')) bill['tags'] = updates['tags'];
      bill['updatedAt'] = DateTime.now().toIso8601String();

      bills[billIndex] = bill;
      account['bills'] = bills;

      // 更新账户余额
      final newAmount = bill['amount'] as num? ?? 0;
      account['balance'] = (account['balance'] as num? ?? 0) - oldAmount + newAmount;

      accounts[accountIndex] = account;
      data['accounts'] = accounts;
      await _saveAccountsData(userId, data);

      return _successResponse(bill);
    } catch (e) {
      return _errorResponse(500, '更新账单失败: $e');
    }
  }

  Future<Response> _deleteBill(Request request, String id) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final accountId = request.url.queryParameters['accountId'];
    if (accountId == null) return _errorResponse(400, '缺少参数: accountId');

    try {
      final data = await _readAccountsData(userId);
      final accounts = (data['accounts'] as List<dynamic>? ?? []).toList();
      final accountIndex = accounts.indexWhere((a) => (a as Map)['id'] == accountId);

      if (accountIndex == -1) return _errorResponse(404, '账户不存在');

      final account = Map<String, dynamic>.from(accounts[accountIndex] as Map);
      final bills = (account['bills'] as List<dynamic>? ?? []).toList();

      final billIndex = bills.indexWhere((b) => (b as Map)['id'] == id);
      if (billIndex == -1) return _errorResponse(404, '账单不存在');

      final bill = bills[billIndex] as Map<String, dynamic>;
      final amount = bill['amount'] as num? ?? 0;

      bills.removeAt(billIndex);
      account['bills'] = bills;

      // 更新账户余额
      account['balance'] = (account['balance'] as num? ?? 0) - amount;

      accounts[accountIndex] = account;
      data['accounts'] = accounts;
      await _saveAccountsData(userId, data);

      return _successResponse({'deleted': true, 'id': id});
    } catch (e) {
      return _errorResponse(500, '删除账单失败: $e');
    }
  }

  // ==================== 统计方法 ====================

  Future<Response> _getStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    final startDate = request.url.queryParameters['startDate'];
    final endDate = request.url.queryParameters['endDate'];

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      var totalIncome = 0.0;
      var totalExpense = 0.0;
      var billCount = 0;

      for (final account in accounts) {
        final bills = (account['bills'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        for (final bill in bills) {
          // 按日期过滤
          if (startDate != null || endDate != null) {
            final billDate = DateTime.parse(bill['date'] as String);
            if (startDate != null && billDate.isBefore(DateTime.parse(startDate))) continue;
            if (endDate != null && billDate.isAfter(DateTime.parse(endDate))) continue;
          }

          final amount = (bill['amount'] as num? ?? 0).toDouble();
          if (amount > 0) {
            totalIncome += amount;
          } else {
            totalExpense += amount.abs();
          }
          billCount++;
        }
      }

      return _successResponse({
        'accountCount': accounts.length,
        'billCount': billCount,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
        'startDate': startDate,
        'endDate': endDate,
      });
    } catch (e) {
      return _errorResponse(500, '获取统计失败: $e');
    }
  }

  Future<Response> _getCategoryStats(Request request) async {
    final userId = _getUserId(request);
    if (userId == null) return _errorResponse(401, '未认证');

    try {
      final data = await _readAccountsData(userId);
      final accountsList = data['accounts'] as List<dynamic>? ?? [];
      final accounts = _parseAccountsList(accountsList);

      final categoryStats = <String, Map<String, dynamic>>{};

      for (final account in accounts) {
        final bills = (account['bills'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

        for (final bill in bills) {
          final category = bill['category'] as String? ?? '未分类';
          final amount = (bill['amount'] as num? ?? 0).toDouble();

          categoryStats.putIfAbsent(category, () => {
            'category': category,
            'income': 0.0,
            'expense': 0.0,
            'count': 0,
          });

          if (amount > 0) {
            categoryStats[category]!['income'] = (categoryStats[category]!['income'] as double) + amount;
          } else {
            categoryStats[category]!['expense'] = (categoryStats[category]!['expense'] as double) + amount.abs();
          }
          categoryStats[category]!['count'] = (categoryStats[category]!['count'] as int) + 1;
        }
      }

      return _successResponse(categoryStats.values.toList());
    } catch (e) {
      return _errorResponse(500, '获取分类统计失败: $e');
    }
  }
}
