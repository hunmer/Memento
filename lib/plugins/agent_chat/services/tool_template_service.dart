import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/saved_tool_template.dart';
import '../models/tool_call_step.dart';
import '../../../core/storage/storage_manager.dart';

/// 工具模板服务
///
/// 管理保存的工具模板，包括保存、加载、删除等操作
class ToolTemplateService extends ChangeNotifier {
  static const String _storageKey = 'agent_chat_tool_templates';

  final StorageManager _storage;
  List<SavedToolTemplate> _templates = [];
  late final Future<void> _initialLoadFuture;

  ToolTemplateService(this._storage) {
    _initialLoadFuture = _loadTemplates();
  }

  /// 获取所有模板
  List<SavedToolTemplate> get templates => List.unmodifiable(_templates);

  /// 确保模板已加载
  Future<void> ensureInitialized() => _initialLoadFuture;

  /// 获取模板列表，可选关键词过滤
  Future<List<SavedToolTemplate>> fetchTemplates({String? query}) async {
    await ensureInitialized();
    if (query == null || query.trim().isEmpty) {
      return templates;
    }
    return searchTemplates(query.trim());
  }

  /// 克隆模板步骤，确保去除执行态字段
  List<ToolCallStep> cloneTemplateSteps(SavedToolTemplate template) {
    return _normalizeSteps(template.steps);
  }

  /// 加载模板
  Future<void> _loadTemplates() async {
    try {
      final data = await _storage.read(_storageKey);
      if (data != null && data is List) {
        _templates = data
            .map((e) => SavedToolTemplate.fromJson(e as Map<String, dynamic>))
            .map((template) => template.copyWith(
                  steps: _normalizeSteps(template.steps),
                ))
            .toList();

        // 按最后使用时间排序，未使用的按创建时间排序
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

        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载工具模板失败: $e');
    }
  }

  /// 保存模板列表到存储
  Future<void> _saveTemplates() async {
    try {
      final data = _templates
          .map(
            (t) => t.copyWith(
              steps: _normalizeSteps(t.steps),
            ),
          )
          .map((t) => t.toJson())
          .toList();
      await _storage.write(_storageKey, data);
    } catch (e) {
      debugPrint('保存工具模板失败: $e');
      rethrow;
    }
  }

  /// 创建新模板
  Future<SavedToolTemplate> createTemplate({
    required String name,
    String? description,
    required List<ToolCallStep> steps,
  }) async {
    // 检查名称是否已存在
    if (_templates.any((t) => t.name == name)) {
      throw Exception('模板名称已存在');
    }

    final template = SavedToolTemplate.create(
      name: name,
      description: description,
      steps: _normalizeSteps(steps),
    );

    _templates.insert(0, template);
    await _saveTemplates();
    notifyListeners();

    return template;
  }

  /// 更新模板
  Future<void> updateTemplate(SavedToolTemplate template) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw Exception('模板不存在');
    }

    _templates[index] = template;
    await _saveTemplates();
    notifyListeners();
  }

  /// 删除模板
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    await _saveTemplates();
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
    _templates[index] = template.markAsUsed();

    // 重新排序
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

    await _saveTemplates();
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
}
