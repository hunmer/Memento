import 'package:flutter/material.dart';
import '../scripts_center_plugin.dart';
import '../models/script_info.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// ScriptsCenter插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
class ScriptsCenterPromptReplacements {
  final ScriptsCenterPlugin _plugin;

  ScriptsCenterPromptReplacements(this._plugin);

  /// 获取脚本列表
  ///
  /// 参数:
  /// - enabled: 启用状态 (all/enabled/disabled, 默认all)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, enabled, disabled } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getScripts(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final enabledFilter = params['enabled']?.toString() ?? 'all';

      // 2. 加载所有脚本
      final allScripts = await _plugin.scriptManager.loadAllScripts();

      // 3. 根据启用状态筛选
      List<ScriptInfo> filteredScripts;
      switch (enabledFilter.toLowerCase()) {
        case 'enabled':
          filteredScripts = allScripts.where((s) => s.enabled).toList();
          break;
        case 'disabled':
          filteredScripts = allScripts.where((s) => !s.enabled).toList();
          break;
        case 'all':
        default:
          filteredScripts = allScripts;
      }

      // 4. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final scriptsJson = filteredScripts.map((s) => s.toJson()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          scriptsJson,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertScriptsByMode(filteredScripts, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取脚本列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取脚本列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取脚本详情
  ///
  /// 参数:
  /// - scriptId: 脚本ID (必需)
  /// - includeCode: 是否包含脚本代码 (true/false, 默认false)
  ///
  /// 返回格式: 脚本完整信息的JSON
  Future<String> getScriptDetail(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final scriptId = params['scriptId']?.toString();
      if (scriptId == null || scriptId.isEmpty) {
        return FieldUtils.toJsonString({
          'error': '缺少必需参数: scriptId',
        });
      }

      final includeCode = params['includeCode']?.toString().toLowerCase() == 'true';

      // 2. 加载所有脚本并查找目标脚本
      final allScripts = await _plugin.scriptManager.loadAllScripts();
      final script = allScripts.where((s) => s.id == scriptId).firstOrNull;

      if (script == null) {
        return FieldUtils.toJsonString({
          'error': '脚本不存在: $scriptId',
        });
      }

      // 3. 构建详情数据
      final detail = {
        'id': script.id,
        'name': script.name,
        'version': script.version,
        'desc': script.description,
        'author': script.author,
        'icon': script.icon,
        'enabled': script.enabled,
        'type': script.type,
        'hasTriggers': script.hasTriggers,
        'hasInputs': script.hasInputs,
        'created': FieldUtils.formatDateTime(script.createdAt),
        'updated': FieldUtils.formatDateTime(script.updatedAt),
      };

      // 添加触发器信息
      if (script.triggers.isNotEmpty) {
        detail['triggers'] = script.triggers.map((t) => {
          'event': t.event,
          if (t.delay != null) 'delay': t.delay,
        }).toList();
      }

      // 添加输入参数信息
      if (script.inputs.isNotEmpty) {
        detail['inputs'] = script.inputs.map((i) => i.toJson()).toList();
      }

      // 可选：包含脚本代码
      if (includeCode) {
        final code = await _plugin.scriptManager.getScriptCode(scriptId);
        if (code != null) {
          detail['code'] = code;
        }
      }

      return FieldUtils.toJsonString(detail);
    } catch (e) {
      debugPrint('获取脚本详情失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取脚本详情时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取脚本执行历史
  ///
  /// 参数:
  /// - scriptId: 脚本ID (可选，留空则获取所有脚本的历史)
  /// - limit: 返回数量限制 (默认10)
  ///
  /// 返回格式: 执行历史记录列表
  Future<String> getExecutionHistory(Map<String, dynamic> params) async {
    try {
      // 注意: 当前 ScriptExecutor 不存储执行历史
      // 这是一个占位实现，需要在 ScriptExecutor 中添加历史记录功能

      return FieldUtils.toJsonString({
        'error': '执行历史功能尚未实现',
        'note': '需要在 ScriptExecutor 中添加历史记录存储功能',
      });
    } catch (e) {
      debugPrint('获取执行历史失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取执行历史时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取脚本统计信息
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD)
  ///
  /// 返回格式: 统计数据
  Future<String> getStatistics(Map<String, dynamic> params) async {
    try {
      // 加载所有脚本
      final allScripts = await _plugin.scriptManager.loadAllScripts();

      // 按类型统计
      final typeStats = <String, int>{};
      for (final script in allScripts) {
        typeStats[script.type] = (typeStats[script.type] ?? 0) + 1;
      }

      // 按作者统计
      final authorStats = <String, int>{};
      for (final script in allScripts) {
        authorStats[script.author] = (authorStats[script.author] ?? 0) + 1;
      }

      // 构建完整统计数据
      final stats = <String, dynamic>{
        'total': allScripts.length,
        'enabled': allScripts.where((s) => s.enabled).length,
        'disabled': allScripts.where((s) => !s.enabled).length,
        'withTriggers': allScripts.where((s) => s.hasTriggers).length,
        'withInputs': allScripts.where((s) => s.hasInputs).length,
        'byType': typeStats,
        'byAuthor': authorStats,
      };

      return FieldUtils.toJsonString(FieldUtils.buildSummaryResponse(stats));
    } catch (e) {
      debugPrint('获取统计信息失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计信息时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取触发器配置
  ///
  /// 参数:
  /// - scriptId: 脚本ID (可选，留空则获取所有脚本的触发器)
  ///
  /// 返回格式: 触发器配置列表
  Future<String> getTriggers(Map<String, dynamic> params) async {
    try {
      final scriptId = params['scriptId']?.toString();

      // 加载所有脚本
      final allScripts = await _plugin.scriptManager.loadAllScripts();

      // 筛选有触发器的脚本
      List<ScriptInfo> scriptsWithTriggers;
      if (scriptId != null && scriptId.isNotEmpty) {
        scriptsWithTriggers = allScripts
            .where((s) => s.id == scriptId && s.hasTriggers)
            .toList();
      } else {
        scriptsWithTriggers = allScripts.where((s) => s.hasTriggers).toList();
      }

      // 构建触发器列表
      final triggers = scriptsWithTriggers.map((script) {
        return {
          'scriptId': script.id,
          'scriptName': script.name,
          'enabled': script.enabled,
          'triggers': script.triggers.map((t) => {
            'event': t.event,
            if (t.delay != null) 'delay': t.delay,
          }).toList(),
        };
      }).toList();

      return FieldUtils.toJsonString({
        'total': triggers.length,
        'triggers': triggers,
      });
    } catch (e) {
      debugPrint('获取触发器配置失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取触发器配置时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取文件夹列表
  ///
  /// 返回格式: 文件夹列表
  Future<String> getFolders(Map<String, dynamic> params) async {
    try {
      final folders = _plugin.scriptManager.folders;

      final folderList = folders.map((folder) {
        return {
          'id': folder.id,
          'name': folder.name,
          'path': folder.path,
          'enabled': folder.enabled,
          'isBuiltIn': folder.isBuiltIn,
          if (folder.icon != null) 'icon': folder.icon,
          if (folder.description != null) 'desc': folder.description,
        };
      }).toList();

      return FieldUtils.toJsonString({
        'total': folderList.length,
        'folders': folderList,
      });
    } catch (e) {
      debugPrint('获取文件夹列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取文件夹列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换脚本数据
  Map<String, dynamic> _convertScriptsByMode(
    List<ScriptInfo> scripts,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildScriptsSummary(scripts);
      case AnalysisMode.compact:
        return _buildScriptsCompact(scripts);
      case AnalysisMode.full:
        return _buildScriptsFull(scripts);
    }
  }

  /// 构建摘要数据 (summary模式)
  Map<String, dynamic> _buildScriptsSummary(List<ScriptInfo> scripts) {
    return FieldUtils.buildSummaryResponse({
      'total': scripts.length,
      'enabled': scripts.where((s) => s.enabled).length,
      'disabled': scripts.where((s) => !s.enabled).length,
      'withTriggers': scripts.where((s) => s.hasTriggers).length,
      'withInputs': scripts.where((s) => s.hasInputs).length,
    });
  }

  /// 构建紧凑数据 (compact模式)
  Map<String, dynamic> _buildScriptsCompact(List<ScriptInfo> scripts) {
    final summary = {
      'total': scripts.length,
      'enabled': scripts.where((s) => s.enabled).length,
    };

    final compactRecords = scripts.map((script) {
      final record = {
        'id': script.id,
        'name': script.name,
        'version': script.version,
        'author': script.author,
        'enabled': script.enabled,
        'type': script.type,
      };

      // 只添加非空字段
      if (script.hasTriggers) {
        record['hasTriggers'] = true;
      }
      if (script.hasInputs) {
        record['hasInputs'] = true;
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(summary, compactRecords);
  }

  /// 构建完整数据 (full模式)
  Map<String, dynamic> _buildScriptsFull(List<ScriptInfo> scripts) {
    final fullRecords = scripts.map((script) => script.toJson()).toList();
    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {}
}
