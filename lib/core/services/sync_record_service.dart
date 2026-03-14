import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/storage_manager.dart';

/// 同步记录
class SyncRecord {
  /// 最后上传时间（客户端成功推送的时间）
  final DateTime? lastUploadTime;

  /// 服务端最后修改时间
  final DateTime? serverModifiedTime;

  SyncRecord({this.lastUploadTime, this.serverModifiedTime});

  factory SyncRecord.fromJson(Map<String, dynamic> json) {
    return SyncRecord(
      lastUploadTime: json['last_upload_time'] != null
          ? DateTime.parse(json['last_upload_time'] as String)
          : null,
      serverModifiedTime: json['server_modified_time'] != null
          ? DateTime.parse(json['server_modified_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_upload_time': lastUploadTime?.toUtc().toIso8601String(),
      'server_modified_time': serverModifiedTime?.toUtc().toIso8601String(),
    };
  }

  SyncRecord copyWith({
    DateTime? lastUploadTime,
    DateTime? serverModifiedTime,
  }) {
    return SyncRecord(
      lastUploadTime: lastUploadTime ?? this.lastUploadTime,
      serverModifiedTime: serverModifiedTime ?? this.serverModifiedTime,
    );
  }
}

/// 同步记录服务
///
/// 负责管理文件同步记录，用于双向同步判断
class SyncRecordService {
  static final SyncRecordService _instance = SyncRecordService._internal();
  factory SyncRecordService() => _instance;
  SyncRecordService._internal();

  static const String _tag = 'SyncRecordService';

  /// 记录文件路径
  static const String _recordFilePath = 'configs/sync_records.json';

  /// 内存中的记录缓存
  final Map<String, SyncRecord> _records = {};

  /// 是否已加载
  bool _loaded = false;

  /// 存储管理器
  StorageManager? _storage;

  /// 最近上传的文件（用于防循环更新）
  final Map<String, DateTime> _recentUploads = {};

  /// 初始化服务
  Future<void> initialize(StorageManager storage) async {
    if (_loaded) return;

    _storage = storage;
    await _load();
    _log('初始化完成，已加载 ${_records.length} 条记录');
  }

  /// 从存储加载记录
  Future<void> _load() async {
    if (_storage == null) {
      _log('存储管理器未设置，跳过加载');
      return;
    }

    try {
      final content = await _storage!.readString(_recordFilePath);
      if (content == null || content.isEmpty) {
        _log('记录文件不存在，使用空记录');
        _loaded = true;
        return;
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final version = json['version'] as int? ?? 1;
      final records = json['records'] as Map<String, dynamic>?;

      if (records != null) {
        records.forEach((key, value) {
          _records[key] = SyncRecord.fromJson(value as Map<String, dynamic>);
        });
      }

      _loaded = true;
      _log('加载完成，版本: $version，记录数: ${_records.length}');
    } catch (e) {
      _log('加载记录失败: $e');
      _loaded = true; // 即使失败也标记为已加载，避免重复加载
    }
  }

  /// 保存记录到存储
  Future<void> _save() async {
    if (_storage == null) {
      _log('存储管理器未设置，跳过保存');
      return;
    }

    try {
      final json = {
        'version': 1,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
        'records': _records.map((key, value) => MapEntry(key, value.toJson())),
      };

      await _storage!.writeString(_recordFilePath, jsonEncode(json));
      _log('保存完成，记录数: ${_records.length}');
    } catch (e) {
      _log('保存记录失败: $e');
    }
  }

  /// 记录推送成功
  ///
  /// [filePath] 文件路径
  /// [serverTime] 服务端返回的修改时间
  Future<void> recordUpload(String filePath, DateTime serverTime) async {
    final record = _records[filePath];
    _records[filePath] = (record ?? SyncRecord()).copyWith(
      lastUploadTime: DateTime.now(),
      serverModifiedTime: serverTime,
    );

    // 记录最近上传，用于防循环
    _recentUploads[filePath] = DateTime.now();
    _cleanRecentUploads();

    await _save();
    _log('记录上传: $filePath, 服务端时间: $serverTime');
  }

  /// 记录拉取成功
  ///
  /// [filePath] 文件路径
  /// [serverTime] 服务端返回的修改时间
  Future<void> recordPull(String filePath, DateTime serverTime) async {
    final record = _records[filePath];
    _records[filePath] = (record ?? SyncRecord()).copyWith(
      serverModifiedTime: serverTime,
    );

    await _save();
    _log('记录拉取: $filePath, 服务端时间: $serverTime');
  }

  /// 判断是否需要从服务端拉取
  ///
  /// 返回 true 表示服务端有更新，需要拉取
  bool needsPull(String filePath, DateTime serverModifiedTime) {
    final record = _records[filePath];

    if (record == null) {
      // 从未同步过，需要拉取
      _log('需要拉取 (无记录): $filePath');
      return true;
    }

    // 如果最近上传过，跳过（防循环）
    if (wasRecentlyUploaded(filePath)) {
      _log('跳过拉取 (最近上传): $filePath');
      return false;
    }

    // 比较服务端修改时间和最后上传时间
    final lastUploadTime = record.lastUploadTime;
    if (lastUploadTime == null) {
      _log('需要拉取 (无上传记录): $filePath');
      return true;
    }

    final needsPull = serverModifiedTime.isAfter(lastUploadTime);
    _log(
      '判断拉取: $filePath, 服务端: $serverModifiedTime, 上传: $lastUploadTime, 结果: $needsPull',
    );
    return needsPull;
  }

  /// 获取文件的同步记录
  SyncRecord? getRecord(String filePath) {
    return _records[filePath];
  }

  /// 检查文件是否最近上传过（5秒内）
  bool wasRecentlyUploaded(String filePath) {
    final uploadTime = _recentUploads[filePath];
    if (uploadTime == null) return false;

    final elapsed = DateTime.now().difference(uploadTime);
    return elapsed < const Duration(seconds: 5);
  }

  /// 标记文件为最近上传（用于防循环更新）
  void markRecentUpload(String filePath) {
    _recentUploads[filePath] = DateTime.now();
    _cleanRecentUploads();
  }

  /// 清理过期的最近上传记录
  void _cleanRecentUploads() {
    final now = DateTime.now();
    _recentUploads.removeWhere((key, time) {
      return now.difference(time) > const Duration(seconds: 10);
    });
  }

  /// 获取所有记录
  Map<String, SyncRecord> get allRecords => Map.unmodifiable(_records);

  /// 清除所有记录
  Future<void> clear() async {
    _records.clear();
    _recentUploads.clear();
    await _save();
    _log('已清除所有记录');
  }

  /// 删除单个文件记录
  Future<void> removeRecord(String filePath) async {
    _records.remove(filePath);
    await _save();
    _log('已删除记录: $filePath');
  }

  /// 输出日志
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag: $message');
    }
  }

  /// 获取记录数量
  int get recordCount => _records.length;

  /// 是否已初始化
  bool get isInitialized => _loaded;
}
