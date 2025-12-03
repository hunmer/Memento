/// 动作存储管理
/// 负责动作配置的持久化存储
library action_storage;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'models/action_definition.dart';
import 'models/action_instance.dart';
import 'models/action_group.dart';
import 'action_manager.dart';

/// 存储配置版本
const String STORAGE_VERSION = '1.0';

/// 动作存储配置文件名
const String CONFIG_FILE_NAME = 'floating_ball_config_v1.json';

/// 动作存储管理类
class ActionStorage {
  // 单例
  static final ActionStorage _instance = ActionStorage._internal();
  factory ActionStorage() => _instance;
  ActionStorage._internal();

  // 存储目录路径
  String? _storageDir;

  /// 初始化存储
  Future<void> initialize({String? storageDir}) async {
    _storageDir = storageDir ?? await _getDefaultStorageDir();

    // 确保目录存在
    final dir = Directory(_storageDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 获取默认存储目录
  Future<String> _getDefaultStorageDir() async {
    // TODO: 从 storage_manager 获取存储目录
    // 或者使用应用数据目录
    // return '${AppPaths.storage}/action';

    // 临时实现
    return 'storage';
  }

  /// 获取配置文件路径
  String get configFilePath {
    if (_storageDir == null) {
      throw StateError('Storage not initialized. Call initialize() first.');
    }
    return '$_storageDir/$CONFIG_FILE_NAME';
  }

  /// 加载配置
  Future<ActionStorageData> loadConfig() async {
    final file = File(configFilePath);

    if (!await file.exists()) {
      // 文件不存在，返回空配置
      return ActionStorageData(
        version: STORAGE_VERSION,
        lastModified: DateTime.now(),
        gestureActions: {},
        customActions: {},
        actionGroups: {},
        settings: {},
      );
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // 解析手势动作
      final gestureActions = <FloatingBallGesture, GestureActionConfig>{};
      final gestureJson = json['gestureActions'] as Map<String, dynamic>?;
      if (gestureJson != null) {
        gestureJson.forEach((key, value) {
          final gesture = FloatingBallGesture.values.firstWhere(
            (g) => g.name == key,
            orElse: () => FloatingBallGesture.tap,
          );
          gestureActions[gesture] = GestureActionConfig.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析自定义动作实例
      final customActions = <String, ActionInstance>{};
      final customActionsJson = json['customActions'] as Map<String, dynamic>?;
      if (customActionsJson != null) {
        customActionsJson.forEach((key, value) {
          customActions[key] = ActionInstance.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析动作组
      final actionGroups = <String, ActionGroup>{};
      final actionGroupsJson = json['actionGroups'] as Map<String, dynamic>?;
      if (actionGroupsJson != null) {
        actionGroupsJson.forEach((key, value) {
          actionGroups[key] = ActionGroup.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析设置
      final settings = json['settings'] as Map<String, dynamic>? ?? {};

      return ActionStorageData(
        version: json['version'] as String? ?? STORAGE_VERSION,
        lastModified: DateTime.parse(json['lastModified'] as String),
        gestureActions: gestureActions,
        customActions: customActions,
        actionGroups: actionGroups,
        settings: settings,
      );
    } catch (e) {
      debugPrint('Failed to load config: $e');
      // 出错时返回空配置
      return ActionStorageData(
        version: STORAGE_VERSION,
        lastModified: DateTime.now(),
        gestureActions: {},
        customActions: {},
        actionGroups: {},
        settings: {},
      );
    }
  }

  /// 保存配置
  Future<void> saveConfig(ActionStorageData data) async {
    final file = File(configFilePath);

    final json = {
      'version': data.version,
      'lastModified': data.lastModified.toIso8601String(),
      'gestureActions': data.gestureActions.map(
        (gesture, config) => MapEntry(gesture.name, config.toJson()),
      ),
      'customActions': data.customActions.map(
        (id, instance) => MapEntry(id, instance.toJson()),
      ),
      'actionGroups': data.actionGroups.map(
        (id, group) => MapEntry(id, group.toJson()),
      ),
      'settings': data.settings,
    };

    final jsonString = JsonEncoder.withIndent('  ').convert(json);

    await file.writeAsString(jsonString);
  }

  /// 备份配置
  Future<String> backupConfig() async {
    final file = File(configFilePath);
    if (!await file.exists()) {
      throw StateError('Config file does not exist');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFileName = 'floating_ball_config_v1_backup_$timestamp.json';
    final backupPath = '$_storageDir/$backupFileName';

    await file.copy(backupPath);

    return backupPath;
  }

  /// 恢复配置
  Future<void> restoreConfig(String backupPath) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw StateError('Backup file does not exist: $backupPath');
    }

    // 备份当前配置
    final currentBackup = await backupConfig();

    try {
      // 恢复配置
      await backupFile.copy(configFilePath);
    } catch (e) {
      // 恢复失败，恢复备份
      await File(currentBackup).copy(configFilePath);
      rethrow;
    }
  }

  /// 导出配置为 JSON 字符串
  Future<String> exportConfigAsJson() async {
    final data = await loadConfig();

    final exportData = {
      'exportVersion': STORAGE_VERSION,
      'exportTime': DateTime.now().toIso8601String(),
      'data': {
        'version': data.version,
        'gestureActions': data.gestureActions.map(
          (gesture, config) => MapEntry(gesture.name, config.toJson()),
        ),
        'customActions': data.customActions.map(
          (id, instance) => MapEntry(id, instance.toJson()),
        ),
        'actionGroups': data.actionGroups.map(
          (id, group) => MapEntry(id, group.toJson()),
        ),
        'settings': data.settings,
      },
    };

    return JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从 JSON 字符串导入配置
  Future<void> importConfigFromJson(String jsonString) async {
    // 备份当前配置
    final backup = await backupConfig();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final dataJson = json['data'] as Map<String, dynamic>? ?? json;

      // 解析手势动作
      final gestureActions = <FloatingBallGesture, GestureActionConfig>{};
      final gestureJson = dataJson['gestureActions'] as Map<String, dynamic>?;
      if (gestureJson != null) {
        gestureJson.forEach((key, value) {
          final gesture = FloatingBallGesture.values.firstWhere(
            (g) => g.name == key,
            orElse: () => FloatingBallGesture.tap,
          );
          gestureActions[gesture] = GestureActionConfig.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析自定义动作实例
      final customActions = <String, ActionInstance>{};
      final customActionsJson = dataJson['customActions'] as Map<String, dynamic>?;
      if (customActionsJson != null) {
        customActionsJson.forEach((key, value) {
          customActions[key] = ActionInstance.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析动作组
      final actionGroups = <String, ActionGroup>{};
      final actionGroupsJson = dataJson['actionGroups'] as Map<String, dynamic>?;
      if (actionGroupsJson != null) {
        actionGroupsJson.forEach((key, value) {
          actionGroups[key] = ActionGroup.fromJson(
            value as Map<String, dynamic>,
          );
        });
      }

      // 解析设置
      final settings = dataJson['settings'] as Map<String, dynamic>? ?? {};

      final data = ActionStorageData(
        version: dataJson['version'] as String? ?? STORAGE_VERSION,
        lastModified: DateTime.now(),
        gestureActions: gestureActions,
        customActions: customActions,
        actionGroups: actionGroups,
        settings: settings,
      );

      await saveConfig(data);
    } catch (e) {
      // 导入失败，恢复备份
      await restoreConfig(backup);
      rethrow;
    }
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    final file = File(configFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取配置信息
  Future<ConfigInfo> getConfigInfo() async {
    final file = File(configFilePath);

    if (!await file.exists()) {
      return ConfigInfo(
        exists: false,
        size: 0,
        lastModified: null,
      );
    }

    final stat = await file.stat();
    return ConfigInfo(
      exists: true,
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  /// 列出所有备份文件
  Future<List<BackupFileInfo>> listBackups() async {
    final dir = Directory(_storageDir!);
    if (!await dir.exists()) return [];

    final files = await dir.list().toList();
    final backups = <BackupFileInfo>[];

    for (final file in files) {
      if (file is File && file.path.contains('backup')) {
        final stat = await file.stat();
        backups.add(BackupFileInfo(
          path: file.path,
          name: file.uri.pathSegments.last,
          size: stat.size,
          createdAt: stat.modified,
        ));
      }
    }

    // 按创建时间排序
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return backups;
  }

  /// 清理旧备份（保留最新 N 个）
  Future<void> cleanOldBackups({int keepCount = 5}) async {
    final backups = await listBackups();

    if (backups.length <= keepCount) return;

    // 删除多余的备份
    for (int i = keepCount; i < backups.length; i++) {
      await File(backups[i].path).delete();
    }
  }

  /// 验证配置文件
  Future<ConfigValidationResult> validateConfig() async {
    final file = File(configFilePath);

    if (!await file.exists()) {
      return ConfigValidationResult(
        isValid: false,
        errors: ['Config file does not exist'],
        warnings: [],
      );
    }

    final errors = <String>[];
    final warnings = <String>[];

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // 检查版本
      final version = json['version'] as String?;
      if (version == null) {
        errors.add('Missing version field');
      } else if (version != STORAGE_VERSION) {
        warnings.add('Version mismatch: expected $STORAGE_VERSION, got $version');
      }

      // 检查必需字段
      final requiredFields = ['version', 'lastModified'];
      for (final field in requiredFields) {
        if (!json.containsKey(field)) {
          errors.add('Missing required field: $field');
        }
      }

      // 检查手势动作格式
      final gestureJson = json['gestureActions'] as Map<String, dynamic>?;
      if (gestureJson != null) {
        for (final entry in gestureJson.entries) {
          final gestureName = entry.key;
          final config = entry.value as Map<String, dynamic>?;

          if (config == null) {
            errors.add('Invalid gesture config for $gestureName');
            continue;
          }

          final gesture = FloatingBallGesture.values
              .firstWhere(
                (g) => g.name == gestureName,
                orElse: () => FloatingBallGesture.tap,
              );

          // 验证配置结构
          try {
            GestureActionConfig.fromJson(config);
          } catch (e) {
            errors.add('Invalid gesture config for $gestureName: $e');
          }
        }
      }

      // 检查自定义动作实例格式
      final customActionsJson = json['customActions'] as Map<String, dynamic>?;
      if (customActionsJson != null) {
        for (final entry in customActionsJson.entries) {
          final id = entry.key;
          final instanceJson = entry.value as Map<String, dynamic>?;

          if (instanceJson == null) {
            errors.add('Invalid custom action instance: $id');
            continue;
          }

          try {
            ActionInstance.fromJson(instanceJson);
          } catch (e) {
            errors.add('Invalid custom action instance $id: $e');
          }
        }
      }

      // 检查动作组格式
      final actionGroupsJson = json['actionGroups'] as Map<String, dynamic>?;
      if (actionGroupsJson != null) {
        for (final entry in actionGroupsJson.entries) {
          final id = entry.key;
          final groupJson = entry.value as Map<String, dynamic>?;

          if (groupJson == null) {
            errors.add('Invalid action group: $id');
            continue;
          }

          try {
            ActionGroup.fromJson(groupJson);
          } catch (e) {
            errors.add('Invalid action group $id: $e');
          }
        }
      }

      return ConfigValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      return ConfigValidationResult(
        isValid: false,
        errors: ['Failed to parse config: $e'],
        warnings: [],
      );
    }
  }
}

/// 存储数据类
class ActionStorageData {
  final String version;
  final DateTime lastModified;
  final Map<FloatingBallGesture, GestureActionConfig> gestureActions;
  final Map<String, ActionInstance> customActions;
  final Map<String, ActionGroup> actionGroups;
  final Map<String, dynamic> settings;

  ActionStorageData({
    required this.version,
    required this.lastModified,
    required this.gestureActions,
    required this.customActions,
    required this.actionGroups,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastModified': lastModified.toIso8601String(),
      'gestureActions': gestureActions.map(
        (gesture, config) => MapEntry(gesture.name, config.toJson()),
      ),
      'customActions': customActions.map(
        (id, instance) => MapEntry(id, instance.toJson()),
      ),
      'actionGroups': actionGroups.map(
        (id, group) => MapEntry(id, group.toJson()),
      ),
      'settings': settings,
    };
  }
}

/// 配置信息
class ConfigInfo {
  final bool exists;
  final int size;
  final DateTime? lastModified;

  const ConfigInfo({
    required this.exists,
    required this.size,
    this.lastModified,
  });
}

/// 备份文件信息
class BackupFileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  const BackupFileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });
}

/// 配置验证结果
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ConfigValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}
