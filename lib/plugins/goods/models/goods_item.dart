import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'usage_record.dart';
import 'custom_field.dart';

class GoodsItem {
  final String id;
  final String title;
  String? _imageUrl;
  final IconData? icon;

  // 获取图片URL，如果是相对路径则转换为绝对路径
  Future<String?> getImageUrl() async {
    if (_imageUrl == null) return null;
    if (_imageUrl!.startsWith('./goods_images/')) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/app_data/${_imageUrl!.substring(2)}';
    }
    return _imageUrl;
  }

  // 同步获取相对路径
  String? get imageUrl => _imageUrl;

  // 设置图片URL，如果是绝对路径则转换为相对路径
  set imageUrl(String? value) {
    if (value != null && value.contains('goods_images/')) {
      // 提取goods_images/之后的部分作为相对路径
      _imageUrl = './goods_images/${value.split('goods_images/').last}';
    } else {
      _imageUrl = value;
    }
  }

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
    String? imageUrl,
    this.icon,
    this.iconColor,
    List<String>? tags,
    this.purchaseDate,
    this.purchasePrice,
    List<UsageRecord>? usageRecords,
    List<CustomField>? customFields,
    this.notes,
  }) : tags = tags ?? [],
       usageRecords = usageRecords ?? [],
       customFields = customFields ?? [] {
    this.imageUrl = imageUrl; // 使用setter来设置图片路径
  }

  DateTime? get lastUsedDate {
    if (usageRecords.isEmpty) return null;
    return usageRecords
        .reduce(
          (value, element) =>
              value.date.isAfter(element.date) ? value : element,
        )
        .date;
  }

  factory GoodsItem.fromJson(Map<String, dynamic> json) {
    return GoodsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?, // 通过setter设置
      icon:
          json['iconData'] != null
              ? IconData(json['iconData'] as int, fontFamily: 'MaterialIcons')
              : null,
      iconColor:
          json['iconColor'] != null ? Color(json['iconColor'] as int) : null,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      purchaseDate:
          json['purchaseDate'] != null
              ? DateTime.parse(json['purchaseDate'] as String)
              : null,
      purchasePrice: json['purchasePrice'] as double?,
      usageRecords:
          (json['usageRecords'] as List?)
              ?.map((e) => UsageRecord.fromJson(e))
              .toList() ??
          [],
      customFields:
          (json['customFields'] as List?)
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
      'imageUrl': _imageUrl, // 保存相对路径
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
      imageUrl: imageUrl ?? this._imageUrl, // 使用原始存储的相对路径
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
