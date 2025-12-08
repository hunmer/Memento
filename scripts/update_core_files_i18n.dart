/// 更新核心模块文件的国际化的Dart脚本
import 'dart:io';

void main() {
  print('开始更新核心模块文件的国际化...\n');

  // 定义需要更新的文件和对应的硬编码文本映射
  final filesToUpdate = [
    {
      'path': 'lib/core/action/action_executor.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: const Text('输入JavaScript代码'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.inputJavaScriptCode),",
        },
        {
          'search': "child: const Text('取消'),",
          'replace': "child: Text(CoreLocalizations.of(context)!.cancel),",
        },
        {
          'search': "child: const Text('执行'),",
          'replace': "child: Text(CoreLocalizations.of(context)!.execute),",
        },
      ],
    },
    {
      'path': 'lib/core/action/examples/custom_action_examples.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: const Text('输入JavaScript代码'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.inputJavaScriptCode),",
        },
        {
          'search': "child: const Text('取消'),",
          'replace': "child: Text(CoreLocalizations.of(context)!.cancel),",
        },
        {
          'search': "child: const Text('保存'),",
          'replace': "child: Text(CoreLocalizations.of(context)!.save),",
        },
        {
          'search': "title: const Text('执行结果'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.executionResult),",
        },
        {
          'search': "Text('执行状态: \${result.success ? \"成功\" : \"失败\"}'),",
          'replace': "Text(CoreLocalizations.of(context)!.executionStatus(result.success)),",
        },
        {
          'search': "const Text('输出数据:'),",
          'replace': "Text(CoreLocalizations.of(context)!.outputData),",
        },
        {
          'search': "const Text('错误信息:'),",
          'replace': "Text(CoreLocalizations.of(context)!.errorMessage),",
        },
        {
          'search': "child: const Text('关闭'),",
          'replace': "child: Text(CoreLocalizations.of(context)!.close),",
        },
        {
          'search': "title: const Text('输入悬浮球JavaScript代码'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.inputFloatingBallJavaScriptCode),",
        },
      ],
    },
    {
      'path': 'lib/core/action/migration/migration_tool.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: Text('配置迁移'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.configMigration),",
        },
        {
          'search': "Text('迁移中...'),",
          'replace': "Text(CoreLocalizations.of(context)!.migrating),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "Text('开始迁移'),",
          'replace': "Text(CoreLocalizations.of(context)!.startMigration),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('关闭')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.close)),",
        },
      ],
    },
    {
      'path': 'lib/core/action/widgets/action_config_form.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "Text('未选择'),",
          'replace': "Text(CoreLocalizations.of(context)!.notSelected),",
        },
        {
          'search': "title: Text('选择颜色'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.selectColor),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "Text('图标选择器（暂未实现）'),",
          'replace': "Text(CoreLocalizations.of(context)!.iconSelectorNotImplemented),",
        },
      ],
    },
    {
      'path': 'lib/core/action/widgets/action_group_editor.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "Text('顺序执行'),",
          'replace': "Text(CoreLocalizations.of(context)!.sequentialExecution),",
        },
        {
          'search': "Text('并行执行'),",
          'replace': "Text(CoreLocalizations.of(context)!.parallelExecution),",
        },
        {
          'search': "Text('条件执行'),",
          'replace': "Text(CoreLocalizations.of(context)!.conditionalExecution),",
        },
        {
          'search': "Text('执行所有动作'),",
          'replace': "Text(CoreLocalizations.of(context)!.executeAllActions),",
        },
        {
          'search': "Text('执行任一动作'),",
          'replace': "Text(CoreLocalizations.of(context)!.executeAnyAction),",
        },
        {
          'search': "Text('只执行第一个'),",
          'replace': "Text(CoreLocalizations.of(context)!.executeFirstOnly),",
        },
        {
          'search': "Text('只执行最后一个'),",
          'replace': "Text(CoreLocalizations.of(context)!.executeLastOnly),",
        },
        {
          'search': "Text('添加动作'),",
          'replace': "Text(CoreLocalizations.of(context)!.addAction),",
        },
        {
          'search': "Text('编辑'),",
          'replace': "Text(CoreLocalizations.of(context)!.edit),",
        },
        {
          'search': "Text('上移'),",
          'replace': "Text(CoreLocalizations.of(context)!.moveUp),",
        },
        {
          'search': "Text('下移'),",
          'replace': "Text(CoreLocalizations.of(context)!.moveDown),",
        },
        {
          'search': "Text('删除'),",
          'replace': "Text(CoreLocalizations.of(context)!.delete),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('保存')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.save)),",
        },
      ],
    },
    {
      'path': 'lib/core/action/widgets/action_selector_dialog.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "Text('清除已设置'),",
          'replace': "Text(CoreLocalizations.of(context)!.clearSettings),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确认')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context, true), child: Text(CoreLocalizations.of(context)!.confirm)),",
        },
        {
          'search': "Text('创建动作组'),",
          'replace': "Text(CoreLocalizations.of(context)!.createActionGroup),",
        },
      ],
    },
    {
      'path': 'lib/core/floating_ball/screens/floating_button_manager_screen.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: Text('确认删除'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.confirmDelete),",
        },
        {
          'search': "content: Text('确定要删除按钮\"\${_buttons[index].title}\"吗？'),",
          'replace': "content: Text(CoreLocalizations.of(context)!.confirmDeleteButton(_buttons[index].title)),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "TextButton(onPressed: () { Navigator.pop(context); _deleteButton(index); }, child: Text('删除')),",
          'replace': "TextButton(onPressed: () { Navigator.pop(context); _deleteButton(index); }, child: Text(CoreLocalizations.of(context)!.delete)),",
        },
        {
          'search': "title: Text('悬浮按钮管理'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.floatingButtonManager),",
        },
        {
          'search': "Text('添加第一个按钮'),",
          'replace': "Text(CoreLocalizations.of(context)!.addFirstButton),",
        },
      ],
    },
    {
      'path': 'lib/core/floating_ball/widgets/floating_button_edit_dialog.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: Text('清空图标/图片'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.clearIconImage),",
        },
        {
          'search': "content: Text('确定要清空当前设置的图标和图片吗？'),",
          'replace': "content: Text(CoreLocalizations.of(context)!.confirmClearIconImage()),",
        },
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
        {
          'search': "TextButton(onPressed: () { Navigator.pop(context); widget.onClear?.call(); }, child: Text('清空')),",
          'replace': "TextButton(onPressed: () { Navigator.pop(context); widget.onClear?.call(); }, child: Text(CoreLocalizations.of(context)!.clear)),",
        },
        {
          'search': "title: Text('选择图标'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.selectIcon),",
        },
      ],
    },
    {
      'path': 'lib/core/floating_ball/widgets/plugin_overlay_selector.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),",
          'replace': "TextButton(onPressed: () => Navigator.pop(context), child: Text(CoreLocalizations.of(context)!.cancel)),",
        },
      ],
    },
    {
      'path': 'lib/core/floating_ball/widgets/plugin_overlay_widget.dart',
      'imports': ["import 'package:Memento/core/l10n/core_localizations.dart';"],
      'replacements': [
        {
          'search': "title: Text('路由错误'),",
          'replace': "title: Text(CoreLocalizations.of(context)!.routeError),",
        },
        {
          'search': "Text('未找到路由: \${settings.name}'),",
          'replace': "Text(CoreLocalizations.of(context)!.routeNotFound(settings.name ?? '')),",
        },
      ],
    },
  ];

  // 更新每个文件
  for (final file in filesToUpdate) {
    updateFile(file);
  }

  print('\n所有文件更新完成！');
  print('\n注意：还需要在 main.dart 中注册核心模块的国际化委托：');
  print('  CoreLocalizationsDelegate(),');
}

void updateFile(Map<String, dynamic> fileConfig) {
  final path = fileConfig['path'] as String;
  final imports = fileConfig['imports'] as List<String>;
  final replacements = fileConfig['replacements'] as List<Map<String, String>>;

  print('处理文件: $path');

  final file = File(path);
  if (!file.existsSync()) {
    print('  警告: 文件不存在，跳过');
    return;
  }

  // 读取文件内容
  String content = file.readAsStringSync();

  // 添加导入语句
  for (final import in imports) {
    if (!content.contains(import)) {
      // 在最后一个 import 语句后添加
      final importRegex = RegExp(r"import\s+'[^']+';");
      final matches = importRegex.allMatches(content);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        final insertIndex = lastMatch.end;
        content = content.substring(0, insertIndex) + '\n' + import + content.substring(insertIndex);
        print('  添加导入: ${import.split('/').last}');
      }
    }
  }

  // 执行替换
  for (final replacement in replacements) {
    final search = replacement['search']!;
    final replace = replacement['replace']!;

    if (content.contains(search)) {
      content = content.replaceAll(search, replace);
      print('  替换: ${search.substring(0, search.length > 50 ? 50 : search.length).replaceAll('\n', '\\n')}...');
    }
  }

  // 写回文件
  file.writeAsStringSync(content);
  print('  完成');
}