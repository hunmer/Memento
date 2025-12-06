import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../day_plugin.dart';
import '../sample_data.dart';

enum SortMode {
  upcoming, // 即将发生
  recent, // 最近添加
  manual, // 手动排序
}

class DayController extends ChangeNotifier {
  final _plugin = DayPlugin.instance;
  final List<MemorialDay> _memorialDays = [];
  bool _isCardView = true;

  List<MemorialDay> get memorialDays => _memorialDays;
  bool get isCardView => _isCardView;

  // 判断是否允许拖拽排序
  bool get isDraggable => _sortMode == SortMode.manual;

  // 初始化
  Future<void> initialize() async {
    await _loadMemorialDays();
    await _loadViewPreference();
  }

  // 切换视图模式
  void toggleView() {
    _isCardView = !_isCardView;
    _saveViewPreference();
    notifyListeners();
  }

  // 加载视图偏好设置
  Future<void> _loadViewPreference() async {
    try {
      // 确保目录存在
      await _plugin.storage.createDirectory('day');

      // 设置默认的配置JSON字符串
      final defaultConfig = jsonEncode({
        'isCardView': true,
        'sortMode': SortMode.upcoming.toString(),
      });

      final configStr = await _plugin.storage.readFile(
        '${'day'}/view_preference.json',
        defaultConfig,
      );

      final config = jsonDecode(configStr);
      _isCardView = config['isCardView'] ?? true;

      // 解析排序模式
      if (config['sortMode'] != null) {
        final sortModeStr = config['sortMode'].toString();
        if (sortModeStr.contains('upcoming')) {
          _sortMode = SortMode.upcoming;
        } else if (sortModeStr.contains('recent')) {
          _sortMode = SortMode.recent;
        } else if (sortModeStr.contains('manual')) {
          _sortMode = SortMode.manual;
        } else {
          _sortMode = SortMode.upcoming;
        }
      } else {
        _sortMode = SortMode.upcoming;
      }
    } catch (e) {
      debugPrint('加载视图偏好设置失败: $e');
      _isCardView = true;
      _sortMode = SortMode.upcoming;
    }
  }

  // 保存视图偏好设置
  Future<void> _saveViewPreference() async {
    try {
      await _plugin.storage.writeFile(
        '${'day'}/view_preference.json',
        jsonEncode({
          'isCardView': _isCardView,
          'sortMode': _sortMode.toString(),
        }),
      );
    } catch (e) {
      debugPrint('保存视图偏好设置失败: $e');
    }
  }

  // 加载纪念日数据
  Future<void> _loadMemorialDays() async {
    // 确保目录存在
    await _plugin.storage.createDirectory('day');

    final filePath = '${'day'}/memorial_days.json';

    // 检查文件是否存在
    final fileExists = await _plugin.storage.fileExists(filePath);

    if (!fileExists) {
      // 文件不存在，写入示例数据
      final sampleDays = DaySampleData.getSampleMemorialDays();
      _memorialDays.clear();
      _memorialDays.addAll(sampleDays);
      await _saveMemorialDays();
      _sortMemorialDays();
      return;
    }

    // 设置默认的空数组JSON字符串
    final defaultContent = '[]';

    final content = await _plugin.storage.readFile(
      filePath,
      defaultContent,
    );

    try {
      final List<dynamic> jsonList = jsonDecode(content);
      _memorialDays.clear();
      // 加载所有纪念日
      _memorialDays.addAll(
        jsonList.map((json) => MemorialDay.fromJson(json)).toList(),
      );

      // 检查是否所有项目都有有效的sortIndex
      var hasInvalidIndex = _memorialDays.any((day) => day.sortIndex < 0);
      if (hasInvalidIndex) {
        // 如果有无效的索引，重新分配所有索引
        for (var i = 0; i < _memorialDays.length; i++) {
          _memorialDays[i] = _memorialDays[i].copyWith(sortIndex: i);
        }
        // 保存更新后的索引
        await _saveMemorialDays();
      }
    } catch (e) {
      debugPrint('解析纪念日数据失败: $e');
      _memorialDays.clear();
    }
    // 始终按当前排序模式排序
    _sortMemorialDays();
  }

  // 保存纪念日数据
  Future<void> _saveMemorialDays() async {
    try {
      final jsonList = _memorialDays.map((day) => day.toJson()).toList();
      await _plugin.storage.writeFile(
        '${'day'}/memorial_days.json',
        jsonEncode(jsonList),
      );
    } catch (e) {
      debugPrint('保存纪念日数据失败: $e');
    }
  }

  // 添加纪念日
  Future<void> addMemorialDay(MemorialDay memorialDay) async {
    // 在手动排序模式下，新项目添加到末尾
    if (_sortMode == SortMode.manual) {
      final newMemorialDay = memorialDay.copyWith(
        sortIndex:
            _memorialDays.isEmpty
                ? 0
                : _memorialDays.map((d) => d.sortIndex).reduce(max) + 1,
      );
      _memorialDays.add(newMemorialDay);
    } else {
      _memorialDays.add(memorialDay);
      _sortMemorialDays();
    }
    await _saveMemorialDays();
    notifyListeners();
  }

  // 更新纪念日
  Future<void> updateMemorialDay(MemorialDay memorialDay) async {
    final index = _memorialDays.indexWhere((day) => day.id == memorialDay.id);
    if (index != -1) {
      _memorialDays[index] = memorialDay;
      _sortMemorialDays();
      await _saveMemorialDays();
      notifyListeners();
    }
  }

  // 删除纪念日
  Future<void> deleteMemorialDay(String id) async {
    _memorialDays.removeWhere((day) => day.id == id);
    await _saveMemorialDays();
    notifyListeners();
  }

  // 按当前排序模式排序
  void _sortMemorialDays() {
    switch (_sortMode) {
      case SortMode.upcoming:
        _memorialDays.sort(
          (a, b) => a.daysRemaining.compareTo(b.daysRemaining),
        );
        break;
      case SortMode.recent:
        _memorialDays.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case SortMode.manual:
        // 按 sortIndex 排序
        _memorialDays.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
        break;
    }
  }

  // 手动重新排序纪念日
  Future<void> reorderMemorialDays(int oldIndex, int newIndex) async {
    // 确保在手动排序模式下
    if (_sortMode != SortMode.manual) return;

    // 调整新索引（ReorderableListView的要求）
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 移动项目
    final item = _memorialDays.removeAt(oldIndex);
    _memorialDays.insert(newIndex, item);

    // 计算新的排序索引
    double newSortIndex;
    if (newIndex == 0) {
      // 移动到开头
      newSortIndex = _memorialDays[1].sortIndex - 1.0;
    } else if (newIndex == _memorialDays.length - 1) {
      // 移动到末尾
      newSortIndex = _memorialDays[newIndex - 1].sortIndex + 1.0;
    } else {
      // 移动到中间，取前后两项sortIndex的平均值
      newSortIndex =
          (_memorialDays[newIndex - 1].sortIndex +
              _memorialDays[newIndex + 1].sortIndex) /
          2.0;
    }

    // 更新移动项目的sortIndex
    _memorialDays[newIndex] = _memorialDays[newIndex].copyWith(
      sortIndex: newSortIndex.round(),
    );

    // 保存更改
    await _saveMemorialDays();

    // 通知监听器
    notifyListeners();
  }

  // 设置自定义排序顺序
  SortMode _sortMode = SortMode.upcoming;
  SortMode get sortMode => _sortMode;

  // 设置排序模式
  Future<void> setSortMode(SortMode mode) async {
    _sortMode = mode;
    _sortMemorialDays();
    // 保存排序模式到偏好设置
    await _saveViewPreference();
    notifyListeners();
  }
}
