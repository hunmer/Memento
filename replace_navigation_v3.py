#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量替换 MaterialPageRoute 为 NavigationHelper 的脚本 v3.0
支持全局导航器、Navigator.push 等更多模式
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
    """替换 MaterialPageRoute 调用 - 全能版本"""

    # 模式1: navigator.push(MaterialPageRoute(...)) - 全局导航器
    pattern1 = r"(\w+)\.push\(\s*MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*(?:,\s*fullscreenDialog:\s*([^,\)]+))?(?:,\s*maintainState:\s*([^,\)]+))?\)"
    def repl1(match):
        var_name = match.group(1)
        builder_code = match.group(2).strip()
        fullscreen = match.group(3).strip() if match.group(3) else None
        maintain = match.group(4).strip() if match.group(4) else None
        params = []
        if fullscreen:
            params.append(f"fullscreenDialog: {fullscreen}")
        if maintain:
            params.append(f"maintainState: {maintain}")
        param_str = ", " + ", ".join(params) if params else ""
        return f"{var_name}.push(NavigationHelper.createRoute({builder_code}{param_str}))"

    content = re.sub(pattern1, repl1, content, flags=re.DOTALL)

    # 模式2: Navigator.of(context).push(MaterialPageRoute(...))
    pattern2 = r"Navigator\.of\(context\)\.push\(\s*MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*(?:,\s*fullscreenDialog:\s*([^,\)]+))?(?:,\s*maintainState:\s*([^,\)]+))?\)"
    def repl2(match):
        builder_code = match.group(1).strip()
        fullscreen = match.group(2).strip() if match.group(2) else None
        maintain = match.group(3).strip() if match.group(3) else None
        params = []
        if fullscreen:
            params.append(f"fullscreenDialog: {fullscreen}")
        if maintain:
            params.append(f"maintainState: {maintain}")
        param_str = ", " + ", ".join(params) if params else ""
        return f"NavigationHelper.push(context, {builder_code}{param_str})"

    content = re.sub(pattern2, repl2, content, flags=re.DOTALL)

    # 模式3: Navigator.push(context, MaterialPageRoute(...))
    pattern3 = r"Navigator\.push\(\s*context,\s*MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*(?:,\s*fullscreenDialog:\s*([^,\)]+))?(?:,\s*maintainState:\s*([^,\)]+))?\)"
    def repl3(match):
        builder_code = match.group(1).strip()
        fullscreen = match.group(2).strip() if match.group(2) else None
        maintain = match.group(3).strip() if match.group(3) else None
        params = []
        if fullscreen:
            params.append(f"fullscreenDialog: {fullscreen}")
        if maintain:
            params.append(f"maintainState: {maintain}")
        param_str = ", " + ", ".join(params) if params else ""
        return f"NavigationHelper.push(context, {builder_code}{param_str})"

    content = re.sub(pattern3, repl3, content, flags=re.DOTALL)

    # 模式4: Navigator.of(context).pushReplacement(MaterialPageRoute(...))
    pattern4 = r"Navigator\.of\(context\)\.pushReplacement\(\s*MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*(?:,\s*fullscreenDialog:\s*([^,\)]+))?\)"
    def repl4(match):
        builder_code = match.group(1).strip()
        fullscreen = match.group(2).strip() if match.group(2) else None
        param_str = f", fullscreenDialog: {fullscreen}" if fullscreen else ""
        return f"NavigationHelper.pushReplacement(context, {builder_code}{param_str})"

    content = re.sub(pattern4, repl4, content, flags=re.DOTALL)

    # 模式5: Navigator.of(context).pushAndRemoveUntil(..., ...)
    pattern5 = r"Navigator\.of\(context\)\.pushAndRemoveUntil\(\s*MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*,\s*(.*?)\)"
    def repl5(match):
        builder_code = match.group(1).strip()
        predicate = match.group(2).strip()
        return f"NavigationHelper.pushAndRemoveUntil(context, {builder_code}, {predicate})"

    content = re.sub(pattern5, repl5, content, flags=re.DOTALL)

    # 模式6: return MaterialPageRoute(...) - 在导航方法中返回路由
    pattern6 = r"return\s+MaterialPageRoute(?:<[^>]+>)?\(\s*builder:\s*\([^)]*\)\s*=>\s*(.*?)\s*\)\s*(?:,\s*fullscreenDialog:\s*([^,\)]+))?(?:,\s*maintainState:\s*([^,\)]+))?;"
    def repl6(match):
        builder_code = match.group(1).strip()
        fullscreen = match.group(2).strip() if match.group(2) else None
        maintain = match.group(3).strip() if match.group(3) else None
        params = []
        if fullscreen:
            params.append(f"fullscreenDialog: {fullscreen}")
        if maintain:
            params.append(f"maintainState: {maintain}")
        param_str = ", " + ", ".join(params) if params else ""
        return f"return NavigationHelper.createRoute({builder_code}{param_str});"

    content = re.sub(pattern6, repl6, content, flags=re.DOTALL)

    return content

def process_file(file_path):
    """处理单个文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            original_content = f.read()

        # 检查是否包含 MaterialPageRoute
        if 'MaterialPageRoute' not in original_content:
            return False, False

        # 添加导入
        import_added = add_import(file_path)

        # 替换内容
        modified_content = replace_material_page_route(original_content)

        # 如果有修改，写回文件
        if modified_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            return True, import_added

        return False, import_added

    except Exception as e:
        print(f"  Error: {e}")
        return False, False

def main():
    """主函数"""
    print("=" * 60)
    print("批量替换 MaterialPageRoute 为 NavigationHelper v3.0")
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
            modified, import_added = process_file(file_path)

            if modified:
                print(f"  [OK] 已替换 MaterialPageRoute")
                success_count += 1
                if import_added:
                    import_count += 1
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
