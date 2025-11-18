import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'usage_record.dart';
import 'custom_field.dart';
import 'path_constants.dart';

class GoodsItem {
  final String id;
  final String title;
  String? _imageUrl;
  String? _thumbUrl;
  final IconData? icon;

  // 获取图片URL，如果是相对路径则转换为绝对路径
  Future<String?> getImageUrl() async {
    if (_imageUrl == null || _imageUrl == "") return null;
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    // 使用清理路径方法确保没有多余斜杠
    return GoodsPathConstants.cleanPath(
      GoodsPathConstants.toAbsolutePath(appDir.path, _imageUrl),
    );
  }

  // 获取缩略图URL，如果是相对路径则转换为绝对路径
  Future<String?> getThumbUrl() async {
    if (_thumbUrl == null || _thumbUrl == "") return null;
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    return GoodsPathConstants.cleanPath(
      GoodsPathConstants.toAbsolutePath(appDir.path, _thumbUrl),
    );
  }

  // 同步获取相对路径
  String? get imageUrl => _imageUrl;
  String? get thumbUrl => _thumbUrl;

  // 设置图片URL，如果是绝对路径则转换为相对路径
  set imageUrl(String? value) {
    _imageUrl = value == "" ? "" : GoodsPathConstants.toRelativePath(value);
  }

  // 设置缩略图URL，如果是绝对路径则转换为相对路径
  set thumbUrl(String? value) {
    _thumbUrl = value == "" ? "" : GoodsPathConstants.toRelativePath(value);
  }

  final Color? iconColor;
  final List<String> tags;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final List<UsageRecord> usageRecords;
  final List<CustomField> customFields;
  final String? notes;
  final List<GoodsItem> subItems;

  // 计算总价格（包含子物品）
  double? get totalPrice {
    if (purchasePrice == null) return null;
    double total = purchasePrice!;
    for (var subItem in subItems) {
      if (subItem.totalPrice != null) {
        total += subItem.totalPrice!;
      }
    }
    return total;
  }

  GoodsItem({
    required this.id,
    required this.title,
    String? imageUrl,
    String? thumbUrl,
    this.icon,
    this.iconColor,
    List<String>? tags,
    this.purchaseDate,
    this.purchasePrice,
    List<UsageRecord>? usageRecords,
    List<CustomField>? customFields,
    this.notes,
    List<GoodsItem>? subItems,
  }) : tags = tags ?? [],
       usageRecords = usageRecords ?? [],
       customFields = customFields ?? [],
       subItems = subItems ?? [] {
    this.imageUrl = imageUrl; // 使用setter来设置图片路径
    this.thumbUrl = thumbUrl; // 使用setter来设置缩略图路径
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
      thumbUrl: json['thumbUrl'] as String?, // 通过setter设置
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
      purchasePrice: json['purchasePrice'] != null ? (json['purchasePrice'] as num)?.toDouble() : null,
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
      subItems:
          (json['subItems'] as List?)
              ?.map((e) => GoodsItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': _imageUrl, // 已经是相对路径
      'thumbUrl': _thumbUrl, // 已经是相对路径
      'iconData': icon?.codePoint,
      'iconColor': iconColor?.value,
      'tags': tags,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'usageRecords': usageRecords.map((record) => record.toJson()).toList(),
      'customFields': customFields.map((field) => field.toJson()).toList(),
      'notes': notes,
      'subItems': subItems.map((item) => item.toJson()).toList(),
    };
  }

  GoodsItem copyWith({
    String? title,
    String? imageUrl,
    String? thumbUrl,
    IconData? icon,
    Color? iconColor,
    List<String>? tags,
    DateTime? purchaseDate,
    double? purchasePrice,
    List<UsageRecord>? usageRecords,
    List<CustomField>? customFields,
    String? notes,
    List<GoodsItem>? subItems,
  }) {
    return GoodsItem(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? _imageUrl, // 使用已存储的相对路径
      thumbUrl: thumbUrl ?? _thumbUrl, // 使用已存储的相对路径
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      tags: tags ?? List.from(this.tags),
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      usageRecords: usageRecords ?? List.from(this.usageRecords),
      customFields: customFields ?? List.from(this.customFields),
      notes: notes ?? this.notes,
      subItems: subItems ?? List.from(this.subItems),
    );
  }

  // 添加使用记录
  GoodsItem addUsageRecord(DateTime date, {String? note}) {
    final newRecords = List<UsageRecord>.from(usageRecords);
    newRecords.add(UsageRecord(date: date, note: note));
    return copyWith(usageRecords: newRecords);
  }
}
