#!/usr/bin/env python3
"""
Dart Import 转换脚本
将相对路径的 import 语句转换为 package 导入格式
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Optional


class DartImportConverter:
    def __init__(self, package_name: str = "Memento"):
        self.package_name = package_name
        self.changes = []  # 记录所有更改

    def convert_relative_to_package_import(self, import_line: str, current_file: str) -> Optional[Tuple[str, str]]:
        """
        将相对路径的 import 语句转换为 package 导入

        Args:
            import_line: 原始的 import 语句
            current_file: 当前文件的路径

        Returns:
            Tuple[新import语句, 转换说明] 或 None（如果不需要转换）
        """
        # 匹配相对路径的 import 语句
        # 例如: import '../../../xx/xx/index.dart'
        pattern = r"import\s+['\"]((\.\./)+[^'\"]+)['\"];"

        match = re.match(pattern, import_line.strip())
        if not match:
            return None

        relative_path = match.group(1)

        # 计算当前文件相对于 lib/ 的深度
        current_path = Path(current_file)
        try:
            # 找到 lib 目录
            lib_idx = current_path.parts.index('lib')
        except ValueError:
            # 如果不在 lib 目录下，则假设在项目根目录
            lib_depth = 0
        else:
            # lib 目录之后的部分就是相对于 lib/ 的深度
            lib_depth = len(current_path.parts[lib_idx + 1:])

        # 计算需要向上跳的层级数
        # 统计 ../ 的数量
        upward_count = 0
        temp_path = relative_path
        while temp_path.startswith('../'):
            upward_count += 1
            temp_path = temp_path[3:]  # 移除 '../'

        # 如果向上跳的层级数大于等于当前深度，则不需要转换
        if upward_count >= lib_depth:
            return None

        # 构建绝对路径
        remaining_path = temp_path
        if remaining_path.startswith('lib/'):
            remaining_path = remaining_path[4:]  # 移除 'lib/' 前缀

        # 构建 package 路径
        package_path = remaining_path

        # 生成新的 import 语句
        new_import = f"import 'package:{self.package_name}/{package_path}';"

        # 生成转换说明
        old_import = import_line.strip()
        conversion_note = f"{old_import} -> {new_import}"

        return new_import, conversion_note

    def process_dart_file(self, file_path: str, dry_run: bool = True) -> bool:
        """
        处理单个 Dart 文件

        Args:
            file_path: Dart 文件路径
            dry_run: 是否为 dry_run 模式

        Returns:
            是否进行了任何修改
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            lines = content.split('\n')
            new_lines = []
            modified = False

            for line_num, line in enumerate(lines, 1):
                result = self.convert_relative_to_package_import(line, file_path)
                if result:
                    new_import, conversion_note = result
                    self.changes.append({
                        'file': file_path,
                        'line': line_num,
                        'old': line.strip(),
                        'new': new_import,
                        'note': conversion_note
                    })

                    if not dry_run:
                        new_lines.append(new_import)
                    else:
                        new_lines.append(line)
                    modified = True
                else:
                    new_lines.append(line)

            # 如果不是 dry_run 模式，且有修改，则写入文件
            if modified and not dry_run:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(new_lines))

            return modified

        except Exception as e:
            print(f"处理文件 {file_path} 时出错: {e}", file=sys.stderr)
            return False

    def find_dart_files(self, lib_dir: str = "lib") -> List[str]:
        """
        查找所有 Dart 文件

        Args:
            lib_dir: lib 目录路径

        Returns:
            Dart 文件路径列表
        """
        dart_files = []
        if not os.path.exists(lib_dir):
            print(f"目录 {lib_dir} 不存在", file=sys.stderr)
            return dart_files

        for root, dirs, files in os.walk(lib_dir):
            for file in files:
                if file.endswith('.dart'):
                    dart_files.append(os.path.join(root, file))

        return dart_files

    def run(self, dry_run: bool = True) -> None:
        """
        执行转换

        Args:
            dry_run: dry_run 模式标志
        """
        print(f"{'='*60}")
        print(f"Dart Import 转换工具")
        print(f"Package Name: {self.package_name}")
        mode_text = 'DRY RUN (仅预览)' if dry_run else '实际修改'
        print(f"模式: {mode_text}")
        print(f"{'='*60}\n")

        # 查找所有 Dart 文件
        dart_files = self.find_dart_files("lib")
        print(f"找到 {len(dart_files)} 个 Dart 文件\n")

        # 处理每个文件
        total_files_modified = 0
        for file_path in dart_files:
            if self.process_dart_file(file_path, dry_run):
                total_files_modified += 1

        # 输出结果
        print(f"\n{'='*60}")
        print(f"转换结果摘要:")
        print(f"  - 扫描文件: {len(dart_files)}")
        print(f"  - 需修改文件: {total_files_modified}")
        print(f"  - 总转换数: {len(self.changes)}")

        if self.changes:
            print(f"\n{'='*60}")
            print(f"转换详情:")
            print(f"{'='*60}")

            for change in self.changes:
                print(f"\n文件: {change['file']}")
                print(f"行号: {change['line']}")
                print(f"转换: {change['note']}")

            print(f"\n{'='*60}")
            if dry_run:
                print("[WARN]  当前为 DRY RUN 模式，不会实际修改文件")
                print("       如需实际修改，请使用: python convert_imports.py --apply")
            else:
                print("[OK]    所有文件已成功修改")
        else:
            print("\n[OK]    所有文件都已使用正确的 package 导入格式，无需转换")


def print_help():
    """打印帮助信息"""
    print("""
Dart Import 转换工具
用法:
  python convert_imports.py [--help] [--apply] [--package-name NAME]

参数:
  --help, -h          显示此帮助信息
  --apply             实际修改文件（默认只预览）
  --package-name NAME 指定包名（默认: Memento）

示例:
  python convert_imports.py                    # 预览模式
  python convert_imports.py --apply            # 实际修改文件
  python convert_imports.py --package-name my_app  # 指定包名
""")


def main():
    """主函数"""
    dry_run = True
    package_name = "Memento"

    # 解析命令行参数
    args = sys.argv[1:]
    if '--help' in args or '-h' in args:
        print_help()
        return

    if '--apply' in args:
        dry_run = False

    # 查找 --package-name 参数
    try:
        idx = args.index('--package-name')
        if idx + 1 < len(args):
            package_name = args[idx + 1]
    except ValueError:
        pass

    # 创建转换器并运行
    converter = DartImportConverter(package_name=package_name)
    converter.run(dry_run=dry_run)


if __name__ == "__main__":
    main()
