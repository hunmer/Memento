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
      final config = await _plugin.storage.readFile('${_plugin.pluginDir}/view_preference.json');
      final data = jsonDecode(config);
      _isCardView = data['isCardView'] ?? true;
    } catch (e) {
      _isCardView = true;
    }
  }

  // 保存视图偏好设置
  Future<void> _saveViewPreference() async {
    try {
      await _plugin.storage.writeFile(
        '${_plugin.pluginDir}/view_preference.json',
        jsonEncode({'isCardView': _isCardView}),
      );
    } catch (e) {
      debugPrint('保存视图偏好设置失败: $e');
    }
  }

  // 加载纪念日数据
  Future<void> _loadMemorialDays() async {
    try {
      final content = await _plugin.storage.readFile('${_plugin.pluginDir}/memorial_days.json');
      final List<dynamic> jsonList = jsonDecode(content);
      _memorialDays = jsonList.map((json) => MemorialDay.fromJson(json)).toList();
    } catch (e) {
      // 如果文件不存在或读取失败，加载测试数据
      _memorialDays = MemorialDay.generateTestData();
      await _saveMemorialDays();
    }
    // 按剩余天数排序
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

  // 按剩余天数排序
  void _sortMemorialDays() {
    _memorialDays.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }
}