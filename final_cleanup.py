#!/usr/bin/env python3
"""
最终清理所有 Localizations 引用
"""
import os
import re
from pathlib import Path

def get_plugin_id_from_path(file_path):
    """从文件路径推断插件ID"""
    parts = Path(file_path).parts
    if 'plugins' in parts:
        plugin_index = parts.index('plugins')
        if plugin_index + 1 < len(parts):
            return parts[plugin_index + 1]
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

    # 步骤1: 删除 XXXLocalizations 的导入
    content = re.sub(
        r"import\s+'[^']*?/l10n/\w+_localizations\.dart';\s*\n",
        '',
        content
    )

    # 步骤2: 删除 XXXLocalizations 类型的声明和参数
    # 例如: final ChatLocalizations l10n =
    content = re.sub(
        r'\b(\w+Localizations)\s+',
        '',
        content
    )

    # 步骤3: 替换 XXXLocalizations.of(context) 调用
    # 例如: ChatLocalizations.of(context) => 删除(因为后续会替换使用方式)
    content = re.sub(
        r'\w+Localizations\.of\(context\)',
        '',
        content
    )

    # 步骤4: 清理多余的空行
    content = re.sub(r'\n\n\n+', '\n\n', content)

    # 如果内容有变化,写回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """主函数"""
    base_dir = Path('D:/Memento/lib')
    fixed_files = []

    # 遍历所有 Dart 文件
    for dart_file in base_dir.rglob('*.dart'):
        if dart_file.is_file() and '.backup' not in str(dart_file):
            try:
                if fix_file(str(dart_file)):
                    fixed_files.append(str(dart_file))
                    print(f"[OK] Fixed: {dart_file.relative_to(base_dir)}")
            except Exception as e:
                print(f"[ERROR] {dart_file.relative_to(base_dir)}: {e}")

    print(f"\nTotal fixed: {len(fixed_files)} files")

if __name__ == '__main__':
    main()
