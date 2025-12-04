#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量替换 MaterialPageRoute 为 NavigationHelper 的脚本
"""

import os
import re
import glob
from pathlib import Path

def add_import(file_path):
    """添加 NavigationHelper 导入"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 检查是否已经导入
    if any('navigation_helper.dart' in line for line in lines):
        return False

    # 找到插入位置（在 flutter/material.dart 导入之后）
    inserted = False
    new_lines = []
    for i, line in enumerate(lines):
        new_lines.append(line)
        if 'flutter/material.dart' in line and not inserted:
            new_lines.append("import 'package:Memento/core/navigation/navigation_helper.dart';\n")
            inserted = True

    if not inserted:
        # 如果没有找到 material.dart，则在顶部添加
        new_lines.insert(0, "import 'package:Memento/core/navigation/navigation_helper.dart';\n")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

    return True

def replace_material_page_route(content):
    """替换 MaterialPageRoute 调用"""

    # 匹配模式1: Navigator.of(context).push(MaterialPageRoute(...))
    pattern1 = r"Navigator\.of\(context\)\.push\(\s*MaterialPageRoute\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\),?\s*\)"
    content = re.sub(pattern1, r"NavigationHelper.push(context, \1)", content, flags=re.DOTALL)

    # 匹配模式2: Navigator.push(context, MaterialPageRoute(...))
    pattern2 = r"Navigator\.push\(\s*context,\s*MaterialPageRoute\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\),?\s*\)"
    content = re.sub(pattern2, r"NavigationHelper.push(context, \1)", content, flags=re.DOTALL)

    # 匹配模式3: Navigator.of(context).pushReplacement(MaterialPageRoute(...))
    pattern3 = r"Navigator\.of\(context\)\.pushReplacement\(\s*MaterialPageRoute\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\),?\s*\)"
    content = re.sub(pattern3, r"NavigationHelper.pushReplacement(context, \1)", content, flags=re.DOTALL)

    # 匹配模式4: Navigator.of(context).pushAndRemoveUntil(..., ...)
    pattern4 = r"Navigator\.of\(context\)\.pushAndRemoveUntil\(\s*MaterialPageRoute\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\),\s*(.*?)\)"
    content = re.sub(pattern4, r"NavigationHelper.pushAndRemoveUntil(context, \1, \2)", content, flags=re.DOTALL)

    return content

def process_file(file_path):
    """处理单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()

        # 检查是否包含 MaterialPageRoute
        if 'MaterialPageRoute' not in original_content:
            return False

        # 添加导入
        import_added = add_import(file_path)

        # 替换内容
        modified_content = replace_material_page_route(original_content)

        # 如果有修改，写回文件
        if modified_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            return True

        return False

    except Exception as e:
        print(f"  Error: {e}")
        return False

def main():
    """主函数"""
    print("=" * 60)
    print("批量替换 MaterialPageRoute 为 NavigationHelper")
    print("=" * 60)

    # 获取所有包含 MaterialPageRoute 的 Dart 文件
    base_dir = Path("D:/Memento/lib")
    dart_files = []

    # 递归搜索所有 .dart 文件
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = Path(root) / file
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        if 'MaterialPageRoute' in f.read():
                            dart_files.append(file_path)
                except:
                    pass

    print(f"\n找到 {len(dart_files)} 个包含 MaterialPageRoute 的文件\n")

    success_count = 0
    import_count = 0

    for i, file_path in enumerate(dart_files, 1):
        print(f"[{i}/{len(dart_files)}] 处理: {file_path.relative_to(base_dir.parent)}")

        try:
            # 添加导入
            if add_import(file_path):
                import_count += 1

            # 读取并替换
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()

            if 'MaterialPageRoute' not in original_content:
                print(f"  跳过: 无 MaterialPageRoute")
                continue

            modified_content = replace_material_page_route(original_content)

            if modified_content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                print(f"  [OK] 已替换 MaterialPageRoute")
                success_count += 1
            else:
                print(f"  [-] 无需修改")

        except Exception as e:
            print(f"  [ERROR] 错误: {e}")

    print("\n" + "=" * 60)
    print(f"完成！共处理 {len(dart_files)} 个文件")
    print(f"  - 添加导入: {import_count} 个文件")
    print(f"  - 替换调用: {success_count} 个文件")
    print("=" * 60)

if __name__ == "__main__":
    main()
