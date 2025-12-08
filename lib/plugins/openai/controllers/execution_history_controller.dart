import 'package:flutter/foundation.dart';
import 'package:Memento/plugins/openai/models/execution_history.dart';
import 'package:Memento/plugins/openai/openai_plugin.dart';

/// 执行历史控制器
///
/// 负责管理预设执行历史的CRUD操作和持久化存储
/// 每个预设的历史记录保存在单独的JSON文件中
class ExecutionHistoryController extends ChangeNotifier {
  /// 当前加载的预设ID
  String? _currentPresetId;

  /// 历史记录列表
  List<ExecutionHistory> _histories = [];

  /// 获取不可变的历史记录列表
  List<ExecutionHistory> get histories => List.unmodifiable(_histories);

  /// 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 获取存储文件路径
  String _getStorageKey(String presetId) {
    return 'openai/execution_histories/$presetId.json';
  }

  /// 加载指定预设的执行历史
  Future<List<ExecutionHistory>> loadHistories(String presetId) async {
    _isLoading = true;
    _currentPresetId = presetId;
    notifyListeners();

    try {
      final plugin = OpenAIPlugin.instance;
      final data = await plugin.storage.read(_getStorageKey(presetId));

      if (data.isEmpty) {
        _histories = [];
      } else {
        final historiesList = data['histories'] as List<dynamic>? ?? [];
        _histories = historiesList
            .map((json) =>
                ExecutionHistory.fromJson(json as Map<String, dynamic>))
            .toList();

        // 按创建时间倒序排序（最新的在前面）
        _histories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      debugPrint('已加载 ${_histories.length} 条执行历史记录');
    } catch (e) {
      debugPrint('加载执行历史失败: $e');
      _histories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _histories;
  }

  /// 添加新的执行记录
  Future<void> addHistory(ExecutionHistory history) async {
    try {
      _histories.insert(0, history); // 插入到列表开头
      await _saveToStorage(history.presetId);
      notifyListeners();
      debugPrint('已添加执行历史: ${history.id}');
    } catch (e) {
      debugPrint('添加执行历史失败: $e');
      rethrow;
    }
  }

  /// 更新执行记录（用于更新状态、响应等）
  Future<void> updateHistory(ExecutionHistory history) async {
    try {
      final index = _histories.indexWhere((h) => h.id == history.id);

      if (index >= 0) {
        _histories[index] = history;
        await _saveToStorage(history.presetId);
        notifyListeners();
        debugPrint('已更新执行历史: ${history.id}');
      }
    } catch (e) {
      debugPrint('更新执行历史失败: $e');
      rethrow;
    }
  }

  /// 删除执行记录
  Future<void> deleteHistory(String historyId) async {
    try {
      final index = _histories.indexWhere((h) => h.id == historyId);

      if (index >= 0) {
        final history = _histories[index];
        _histories.removeAt(index);
        await _saveToStorage(history.presetId);
        notifyListeners();
        debugPrint('已删除执行历史: $historyId');
      }
    } catch (e) {
      debugPrint('删除执行历史失败: $e');
      rethrow;
    }
  }

  /// 清空指定预设的所有历史记录
  Future<void> clearHistories(String presetId) async {
    try {
      _histories.clear();
      await _saveToStorage(presetId);
      notifyListeners();
      debugPrint('已清空预设的所有执行历史: $presetId');
    } catch (e) {
      debugPrint('清空执行历史失败: $e');
      rethrow;
    }
  }

  /// 获取单条历史记录
  ExecutionHistory? getHistory(String historyId) {
    try {
      return _histories.firstWhere((h) => h.id == historyId);
    } catch (e) {
      return null;
    }
  }

  /// 获取成功的执行次数
  int get successCount {
    return _histories.where((h) => h.status == 'success').length;
  }

  /// 获取失败的执行次数
  int get errorCount {
    return _histories.where((h) => h.status == 'error').length;
  }

  /// 获取平均执行时间（毫秒）
  double get averageDuration {
    final successHistories =
        _histories.where((h) => h.status == 'success' && h.durationMs != null);

    if (successHistories.isEmpty) return 0;

    final total = successHistories.fold<int>(
      0,
      (sum, h) => sum + (h.durationMs ?? 0),
    );

    return total / successHistories.length;
  }

  /// 保存到存储
  Future<void> _saveToStorage(String presetId) async {
    try {
      final plugin = OpenAIPlugin.instance;
      final data = {
        'presetId': presetId,
        'histories': _histories.map((h) => h.toJson()).toList(),
      };
      await plugin.storage.write(_getStorageKey(presetId), data);
    } catch (e) {
      debugPrint('保存执行历史到存储失败: $e');
      rethrow;
    }
  }

  /// 导出历史记录
  Map<String, dynamic> exportHistories() {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'presetId': _currentPresetId,
      'histories': _histories.map((h) => h.toJson()).toList(),
    };
  }

  /// 删除预设时清理对应的历史文件
  Future<void> deletePresetHistories(String presetId) async {
    try {
      final plugin = OpenAIPlugin.instance;
      await plugin.storage.delete(_getStorageKey(presetId));
      debugPrint('已删除预设的历史文件: $presetId');

      // 如果当前加载的是这个预设的历史，清空列表
      if (_currentPresetId == presetId) {
        _histories.clear();
        _currentPresetId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('删除预设历史文件失败: $e');
    }
  }
}
