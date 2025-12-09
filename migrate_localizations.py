#!/usr/bin/env python3
"""
批量迁移插件从旧的 localizations 系统到 GetX 翻译系统
"""

import os
import re
from pathlib import Path

# 插件列表和对应的前缀
PLUGINS = {
    'activity': 'activity_',
    'agent_chat': 'agentChat_',
    'bill': 'bill_',
    'calendar': 'calendar_',
    'calendar_album': 'calendarAlbum_',
    'chat': 'chat_',
    'checkin': 'checkin_',
    'contact': 'contact_',
    'database': 'database_',
    'day': 'day_',
}

def migrate_file(file_path, plugin_name, prefix):
    """迁移单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # 构建localizations类名（首字母大写）
        class_name = ''.join(word.capitalize() for word in plugin_name.split('_')) + 'Localizations'

        # 1. 删除旧的localizations导入
        import_patterns = [
            rf"import '.*l10n/{plugin_name}_localizations\.dart';?\n",
            rf"import 'package:Memento/plugins/{plugin_name}/l10n/{plugin_name}_localizations\.dart';?\n",
            rf"import '.*l10n/.*_localizations\.dart';?\n",
        ]

        for pattern in import_patterns:
            content = re.sub(pattern, '', content)

        # 2. 添加 GetX 导入（如果还没有）
        if "import 'package:get/get.dart';" not in content and "from 'package:get/get.dart'" not in content:
            # 在第一个import之后添加
            import_match = re.search(r"^import .*?;", content, re.MULTILINE)
            if import_match:
                insert_pos = import_match.end()
                content = content[:insert_pos] + "\nimport 'package:get/get.dart';" + content[insert_pos:]

        # 3. 替换 XxxLocalizations.of(context).someKey 为 'prefix_someKey'.tr
        # 匹配模式: XxxLocalizations.of(context).propertyName
        pattern = rf"{class_name}\.of\(context\)\.(\w+)"

        def replace_with_tr(match):
            property_name = match.group(1)
            return f"'{prefix}{property_name}'.tr"

        content = re.sub(pattern, replace_with_tr, content)

        # 4. 处理带参数的方法调用 (如果有)
        # 例如: XxxLocalizations.of(context).methodName(arg1, arg2)
        # 转换为: 'prefix_methodName'.trParams({'arg1': value1, 'arg2': value2})
        # 这个比较复杂，暂时先不处理，等到实际遇到再手动调整

        # 只有内容改变了才写入
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False

    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def migrate_plugin(plugin_name, prefix):
    """迁移整个插件"""
    plugin_path = Path(f"D:/Memento/lib/plugins/{plugin_name}")

    if not plugin_path.exists():
        print(f"Plugin {plugin_name} not found at {plugin_path}")
        return 0, []

    modified_files = []
    count = 0

    # 遍历所有 .dart 文件（排除 l10n 目录）
    for dart_file in plugin_path.rglob("*.dart"):
        # 跳过 l10n 目录中的文件
        if '/l10n/' in str(dart_file).replace('\\', '/') or '\\l10n\\' in str(dart_file):
            continue

        if migrate_file(dart_file, plugin_name, prefix):
            modified_files.append(str(dart_file))
            count += 1

    return count, modified_files

def main():
    """主函数"""
    # 设置输出编码
    import sys
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')

    print("Starting migration to GetX translation system...\n")

    total_count = 0
    all_modified_files = []

    for plugin_name, prefix in PLUGINS.items():
        print(f"\n{'='*60}")
        print(f"Processing plugin: {plugin_name} (prefix: {prefix})")
        print('='*60)

        count, modified_files = migrate_plugin(plugin_name, prefix)

        if count > 0:
            print(f"\n[OK] Successfully migrated {count} files:")
            for file in modified_files:
                print(f"  - {file}")
            total_count += count
            all_modified_files.extend(modified_files)
        else:
            print(f"\n[SKIP] No files to migrate")

    print(f"\n{'='*60}")
    print(f"Migration completed!")
    print(f"Processed {len(PLUGINS)} plugins")
    print(f"Modified {total_count} files")
    print('='*60)

    if all_modified_files:
        print("\nAll modified files:")
        for file in all_modified_files:
            print(f"  - {file}")

if __name__ == '__main__':
    main()
