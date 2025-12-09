#!/usr/bin/env python3
"""
手动处理activity插件的遗漏文件
"""

import re

# 需要处理的文件
files_to_fix = [
    "D:/Memento/lib/plugins/activity/widgets/activity_form/activity_form_state.dart",
    "D:/Memento/lib/plugins/activity/screens/tag_statistics_screen.dart",
    "D:/Memento/lib/plugins/activity/screens/activity_settings_screen.dart",
    "D:/Memento/lib/plugins/activity/home_widgets.dart",
]

def process_file(file_path):
    """处理单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # 1. 删除旧的localizations导入
        import_patterns = [
            r"import '.*l10n/activity_localizations\.dart';?\n",
            r"import 'package:Memento/plugins/activity/l10n/activity_localizations\.dart';?\n",
        ]

        for pattern in import_patterns:
            content = re.sub(pattern, '', content)

        # 2. 确保有 GetX 导入
        if "import 'package:get/get.dart';" not in content:
            # 在第一个import之后添加
            import_match = re.search(r"^import .*?;", content, re.MULTILINE)
            if import_match:
                insert_pos = import_match.end()
                content = content[:insert_pos] + "\nimport 'package:get/get.dart';" + content[insert_pos:]

        # 3. 替换 ActivityLocalizations.of(context).someKey 为 'activity_someKey'.tr
        pattern = r"ActivityLocalizations\.of\(context\)\.(\w+)"

        def replace_with_tr(match):
            property_name = match.group(1)
            return f"'activity_{property_name}'.tr"

        content = re.sub(pattern, replace_with_tr, content)

        # 只有内容改变了才写入
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"[OK] Fixed: {file_path}")
            return True
        else:
            print(f"[SKIP] No changes needed: {file_path}")
            return False

    except Exception as e:
        print(f"[ERROR] {file_path}: {e}")
        return False

def main():
    """主函数"""
    print("Processing activity plugin remaining files...\n")

    fixed_count = 0
    for file_path in files_to_fix:
        if process_file(file_path):
            fixed_count += 1

    print(f"\nDone! Fixed {fixed_count}/{len(files_to_fix)} files.")

if __name__ == '__main__':
    main()
