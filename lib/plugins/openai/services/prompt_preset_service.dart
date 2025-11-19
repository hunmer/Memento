import 'package:flutter/foundation.dart';
import '../../../core/plugin_manager.dart';
import '../openai_plugin.dart';
import '../models/prompt_preset.dart';

/// Prompt 预设管理服务
/// 提供 CRUD 操作和预设获取功能
class PromptPresetService extends ChangeNotifier {
  static final PromptPresetService _instance = PromptPresetService._internal();
  factory PromptPresetService() => _instance;
  PromptPresetService._internal();

  List<PromptPreset> _presets = [];
  List<PromptPreset> get presets => List.unmodifiable(_presets);

  static const String _storageKey = 'openai/prompt_presets.json';

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
}
