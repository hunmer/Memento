import 'package:flutter/foundation.dart';
import '../models/analysis_preset.dart';
import '../openai_plugin.dart';

/// 分析预设控制器
///
/// 负责管理分析预设的CRUD操作和持久化存储
/// 使用单例模式确保全局唯一实例
class AnalysisPresetController extends ChangeNotifier {
  static final AnalysisPresetController _instance =
      AnalysisPresetController._internal();

  factory AnalysisPresetController() => _instance;

  AnalysisPresetController._internal();

  /// 预设列表
  List<AnalysisPreset> _presets = [];

  /// 获取不可变的预设列表
  List<AnalysisPreset> get presets => List.unmodifiable(_presets);

  /// 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 存储文件路径
  static const String _storageKey = 'openai/analysis_presets.json';

  /// 加载所有预设
  Future<List<AnalysisPreset>> loadPresets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final plugin = OpenAIPlugin.instance;
      final data = await plugin.storage.read(_storageKey);

      if (data.isEmpty) {
        _presets = [];
      } else {
        final presetsList = data['presets'] as List<dynamic>? ?? [];
        _presets = presetsList
            .map((json) => AnalysisPreset.fromJson(json as Map<String, dynamic>))
            .toList();

        // 按更新时间倒序排序（最新的在前面）
        _presets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      debugPrint('已加载 ${_presets.length} 个分析预设');
    } catch (e) {
      debugPrint('加载分析预设失败: $e');
      _presets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _presets;
  }

  /// 保存预设（新建或更新）
  Future<void> savePreset(AnalysisPreset preset) async {
    try {
      final index = _presets.indexWhere((p) => p.id == preset.id);

      if (index >= 0) {
        // 更新现有预设
        _presets[index] = preset.copyWith(updatedAt: DateTime.now());
        debugPrint('已更新预设: ${preset.title}');
      } else {
        // 添加新预设
        _presets.insert(0, preset); // 插入到列表开头
        debugPrint('已添加新预设: ${preset.title}');
      }

      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('保存预设失败: $e');
      rethrow;
    }
  }

  /// 删除预设
  Future<void> deletePreset(String presetId) async {
    try {
      final index = _presets.indexWhere((p) => p.id == presetId);

      if (index >= 0) {
        final preset = _presets[index];
        _presets.removeAt(index);
        await _saveToStorage();
        notifyListeners();
        debugPrint('已删除预设: ${preset.title}');
      }
    } catch (e) {
      debugPrint('删除预设失败: $e');
      rethrow;
    }
  }

  /// 获取单个预设
  Future<AnalysisPreset?> getPreset(String presetId) async {
    try {
      return _presets.firstWhere((p) => p.id == presetId);
    } catch (e) {
      debugPrint('获取预设失败: $e');
      return null;
    }
  }

  /// 根据标签筛选预设
  List<AnalysisPreset> getPresetsByTag(String tag) {
    return _presets.where((p) => p.tags.contains(tag)).toList();
  }

  /// 搜索预设（按标题或描述）
  List<AnalysisPreset> searchPresets(String keyword) {
    if (keyword.isEmpty) return _presets;

    final lowerKeyword = keyword.toLowerCase();
    return _presets.where((p) {
      return p.title.toLowerCase().contains(lowerKeyword) ||
          p.description.toLowerCase().contains(lowerKeyword) ||
          p.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
    }).toList();
  }

  /// 获取所有标签（去重）
  List<String> getAllTags() {
    final tagsSet = <String>{};
    for (var preset in _presets) {
      tagsSet.addAll(preset.tags);
    }
    return tagsSet.toList()..sort();
  }

  /// 清空所有预设关联的智能体ID（用于智能体删除时）
  Future<void> clearAgentIdInPresets(String agentId) async {
    bool hasChanges = false;

    for (var preset in _presets) {
      if (preset.agentId == agentId) {
        preset.agentId = null;
        preset.updatedAt = DateTime.now();
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveToStorage();
      notifyListeners();
      debugPrint('已清除预设中关联的智能体: $agentId');
    }
  }

  /// 保存到存储
  Future<void> _saveToStorage() async {
    try {
      final plugin = OpenAIPlugin.instance;
      final data = {
        'presets': _presets.map((p) => p.toJson()).toList(),
      };
      await plugin.storage.write(_storageKey, data);
    } catch (e) {
      debugPrint('保存预设到存储失败: $e');
      rethrow;
    }
  }

  /// 导出预设（用于备份或分享）
  Map<String, dynamic> exportPresets() {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'presets': _presets.map((p) => p.toJson()).toList(),
    };
  }

  /// 导入预设（用于恢复或分享）
  Future<int> importPresets(Map<String, dynamic> data, {bool merge = true}) async {
    try {
      final importedPresets = (data['presets'] as List<dynamic>?)
          ?.map((json) => AnalysisPreset.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      if (merge) {
        // 合并模式：只添加不存在的预设
        int addedCount = 0;
        for (var preset in importedPresets) {
          if (!_presets.any((p) => p.id == preset.id)) {
            _presets.add(preset);
            addedCount++;
          }
        }
        debugPrint('合并导入了 $addedCount 个预设');
        await _saveToStorage();
        notifyListeners();
        return addedCount;
      } else {
        // 替换模式：完全替换现有预设
        _presets = importedPresets;
        debugPrint('完全替换导入了 ${_presets.length} 个预设');
        await _saveToStorage();
        notifyListeners();
        return _presets.length;
      }
    } catch (e) {
      debugPrint('导入预设失败: $e');
      rethrow;
    }
  }
}
