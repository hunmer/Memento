import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../day_plugin.dart';

enum SortMode {
  upcoming,  // 即将发生
  recent,    // 最近添加
  manual     // 手动排序
}

class DayController extends ChangeNotifier {
  final _plugin = DayPlugin.instance;
  final List<MemorialDay> _memorialDays = [];
  bool _isCardView = true;

  List<MemorialDay> get memorialDays => _memorialDays;
  bool get isCardView => _isCardView;

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
      await _plugin.storage.createDirectory(_plugin.pluginDir);

      // 设置默认的配置JSON字符串
      final defaultConfig = jsonEncode({
        'isCardView': true,
        'useCustomOrder': false,
      });

      final config = await _plugin.storage.readFile(
        '${_plugin.pluginDir}/view_preference.json',
        defaultConfig,
      );
    } catch (e) {
      _isCardView = true;
      _sortMode = SortMode.upcoming;
    }
  }

  // 保存视图偏好设置
  Future<void> _saveViewPreference() async {
    try {
      await _plugin.storage.writeFile(
        '${_plugin.pluginDir}/view_preference.json',
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
    await _plugin.storage.createDirectory(_plugin.pluginDir);

    // 设置默认的空数组JSON字符串
    final defaultContent = '[]';

    final content = await _plugin.storage.readFile(
      '${_plugin.pluginDir}/memorial_days.json',
      defaultContent,
    );
    
    try {
      final List<dynamic> jsonList = jsonDecode(content);
      _memorialDays.clear();
      // 为每个项目分配sortIndex
      _memorialDays.addAll(
        jsonList.map((json) => MemorialDay.fromJson(json)).toList(),
      );
      // 为未设置sortIndex的项目分配-1
      for (var i = 0; i < _memorialDays.length; i++) {
        if (_memorialDays[i].sortIndex == 0) {
          _memorialDays[i] = _memorialDays[i].copyWith(sortIndex: -1);
        }
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
        '${_plugin.pluginDir}/memorial_days.json',
        jsonEncode(jsonList),
      );
    } catch (e) {
      debugPrint('保存纪念日数据失败: $e');
    }
  }

  // 添加纪念日
  Future<void> addMemorialDay(MemorialDay memorialDay) async {
    _memorialDays.add(memorialDay);
    _sortMemorialDays();
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
        _memorialDays.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
        break;
      case SortMode.recent:
        _memorialDays.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case SortMode.manual:
        _memorialDays.sort((a, b) {
          // 未设置sortIndex的项目(-1)排在最后
          if (a.sortIndex == -1) return 1;
          if (b.sortIndex == -1) return -1;
          return a.sortIndex.compareTo(b.sortIndex);
        });
        break;
    }
  }

  // 手动重新排序纪念日
  Future<void> reorderMemorialDays(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _memorialDays.removeAt(oldIndex);
    _memorialDays.insert(newIndex, item);
    
    // 更新所有项目的sortIndex
    for (var i = 0; i < _memorialDays.length; i++) {
      _memorialDays[i] = _memorialDays[i].copyWith(
        sortIndex: i,
      );
    }
    
    // 立即同步保存数据
    await _saveMemorialDays();
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
    // 如果是手动排序模式，立即保存当前排序
    if (_sortMode == SortMode.manual) {
      await _saveMemorialDays();
    }
    notifyListeners();
  }
}
