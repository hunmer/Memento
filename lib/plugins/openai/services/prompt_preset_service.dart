import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';
import 'package:Memento/plugins/openai/models/prompt_preset.dart';
import 'package:Memento/plugins/openai/sample_data.dart';

/// Prompt 预设管理服务
/// 提供 CRUD 操作和预设获取功能
class PromptPresetService extends ChangeNotifier {
  static final PromptPresetService _instance = PromptPresetService._internal();
  factory PromptPresetService() => _instance;
  PromptPresetService._internal();

  List<PromptPreset> _presets = [];
  List<PromptPreset> get presets => List.unmodifiable(_presets);

  static const String _storageKey = 'openai/prompt_presets.json';

  /// 预设类别映射
  static const Map<String, String> categoryNames = {
    'communication': '通用对话',
    'analysis': '数据分析',
    'creative': '创意写作',
    'technical': '技术编程',
    'education': '学习教育',
    'lifestyle': '健康生活',
    'travel': '旅行规划',
    'support': '心理支持',
  };

  /// 加载所有预设
  Future<List<PromptPreset>> loadPresets() async {
    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      final data = await plugin.storage.read(_storageKey);

      if (data.isNotEmpty && data['presets'] != null) {
        _presets = (data['presets'] as List)
            .map((json) => PromptPreset.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _presets = [];
      }

      notifyListeners();
      return _presets;
    } catch (e) {
      debugPrint('Error loading prompt presets: $e');
      _presets = [];
      return _presets;
    }
  }

  /// 保存所有预设
  Future<void> _savePresets() async {
    try {
      final plugin = PluginManager.instance.getPlugin('openai') as OpenAIPlugin;
      await plugin.storage.write(_storageKey, {
        'presets': _presets.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('Error saving prompt presets: $e');
      rethrow;
    }
  }

  /// 添加预设
  Future<void> addPreset(PromptPreset preset) async {
    _presets.add(preset);
    await _savePresets();
    notifyListeners();
  }

  /// 更新预设
  Future<void> updatePreset(PromptPreset preset) async {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _presets[index] = preset;
      await _savePresets();
      notifyListeners();
    }
  }

  /// 删除预设
  Future<void> deletePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _savePresets();
    notifyListeners();
  }

  /// 根据 ID 获取预设
  PromptPreset? getPresetById(String id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据 ID 获取预设的 prompt 内容
  /// 如果找不到预设，返回 null
  Future<String?> getPresetContent(String? presetId) async {
    if (presetId == null || presetId.isEmpty) {
      return null;
    }

    // 确保预设已加载
    if (_presets.isEmpty) {
      await loadPresets();
    }

    final preset = getPresetById(presetId);
    return preset?.content;
  }

  /// 根据类别筛选预设
  List<PromptPreset> getPresetsByCategory(String? category) {
    if (category == null || category.isEmpty) {
      return List.unmodifiable(_presets);
    }
    return _presets.where((p) => p.category == category).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// 获取所有类别
  List<String> getCategories() {
    final categories = <String>{};
    for (final preset in _presets) {
      if (preset.category != null) {
        categories.add(preset.category!);
      }
    }
    return categories.toList()..sort();
  }

  /// 获取默认预设
  List<PromptPreset> get defaultPresets {
    return _presets.where((p) => p.isDefault).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// 按标签搜索预设
  List<PromptPreset> searchPresets(String query) {
    if (query.isEmpty) {
      return List.unmodifiable(_presets);
    }

    final lowerQuery = query.toLowerCase();
    return _presets.where((preset) {
      return preset.name.toLowerCase().contains(lowerQuery) ||
          preset.description.toLowerCase().contains(lowerQuery) ||
          preset.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// 获取预设统计信息
  Map<String, int> getPresetStats() {
    final stats = <String, int>{'total': _presets.length};

    // 按类别统计
    for (final category in getCategories()) {
      stats['category_$category'] = getPresetsByCategory(category).length;
    }

    // 默认预设数量
    stats['default'] = defaultPresets.length;

    return stats;
  }

  /// 重置为默认预设
  /// 删除所有自定义预设，恢复到默认状态
  Future<void> resetToDefaults() async {
    try {
      // 导入示例数据中的默认预设
      final defaultPresets = OpenAISampleData.defaultPresets;

      _presets = defaultPresets;
      await _savePresets();
      notifyListeners();

      debugPrint('已重置为 ${defaultPresets.length} 个默认预设');
    } catch (e) {
      debugPrint('重置默认预设失败: $e');
      rethrow;
    }
  }

  /// 导出预设为 JSON 字符串
  String exportPresets() {
    final data = {
      'presets': _presets.map((p) => p.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    return data.toString();
  }

  /// 从 JSON 字符串导入预设
  Future<void> importPresets(String jsonString) async {
    try {
      final data = json.decode(jsonString);
      if (data['presets'] != null) {
        final importedPresets = (data['presets'] as List)
            .map((json) => PromptPreset.fromJson(json as Map<String, dynamic>))
            .toList();

        // 合并导入的预设（避免重复）
        for (final preset in importedPresets) {
          if (!_presets.any((p) => p.id == preset.id)) {
            _presets.add(preset);
          }
        }

        await _savePresets();
        notifyListeners();
        debugPrint('成功导入 ${importedPresets.length} 个预设');
      }
    } catch (e) {
      debugPrint('导入预设失败: $e');
      rethrow;
    }
  }
}
