import 'dart:convert';
import 'package:flutter/material.dart';

/// 账户余额卡片数据模型
///
/// 用于表示单个账户的信息，包括名称、图标、颜色、账单数量和余额
class AccountBalanceCardData {
  /// 账户名称
  final String name;

  /// 图标代码 (Material Icons 图标名称)
  final String iconName;

  /// 图标颜色 (十六进制字符串，如 "#3498DB")
  final String iconColor;

  /// 账单数量
  final int billCount;

  /// 余额
  final double balance;

  const AccountBalanceCardData({
    required this.name,
    required this.iconName,
    required this.iconColor,
    required this.billCount,
    required this.balance,
  });

  /// 从 JSON 创建实例
  factory AccountBalanceCardData.fromJson(Map<String, dynamic> json) {
    return AccountBalanceCardData(
      name: json['name'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'account_balance_wallet',
      iconColor: json['iconColor'] as String? ?? '#3498DB',
      billCount: (json['billCount'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconName': iconName,
      'iconColor': iconColor,
      'billCount': billCount,
      'balance': balance,
    };
  }

  /// 获取 IconData 对象
  IconData get iconData {
    // 尝试从 Material Icons 中获取图标
    // 由于无法动态映射，使用默认图标
    return Icons.account_balance_wallet;
  }

  /// 获取 Color 对象
  Color get iconColorObject {
    try {
      final colorString = iconColor.replaceAll('#', '');
      if (colorString.length == 6) {
        final colorValue = int.parse(colorString, radix: 16);
        return Color(0xFF000000 | colorValue);
      }
    } catch (e) {
      // 解析失败，返回默认颜色
    }
    return const Color(0xFF3498DB);
  }

  /// 从 JSON 字符串创建实例列表
  static List<AccountBalanceCardData> listFromJson(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AccountBalanceCardData.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 转换为 JSON 字符串
  static String listToJson(List<AccountBalanceCardData> data) {
    return jsonEncode(data.map((item) => item.toJson()).toList());
  }

  /// 复制并修改部分属性
  AccountBalanceCardData copyWith({
    String? name,
    String? iconName,
    String? iconColor,
    int? billCount,
    double? balance,
  }) {
    return AccountBalanceCardData(
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      iconColor: iconColor ?? this.iconColor,
      billCount: billCount ?? this.billCount,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'AccountBalanceCardData(name: $name, iconName: $iconName, iconColor: $iconColor, billCount: $billCount, balance: $balance)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountBalanceCardData &&
        other.name == name &&
        other.iconName == iconName &&
        other.iconColor == iconColor &&
        other.billCount == billCount &&
        other.balance == balance;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      iconName,
      iconColor,
      billCount,
      balance,
    );
  }
}
