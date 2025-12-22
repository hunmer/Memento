import 'package:flutter/foundation.dart';
import 'package:Memento/core/storage/storage_manager.dart';
import '../models/agent_chain_preset.dart';

/// Agent 链预设服务
///
/// 负责 Agent 链预设的存储、加载和管理
class AgentChainPresetService extends ChangeNotifier {
  final StorageManager storage;

  /// 预设列表缓存
  List<AgentChainPreset> _presets = [];

  /// 是否已初始化
  bool _isInitialized = false;

  AgentChainPresetService({required this.storage});

  /// 获取所有预设
  List<AgentChainPreset> get presets => List.unmodifiable(_presets);

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    await loadPresets();
    _isInitialized = true;
  }

  /// 加载所有预设
  Future<List<AgentChainPreset>> loadPresets() async {
    try {
      final data = await storage.read('agent_chat/chain_presets');
      if (data is List) {
        _presets = data
            .map((json) => AgentChainPreset.fromJson(json as Map<String, dynamic>))
            .toList();

        // 按更新时间倒序排序
        _presets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        _presets = [];
      }
    } catch (e) {
      debugPrint('加载 Agent 链预设失败: $e');
      _presets = [];
    }

    notifyListeners();
    return _presets;
  }

  /// 保存所有预设到存储
  Future<void> _savePresets() async {
    try {
      final data = _presets.map((preset) => preset.toJson()).toList();
      await storage.write('agent_chat/chain_presets', data);
    } catch (e) {
      debugPrint('保存 Agent 链预设失败: $e');
      rethrow;
    }
  }

  /// 保存预设
  Future<void> savePreset(AgentChainPreset preset) async {
    // 检查是否已存在同 ID 的预设
    final existingIndex = _presets.indexWhere((p) => p.id == preset.id);

    if (existingIndex >= 0) {
      // 更新现有预设
      _presets[existingIndex] = preset.copyWith(updatedAt: DateTime.now());
    } else {
      // 添加新预设
      _presets.insert(0, preset);
    }

    await _savePresets();
    notifyListeners();
  }

  /// 删除预设
  Future<void> deletePreset(String presetId) async {
    _presets.removeWhere((preset) => preset.id == presetId);

    await _savePresets();
    notifyListeners();
  }

  /// 获取指定预设
  AgentChainPreset? getPreset(String presetId) {
    try {
      return _presets.firstWhere((preset) => preset.id == presetId);
    } catch (e) {
      return null;
    }
  }

  /// 检查预设名称是否已存在
  bool isNameExists(String name, {String? excludeId}) {
    return _presets.any(
      (preset) => preset.name == name && preset.id != excludeId,
    );
  }

  @override
  void dispose() {
    _presets.clear();
    super.dispose();
  }
}
