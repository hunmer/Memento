import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:Memento/plugins/scripts_center/models/script_info.dart';
import 'package:Memento/plugins/scripts_center/models/script_folder.dart';
import 'package:Memento/plugins/scripts_center/models/script_input.dart';
import 'package:Memento/plugins/scripts_center/models/script_trigger.dart';
import 'script_loader.dart';

/// 脚本管理器服务
///
/// 提供脚本CRUD操作和状态管理，使用ChangeNotifier通知UI更新
class ScriptManager extends ChangeNotifier {
  final ScriptLoader loader;

  /// 所有脚本文件夹列表
  List<ScriptFolder> _folders = [];

  /// 当前选中的文件夹
  ScriptFolder? _currentFolder;

  /// 所有脚本列表
  List<ScriptInfo> _scripts = [];

  /// 脚本代码缓存 (scriptId -> code)
  final Map<String, String> _codeCache = {};

  /// 是否正在加载
  bool _isLoading = false;

  /// 最后一次错误信息
  String? _lastError;

  ScriptManager(this.loader);

  /// 获取所有脚本文件夹
  List<ScriptFolder> get folders => List.unmodifiable(_folders);

  /// 获取当前选中的文件夹
  ScriptFolder? get currentFolder => _currentFolder;

  /// 获取所有脚本
  List<ScriptInfo> get scripts => List.unmodifiable(_scripts);

  /// 获取已启用的脚本
  List<ScriptInfo> getEnabledScripts() {
    return _scripts.where((script) => script.enabled).toList();
  }

  /// 获取已禁用的脚本
  List<ScriptInfo> getDisabledScripts() {
    return _scripts.where((script) => !script.enabled).toList();
  }

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 最后一次错误
  String? get lastError => _lastError;

  /// 脚本数量
  int get scriptCount => _scripts.length;

  /// 已启用脚本数量
  int get enabledScriptCount => getEnabledScripts().length;

  /// 初始化文件夹列表
  Future<void> initializeFolders(List<ScriptFolder> folders) async {
    _folders = folders;

    // 设置默认选中第一个文件夹
    if (_folders.isNotEmpty) {
      _currentFolder = _folders.first;
    }

    notifyListeners();
  }

  /// 设置当前文件夹
  Future<void> setCurrentFolder(ScriptFolder folder) async {
    if (!_folders.contains(folder)) {
      throw Exception('文件夹不存在: ${folder.name}');
    }

    _currentFolder = folder;
    notifyListeners();

    // 重新加载当前文件夹的脚本
    await loadScripts();
  }

  /// 添加新文件夹
  Future<void> addFolder(ScriptFolder folder) async {
    if (_folders.any((f) => f.id == folder.id)) {
      throw Exception('文件夹ID已存在: ${folder.id}');
    }

    _folders.add(folder);
    notifyListeners();

    print('✅ 添加文件夹: ${folder.name}');
  }

  /// 删除文件夹（不能删除内置文件夹）
  Future<void> removeFolder(String folderId) async {
    final folder = _folders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => throw Exception('文件夹不存在: $folderId'),
    );

    if (folder.isBuiltIn) {
      throw Exception('不能删除内置文件夹');
    }

    _folders.removeWhere((f) => f.id == folderId);

    // 如果删除的是当前文件夹，切换到第一个文件夹
    if (_currentFolder?.id == folderId && _folders.isNotEmpty) {
      _currentFolder = _folders.first;
      await loadScripts();
    }

    notifyListeners();
    print('✅ 删除文件夹: ${folder.name}');
  }

  /// 更新文件夹
  Future<void> updateFolder(ScriptFolder folder) async {
    final index = _folders.indexWhere((f) => f.id == folder.id);
    if (index == -1) {
      throw Exception('文件夹不存在: ${folder.id}');
    }

    _folders[index] = folder;
    notifyListeners();

    print('✅ 更新文件夹: ${folder.name}');
  }

  /// 加载当前文件夹的脚本
  Future<void> loadScripts() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // 如果没有选中文件夹，加载空列表
      if (_currentFolder == null) {
        _scripts = [];
        print('⚠️ 未选中任何文件夹');
        return;
      }

      // 加载当前文件夹的脚本
      _scripts = await loader.scanScriptsInFolder(_currentFolder!);

      // 按名称排序
      _scripts.sort((a, b) => a.name.compareTo(b.name));

      // 同步本地文件代码
      await _syncLocalScriptFiles();

      print('✅ 从文件夹 ${_currentFolder!.name} 加载了 ${_scripts.length} 个脚本');
    } catch (e) {
      _lastError = '加载脚本失败: $e';
      print('❌ $_lastError');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 同步本地脚本文件代码
  ///
  /// 遍历所有脚本，如果脚本配置了 localScriptPath，
  /// 则从本地文件同步最新代码到脚本（方便调试）
  Future<void> _syncLocalScriptFiles() async {
    for (final script in _scripts) {
      if (script.localScriptPath == null || script.localScriptPath!.isEmpty) {
        continue;
      }

      try {
        final file = File(script.localScriptPath!);
        if (!await file.exists()) {
          print('⚠️ 本地脚本文件不存在: ${script.localScriptPath}');
          continue;
        }

        // 读取本地文件内容
        final localCode = await file.readAsString();

        // 获取当前脚本代码
        final currentCode = await loader.loadScriptCode(script.id);

        // 如果代码不同，则同步
        if (currentCode != localCode) {
          await loader.saveScriptCode(script.id, localCode);
          // 清除缓存，确保下次加载使用新代码
          _codeCache.remove(script.id);
          print('🔄 已同步本地文件代码: ${script.id} <- ${script.localScriptPath}');
        }
      } catch (e) {
        print('⚠️ 同步本地脚本文件失败 ${script.id}: $e');
      }
    }
  }

  /// 加载所有文件夹的所有脚本（用于获取所有启用的脚本）
  Future<List<ScriptInfo>> loadAllScripts() async {
    final allScripts = <ScriptInfo>[];

    for (final folder in _folders.where((f) => f.enabled)) {
      try {
        final scripts = await loader.scanScriptsInFolder(folder);
        allScripts.addAll(scripts);
      } catch (e) {
        print('⚠️ 加载文件夹 ${folder.name} 失败: $e');
      }
    }

    return allScripts;
  }

  /// 根据ID获取脚本
  ScriptInfo? getScriptById(String id) {
    try {
      return _scripts.firstWhere((script) => script.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取脚本代码（带缓存）
  Future<String?> getScriptCode(String scriptId) async {
    // 先查缓存
    if (_codeCache.containsKey(scriptId)) {
      return _codeCache[scriptId];
    }

    // 从文件加载
    final code = await loader.loadScriptCode(scriptId);
    if (code != null) {
      _codeCache[scriptId] = code;
    }

    return code;
  }

  /// 切换脚本启用状态
  Future<void> toggleScript(String scriptId, bool enabled) async {
    try {
      final script = getScriptById(scriptId);
      if (script == null) {
        throw Exception('脚本不存在: $scriptId');
      }

      // 更新状态
      final updatedScript = script.copyWith(
        enabled: enabled,
        updatedAt: DateTime.now(),
      );

      // 保存到文件
      await loader.saveScriptMetadata(scriptId, updatedScript);

      // 更新内存中的脚本信息
      final index = _scripts.indexWhere((s) => s.id == scriptId);
      if (index != -1) {
        _scripts[index] = updatedScript;
        notifyListeners();
      }

      print('✅ ${enabled ? "启用" : "禁用"}脚本: $scriptId');
    } catch (e) {
      _lastError = '切换脚本状态失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 保存脚本元数据
  Future<void> saveScriptMetadata(String scriptId, ScriptInfo info) async {
    try {
      // 保存到文件
      await loader.saveScriptMetadata(scriptId, info);

      // 更新内存中的脚本信息
      final index = _scripts.indexWhere((s) => s.id == scriptId);
      if (index != -1) {
        _scripts[index] = info;
      } else {
        _scripts.add(info);
      }

      notifyListeners();
      print('✅ 保存脚本元数据成功: $scriptId');
    } catch (e) {
      _lastError = '保存脚本元数据失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 保存脚本代码
  Future<void> saveScriptCode(String scriptId, String code) async {
    try {
      // 保存到文件
      await loader.saveScriptCode(scriptId, code);

      // 更新缓存
      _codeCache[scriptId] = code;

      // 更新脚本的修改时间
      final script = getScriptById(scriptId);
      if (script != null) {
        await saveScriptMetadata(
          scriptId,
          script.copyWith(updatedAt: DateTime.now()),
        );
      }

      print('✅ 保存脚本代码成功: $scriptId');
    } catch (e) {
      _lastError = '保存脚本代码失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 删除脚本
  Future<void> deleteScript(String scriptId) async {
    try {
      // 从文件删除
      await loader.deleteScript(scriptId);

      // 从内存移除
      _scripts.removeWhere((script) => script.id == scriptId);

      // 清除缓存
      _codeCache.remove(scriptId);

      notifyListeners();
      print('✅ 删除脚本成功: $scriptId');
    } catch (e) {
      _lastError = '删除脚本失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 创建新脚本
  Future<ScriptInfo> createScript({
    required String scriptId,
    required String name,
    String version = '1.0.0',
    String description = '',
    String icon = 'code',
    String author = 'Unknown',
  }) async {
    try {
      // 检查ID是否已存在
      if (getScriptById(scriptId) != null) {
        throw Exception('脚本ID已存在: $scriptId');
      }

      // 创建脚本
      final scriptInfo = await loader.createScript(
        scriptId: scriptId,
        name: name,
        version: version,
        description: description,
        icon: icon,
        author: author,
      );

      // 添加到列表
      _scripts.add(scriptInfo);
      _scripts.sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
      print('✅ 创建脚本成功: $scriptId');

      return scriptInfo;
    } catch (e) {
      _lastError = '创建脚本失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 刷新单个脚本
  Future<void> refreshScript(String scriptId) async {
    try {
      final scriptInfo = await loader.loadScriptMetadata(scriptId);
      if (scriptInfo == null) {
        throw Exception('脚本不存在: $scriptId');
      }

      // 更新内存中的脚本信息
      final index = _scripts.indexWhere((s) => s.id == scriptId);
      if (index != -1) {
        _scripts[index] = scriptInfo;
      } else {
        _scripts.add(scriptInfo);
      }

      // 清除代码缓存，强制重新加载
      _codeCache.remove(scriptId);

      notifyListeners();
      print('✅ 刷新脚本成功: $scriptId');
    } catch (e) {
      _lastError = '刷新脚本失败: $e';
      print('❌ $_lastError');
      rethrow;
    }
  }

  /// 清除所有缓存
  void clearCache() {
    _codeCache.clear();
    print('✅ 清除脚本缓存');
  }

  /// 根据类型筛选脚本
  List<ScriptInfo> getScriptsByType(String type) {
    return _scripts.where((script) => script.type == type).toList();
  }

  /// 获取有触发器的脚本
  List<ScriptInfo> getScriptsWithTriggers() {
    return _scripts.where((script) => script.hasTriggers).toList();
  }

  /// 搜索脚本
  List<ScriptInfo> searchScripts(String query) {
    if (query.isEmpty) return _scripts;

    final lowerQuery = query.toLowerCase();
    return _scripts.where((script) {
      return script.name.toLowerCase().contains(lowerQuery) ||
          script.description.toLowerCase().contains(lowerQuery) ||
          script.author.toLowerCase().contains(lowerQuery) ||
          script.id.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 导出脚本配置（用于备份）
  Map<String, dynamic> exportScriptsConfig() {
    return {
      'version': '1.0.0',
      'exportTime': DateTime.now().toIso8601String(),
      'scripts': _scripts.map((s) => s.toJson()).toList(),
    };
  }

  /// 从编辑界面的结果数据保存脚本（统一处理创建和更新）
  ///
  /// [result] - 从 ScriptEditScreen 返回的数据
  /// [existingScript] - 如果为 null 则创建新脚本，否则更新现有脚本
  Future<void> saveScriptFromEditResult(
    Map<String, dynamic> result, {
    ScriptInfo? existingScript,
  }) async {
    // 解析触发器数据
    final triggersData = result['triggers'] as List<dynamic>? ?? [];
    final triggers = triggersData
        .map((t) => ScriptTrigger.fromJson(t as Map<String, dynamic>))
        .toList();

    // 解析输入参数数据
    final inputsData = (result['inputs'] as List<dynamic>? ?? [])
        .map((e) => e as ScriptInput)
        .toList();

    if (existingScript == null) {
      // 创建新脚本
      await createScript(
        scriptId: result['id'] as String,
        name: result['name'] as String,
        description: result['description'] as String,
        version: result['version'] as String,
        icon: result['icon'] as String,
        author: result['author'] as String,
      );

      // 获取新创建的脚本并更新其他属性
      final newScript = getScriptById(result['id'] as String);
      if (newScript != null) {
        await saveScriptMetadata(
          newScript.id,
          newScript.copyWith(
            enabled: result['enabled'] as bool,
            type: result['type'] as String,
            updateUrl: result['updateUrl'] as String?,
            inputs: inputsData,
            triggers: triggers,
            localScriptPath: result['localScriptPath'] as String?,
          ),
        );

        // 保存代码
        final code = result['code'] as String? ?? '';
        if (code.isNotEmpty) {
          await saveScriptCode(newScript.id, code);
        }
      }
    } else {
      // 编辑现有脚本
      final updatedScript = existingScript.copyWith(
        name: result['name'] as String,
        description: result['description'] as String,
        version: result['version'] as String,
        icon: result['icon'] as String,
        author: result['author'] as String,
        enabled: result['enabled'] as bool,
        type: result['type'] as String,
        updateUrl: result['updateUrl'] as String?,
        inputs: inputsData,
        triggers: triggers,
        updatedAt: DateTime.now(),
        localScriptPath: result['localScriptPath'] as String?,
      );

      await saveScriptMetadata(existingScript.id, updatedScript);

      // 保存代码
      final code = result['code'] as String? ?? '';
      await saveScriptCode(existingScript.id, code);
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
