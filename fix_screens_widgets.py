#!/usr/bin/env python3
"""
修复 screens 和 widgets 层的 Localizations 引用错误
"""
import os
import re
from pathlib import Path

def get_context_from_path(file_path):
    """从文件路径推断上下文前缀"""
    parts = Path(file_path).parts

    if 'screens' in parts:
        # screens 层使用 'screens_' 前缀
        return 'screens'
    elif 'widgets' in parts:
        # widgets 层使用 'app_' 前缀
        return 'app'
    return 'app'

def fix_file(file_path):
    """修复单个文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    prefix = get_context_from_path(file_path)

    # 步骤1: 移除 l10n 变量声明
    content = re.sub(
        r'^\s*final l10n = \w+Localizations\.of\(context\);?\s*$',
        '',
        content,
        flags=re.MULTILINE
    )

    # 步骤2: 替换 l10n.xxx 为 AppLocalizations.translate()
    content = re.sub(
        r'\bl10n\.(\w+)',
        lambda m: f"AppLocalizations.of(context)!.translate('{prefix}_{m.group(1)}')",
        content
    )

    # 步骤3: 添加 AppLocalizations 导入（如果需要）
    if 'AppLocalizations' in content and "import 'package:Memento/l10n/app_localizations.dart'" not in content:
        # 找到最后一个 import 语句的位置
        import_pattern = r"(import '[^']+';)\s*\n"
        imports = list(re.finditer(import_pattern, content))
        if imports:
            last_import = imports[-1]
            insert_pos = last_import.end()
            content = (
                content[:insert_pos] +
                "import 'package:Memento/l10n/app_localizations.dart';\n" +
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
    base_dirs = [
        Path('D:/Memento/lib/screens'),
        Path('D:/Memento/lib/widgets'),
    ]
    fixed_files = []

    for base_dir in base_dirs:
        if not base_dir.exists():
            continue

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
