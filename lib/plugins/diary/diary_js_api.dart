part of 'diary_plugin.dart';

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 日记查询接口
      'getDiaries': _jsGetDiaries,
      'getDiary': _jsGetDiary,

      // 日记操作接口
      'saveDiary': _jsSaveDiary,
      'deleteDiary': _jsDeleteDiary,

      // 统计接口
      'getTodayStats': _jsGetTodayStats,
      'getMonthStats': _jsGetMonthStats,
      'getTodayWordCount': _jsGetTodayWordCount,
      'getMonthWordCount': _jsGetMonthWordCount,
      'getMonthProgress': _jsGetMonthProgress,

      // 日记条目操作接口（直接操作方法）
      'loadDiaryEntry': _jsLoadDiaryEntry,
      'saveDiaryEntry': _jsSaveDiaryEntry,
      'deleteDiaryEntry': _jsDeleteDiaryEntry,
      'hasEntryForDate': _jsHasEntryForDate,
      'getDiaryStats': _jsGetDiaryStats,

      // 日记查找接口
      'findDiaryBy': _jsFindDiaryBy,
      'findDiaryByDate': _jsFindDiaryByDate,
      'findDiaryByTitle': _jsFindDiaryByTitle,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取指定日期范围的日记
  /// 参数: {"startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD", "offset": number, "count": number}
  /// 返回: JSON 字符串，包含日记列表
  Future<Map<String, dynamic>> _jsGetDiaries(
    Map<String, dynamic> params,
  ) async {
    try {
      // 验证必需参数
      if (!params.containsKey('startDate')) {
        return {'error': '缺少必需参数: startDate', 'total': 0, 'diaries': []};
      }
      if (!params.containsKey('endDate')) {
        return {'error': '缺少必需参数: endDate', 'total': 0, 'diaries': []};
      }

      // 使用 UseCase 获取日记列表
      final result = await _diaryUseCase.getEntries(params);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误', 'total': 0, 'diaries': []};
      }

      final diaries = result.dataOrNull ?? [];

      // 检查是否需要分页格式
      final int? offset = params['offset'];
      final int? count = params['count'];

      // 如果没有分页参数，返回原格式（向后兼容）
      if (offset == null && count == null) {
        return {
          'total': diaries.length,
          'diaries': diaries,
        };
      }

      // 有分页参数时，返回分页格式
      return {
        'total': diaries.length,
        'offset': offset ?? 0,
        'count': count ?? 20,
        'hasMore': (offset ?? 0) + (count ?? 20) < diaries.length,
        'diaries': diaries,
      };
    } catch (e) {
      return {'error': '获取日记失败: $e', 'total': 0, 'diaries': []};
    }
  }

  /// 获取指定日期的日记
  /// 参数: {"date": "YYYY-MM-DD"}
  /// 返回: JSON 字符串，包含日记内容
  Future<Map<String, dynamic>> _jsGetDiary(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'exists': false, 'error': '缺少必需参数: date'};
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate(params);

      if (result.isFailure) {
        return {'exists': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      final entry = result.dataOrNull;

      if (entry == null) {
        return {'exists': false, 'error': '该日期没有日记'};
      }

      return {
        'exists': true,
        'date': entry['date'],
        'title': entry['title'],
        'content': entry['content'],
        'mood': entry['mood'],
        'wordCount': (entry['content'] as String).length,
        'createdAt': entry['createdAt'],
        'updatedAt': entry['updatedAt'],
      };
    } catch (e) {
      return {'exists': false, 'error': '获取日记失败: $e'};
    }
  }

  /// 保存日记
  /// 参数: {"date": "YYYY-MM-DD", "content": "日记内容", "title": "标题（可选）", "mood": "心情（可选）"}
  /// 返回: JSON 字符串，包含成功状态
  Future<Map<String, dynamic>> _jsSaveDiary(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'success': false, 'error': '缺少必需参数: date'};
      }
      if (!params.containsKey('content')) {
        return {'success': false, 'error': '缺少必需参数: content'};
      }

      // 先检查是否已存在
      final checkResult = await _diaryUseCase.getEntryByDate({'date': params['date']});
      final exists = checkResult.dataOrNull != null;

      // 使用 UseCase 保存日记
      final result = exists
          ? await _diaryUseCase.updateEntry(params)
          : await _diaryUseCase.createEntry(params);

      if (result.isFailure) {
        return {'success': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return {'success': true, 'message': '日记保存成功', 'date': params['date']};
    } catch (e) {
      return {'success': false, 'error': '保存日记失败: $e'};
    }
  }

  /// 删除日记
  /// 参数: {"date": "YYYY-MM-DD"}
  /// 返回: JSON 字符串，包含成功状态
  Future<Map<String, dynamic>> _jsDeleteDiary(
    Map<String, dynamic> params,
  ) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'success': false, 'error': '缺少必需参数: date'};
      }

      // 使用 UseCase 删除日记
      final result = await _diaryUseCase.deleteEntry(params);

      if (result.isFailure) {
        return {'success': false, 'error': result.errorOrNull?.message ?? '未知错误'};
      }

      final data = result.dataOrNull;
      final deleted = data?['deleted'] ?? false;

      return {
        'success': deleted,
        'message': deleted ? '日记删除成功' : '该日期没有日记',
        'date': params['date'],
      };
    } catch (e) {
      return {'success': false, 'error': '删除日记失败: $e'};
    }
  }

  /// 获取今日统计
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: JSON 字符串，包含今日字数
  Future<Map<String, dynamic>> _jsGetTodayStats(
    Map<String, dynamic> params,
  ) async {
    try {
      // 使用 UseCase 获取今日字数
      final result = await _diaryUseCase.getTodayWordCount(params);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误', 'wordCount': 0};
      }

      final wordCount = result.dataOrNull ?? 0;
      final today = DateTime.now();

      return {
        'date': today.toIso8601String().split('T')[0],
        'wordCount': wordCount,
      };
    } catch (e) {
      return {'error': '获取今日统计失败: $e', 'wordCount': 0};
    }
  }

  /// 获取本月统计
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: JSON 字符串，包含本月字数和进度
  Future<Map<String, dynamic>> _jsGetMonthStats(
    Map<String, dynamic> params,
  ) async {
    try {
      // 使用 UseCase 获取本月字数和进度
      final wordCountResult = await _diaryUseCase.getMonthWordCount(params);
      final progressResult = await _diaryUseCase.getMonthProgress(params);

      if (wordCountResult.isFailure || progressResult.isFailure) {
        return {
          'error': '获取本月统计失败',
          'wordCount': 0,
          'completedDays': 0,
          'totalDays': 0,
          'progress': '0.0',
        };
      }

      final wordCount = wordCountResult.dataOrNull ?? 0;
      final progress = progressResult.dataOrNull ?? {};
      final completedDays = progress['completedDays'] ?? 0;
      final totalDays = progress['totalDays'] ?? 0;
      final now = DateTime.now();

      return {
        'year': now.year,
        'month': now.month,
        'wordCount': wordCount,
        'completedDays': completedDays,
        'totalDays': totalDays,
        'progress': totalDays > 0
            ? (completedDays / totalDays * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      return {
        'error': '获取本月统计失败: $e',
        'wordCount': 0,
        'completedDays': 0,
        'totalDays': 0,
        'progress': '0.0',
      };
    }
  }

  // ==================== 新增 JS API 实现 ====================

  /// 获取今日字数（直接返回数字）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 数字，今日字数
  Future<int> _jsGetTodayWordCount(Map<String, dynamic> params) async {
    final result = await _diaryUseCase.getTodayWordCount(params);
    return result.dataOrNull ?? 0;
  }

  /// 获取本月字数（直接返回数字）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 数字，本月总字数
  Future<int> _jsGetMonthWordCount(Map<String, dynamic> params) async {
    final result = await _diaryUseCase.getMonthWordCount(params);
    return result.dataOrNull ?? 0;
  }

  /// 获取本月进度（直接返回对象）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 对象，包含 completedDays 和 totalDays
  Future<Map<String, int>> _jsGetMonthProgress(
    Map<String, dynamic> params,
  ) async {
    final result = await _diaryUseCase.getMonthProgress(params);
    final progress = result.dataOrNull ?? {};
    return {
      'completedDays': progress['completedDays'] ?? 0,
      'totalDays': progress['totalDays'] ?? 0,
    };
  }

  /// 加载日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 日记对象或 null
  Future<Map<String, dynamic>?> _jsLoadDiaryEntry(
    Map<String, dynamic> params,
  ) async {
    try {
      if (!params.containsKey('dateStr')) {
        return {'error': '缺少必需参数: dateStr'};
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return result.dataOrNull;
    } catch (e) {
      return {'error': '加载日记失败: $e'};
    }
  }

  /// 保存日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD", "content": "内容", "title": "标题（可选）", "mood": "心情（可选）"}
  /// 返回: 保存后的日记对象
  Future<Map<String, dynamic>> _jsSaveDiaryEntry(
    Map<String, dynamic> params,
  ) async {
    try {
      if (!params.containsKey('dateStr') || !params.containsKey('content')) {
        return {'error': '缺少必需参数: dateStr 或 content'};
      }

      // 转换参数格式
      final saveParams = {
        'date': params['dateStr'],
        'content': params['content'],
        'title': params['title'] ?? '',
        'mood': params['mood'],
      };

      // 先检查是否已存在
      final checkResult = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});
      final exists = checkResult.dataOrNull != null;

      // 使用 UseCase 保存
      final result = exists
          ? await _diaryUseCase.updateEntry(saveParams)
          : await _diaryUseCase.createEntry(saveParams);

      if (result.isFailure) {
        return {'error': result.errorOrNull?.message ?? '未知错误'};
      }

      return result.dataOrNull ?? {};
    } catch (e) {
      return {'error': '保存日记失败: $e'};
    }
  }

  /// 删除日记条目（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 布尔值，删除成功返回 true
  Future<bool> _jsDeleteDiaryEntry(Map<String, dynamic> params) async {
    try {
      if (!params.containsKey('dateStr')) {
        return false;
      }

      // 使用 UseCase 删除
      final result = await _diaryUseCase.deleteEntry({'date': params['dateStr']});

      if (result.isFailure) {
        debugPrint('Delete diary entry error: ${result.errorOrNull?.message ?? '未知错误'}');
        return false;
      }

      final data = result.dataOrNull;
      return data?['deleted'] ?? false;
    } catch (e) {
      debugPrint('Delete diary entry error: $e');
      return false;
    }
  }

  /// 检查日期是否有日记（直接操作方法）
  /// 参数: {"dateStr": "YYYY-MM-DD"}
  /// 返回: 布尔值，存在返回 true
  Future<bool> _jsHasEntryForDate(Map<String, dynamic> params) async {
    try {
      if (!params.containsKey('dateStr')) {
        return false;
      }

      // 使用 UseCase 获取日记
      final result = await _diaryUseCase.getEntryByDate({'date': params['dateStr']});
      return result.dataOrNull != null;
    } catch (e) {
      debugPrint('Check diary entry error: $e');
      return false;
    }
  }

  /// 获取日记统计（直接操作方法）
  /// 参数: {} (空对象，保持接口一致性)
  /// 返回: 统计对象
  Future<Map<String, dynamic>> _jsGetDiaryStats(
    Map<String, dynamic> params,
  ) async {
    final result = await _diaryUseCase.getStats(params);
    return result.dataOrNull ?? {};
  }

  // ==================== 日记查找接口实现 ====================

  /// 通用日记查找方法
  /// 参数: {"field": string, "value": any, "findAll": boolean}
  /// 返回: findAll=false 时返回单个日记对象或 null；findAll=true 时返回日记数组
  Future<dynamic> _jsFindDiaryBy(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('field')) {
        return {'error': '缺少必需参数: field'};
      }
      if (!params.containsKey('value')) {
        return {'error': '缺少必需参数: value'};
      }

      final field = params['field'] as String;
      final value = params['value'];
      final findAll = params['findAll'] == true;

      // 获取所有日记
      final now = DateTime.now();
      final startDate = DateTime(2000, 1, 1); // 足够早的日期
      final endDate = DateTime(now.year + 1, 12, 31); // 足够晚的日期

      final result = await _diaryUseCase.getEntries({
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      });

      if (result.isFailure) {
        return findAll ? [] : null;
      }

      final diaries = result.dataOrNull ?? [];

      // 根据字段进行筛选
      final matches = diaries.where((diary) {
        if (!diary.containsKey(field)) return false;
        final fieldValue = diary[field];
        return fieldValue == value;
      }).toList();

      // 根据 findAll 参数返回结果
      if (findAll) {
        return matches;
      } else {
        return matches.isEmpty ? null : matches.first;
      }
    } catch (e) {
      debugPrint('Find diary by field error: $e');
      return params['findAll'] == true ? [] : null;
    }
  }

  /// 根据日期查找日记（findDiaryBy 的便捷方法）
  /// 参数: {"date": "YYYY-MM-DD"}
  /// 返回: 日记对象或 null
  Future<Map<String, dynamic>?> _jsFindDiaryByDate(
    Map<String, dynamic> params,
  ) async {
    try {
      // 验证必需参数
      if (!params.containsKey('date')) {
        return {'error': '缺少必需参数: date'};
      }

      // 直接调用 getDiary，它返回的格式与 findDiaryByDate 要求一致
      final result = await _jsGetDiary({'date': params['date']});

      // 如果存在，返回日记对象；否则返回 null
      if (result['exists'] == true) {
        // 移除 exists 字段，返回纯日记对象
        final diary = Map<String, dynamic>.from(result);
        diary.remove('exists');
        return diary;
      }

      return null;
    } catch (e) {
      debugPrint('Find diary by date error: $e');
      return null;
    }
  }

  /// 根据标题查找日记
  /// 参数: {"title": string, "fuzzy": boolean, "findAll": boolean}
  /// 返回: findAll=false 时返回单个日记或 null；findAll=true 时返回日记数组
  Future<dynamic> _jsFindDiaryByTitle(Map<String, dynamic> params) async {
    try {
      // 验证必需参数
      if (!params.containsKey('title')) {
        return {'error': '缺少必需参数: title'};
      }

      final title = params['title'] as String;
      final fuzzy = params['fuzzy'] == true;
      final findAll = params['findAll'] == true;

      // 获取所有日记
      final now = DateTime.now();
      final startDate = DateTime(2000, 1, 1);
      final endDate = DateTime(now.year + 1, 12, 31);

      final result = await _diaryUseCase.getEntries({
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      });

      if (result.isFailure) {
        return findAll ? [] : null;
      }

      final diaries = result.dataOrNull ?? [];

      // 根据模糊匹配或精确匹配进行筛选
      final matches = diaries.where((diary) {
        final diaryTitle = diary['title'] as String? ?? '';
        if (fuzzy) {
          return diaryTitle.toLowerCase().contains(title.toLowerCase());
        } else {
          return diaryTitle == title;
        }
      }).toList();

      // 根据 findAll 参数返回结果
      if (findAll) {
        return matches;
      } else {
        return matches.isEmpty ? null : matches.first;
      }
    } catch (e) {
      debugPrint('Find diary by title error: $e');
      return params['findAll'] == true ? [] : null;
    }
  }
