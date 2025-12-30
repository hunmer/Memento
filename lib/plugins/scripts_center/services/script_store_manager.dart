import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/core/storage/storage_manager.dart';
import 'package:Memento/plugins/scripts_center/models/script_store_models.dart';
import 'package:Memento/plugins/scripts_center/services/script_loader.dart';

/// 脚本商场管理器
///
/// 负责：
/// - 源配置管理（添加、删除、切换）
/// - 脚本列表获取与缓存
/// - 搜索与过滤
/// - 已安装脚本状态追踪
class ScriptStoreManager extends ChangeNotifier {
  final StorageManager _storage;
  final ScriptLoader _scriptLoader;
  final http.Client _httpClient;

  // 存储键
  static const String _sourcesKey = 'scripts_center_script_sources';
  static const String _installedKey = 'scripts_center_installed_scripts';

  // 状态
  List<ScriptStoreSource> _sources = [];
  ScriptStoreSource? _currentSource;
  List<ScriptStoreItem> _scripts = [];
  Map<String, InstalledScript> _installedScripts = {}; // scriptId -> InstalledScript
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ScriptStoreSource> get sources => List.unmodifiable(_sources);
  ScriptStoreSource? get currentSource => _currentSource;
  List<ScriptStoreItem> get scripts => List.unmodifiable(_scripts);
  Map<String, InstalledScript> get installedScripts =>
      Map.unmodifiable(_installedScripts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  ScriptStoreManager({
    required StorageManager storage,
    required ScriptLoader scriptLoader,
  }) : _storage = storage,
       _scriptLoader = scriptLoader,
       _httpClient = http.Client();

  /// 初始化
  Future<void> initialize() async {
    await _loadSources();
    await _loadInstalledScripts();

    if (_sources.isEmpty) {
      await _addDefaultSource();
    }

    // 设置当前源为默认源或第一个源
    _currentSource = _sources.firstWhere(
      (s) => s.isDefault,
      orElse: () => _sources.first,
    );

    // 获取脚本列表
    await fetchScripts();
  }

  /// 添加默认源
  Future<void> _addDefaultSource() async {
    final localSource = ScriptStoreSource(
      id: const Uuid().v4(),
      name: '本地开发仓库',
      url: 'http://127.0.0.1:8080/scripts/scripts.json',
      baseUrl: 'http://127.0.0.1:8080/scripts',
      createdAt: DateTime.now(),
    );
    await addSource(localSource);

    final defaultSource = ScriptStoreSource(
      id: const Uuid().v4(),
      name: '网络仓库',
      url:
          'https://gitee.com/neysummer2000/memento/raw/master/online/scripts/scripts.json',
      baseUrl: 'https://gitee.com/neysummer2000/memento/raw/master/online/scripts',
      isDefault: true,
      createdAt: DateTime.now(),
    );
    await addSource(defaultSource);
  }

  // ==================== 源管理 ====================

  /// 添加源
  Future<void> addSource(ScriptStoreSource source) async {
    _sources.add(source);
    await _saveSources();
    notifyListeners();
  }

  /// 更新源
  Future<void> updateSource(ScriptStoreSource source) async {
    final index = _sources.indexWhere((s) => s.id == source.id);
    if (index != -1) {
      _sources[index] = source;
      await _saveSources();

      // 如果更新的是当前源，同步更新
      if (_currentSource?.id == source.id) {
        _currentSource = source;
      }

      notifyListeners();
    }
  }

  /// 删除源
  Future<void> deleteSource(String sourceId) async {
    _sources.removeWhere((s) => s.id == sourceId);
    await _saveSources();

    // 如果删除的是当前源，切换到其他源
    if (_currentSource?.id == sourceId) {
      _currentSource = _sources.isNotEmpty ? _sources.first : null;
      if (_currentSource != null) {
        await fetchScripts();
      } else {
        _scripts = [];
      }
    }

    notifyListeners();
  }

  /// 切换源
  Future<void> switchSource(String sourceId) async {
    final source = _sources.firstWhere((s) => s.id == sourceId);
    _currentSource = source;
    await fetchScripts();
    notifyListeners();
  }

  // ==================== 脚本管理 ====================

  /// 获取脚本列表
  Future<void> fetchScripts() async {
    if (_currentSource == null) {
      _scripts = [];
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _httpClient
          .get(Uri.parse(_currentSource!.url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> jsonList = json.decode(
        utf8.decode(response.bodyBytes),
      );
      _scripts =
          jsonList
              .map(
                (json) => ScriptStoreItem.fromJson(
                  json as Map<String, dynamic>,
                  _currentSource!.id,
                ),
              )
              .toList();

      // 更新已安装状态
      for (var script in _scripts) {
        final installed = _installedScripts[script.id];
        if (installed != null) {
          script.isInstalled = true;
          script.installedVersion = installed.version;
        }
      }

      // 更新源的最后获取时间和脚本数量
      _currentSource = _currentSource!.copyWith(
        lastFetchedAt: DateTime.now(),
        scriptCount: _scripts.length,
      );
      await updateSource(_currentSource!);
    } on SocketException {
      _error = 'Network error: Please check your connection';
    } on http.ClientException {
      _error = 'Network error: Failed to connect';
    } on FormatException {
      _error = 'Invalid JSON format in source data';
    } catch (e) {
      _error = 'Failed to fetch scripts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索脚本（支持名称、描述、标签过滤）
  List<ScriptStoreItem> searchScripts(
    String query, {
    List<String>? tags,
    bool? installedOnly,
  }) {
    var result = _scripts;

    // 搜索词过滤
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result =
          result.where((script) {
            return script.name.toLowerCase().contains(lowerQuery) ||
                (script.description?.toLowerCase().contains(lowerQuery) ?? false) ||
                script.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          }).toList();
    }

    // 标签过滤
    if (tags != null && tags.isNotEmpty) {
      result =
          result.where((script) {
            return tags.any((tag) => script.tags.contains(tag));
          }).toList();
    }

    // 已安装过滤
    if (installedOnly == true) {
      result = result.where((script) => script.isInstalled).toList();
    }

    return result;
  }

  /// 获取所有标签
  List<String> getAllTags() {
    final tagSet = <String>{};
    for (var script in _scripts) {
      tagSet.addAll(script.tags);
    }
    final tags = tagSet.toList();
    tags.sort();
    return tags;
  }

  // ==================== 已安装脚本管理 ====================

  /// 检查脚本是否已安装
  bool isScriptInstalled(String scriptId) {
    return _installedScripts.containsKey(scriptId);
  }

  /// 获取已安装脚本信息
  InstalledScript? getInstalledScript(String scriptId) {
    return _installedScripts[scriptId];
  }

  /// 标记脚本为已安装
  Future<void> markAsInstalled(
    String scriptId,
    String version,
    String sourceId,
  ) async {
    _installedScripts[scriptId] = InstalledScript(
      scriptId: scriptId,
      version: version,
      installedAt: DateTime.now(),
      sourceId: sourceId,
    );

    // 更新脚本列表中的状态
    final script = _scripts.cast<ScriptStoreItem?>().firstWhere(
      (s) => s?.id == scriptId,
      orElse: () => null,
    );
    if (script != null) {
      script.isInstalled = true;
      script.installedVersion = version;
      notifyListeners();
    }

    await _saveInstalledScripts();
  }

  /// 卸载脚本
  Future<void> uninstallScript(String scriptId) async {
    final installed = _installedScripts[scriptId];
    if (installed == null) return;

    try {
      // 获取脚本目录
      final scriptsPath = await _scriptLoader.getScriptsDirectory();
      final scriptDir = Directory(path.join(scriptsPath, scriptId));

      // 删除脚本目录
      if (await scriptDir.exists()) {
        await scriptDir.delete(recursive: true);
      }

      // 更新状态
      _installedScripts.remove(scriptId);

      // 更新脚本列表中的状态
      final script = _scripts.cast<ScriptStoreItem?>().firstWhere(
        (s) => s?.id == scriptId,
        orElse: () => null,
      );
      if (script != null) {
        script.isInstalled = false;
        script.installedVersion = null;
      }

      await _saveInstalledScripts();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to uninstall script: $e');
    }
  }

  // ==================== 持久化方法 ====================

  /// 加载源配置
  Future<void> _loadSources() async {
    try {
      final data = await _storage.read(_sourcesKey);
      if (data != null && data is List) {
        _sources =
            data
                .map(
                  (item) =>
                      ScriptStoreSource.fromJson(item as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('Failed to load sources: $e');
    }
  }

  /// 保存源配置
  Future<void> _saveSources() async {
    try {
      final jsonList = _sources.map((s) => s.toJson()).toList();
      await _storage.write(_sourcesKey, jsonList);
    } catch (e) {
      debugPrint('Failed to save sources: $e');
    }
  }

  /// 加载已安装脚本
  Future<void> _loadInstalledScripts() async {
    try {
      final data = await _storage.read(_installedKey);
      if (data != null && data is List) {
        _installedScripts = {};
        for (var item in data) {
          final installed = InstalledScript.fromJson(item as Map<String, dynamic>);
          // 验证脚本是否真实存在
          final scriptsPath = await _scriptLoader.getScriptsDirectory();
          final scriptDir = Directory(path.join(scriptsPath, installed.scriptId));
          if (await scriptDir.exists()) {
            _installedScripts[installed.scriptId] = installed;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load installed scripts: $e');
      _installedScripts = {};
    }
  }

  /// 保存已安装脚本
  Future<void> _saveInstalledScripts() async {
    try {
      final jsonList = _installedScripts.values.map((s) => s.toJson()).toList();
      await _storage.write(_installedKey, jsonList);
    } catch (e) {
      debugPrint('Failed to save installed scripts: $e');
    }
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
