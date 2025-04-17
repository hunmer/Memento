import 'package:flutter/material.dart';
import 'usage_record.dart';
import 'custom_field.dart';

class GoodsItem {
  final String id;
  final String title;
  final String? imageUrl;
  final IconData? icon;
  final Color? iconColor;
  final List<String> tags;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final List<UsageRecord> usageRecords;
  final List<CustomField> customFields;
  final String? notes;

  GoodsItem({
    required this.id,
    required this.title,
    this.imageUrl,
    this.icon,
    this.iconColor,
    List<String>? tags,
    this.purchaseDate,
    this.purchasePrice,
    List<UsageRecord>? usageRecords,
    List<CustomField>? customFields,
    this.notes,
  }) : 
    tags = tags ?? [],
    usageRecords = usageRecords ?? [],
    customFields = customFields ?? [];

  DateTime? get lastUsedDate {
    if (usageRecords.isEmpty) return null;
    return usageRecords
        .reduce((value, element) => 
            value.date.isAfter(element.date) ? value : element)
        .date;
  }

  factory GoodsItem.fromJson(Map<String, dynamic> json) {
    return GoodsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      icon: json['iconData'] != null
          ? IconData(json['iconData'] as int, fontFamily: 'MaterialIcons')
          : null,
      iconColor: json['iconColor'] != null
          ? Color(json['iconColor'] as int)
          : null,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      purchasePrice: json['purchasePrice'] as double?,
      usageRecords: (json['usageRecords'] as List?)
          ?.map((e) => UsageRecord.fromJson(e))
          .toList() ??
          [],
      customFields: (json['customFields'] as List?)
          ?.map((e) => CustomField.fromJson(e))
          .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'iconData': icon?.codePoint,
      'iconColor': iconColor?.value,
      'tags': tags,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'usageRecords': usageRecords.map((record) => record.toJson()).toList(),
      'customFields': customFields.map((field) => field.toJson()).toList(),
      'notes': notes,
    };
  }

  GoodsItem copyWith({
    String? title,
    String? imageUrl,
    IconData? icon,
    Color? iconColor,
    List<String>? tags,
    DateTime? purchaseDate,
    double? purchasePrice,
    List<UsageRecord>? usageRecords,
    List<CustomField>? customFields,
    String? notes,
  }) {
    return GoodsItem(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      tags: tags ?? List.from(this.tags),
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      usageRecords: usageRecords ?? List.from(this.usageRecords),
      customFields: customFields ?? List.from(this.customFields),
      notes: notes ?? this.notes,
    );
  }

  // 添加使用记录
  GoodsItem addUsageRecord(DateTime date, {String? note}) {
    final newRecords = List<UsageRecord>.from(usageRecords);
    newRecords.add(UsageRecord(date: date, note: note));
    return copyWith(usageRecords: newRecords);
  }
}