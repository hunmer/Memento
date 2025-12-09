#!/usr/bin/env python3
"""
批量修复 Memento 项目中的 Localizations 引用错误 (使用 GetX 翻译系统)
"""
import os
import re
from pathlib import Path

# 插件ID映射
PLUGIN_IDS = {
    'calendar_album': 'calendar_album',
    'calendar': 'calendar',
    'chat': 'chat',
    'habits': 'habits',
    'nfc': 'nfc',
    'nodes': 'nodes',
    'notes': 'notes',
    'openai': 'openai',
    'store': 'store',
    'timer': 'timer',
    'todo': 'todo',
    'tracker': 'tracker',
    'contact': 'contact',
    'checkin': 'checkin',
    'goods': 'goods',
    'day': 'day',
    'bill': 'bill',
    'activity': 'activity',
}

def get_plugin_id_from_path(file_path):
    """从文件路径推断插件ID"""
    parts = Path(file_path).parts
    if 'plugins' in parts:
        plugin_index = parts.index('plugins')
        if plugin_index + 1 < len(parts):
            plugin_name = parts[plugin_index + 1]
            return PLUGIN_IDS.get(plugin_name, plugin_name)
    elif 'screens' in parts:
        return 'screens'
    elif 'widgets' in parts:
        return 'app'
    return 'app'

def fix_file(file_path):
    """修复单个文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    plugin_id = get_plugin_id_from_path(file_path)

    # 步骤1: 移除错误的 AppLocalizations 导入
    content = re.sub(
        r"import 'package:Memento/l10n/app_localizations\.dart';\s*\n",
        '',
        content
    )

    # 步骤2: 替换 AppLocalizations.of(context)!.translate() 为 .tr
    content = re.sub(
        r"AppLocalizations\.of\(context\)!\.translate\('([^']+)'\)",
        lambda m: f"'{m.group(1)}'.tr",
        content
    )

    # 步骤3: 如果文件中有 .tr 但没有导入 get，添加导入
    if '.tr' in content and "import 'package:get/get.dart';" not in content:
        # 找到最后一个 import 语句的位置
        import_pattern = r"(import '[^']+';)\s*\n"
        imports = list(re.finditer(import_pattern, content))
        if imports:
            last_import = imports[-1]
            insert_pos = last_import.end()
            content = (
                content[:insert_pos] +
                "import 'package:get/get.dart';\n" +
                content[insert_pos:]
            )

    # 如果内容有变化，写回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """主函数"""
    base_dir = Path('D:/Memento/lib/plugins')
    fixed_files = []

    # 遍历所有 Dart 文件
    for dart_file in base_dir.rglob('*.dart'):
        if dart_file.is_file():
            try:
                if fix_file(str(dart_file)):
                    fixed_files.append(str(dart_file))
                    print(f"[OK] Fixed: {dart_file.relative_to(base_dir.parent)}")
            except Exception as e:
                print(f"[ERROR] {dart_file.relative_to(base_dir.parent)}: {e}")

    print(f"\nTotal fixed: {len(fixed_files)} files")

if __name__ == '__main__':
    main()
