#!/usr/bin/env python3
"""
Memento 小应用仓库 - 文件列表生成工具

功能：
- 自动扫描指定目录下的所有小应用
- 计算每个文件的 MD5 和大小
- 生成 files.json 文件

使用方法：
    python3 generate_files_json.py
    python3 generate_files_json.py --app password_manager  # 只处理指定应用
    python3 generate_files_json.py --dry-run              # 预览不写入
"""

import os
import sys
import json
import hashlib
import argparse
from pathlib import Path
from typing import List, Dict, Optional


def calculate_md5(file_path: str) -> str:
    """计算文件的 MD5 值"""
    hash_md5 = hashlib.md5()
    try:
        with open(file_path, "rb") as f:
            # 分块读取，避免大文件占用过多内存
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except Exception as e:
        print(f"  ❌ 计算 MD5 失败: {file_path} - {e}")
        return ""


def get_file_size(file_path: str) -> int:
    """获取文件大小（字节）"""
    try:
        return os.path.getsize(file_path)
    except Exception as e:
        print(f"  ❌ 获取文件大小失败: {file_path} - {e}")
        return 0


def should_ignore_file(file_name: str) -> bool:
    """判断文件是否应该被忽略"""
    ignore_patterns = [
        'files.json',      # 文件列表本身
        '.DS_Store',       # macOS 系统文件
        'Thumbs.db',       # Windows 系统文件
        '.gitkeep',        # Git 占位文件
        '.gitignore',      # Git 配置
        'README.md',       # 说明文档
        'LICENSE',         # 许可证文件
    ]

    # 检查是否匹配忽略模式
    if file_name in ignore_patterns:
        return True

    # 忽略隐藏文件
    if file_name.startswith('.'):
        return True

    return False


def scan_app_directory(app_path: Path) -> List[Dict[str, any]]:
    """
    扫描应用目录，生成文件列表

    Args:
        app_path: 应用目录路径

    Returns:
        文件信息列表
    """
    files_info = []

    # 递归遍历目录
    for root, dirs, files in os.walk(app_path):
        # 排除隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for file_name in sorted(files):
            if should_ignore_file(file_name):
                continue

            file_path = Path(root) / file_name

            # 计算相对于应用目录的路径
            try:
                relative_path = file_path.relative_to(app_path)
            except ValueError:
                continue

            # 使用正斜杠作为路径分隔符（跨平台兼容）
            relative_path_str = str(relative_path).replace(os.sep, '/')

            print(f"  📄 处理文件: {relative_path_str}")

            # 计算 MD5 和大小
            md5_hash = calculate_md5(str(file_path))
            file_size = get_file_size(str(file_path))

            if md5_hash and file_size > 0:
                files_info.append({
                    "path": relative_path_str,
                    "md5": md5_hash,
                    "size": file_size
                })
                print(f"    ✓ MD5: {md5_hash}, Size: {file_size} bytes")
            else:
                print(f"    ⚠️  跳过无效文件")

    return files_info


def generate_files_json(base_path: Path, app_name: Optional[str] = None, dry_run: bool = False) -> int:
    """
    生成应用的 files.json 文件

    Args:
        base_path: 仓库根目录
        app_name: 指定应用名称（可选）
        dry_run: 是否为预览模式

    Returns:
        处理的应用数量
    """
    processed_count = 0

    # 如果指定了应用名称，只处理该应用
    if app_name:
        app_dirs = [app_name]
    else:
        # 获取所有子目录（排除特殊目录）
        app_dirs = [
            d for d in os.listdir(base_path)
            if os.path.isdir(base_path / d) and not d.startswith('.')
        ]

    for app_dir in sorted(app_dirs):
        app_path = base_path / app_dir

        # 确认目录存在
        if not app_path.exists() or not app_path.is_dir():
            print(f"\n⚠️  跳过: {app_dir} (不是有效目录)")
            continue

        print(f"\n{'='*60}")
        print(f"📦 处理应用: {app_dir}")
        print(f"{'='*60}")

        # 扫描目录
        files_info = scan_app_directory(app_path)

        if not files_info:
            print(f"  ⚠️  未找到有效文件，跳过")
            continue

        # 生成 JSON
        json_path = app_path / "files.json"
        json_content = json.dumps(files_info, indent=2, ensure_ascii=False)

        if dry_run:
            print(f"\n  🔍 [预览模式] 将写入到: {json_path}")
            print(f"\n{json_content}")
        else:
            try:
                with open(json_path, 'w', encoding='utf-8') as f:
                    f.write(json_content)
                print(f"\n  ✅ 成功生成: {json_path}")
                print(f"  📊 文件总数: {len(files_info)}")
                print(f"  💾 总大小: {sum(f['size'] for f in files_info)} bytes")
            except Exception as e:
                print(f"  ❌ 写入失败: {e}")
                continue

        processed_count += 1

    return processed_count


def main():
    parser = argparse.ArgumentParser(
        description='Memento 小应用仓库 - 文件列表生成工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                          # 处理所有应用
  %(prog)s --app password_manager   # 只处理密码管理器
  %(prog)s --dry-run                # 预览模式，不实际写入文件
  %(prog)s --app my_app --dry-run   # 预览指定应用
        """
    )

    parser.add_argument(
        '--app',
        type=str,
        help='指定要处理的应用名称（目录名）'
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='预览模式，不实际写入文件'
    )

    parser.add_argument(
        '--base-path',
        type=str,
        default='.',
        help='仓库根目录路径（默认为当前目录）'
    )

    args = parser.parse_args()

    # 确定基础路径
    base_path = Path(args.base_path).resolve()

    print("="*60)
    print("🚀 Memento 小应用仓库 - 文件列表生成工具")
    print("="*60)
    print(f"📁 仓库路径: {base_path}")

    if args.app:
        print(f"🎯 目标应用: {args.app}")
    else:
        print(f"🎯 目标应用: 全部")

    if args.dry_run:
        print(f"🔍 运行模式: 预览模式（不写入文件）")
    else:
        print(f"✍️  运行模式: 正常模式（将写入文件）")

    # 检查目录是否存在
    if not base_path.exists():
        print(f"\n❌ 错误: 目录不存在 - {base_path}")
        sys.exit(1)

    # 生成文件列表
    try:
        processed_count = generate_files_json(base_path, args.app, args.dry_run)

        print(f"\n{'='*60}")
        print(f"✨ 完成!")
        print(f"📊 处理应用数: {processed_count}")
        print(f"{'='*60}\n")

        if processed_count == 0:
            print("⚠️  警告: 未处理任何应用，请检查目录结构")
            sys.exit(1)

    except KeyboardInterrupt:
        print(f"\n\n⚠️  操作已取消")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
