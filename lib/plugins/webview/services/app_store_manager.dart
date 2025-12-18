import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:Memento/core/storage/storage_manager.dart';
import '../models/app_store_models.dart';
import '../services/card_manager.dart';

/// 应用商场管理器
///
/// 负责：
/// - 源配置管理（添加、删除、切换）
/// - 应用列表获取与缓存
/// - 搜索与过滤
/// - 已安装应用状态追踪
class AppStoreManager extends ChangeNotifier {
  final StorageManager _storage;
  final CardManager _cardManager;
  final http.Client _httpClient;

  // 存储键
  static const String _sourcesKey = 'webview_app_sources';

  // 状态
  List<AppStoreSource> _sources = [];
  AppStoreSource? _currentSource;
  List<MiniApp> _apps = [];
  Map<String, InstalledApp> _installedApps = {}; // appId -> InstalledApp
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppStoreSource> get sources => List.unmodifiable(_sources);
  AppStoreSource? get currentSource => _currentSource;
  List<MiniApp> get apps => List.unmodifiable(_apps);
  Map<String, InstalledApp> get installedApps =>
      Map.unmodifiable(_installedApps);
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppStoreManager({
    required StorageManager storage,
    required CardManager cardManager,
  }) : _storage = storage,
       _cardManager = cardManager,
       _httpClient = http.Client();

  /// 初始化
  Future<void> initialize() async {
    await _loadSources();
    await _loadInstalledApps();

    if (_sources.isEmpty) {
      await _addDefaultSource();
    }

    // 设置当前源为默认源或第一个源
    _currentSource = _sources.firstWhere(
      (s) => s.isDefault,
      orElse: () => _sources.first,
    );

    // 获取应用列表
    await fetchApps();
  }

  /// 添加默认源
  Future<void> _addDefaultSource() async {
    final localSource = AppStoreSource(
      id: const Uuid().v4(),
      name: '本地开发仓库',
      url: 'http://127.0.0.1:8080/apps.json',
      baseUrl: 'http://127.0.0.1:8080',
      createdAt: DateTime.now(),
    );
    await addSource(localSource);

    final defaultSource = AppStoreSource(
      id: const Uuid().v4(),
      name: '网络仓库',
      url:
          'https://gitee.com/neysummer2000/memento/raw/master/mini_apps_store/apps.json',
      baseUrl:
          'https://gitee.com/neysummer2000/memento/raw/master/mini_apps_store',
      isDefault: true,
      createdAt: DateTime.now(),
    );
    await addSource(defaultSource);
  }

  // ==================== 源管理 ====================

  /// 添加源
  Future<void> addSource(AppStoreSource source) async {
    _sources.add(source);
    await _saveSources();
    notifyListeners();
  }

  /// 更新源
  Future<void> updateSource(AppStoreSource source) async {
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
        await fetchApps();
      } else {
        _apps = [];
      }
    }

    notifyListeners();
  }

  /// 切换源
  Future<void> switchSource(String sourceId) async {
    final source = _sources.firstWhere((s) => s.id == sourceId);
    _currentSource = source;
    await fetchApps();
    notifyListeners();
  }

  // ==================== 应用管理 ====================

  /// 获取应用列表
  Future<void> fetchApps() async {
    if (_currentSource == null) {
      _apps = [];
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
      _apps =
          jsonList
              .map(
                (json) => MiniApp.fromJson(
                  json as Map<String, dynamic>,
                  _currentSource!.id,
                ),
              )
              .toList();

      // 更新已安装状态
      for (var app in _apps) {
        final installed = _installedApps[app.id];
        if (installed != null) {
          app.isInstalled = true;
          app.installedVersion = installed.version;
        }
      }

      // 更新源的最后获取时间和应用数量
      _currentSource = _currentSource!.copyWith(
        lastFetchedAt: DateTime.now(),
        appCount: _apps.length,
      );
      await updateSource(_currentSource!);
    } on SocketException {
      _error = 'Network error: Please check your connection';
    } on http.ClientException {
      _error = 'Network error: Failed to connect';
    } on FormatException {
      _error = 'Invalid JSON format in source data';
    } catch (e) {
      _error = 'Failed to fetch apps: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索应用（支持标题、描述、标签过滤）
  List<MiniApp> searchApps(
    String query, {
    List<String>? tags,
    bool? installedOnly,
  }) {
    var result = _apps;

    // 搜索词过滤
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result =
          result.where((app) {
            return app.title.toLowerCase().contains(lowerQuery) ||
                (app.desc?.toLowerCase().contains(lowerQuery) ?? false) ||
                app.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
          }).toList();
    }

    // 标签过滤
    if (tags != null && tags.isNotEmpty) {
      result =
          result.where((app) {
            return tags.any((tag) => app.tags.contains(tag));
          }).toList();
    }

    // 已安装过滤
    if (installedOnly == true) {
      result = result.where((app) => app.isInstalled).toList();
    }

    return result;
  }

  /// 获取所有标签
  List<String> getAllTags() {
    final tagSet = <String>{};
    for (var app in _apps) {
      tagSet.addAll(app.tags);
    }
    final tags = tagSet.toList();
    tags.sort();
    return tags;
  }

  // ==================== 已安装应用管理 ====================

  /// 检查应用是否已安装
  bool isAppInstalled(String appId) {
    return _installedApps.containsKey(appId);
  }

  /// 获取已安装应用信息
  InstalledApp? getInstalledApp(String appId) {
    return _installedApps[appId];
  }

  /// 标记应用为已安装
  Future<void> markAsInstalled(
    String appId,
    String version,
    String sourceId,
    String cardId,
  ) async {
    _installedApps[appId] = InstalledApp(
      appId: appId,
      version: version,
      installedAt: DateTime.now(),
      sourceId: sourceId,
      cardId: cardId,
    );

    // 更新应用列表中的状态
    final app = _apps.cast<MiniApp?>().firstWhere(
      (a) => a?.id == appId,
      orElse: () => null,
    );
    if (app != null) {
      app.isInstalled = true;
      app.installedVersion = version;
      notifyListeners();
    }
  }

  /// 卸载应用
  Future<void> uninstallApp(String appId) async {
    final installed = _installedApps[appId];
    if (installed == null) return;

    try {
      // 删除卡片（容错处理）
      try {
        await _cardManager.deleteCard(installed.cardId);
      } catch (e) {
        debugPrint('Card already deleted or not found: $e');
      }

      // 删除文件目录
      final appDir = await _getAppDirectory(appId);
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }

      // 更新状态
      _installedApps.remove(appId);

      // 更新应用列表中的状态
      final app = _apps.cast<MiniApp?>().firstWhere(
        (a) => a?.id == appId,
        orElse: () => null,
      );
      if (app != null) {
        app.isInstalled = false;
        app.installedVersion = null;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to uninstall app: $e');
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
                      AppStoreSource.fromJson(item as Map<String, dynamic>),
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

  /// 加载已安装应用
  ///
  /// 通过遍历 http_server 目录的子文件夹来确定实际已安装的应用
  /// 从 CardManager 中获取关联的卡片信息
  Future<void> _loadInstalledApps() async {
    try {
      // 1. 获取 http_server 目录
      final appDataDir = await _storage.getApplicationDataDirectory();
      final pluginPath = _storage.getPluginStoragePath('webview');
      final httpServerDir = Directory(
        path.join(appDataDir.path, pluginPath, 'http_server'),
      );

      // 2. 如果目录不存在，创建它
      if (!await httpServerDir.exists()) {
        await httpServerDir.create(recursive: true);
        _installedApps = {};
        return;
      }

      // 3. 获取所有卡片（用于查找关联信息）
      final cards = _cardManager.getAllCards();

      // 4. 遍历子文件夹，每个文件夹名即为 appId
      _installedApps = {};
      await for (final entity in httpServerDir.list()) {
        if (entity is Directory) {
          final appId = path.basename(entity.path);

          // 尝试从对应的 WebViewCard 中获取信息
          try {
            final matchedCard = cards.firstWhere(
              (card) => card.url.contains('/$appId/'),
              orElse: () => throw Exception('Card not found'),
            );

            _installedApps[appId] = InstalledApp(
              appId: appId,
              version: 'unknown', // 版本信息不再持久化
              installedAt: matchedCard.createdAt,
              sourceId: '', // 来源信息不再持久化
              cardId: matchedCard.id,
            );
          } catch (e) {
            // 如果找不到对应的卡片，创建最小化的对象
            debugPrint('Cannot find card for $appId: $e');
            _installedApps[appId] = InstalledApp(
              appId: appId,
              version: 'unknown',
              installedAt: entity.statSync().modified,
              sourceId: '',
              cardId: '',
            );
          }
        }
      }

      debugPrint(
        'Loaded ${_installedApps.length} installed apps from filesystem',
      );
    } catch (e) {
      debugPrint('Failed to load installed apps from filesystem: $e');
      _installedApps = {};
    }
  }

  // ==================== 辅助方法 ====================

  /// 获取应用目录
  Future<Directory> _getAppDirectory(String appId) async {
    // 使用与 card_manager 一致的路径获取方式
    final appDataDir = await _storage.getApplicationDataDirectory();
    final pluginPath = _storage.getPluginStoragePath('webview');
    final httpRoot = path.join(appDataDir.path, pluginPath, 'http_server');
    // 构建完整路径：app_data/webview/http_server/appId
    return Directory(path.join(httpRoot, appId));
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
