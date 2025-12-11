/// 模型复制脚本 - 将 Flutter 应用中的数据模型复制到 shared_models 包
///
/// 使用方法:
///   dart run scripts/copy_models.dart
///
/// 此脚本会:
/// 1. 读取配置的模型文件映射
/// 2. 复制源文件到目标位置
/// 3. 自动替换 import 路径
/// 4. 移除 Flutter 特定依赖

import 'dart:io';

/// 模型文件映射: 源路径 -> 目标路径 (相对于项目根目录)
const Map<String, String> modelMappings = {
  // Chat 插件模型
  'lib/plugins/chat/models/user.dart': 'shared_models/lib/models/user.dart',
  'lib/plugins/chat/models/message.dart':
      'shared_models/lib/models/message.dart',
  'lib/plugins/chat/models/channel.dart':
      'shared_models/lib/models/channel.dart',

  // Diary 插件模型
  'lib/plugins/diary/models/diary_entry.dart':
      'shared_models/lib/models/diary_entry.dart',

  // Activity 插件模型
  'lib/plugins/activity/models/activity_record.dart':
      'shared_models/lib/models/activity_record.dart',

  // Notes 插件模型
  'lib/plugins/notes/models/note.dart': 'shared_models/lib/models/note.dart',
  'lib/plugins/notes/models/folder.dart':
      'shared_models/lib/models/folder.dart',

  // Todo 插件模型
  'lib/plugins/todo/models/task.dart': 'shared_models/lib/models/task.dart',

  // Bill 插件模型
  'lib/plugins/bill/models/bill.dart': 'shared_models/lib/models/bill.dart',
  'lib/plugins/bill/models/account.dart':
      'shared_models/lib/models/account.dart',

  // Tracker 插件模型
  'lib/plugins/tracker/models/goal.dart': 'shared_models/lib/models/goal.dart',
  'lib/plugins/tracker/models/record.dart':
      'shared_models/lib/models/record.dart',

  // Goods 插件模型
  'lib/plugins/goods/models/goods_item.dart':
      'shared_models/lib/models/goods_item.dart',

  // Contact 插件模型
  'lib/plugins/contact/models/contact_model.dart':
      'shared_models/lib/models/contact.dart',

  // Habits 插件模型
  'lib/plugins/habits/models/habit.dart': 'shared_models/lib/models/habit.dart',

  // Checkin 插件模型
  'lib/plugins/checkin/models/checkin_item.dart':
      'shared_models/lib/models/checkin_item.dart',

  // Calendar 插件模型
  'lib/plugins/calendar/models/event.dart':
      'shared_models/lib/models/event.dart',

  // Day 插件模型
  'lib/plugins/day/models/memorial_day.dart':
      'shared_models/lib/models/memorial_day.dart',
};

/// 需要从复制的文件中移除的 import 模式
final List<RegExp> removeImportPatterns = [
  // Flutter 相关
  RegExp(r"import\s+'package:flutter/.*';"),
  // Material
  RegExp(r"import\s+'package:flutter/material\.dart';"),
  // Memento 特定工具 (非模型)
  RegExp(r"import\s+'package:memento/core/utils/.*';"),
  RegExp(r"import\s+'package:memento/widgets/.*';"),
  RegExp(r"import\s+'package:memento/screens/.*';"),
  // 本地化
  RegExp(r"import\s+'.*l10n.*';"),
];

/// 需要替换的 import 模式
final Map<RegExp, String> replaceImportPatterns = {
  // 将 package:memento/plugins/.../models/ 替换为 package:shared_models/models/
  RegExp(r"import\s+'package:memento/plugins/\w+/models/(\w+\.dart)';"):
      "import 'package:shared_models/models/\$1';",
};

void main(List<String> args) async {
  final projectRoot = Directory.current.path;

  print('=== Memento 模型复制脚本 ===');
  print('项目根目录: $projectRoot');
  print('');

  // 确保目标目录存在
  final modelsDir = Directory('$projectRoot/shared_models/lib/models');
  if (!modelsDir.existsSync()) {
    modelsDir.createSync(recursive: true);
    print('创建目录: ${modelsDir.path}');
  }

  int successCount = 0;
  int skipCount = 0;
  int errorCount = 0;

  for (final entry in modelMappings.entries) {
    final sourcePath = '$projectRoot/${entry.key}';
    final targetPath = '$projectRoot/${entry.value}';

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      print('  跳过: ${entry.key} (源文件不存在)');
      skipCount++;
      continue;
    }

    try {
      // 读取源文件
      String content = sourceFile.readAsStringSync();

      // 移除不需要的 import
      for (final pattern in removeImportPatterns) {
        content = content.replaceAll(pattern, '// [移除] Flutter 依赖');
      }

      // 替换 import 路径
      for (final entry in replaceImportPatterns.entries) {
        content = content.replaceAllMapped(
          entry.key,
          (match) => entry.value.replaceAll('\$1', match.group(1) ?? ''),
        );
      }

      // 添加注释说明
      content = '''// 此文件由 scripts/copy_models.dart 自动生成
// 请勿手动编辑，修改请在源文件进行
// 源文件: ${entry.key}
// 生成时间: ${DateTime.now().toIso8601String()}

$content''';

      // 确保目标目录存在
      final targetFile = File(targetPath);
      if (!targetFile.parent.existsSync()) {
        targetFile.parent.createSync(recursive: true);
      }

      // 写入目标文件
      targetFile.writeAsStringSync(content);

      print('  复制: ${entry.key} -> ${entry.value}');
      successCount++;
    } catch (e) {
      print('  错误: ${entry.key} - $e');
      errorCount++;
    }
  }

  print('');
  print('=== 复制完成 ===');
  print('成功: $successCount');
  print('跳过: $skipCount');
  print('错误: $errorCount');

  // 生成导出文件
  _generateExportFile(projectRoot);
}

/// 生成模型导出文件
void _generateExportFile(String projectRoot) {
  final modelsDir = Directory('$projectRoot/shared_models/lib/models');
  if (!modelsDir.existsSync()) return;

  final files = modelsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  if (files.isEmpty) {
    print('\n没有找到模型文件，跳过生成导出文件');
    return;
  }

  final exports = files.map((f) => "export 'models/$f';").join('\n');

  final content = '''// 此文件由 scripts/copy_models.dart 自动生成
// 导出所有共享模型

// 同步相关模型
export 'sync/sync_request.dart';
export 'sync/sync_response.dart';

// 认证相关模型
export 'auth/auth_models.dart';

// 通用工具
export 'utils/md5_utils.dart';

// 数据模型
$exports
''';

  final exportFile = File('$projectRoot/shared_models/lib/shared_models.dart');
  exportFile.writeAsStringSync(content);

  print('\n生成导出文件: shared_models/lib/shared_models.dart');
  print('包含 ${files.length} 个模型文件');
}
