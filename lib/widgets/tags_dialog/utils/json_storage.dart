import 'dart:convert';
import 'dart:io';
import 'package:Memento/widgets/tags_dialog/models/models.dart';

/// JSON 文件存储工具
class JsonStorage {
  /// 文件路径
  final String filePath;

  JsonStorage(this.filePath);

  /// 加载数据
  Future<List<TagGroupWithTags>?> load() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return null;
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((e) => TagGroupWithTags.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('加载 JSON 文件失败: $e');
      return null;
    }
  }

  /// 保存数据
  Future<bool> save(List<TagGroupWithTags> groups) async {
    try {
      final file = File(filePath);
      final jsonList = groups.map((e) => e.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      // 确保目录存在
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('保存 JSON 文件失败: $e');
      return false;
    }
  }

  /// 删除文件
  Future<bool> delete() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      print('删除 JSON 文件失败: $e');
      return false;
    }
  }

  /// 检查文件是否存在
  Future<bool> exists() async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
