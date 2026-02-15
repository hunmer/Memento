import 'package:flutter/foundation.dart';
import 'package:Memento/core/storage/storage_manager.dart';

/// TTS 播报设置数据类
class TTSAnnouncementSettings {
  final bool isEnabled;
  final String? serviceId;
  final int unrecordedIntervalMinutes;
  final String textTemplate;
  final bool checkOnlyWorkHours;
  final int workHoursStart;
  final int workHoursEnd;
  final bool enableHapticFeedback;

  const TTSAnnouncementSettings({
    this.isEnabled = false,
    this.serviceId,
    this.unrecordedIntervalMinutes = 5,
    this.textTemplate = '已超过 {unrecorded_time} 分钟未记录活动',
    this.checkOnlyWorkHours = false,
    this.workHoursStart = 9,
    this.workHoursEnd = 18,
    this.enableHapticFeedback = true,
  });

  TTSAnnouncementSettings copyWith({
    bool? isEnabled,
    String? serviceId,
    int? unrecordedIntervalMinutes,
    String? textTemplate,
    bool? checkOnlyWorkHours,
    int? workHoursStart,
    int? workHoursEnd,
    bool? enableHapticFeedback,
  }) {
    return TTSAnnouncementSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      serviceId: serviceId ?? this.serviceId,
      unrecordedIntervalMinutes: unrecordedIntervalMinutes ?? this.unrecordedIntervalMinutes,
      textTemplate: textTemplate ?? this.textTemplate,
      checkOnlyWorkHours: checkOnlyWorkHours ?? this.checkOnlyWorkHours,
      workHoursStart: workHoursStart ?? this.workHoursStart,
      workHoursEnd: workHoursEnd ?? this.workHoursEnd,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'serviceId': serviceId,
      'unrecordedIntervalMinutes': unrecordedIntervalMinutes,
      'textTemplate': textTemplate,
      'checkOnlyWorkHours': checkOnlyWorkHours,
      'workHoursStart': workHoursStart,
      'workHoursEnd': workHoursEnd,
      'enableHapticFeedback': enableHapticFeedback,
    };
  }

  factory TTSAnnouncementSettings.fromJson(Map<String, dynamic> json) {
    return TTSAnnouncementSettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      serviceId: json['serviceId'] as String?,
      unrecordedIntervalMinutes: json['unrecordedIntervalMinutes'] as int? ?? 5,
      textTemplate: json['textTemplate'] as String? ?? '已超过 {unrecorded_time} 分钟未记录活动',
      checkOnlyWorkHours: json['checkOnlyWorkHours'] as bool? ?? false,
      workHoursStart: json['workHoursStart'] as int? ?? 9,
      workHoursEnd: json['workHoursEnd'] as int? ?? 18,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
    );
  }
}

/// TTS 播报设置管理器
class TTSAnnouncementSettingsManager {
  final StorageManager _storage;
  final String _settingsFileName;

  TTSAnnouncementSettingsManager({
    required StorageManager storage,
    String settingsFileName = 'activity/tts_announcement_settings.json',
  })  : _storage = storage,
        _settingsFileName = settingsFileName;

  /// 读取设置
  Future<TTSAnnouncementSettings> load() async {
    try {
      final json = await _storage.read(_settingsFileName);
      if (json.isEmpty) {
        return const TTSAnnouncementSettings();
      }
      return TTSAnnouncementSettings.fromJson(json);
    } catch (e) {
      debugPrint('[TTSAnnouncementSettings] 加载设置失败: $e');
      return const TTSAnnouncementSettings();
    }
  }

  /// 保存设置
  Future<void> save(TTSAnnouncementSettings settings) async {
    try {
      await _storage.write(_settingsFileName, settings.toJson());
    } catch (e) {
      debugPrint('[TTSAnnouncementSettings] 保存设置失败: $e');
      rethrow;
    }
  }

  /// 合并更新设置
  Future<TTSAnnouncementSettings> update({
    bool? isEnabled,
    String? serviceId,
    int? unrecordedIntervalMinutes,
    String? textTemplate,
    bool? checkOnlyWorkHours,
    int? workHoursStart,
    int? workHoursEnd,
    bool? enableHapticFeedback,
  }) async {
    final current = await load();
    final updated = current.copyWith(
      isEnabled: isEnabled,
      serviceId: serviceId,
      unrecordedIntervalMinutes: unrecordedIntervalMinutes,
      textTemplate: textTemplate,
      checkOnlyWorkHours: checkOnlyWorkHours,
      workHoursStart: workHoursStart,
      workHoursEnd: workHoursEnd,
      enableHapticFeedback: enableHapticFeedback,
    );
    await save(updated);
    return updated;
  }
}
