#!/usr/bin/env python3
"""
修复剩余的 Localizations 引用错误
"""
import os
import re
from pathlib import Path

def fix_file(file_path):
    """修复单个文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 步骤1: 移除方法参数中的 XXXLocalizations 类型引用
    # 例如: Widget _buildListView(BillLocalizations l10n) => Widget _buildListView()
    content = re.sub(
        r'\((\w+Localizations)\s+l10n\)',
        r'()',
        content
    )

    # 步骤2: 移除方法调用中的 l10n 参数传递
    # 例如: _buildListView(l10n) => _buildListView()
    content = re.sub(
        r'(\w+)\(l10n\)',
        r'\1()',
        content
    )

    # 步骤3: 替换 XXXLocalizations.of(context) 为翻译键
    # CalendarAlbumLocalizations.of(context) => null (需要手动替换为实际的翻译键)
    # 先移除类定义中的类型声明
    content = re.sub(
        r'\b(\w+Localizations)\s+l10n\b',
        '',
        content
    )

    # 步骤4: 移除单独的 final XXXLocalizations l10n = ... 声明
    content = re.sub(
        r'^\s*final\s+\w+Localizations\s+l10n\s*=\s*\w+Localizations\.of\(context\);?\s*$',
        '',
        content,
        flags=re.MULTILINE
    )

    # 步骤5: 移除类型为 XXXLocalizations 的变量声明
    content = re.sub(
        r'^\s*\w+Localizations\s+l10n\s*=\s*\w+Localizations\.of\(context\);?\s*$',
        '',
        content,
        flags=re.MULTILINE
    )

    # 步骤6: 替换 XXXLocalizations.of(context) 调用为 Get.find() (如果可以确定上下文)
    # 这个需要根据具体的插件ID来决定,暂时留空

    # 如果内容有变化，写回文件
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
        if dart_file.is_file():
            try:
                if fix_file(str(dart_file)):
                    fixed_files.append(str(dart_file))
                    print(f"[OK] Fixed: {dart_file.relative_to(base_dir)}")
            except Exception as e:
                print(f"[ERROR] {dart_file.relative_to(base_dir)}: {e}")

    print(f"\nTotal fixed: {len(fixed_files)} files")

if __name__ == '__main__':
    main()
