import 'package:flutter/material.dart';

/// 快捷记账预设数据模型
class BillShortcut {
  /// 唯一标识
  final String id;

  /// 显示名称（如"早餐"、"打车"）
  final String name;

  /// 账户ID
  final String accountId;

  /// 分类（如"餐饮"、"交通"）
  final String category;

  /// 预设金额（可选，null表示每次手动输入）
  final double? amount;

  /// 是否支出
  final bool isExpense;

  /// 图标（自动从分类获取）
  final IconData icon;

  /// 图标颜色
  final Color iconColor;

  BillShortcut({
    String? id,
    required this.name,
    required this.accountId,
    required this.category,
    this.amount,
    required this.isExpense,
    required this.icon,
    required this.iconColor,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountId': accountId,
      'category': category,
      'amount': amount,
      'isExpense': isExpense,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'iconColor': iconColor.value,
    };
  }

  /// 从JSON反序列化
  factory BillShortcut.fromJson(Map<String, dynamic> json) {
    return BillShortcut(
      id: json['id'] as String,
      name: json['name'] as String,
      accountId: json['accountId'] as String,
      category: json['category'] as String,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      isExpense: json['isExpense'] as bool,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      iconColor: Color(json['iconColor'] as int),
    );
  }

  /// 复制并修改部分字段
  BillShortcut copyWith({
    String? id,
    String? name,
    String? accountId,
    String? category,
    double? amount,
    bool? isExpense,
    IconData? icon,
    Color? iconColor,
  }) {
    return BillShortcut(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  @override
  String toString() {
    return 'BillShortcut(id: $id, name: $name, category: $category, '
        'amount: $amount, isExpense: $isExpense)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BillShortcut &&
        other.id == id &&
        other.name == name &&
        other.accountId == accountId &&
        other.category == category &&
        other.amount == amount &&
        other.isExpense == isExpense;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        accountId.hashCode ^
        category.hashCode ^
        (amount?.hashCode ?? 0) ^
        isExpense.hashCode;
  }
}

/// 快捷记账小组件配置
class BillShortcutsWidgetConfig {
  /// 小组件ID
  final int widgetId;

  /// 预设列表
  final List<BillShortcut> shortcuts;

  BillShortcutsWidgetConfig({
    required this.widgetId,
    required this.shortcuts,
  });

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'shortcuts': shortcuts.map((s) => s.toJson()).toList(),
    };
  }

  /// 从JSON反序列化
  factory BillShortcutsWidgetConfig.fromJson(Map<String, dynamic> json) {
    return BillShortcutsWidgetConfig(
      widgetId: json['widgetId'] as int,
      shortcuts: (json['shortcuts'] as List)
          .map((s) => BillShortcut.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 复制并修改部分字段
  BillShortcutsWidgetConfig copyWith({
    int? widgetId,
    List<BillShortcut>? shortcuts,
  }) {
    return BillShortcutsWidgetConfig(
      widgetId: widgetId ?? this.widgetId,
      shortcuts: shortcuts ?? this.shortcuts,
    );
  }

  @override
  String toString() {
    return 'BillShortcutsWidgetConfig(widgetId: $widgetId, '
        'shortcuts: ${shortcuts.length} items)';
  }
}
