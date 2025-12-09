import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:Memento/plugins/agent_chat/models/saved_tool_template.dart';
import 'package:Memento/plugins/agent_chat/models/tool_call_step.dart';
import 'package:Memento/core/storage/storage_manager.dart';

/// 工具模板服务
///
/// 管理保存的工具模板，包括保存、加载、删除等操作
/// 每个模板存储为独立的 JSON 文件
class ToolTemplateService extends ChangeNotifier {
  /// 旧存储键（用于迁移）
  static const String _oldStorageKey = 'agent_chat_tool_templates';

  /// 模板存储目录
  static const String _templatesDir = 'agent_chat/tool_templates';

  /// 默认模板 assets 路径
  static const String _defaultTemplatesAssetPath = 'assets/tool_templates';

  /// 默认模板文件列表
  static const List<String> _defaultTemplateFiles = [
    'todo',
    'notes',
    'tracker',
    'store',
    'timer',
    'chat',
    'diary',
    'activity',
    'checkin',
    'bill',
    'calendar',
    'calendar_album',
    'contact',
    'database',
    'day',
    'goods',
    'habits',
    'nodes',
  ];

  final StorageManager _storage;
  List<SavedToolTemplate> _templates = [];
  late final Future<void> _initialLoadFuture;

  ToolTemplateService(this._storage) {
    _initialLoadFuture = _initialize();
  }

  /// 初始化服务
  Future<void> _initialize() async {
    await _storage.createDirectory(_templatesDir);
    await _migrateOldFormat();
    await _loadTemplates();
    await _ensureDefaultTemplates();
  }

  /// 获取所有模板
  List<SavedToolTemplate> get templates => List.unmodifiable(_templates);

  /// 确保模板已加载
  Future<void> ensureInitialized() => _initialLoadFuture;

  /// 获取模板列表，可选关键词和标签过滤
  Future<List<SavedToolTemplate>> fetchTemplates({
    String? query,
    String? tag,
  }) async {
    await ensureInitialized();
    if (query == null || query.trim().isEmpty) {
      if (tag == null || tag.trim().isEmpty) {
        return templates;
      }
      return filterByTag(tag.trim());
    }
    var result = searchTemplates(query.trim());
    if (tag != null && tag.trim().isNotEmpty) {
      result = result.where((t) => t.tags.contains(tag.trim())).toList();
    }
    return result;
  }

  /// 克隆模板步骤，确保去除执行态字段
  List<ToolCallStep> cloneTemplateSteps(SavedToolTemplate template) {
    return _normalizeSteps(template.steps);
  }

  /// 迁移旧格式数据到新格式
  Future<void> _migrateOldFormat() async {
    try {
      final oldData = await _storage.read(_oldStorageKey);
      if (oldData != null && oldData is List && oldData.isNotEmpty) {
        debugPrint('检测到旧格式工具模板，开始迁移...');

        for (final item in oldData) {
          try {
            final template = SavedToolTemplate.fromJson(
              item as Map<String, dynamic>,
            );
            final normalizedTemplate = template.copyWith(
              steps: _normalizeSteps(template.steps),
            );
            await _saveTemplateFile(normalizedTemplate);
          } catch (e) {
            debugPrint('迁移模板失败: $e');
          }
        }

        // 删除旧数据
        await _storage.delete(_oldStorageKey);
        debugPrint('工具模板迁移完成，已删除旧数据');
      }
    } catch (e) {
      debugPrint('迁移旧格式失败: $e');
    }
  }

  /// 确保默认模板存在
  Future<void> _ensureDefaultTemplates() async {
    for (final fileName in _defaultTemplateFiles) {
      try {
        final assetPath = '$_defaultTemplatesAssetPath/$fileName.json';
        final jsonString = await rootBundle.loadString(assetPath);
        final List<dynamic> jsonList = json.decode(jsonString);

        for (final jsonData in jsonList) {
          final template = SavedToolTemplate.fromJson(
            jsonData as Map<String, dynamic>,
          );

          // 只有在模板不存在时才添加
          if (!_templates.any((t) => t.id == template.id)) {
            final normalizedTemplate = template.copyWith(
              steps: _normalizeSteps(template.steps),
            );
            await _saveTemplateFile(normalizedTemplate);
            _templates.add(normalizedTemplate);
          }
        }
      } catch (e) {
        debugPrint('加载默认模板失败 ($fileName): $e');
      }
    }
    _sortTemplates();
    notifyListeners();
  }

  /// 从 assets 加载所有默认模板
  Future<List<SavedToolTemplate>> _loadDefaultTemplatesFromAssets() async {
    final List<SavedToolTemplate> templates = [];

    for (final fileName in _defaultTemplateFiles) {
      try {
        final assetPath = '$_defaultTemplatesAssetPath/$fileName.json';
        final jsonString = await rootBundle.loadString(assetPath);
        final List<dynamic> jsonList = json.decode(jsonString);

        for (final jsonData in jsonList) {
          final template = SavedToolTemplate.fromJson(
            jsonData as Map<String, dynamic>,
          );
          templates.add(template.copyWith(
            steps: _normalizeSteps(template.steps),
          ));
        }
      } catch (e) {
        debugPrint('加载默认模板失败 ($fileName): $e');
      }
    }

    return templates;
  }

  /// 恢复默认模板
  Future<void> restoreDefaultTemplates() async {
    final defaults = await _loadDefaultTemplatesFromAssets();
    for (final template in defaults) {
      await _saveTemplateFile(template);
      _templates.removeWhere((t) => t.id == template.id);
      _templates.add(template);
    }
    _sortTemplates();
    notifyListeners();
  }

  /// 加载所有模板
  Future<void> _loadTemplates() async {
    try {
      // 获取所有模板文件
      final keys = await _storage.getKeysWithPrefix(_templatesDir);

      _templates = [];
      for (final key in keys) {
        if (!key.endsWith('.json')) continue;

        try {
          final data = await _storage.readJson(key);
          if (data != null && data is Map<String, dynamic>) {
            final template = SavedToolTemplate.fromJson(data);
            _templates.add(
              template.copyWith(steps: _normalizeSteps(template.steps)),
            );
          }
        } catch (e) {
          debugPrint('加载模板失败 ($key): $e');
        }
      }

      _sortTemplates();
      notifyListeners();
    } catch (e) {
      debugPrint('加载工具模板失败: $e');
    }
  }

  /// 排序模板列表
  void _sortTemplates() {
    _templates.sort((a, b) {
      if (a.lastUsedAt != null && b.lastUsedAt != null) {
        return b.lastUsedAt!.compareTo(a.lastUsedAt!);
      } else if (a.lastUsedAt != null) {
        return -1;
      } else if (b.lastUsedAt != null) {
        return 1;
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });
  }

  /// 获取模板文件路径
  String _getTemplatePath(String id) => '$_templatesDir/$id.json';

  /// 保存单个模板文件
  Future<void> _saveTemplateFile(SavedToolTemplate template) async {
    try {
      final normalizedTemplate = template.copyWith(
        steps: _normalizeSteps(template.steps),
      );
      await _storage.writeJson(
        _getTemplatePath(template.id),
        normalizedTemplate.toJson(),
      );
    } catch (e) {
      debugPrint('保存工具模板失败: $e');
      rethrow;
    }
  }

  /// 删除模板文件
  Future<void> _deleteTemplateFile(String id) async {
    try {
      await _storage.deleteFile(_getTemplatePath(id));
    } catch (e) {
      debugPrint('删除工具模板文件失败: $e');
    }
  }

  /// 创建新模板
  Future<SavedToolTemplate> createTemplate({
    required String name,
    String? description,
    required List<ToolCallStep> steps,
    List<Map<String, String>>? declaredTools,
    List<String>? tags,
  }) async {
    // 检查名称是否已存在
    if (_templates.any((t) => t.name == name)) {
      throw Exception('模板名称已存在');
    }

    final template = SavedToolTemplate.create(
      name: name,
      description: description,
      steps: _normalizeSteps(steps),
      declaredTools: declaredTools,
      tags: tags,
    );

    _templates.insert(0, template);
    await _saveTemplateFile(template);
    notifyListeners();

    return template;
  }

  /// 更新模板
  Future<void> updateTemplate(SavedToolTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw Exception('模板不存在');
    }

    final updatedTemplate = template.copyWith(
      steps: _normalizeSteps(template.steps),
    );
    _templates[index] = updatedTemplate;
    await _saveTemplateFile(updatedTemplate);
    notifyListeners();
  }

  /// 删除模板
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _deleteTemplateFile(id);
    notifyListeners();
  }

  /// 根据名称获取模板
  SavedToolTemplate? getTemplateByName(String name) {
    try {
      return _templates.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据ID获取模板
  SavedToolTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 标记模板为已使用
  Future<void> markTemplateAsUsed(String id) async {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final template = _templates[index];
    final updatedTemplate = template.markAsUsed();
    _templates[index] = updatedTemplate;

    // 重新排序
    _sortTemplates();

    await _saveTemplateFile(updatedTemplate);
    notifyListeners();
  }

  /// 搜索模板
  List<SavedToolTemplate> searchTemplates(String query) {
    if (query.isEmpty) return templates;

    final lowerQuery = query.toLowerCase();
    return _templates.where((t) {
      return t.name.toLowerCase().contains(lowerQuery) ||
          (t.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 根据标签过滤模板
  List<SavedToolTemplate> filterByTag(String tag) {
    return _templates.where((t) => t.tags.contains(tag)).toList();
  }

  /// 获取所有标签（去重排序）
  List<String> getAllTags() {
    final allTags = <String>{};
    for (var template in _templates) {
      allTags.addAll(template.tags);
    }
    final sortedTags = allTags.toList()..sort();
    return sortedTags;
  }

  List<ToolCallStep> _normalizeSteps(List<ToolCallStep> steps) {
    return steps
        .map((step) => step.withoutRuntimeState())
        .toList(growable: false);
  }
}
