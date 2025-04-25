import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../day_plugin.dart';

class DayController extends ChangeNotifier {
  final _plugin = DayPlugin.instance;
  List<MemorialDay> _memorialDays = [];
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
      _useCustomOrder = false;
    }
  }

  // 保存视图偏好设置
  Future<void> _saveViewPreference() async {
    try {
      await _plugin.storage.writeFile(
        '${_plugin.pluginDir}/view_preference.json',
        jsonEncode({
          'isCardView': _isCardView,
          'useCustomOrder': _useCustomOrder,
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
    // 如果文件不存在或读取失败，加载测试数据
    // _memorialDays = MemorialDay.generateTestData();
    await _saveMemorialDays();
    // 如果不使用自定义排序，则按剩余天数排序
    if (!_useCustomOrder) {
      _sortMemorialDays();
    }
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

  // 按剩余天数排序
  void _sortMemorialDays() {
    _memorialDays.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  // 手动重新排序纪念日
  Future<void> reorderMemorialDays(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      // 如果将项目向下移动，需要减1，因为移除oldIndex后，newIndex的位置会变化
      newIndex -= 1;
    }
    final item = _memorialDays.removeAt(oldIndex);
    _memorialDays.insert(newIndex, item);
    await _saveMemorialDays();
    notifyListeners();
  }

  // 设置自定义排序顺序
  bool _useCustomOrder = false;
  bool get useCustomOrder => _useCustomOrder;

  // 切换排序模式
  Future<void> toggleSortMode() async {
    _useCustomOrder = !_useCustomOrder;
    if (!_useCustomOrder) {
      // 如果切换回自动排序，重新按剩余天数排序
      _sortMemorialDays();
    }
    await _saveViewPreference();
    notifyListeners();
  }
}
