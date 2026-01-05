part of 'day_plugin.dart';

// ==================== JS API 实现 ====================
// 以下函数供 DayPlugin.defineJSAPI() 使用

/// 获取所有纪念日
/// @param params.offset 起始位置（可选，默认 0）
/// @param params.count 返回数量（可选，默认 100）
Future<String> _jsGetMemorialDays(Map<String, dynamic> params) async {
    try {
      final result = await DayPlugin.instance._useCase.getMemorialDays(params);
      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }
      return jsonEncode({
        'success': true,
        'data': result.dataOrNull ?? [],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 创建纪念日
  Future<String> _jsCreateMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await DayPlugin.instance._useCase.createMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'data': result.dataOrNull});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 更新纪念日
  Future<String> _jsUpdateMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await DayPlugin.instance._useCase.updateMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'data': result.dataOrNull});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 删除纪念日
  Future<String> _jsDeleteMemorialDay(Map<String, dynamic> params) async {
    try {
      final result = await DayPlugin.instance._useCase.deleteMemorialDay(params);
      if (result.isFailure) {
        return jsonEncode({'success': false, 'error': result.errorOrNull?.message});
      }
      return jsonEncode({'success': true, 'message': '纪念日已删除'});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取距离指定日期的天数
  Future<String> _jsGetDaysUntil(Map<String, dynamic> params) async {
    try {
      final String? date = params['date'];
      if (date == null) {
        return jsonEncode({'error': '缺少必需参数: date'});
      }

      final targetDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final days = target.difference(today).inDays;

      return jsonEncode({
        'success': true,
        'days': days,
        'isExpired': days < 0,
        'isToday': days == 0,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 获取即将到来的纪念日
  Future<String> _jsGetUpcomingDays(Map<String, dynamic> params) async {
    try {
      final int withinDays = params['withinDays'] ?? 7;

      final upcomingDays = DayPlugin.instance._controller.memorialDays.where((day) {
        final daysRemaining = day.daysRemaining;
        return daysRemaining >= 0 && daysRemaining <= withinDays;
      }).toList();

      return jsonEncode({
        'success': true,
        'data': upcomingDays.map((d) => d.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  // ==================== 查找方法 ====================

  /// 通用纪念日查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindMemorialDayBy(Map<String, dynamic> params) async {
    try {
      final String? field = params['field'];
      if (field == null || field.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: field'});
      }

      final dynamic value = params['value'];
      if (value == null) {
        return jsonEncode({'error': '缺少必需参数: value'});
      }

      final bool findAll = params['findAll'] ?? false;

      final days = DayPlugin.instance._controller.memorialDays;
      final List<MemorialDay> matchedDays = [];

      for (final day in days) {
        final dayJson = day.toJson();

        // 检查字段是否匹配
        if (dayJson.containsKey(field) && dayJson[field] == value) {
          matchedDays.add(day);
          if (!findAll) break; // 只找第一个
        }
      }

      if (findAll) {
        return jsonEncode(matchedDays.map((d) => d.toJson()).toList());
      } else {
        if (matchedDays.isEmpty) {
          return jsonEncode(null);
        }
        return jsonEncode(matchedDays.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 根据ID查找纪念日
  /// @param params.id 纪念日ID (必需)
  Future<String> _jsFindMemorialDayById(Map<String, dynamic> params) async {
    try {
      final result = await DayPlugin.instance._useCase.getMemorialDayById(params);
      if (result.isFailure) {
        return jsonEncode({'error': result.errorOrNull?.message});
      }
      return jsonEncode(result.dataOrNull);
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  /// 根据名称查找纪念日
  /// @param params.name 纪念日名称 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  Future<String> _jsFindMemorialDayByName(Map<String, dynamic> params) async {
    try {
      final String? name = params['name'];
      if (name == null || name.isEmpty) {
        return jsonEncode({'error': '缺少必需参数: name'});
      }

      final bool fuzzy = params['fuzzy'] ?? false;
      final bool findAll = params['findAll'] ?? false;

      final days = DayPlugin.instance._controller.memorialDays;
      final List<MemorialDay> matchedDays = [];

      for (final day in days) {
        bool matches = false;
        if (fuzzy) {
          matches = day.title.contains(name);
        } else {
          matches = day.title == name;
        }

        if (matches) {
          matchedDays.add(day);
          if (!findAll) break;
        }
      }

      if (findAll) {
        return jsonEncode(matchedDays.map((d) => d.toJson()).toList());
      } else {
        if (matchedDays.isEmpty) {
          return jsonEncode(null);
        }
        return jsonEncode(matchedDays.first.toJson());
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }
