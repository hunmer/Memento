import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webdav_client/webdav_client.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/storage_manager.dart';

class WebDAVController {
  final BuildContext context;
  Client? _client;
  bool _isConnected = false;

  WebDAVController(this.context);

  bool get isConnected => _isConnected;

  // 连接到WebDAV服务器
  Future<bool> connect({
    required String url,
    required String username,
    required String password,
    required String dataPath,
  }) async {
    try {
      final client = newClient(
        url,
        user: username,
        password: password,
        debug: true,
      );

      // 测试连接
      await client.ping();

      // 确保远程数据目录存在
      try {
        await client.mkdir(dataPath);
      } catch (e) {
        // 目录可能已经存在，忽略错误
      }

      _client = client;
      _isConnected = true;

      // 保存连接信息
      final StorageManager storageManager = StorageManager();
      await storageManager.writeJson('webdav_config.json', {
        'url': url,
        'username': username,
        'password': password,
        'dataPath': dataPath,
        'isConnected': true,
      });

      return true;
    } catch (e) {
      debugPrint('WebDAV连接失败: $e');
      _isConnected = false;
      return false;
    }
  }

  // 断开WebDAV连接
  Future<void> disconnect() async {
    _client = null;
    _isConnected = false;
    
    final StorageManager storageManager = StorageManager();
    await storageManager.writeJson('webdav_config.json', {
      'isConnected': false,
    });
  }

  // 从本地同步到WebDAV
  Future<bool> syncLocalToWebDAV() async {
    if (!_isConnected || _client == null) {
      return false;
    }

    try {
      final StorageManager storageManager = StorageManager();
      final config = await storageManager.readJson('webdav_config.json');
      final remotePath = config['dataPath'] as String;
      
      // 获取本地应用数据目录
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/app_data';
      
      // 递归上传本地文件到WebDAV
      return await _uploadDirectory(Directory(localPath), '', remotePath);
    } catch (e) {
      debugPrint('同步本地到WebDAV失败: $e');
      return false;
    }
  }

  // 递归上传目录
  Future<bool> _uploadDirectory(Directory dir, String relativePath, String remotePath) async {
    try {
      final entities = dir.listSync();
      
      for (var entity in entities) {
        final name = entity.path.split('/').last;
        final currentRelativePath = relativePath.isEmpty ? name : '$relativePath/$name';
        final remoteFilePath = '$remotePath/$currentRelativePath';
        
        if (entity is File) {
          // 上传文件
          await _client!.writeFromFile(entity.path, remoteFilePath);
        } else if (entity is Directory) {
          // 创建远程目录
          try {
            await _client!.mkdir(remoteFilePath);
          } catch (e) {
            // 目录可能已存在，忽略错误
          }
          
          // 递归处理子目录
          await _uploadDirectory(entity, currentRelativePath, remotePath);
        }
      }
      return true;
    } catch (e) {
      debugPrint('上传目录失败: $e');
      return false;
    }
  }

  // 从WebDAV同步到本地
  Future<bool> syncWebDAVToLocal() async {
    if (!_isConnected || _client == null) {
      return false;
    }

    try {
      final StorageManager storageManager = StorageManager();
      final config = await storageManager.readJson('webdav_config.json');
      final remotePath = config['dataPath'] as String;
      
      // 获取本地应用数据目录
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/app_data';
      
      // 递归下载WebDAV文件到本地
      return await _downloadDirectory(remotePath, Directory(localPath));
    } catch (e) {
      debugPrint('同步WebDAV到本地失败: $e');
      return false;
    }
  }

  // 递归下载目录
  Future<bool> _downloadDirectory(String remotePath, Directory localDir) async {
    try {
      // 确保本地目录存在
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      
      // 列出远程目录内容
      final files = await _client!.readDir(remotePath);
      
      for (var file in files) {
        final name = file.name;
        if (name == null) continue;
        
        final localFilePath = '${localDir.path}/$name';
        final remoteFilePath = '$remotePath/$name';
        
        if (file.isDir ?? false) {
          // 处理目录
          final newLocalDir = Directory(localFilePath);
          await _downloadDirectory(remoteFilePath, newLocalDir);
        } else {
          // 下载文件
          await _client!.writeToFile(remoteFilePath, localFilePath);
        }
      }
      return true;
    } catch (e) {
      debugPrint('下载目录失败: $e');
      return false;
    }
  }

  // 检查WebDAV连接配置
  Future<Map<String, dynamic>?> getWebDAVConfig() async {
    try {
      final StorageManager storageManager = StorageManager();
      if (await storageManager.fileExists('webdav_config.json')) {
        final config = await storageManager.readJson('webdav_config.json');
        if (config['isConnected'] == true) {
          // 如果有保存的连接，尝试重新连接
          final connected = await connect(
            url: config['url'],
            username: config['username'],
            password: config['password'],
            dataPath: config['dataPath'],
          );
          
          if (connected) {
            return config;
          }
        }
        return config;
      }
    } catch (e) {
      debugPrint('获取WebDAV配置失败: $e');
    }
    return null;
  }
}