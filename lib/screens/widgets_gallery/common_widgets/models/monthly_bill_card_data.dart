import 'dart:convert';

/// 月度账单卡片数据模型
///
/// 用于表示月度账单信息，包括标题、收入、支出和结余
class MonthlyBillCardData {
  /// 账单标题（如"6月账单"）
  final String title;

  /// 收入金额
  final double income;

  /// 支出金额
  final double expense;

  /// 结余金额
  final double balance;

  const MonthlyBillCardData({
    required this.title,
    required this.income,
    required this.expense,
    required this.balance,
  });

  /// 从 JSON 创建实例
  factory MonthlyBillCardData.fromJson(Map<String, dynamic> json) {
    return MonthlyBillCardData(
      title: json['title'] as String? ?? '月度账单',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'income': income,
      'expense': expense,
      'balance': balance,
    };
  }

  /// 从 JSON 字符串创建实例
  static MonthlyBillCardData fromJsonString(String jsonString) {
    if (jsonString.isEmpty) {
      return MonthlyBillCardData.defaults();
    }
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return MonthlyBillCardData.fromJson(json);
    } catch (e) {
      return MonthlyBillCardData.defaults();
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 获取默认数据
  static MonthlyBillCardData defaults() {
    return const MonthlyBillCardData(
      title: '6月账单',
      income: 1024.00,
      expense: 2048.00,
      balance: -1024.00,
    );
  }

  /// 复制并修改部分属性
  MonthlyBillCardData copyWith({
    String? title,
    double? income,
    double? expense,
    double? balance,
  }) {
    return MonthlyBillCardData(
      title: title ?? this.title,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'MonthlyBillCardData(title: $title, income: $income, expense: $expense, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MonthlyBillCardData &&
        other.title == title &&
        other.income == income &&
        other.expense == expense &&
        other.balance == balance;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      income,
      expense,
      balance,
    );
  }
}
