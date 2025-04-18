import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BillModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String category;
  final String? note;
  final bool isExpense;

  BillModel({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
    required this.category,
    this.note,
    required this.isExpense,
  }) : id = id ?? const Uuid().v4();

  BillModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    IconData? icon,
    Color? color,
    String? category,
    String? note,
    bool? isExpense,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      note: note ?? this.note,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'category': category,
      'note': note,
      'isExpense': isExpense,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      icon: IconData(
        map['iconCodePoint'],
        fontFamily: map['iconFontFamily'],
        fontPackage: map['iconFontPackage'],
      ),
      color: Color(map['colorValue']),
      category: map['category'],
      note: map['note'],
      isExpense: map['isExpense'],
    );
  }
}