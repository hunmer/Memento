import 'dart:io';
import 'dart:convert' show json;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import '../../../core/storage/storage_manager.dart';
import '../models/script_info.dart';
import '../models/script_folder.dart';

/// 脚本加载器服务
///
/// 负责扫描脚本目录，加载JS代码和JSON元数据
class ScriptLoader {
  final StorageManager storage;

  ScriptLoader(this.storage);

  /// 获取默认scripts目录路径
  Future<String> getScriptsDirectory() async {
    if (kIsWeb) {
      return 'scripts'; // Web平台使用相对路径
    } else {
      final appDir = await StorageManager.getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'app_data', 'scripts');
    }
  }

  /// 扫描指定文件夹，返回该文件夹下的所有脚本信息
  Future<List<ScriptInfo>> scanScriptsInFolder(ScriptFolder folder) async {
    try {
      final folderPath = folder.path;

      // Web平台特殊处理
      if (kIsWeb) {
        return await _scanScriptsWeb(folderPath);
      }

      // 移动端和桌面端
      final scriptsDir = Directory(folderPath);

      // 如果目录不存在，创建它（仅对非内置文件夹）
      if (!await scriptsDir.exists()) {
        if (!folder.isBuiltIn) {
          await scriptsDir.create(recursive: true);
        }
        return [];
      }

      final List<ScriptInfo> scripts = [];

      // 遍历子目录
      await for (var entity in scriptsDir.list()) {
        if (entity is Directory) {
          final scriptId = path.basename(entity.path);
          try {
            final scriptInfo = await loadScriptMetadata(scriptId, folderPath);
            if (scriptInfo != null) {
              scripts.add(scriptInfo);
            }
          } catch (e) {
            print('⚠️ 加载脚本失败: $scriptId, 错误: $e');
          }
        }
      }

      return scripts;
    } catch (e) {
      print('❌ 扫描脚本文件夹失败: ${folder.name}, 错误: $e');
      return [];
    }
  }

  /// 扫描scripts目录，返回所有脚本信息（已废弃，建议使用 scanScriptsInFolder）
  @Deprecated('使用 scanScriptsInFolder 代替')
  Future<List<ScriptInfo>> scanScripts() async {
    try {
      final scriptsPath = await getScriptsDirectory();

      // Web平台特殊处理
      if (kIsWeb) {
        return await _scanScriptsWeb(scriptsPath);
      }

      // 移动端和桌面端
      final scriptsDir = Directory(scriptsPath);

      // 如果目录不存在，创建它
      if (!await scriptsDir.exists()) {
        await scriptsDir.create(recursive: true);
        return [];
      }

      final List<ScriptInfo> scripts = [];

      // 遍历子目录
      await for (var entity in scriptsDir.list()) {
        if (entity is Directory) {
          final scriptId = path.basename(entity.path);
          try {
            final scriptInfo = await loadScriptMetadata(scriptId, scriptsPath);
            if (scriptInfo != null) {
              scripts.add(scriptInfo);
            }
          } catch (e) {
            print('⚠️ 加载脚本失败: $scriptId, 错误: $e');
          }
        }
      }

      return scripts;
    } catch (e) {
      print('❌ 扫描脚本目录失败: $e');
      return [];
    }
  }

  /// 加载内置脚本的元数据
  Future<ScriptInfo?> _loadBuiltInScriptMetadata(
    String scriptId,
    String assetsPath,
  ) async {
    try {
      final metadataPath = '$assetsPath/${scriptId}_metadata.json';

      // 从 assets 加载 JSON 文件
      final jsonString = await rootBundle.loadString(metadataPath);
      final jsonData = json.decode(jsonString);

      if (jsonData is! Map<String, dynamic>) {
        print('⚠️ 无效的元数据格式: $scriptId');
        return null;
      }

      // 创建 ScriptInfo 对象
      return ScriptInfo.fromJson(
        jsonData,
        id: scriptId,
        path: '$assetsPath/$scriptId',
      );
    } catch (e) {
      print('❌ 加载内置脚本元数据失败: $scriptId, 错误: $e');
      return null;
    }
  }

  /// Web平台扫描脚本（使用索引文件）
  Future<List<ScriptInfo>> _scanScriptsWeb(String scriptsPath) async {
    try {
      // Web平台需要维护一个scripts索引文件
      final indexData = await storage.readJson('$scriptsPath/index.json', []);
      if (indexData is! List) return [];

      final List<ScriptInfo> scripts = [];
      for (final scriptId in indexData) {
        try {
          final scriptInfo = await loadScriptMetadata(scriptId as String);
          if (scriptInfo != null) {
            scripts.add(scriptInfo);
          }
        } catch (e) {
          print('⚠️ Web加载脚本失败: $scriptId, 错误: $e');
        }
      }

      return scripts;
    } catch (e) {
      print('❌ Web扫描脚本失败: $e');
      return [];
    }
  }

  /// 加载单个脚本的元数据
  Future<ScriptInfo?> loadScriptMetadata(
    String scriptId, [
    String? basePath,
  ]) async {
    try {
      final scriptsPath = basePath ?? await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);
      final metadataPath = path.join(scriptPath, 'metadata.json');

      // 检查metadata.json是否存在
      if (!await storage.fileExists(metadataPath)) {
        print('⚠️ 元数据文件不存在: $metadataPath');
        return null;
      }

      // 读取并解析JSON
      final jsonData = await storage.readJson(metadataPath);
      if (jsonData == null || jsonData is! Map<String, dynamic>) {
        print('⚠️ 无效的元数据格式: $scriptId');
        return null;
      }

      // 创建ScriptInfo对象
      return ScriptInfo.fromJson(jsonData, id: scriptId, path: scriptPath);
    } catch (e) {
      print('❌ 加载脚本元数据失败: $scriptId, 错误: $e');
      return null;
    }
  }

  /// 读取脚本代码
  Future<String?> loadScriptCode(String scriptId) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);
      final codePath = path.join(scriptPath, 'script.js');

      // 检查script.js是否存在
      if (!await storage.fileExists(codePath)) {
        print('⚠️ 脚本文件不存在: $codePath');
        return null;
      }

      // 读取代码内容
      return await storage.readString(codePath);
    } catch (e) {
      print('❌ 加载脚本代码失败: $scriptId, 错误: $e');
      return null;
    }
  }

  /// 保存脚本元数据
  Future<void> saveScriptMetadata(String scriptId, ScriptInfo info) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);
      final metadataPath = path.join(scriptPath, 'metadata.json');

      // 确保目录存在
      await _ensureScriptDirectoryExists(scriptPath);

      // 更新修改时间
      final updatedInfo = info.copyWith(updatedAt: DateTime.now());

      // 写入JSON
      await storage.writeJson(metadataPath, updatedInfo.toJson());

      print('✅ 保存脚本元数据成功: $scriptId');
    } catch (e) {
      print('❌ 保存脚本元数据失败: $scriptId, 错误: $e');
      rethrow;
    }
  }

  /// 保存脚本代码
  Future<void> saveScriptCode(String scriptId, String code) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);
      final codePath = path.join(scriptPath, 'script.js');

      // 确保目录存在
      await _ensureScriptDirectoryExists(scriptPath);

      // 写入代码
      await storage.writeString(codePath, code);

      print('✅ 保存脚本代码成功: $scriptId');
    } catch (e) {
      print('❌ 保存脚本代码失败: $scriptId, 错误: $e');
      rethrow;
    }
  }

  /// 删除脚本
  Future<void> deleteScript(String scriptId) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);

      if (kIsWeb) {
        // Web平台删除文件
        await storage.deleteFile(path.join(scriptPath, 'metadata.json'));
        await storage.deleteFile(path.join(scriptPath, 'script.js'));

        // 更新索引
        await _removeFromWebIndex(scriptId);
      } else {
        // 移动端和桌面端删除目录
        final scriptDir = Directory(scriptPath);
        if (await scriptDir.exists()) {
          await scriptDir.delete(recursive: true);
        }
      }

      print('✅ 删除脚本成功: $scriptId');
    } catch (e) {
      print('❌ 删除脚本失败: $scriptId, 错误: $e');
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
      final scriptsPath = await getScriptsDirectory();
      final scriptPath = path.join(scriptsPath, scriptId);

      // 检查是否已存在
      if (await _scriptExists(scriptPath)) {
        throw Exception('脚本已存在: $scriptId');
      }

      // 创建ScriptInfo
      final scriptInfo = ScriptInfo(
        id: scriptId,
        path: scriptPath,
        name: name,
        version: version,
        description: description,
        icon: icon,
        author: author,
        enabled: true,
        type: 'module',
        triggers: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 保存元数据
      await saveScriptMetadata(scriptId, scriptInfo);

      // 创建空的script.js
      await saveScriptCode(scriptId, _getDefaultScriptTemplate(name));

      // Web平台更新索引
      if (kIsWeb) {
        await _addToWebIndex(scriptId);
      }

      print('✅ 创建脚本成功: $scriptId');
      return scriptInfo;
    } catch (e) {
      print('❌ 创建脚本失败: $scriptId, 错误: $e');
      rethrow;
    }
  }

  /// 检查脚本是否存在
  Future<bool> _scriptExists(String scriptPath) async {
    if (kIsWeb) {
      return await storage.fileExists('$scriptPath/metadata.json');
    } else {
      return await Directory(scriptPath).exists();
    }
  }

  /// 确保脚本目录存在
  Future<void> _ensureScriptDirectoryExists(String scriptPath) async {
    if (!kIsWeb) {
      final dir = Directory(scriptPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Web平台：添加到索引文件
  Future<void> _addToWebIndex(String scriptId) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final indexData =
          await storage.readJson('$scriptsPath/index.json', []) as List;

      if (!indexData.contains(scriptId)) {
        indexData.add(scriptId);
        await storage.writeJson('$scriptsPath/index.json', indexData);
      }
    } catch (e) {
      print('⚠️ 更新Web索引失败: $e');
    }
  }

  /// Web平台：从索引文件移除
  Future<void> _removeFromWebIndex(String scriptId) async {
    try {
      final scriptsPath = await getScriptsDirectory();
      final indexData =
          await storage.readJson('$scriptsPath/index.json', []) as List;

      indexData.remove(scriptId);
      await storage.writeJson('$scriptsPath/index.json', indexData);
    } catch (e) {
      print('⚠️ 更新Web索引失败: $e');
    }
  }

  /// 获取默认脚本模板
  String _getDefaultScriptTemplate(String name) {
    return '''// $name
// 创建时间: ${DateTime.now().toIso8601String()}

(async function() {
  // 获取传入参数
  const params = typeof args !== 'undefined' ? args : {};

  log('脚本开始执行: $name', 'info');

  try {
    // 在这里编写你的脚本逻辑

    // 示例：访问存储
    // const data = await storage.get('my_key');
    // await storage.set('my_key', { value: 'Hello' });

    // 示例：触发事件
    // emit('my_custom_event', { message: 'Hello from script' });

    // 示例：调用其他脚本
    // const result = await runScript('other_script', { param1: 'value' });

    log('脚本执行完成', 'info');
    return { success: true, message: '执行成功' };
  } catch (error) {
    log('脚本执行失败: ' + error, 'error');
    return { success: false, error: error.toString() };
  }
})();
''';
  }
}
