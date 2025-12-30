#!/usr/bin/env python3
"""
Memento 仓库 - 文件列表生成工具

功能：
- 自动扫描指定目录下的所有应用和脚本
- 计算每个文件的 MD5 和大小
- 生成 files.json 文件

使用方法：
    python3 generate_files_json.py
    python3 generate_files_json.py --type apps           # 只处理 apps
    python3 generate_files_json.py --type scripts        # 只处理 scripts
    python3 generate_files_json.py --app password_manager  # 只处理指定应用
    python3 generate_files_json.py --script ai_encouragement_bot  # 只处理指定脚本
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


def scan_item_directory(item_path: Path) -> List[Dict[str, any]]:
    """
    扫描应用/脚本目录，生成文件列表

    Args:
        item_path: 应用/脚本目录路径

    Returns:
        文件信息列表
    """
    files_info = []

    # 递归遍历目录
    for root, dirs, files in os.walk(item_path):
        # 排除隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for file_name in sorted(files):
            if should_ignore_file(file_name):
                continue

            file_path = Path(root) / file_name

            # 计算相对于应用/脚本目录的路径
            try:
                relative_path = file_path.relative_to(item_path)
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


def generate_files_json_for_type(base_path: Path, item_type: str, item_name: Optional[str] = None, dry_run: bool = False) -> int:
    """
    生成指定类型（apps/scripts）的 files.json 文件

    Args:
        base_path: 仓库根目录
        item_type: 类型 (apps/scripts)
        item_name: 指定应用/脚本名称（可选）
        dry_run: 是否为预览模式

    Returns:
        处理的应用/脚本数量
    """
    processed_count = 0
    type_path = base_path / item_type

    if not type_path.exists():
        print(f"\n⚠️  跳过: {item_type} 目录不存在")
        return 0

    # 如果指定了名称，只处理该应用/脚本
    if item_name:
        item_dirs = [item_name]
    else:
        # 获取所有子目录（排除特殊目录）
        item_dirs = [
            d for d in os.listdir(type_path)
            if os.path.isdir(type_path / d) and not d.startswith('.')
        ]

    for item_dir in sorted(item_dirs):
        item_path = type_path / item_dir

        # 确认目录存在
        if not item_path.exists() or not item_path.is_dir():
            print(f"\n⚠️  跳过: {item_dir} (不是有效目录)")
            continue

        print(f"\n{'='*60}")
        item_label = "应用" if item_type == "apps" else "脚本"
        print(f"📦 处理{item_label}: {item_dir}")
        print(f"{'='*60}")

        # 扫描目录
        files_info = scan_item_directory(item_path)

        if not files_info:
            print(f"  ⚠️  未找到有效文件，跳过")
            continue

        # 生成 JSON
        json_path = item_path / "files.json"
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
        description='Memento 仓库 - 文件列表生成工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                                    # 处理所有应用和脚本
  %(prog)s --type apps                        # 只处理应用
  %(prog)s --type scripts                     # 只处理脚本
  %(prog)s --app password_manager             # 只处理密码管理器
  %(prog)s --script ai_encouragement_bot      # 只处理 AI 鼓励助手
  %(prog)s --dry-run                          # 预览模式，不实际写入文件
        """
    )

    parser.add_argument(
        '--type',
        type=str,
        choices=['apps', 'scripts', 'all'],
        default='all',
        help='指定要处理的类型 (apps/scripts/all)，默认为 all'
    )

    parser.add_argument(
        '--app',
        type=str,
        help='指定要处理的应用名称（目录名）'
    )

    parser.add_argument(
        '--script',
        type=str,
        help='指定要处理的脚本名称（目录名）'
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
    print("🚀 Memento 仓库 - 文件列表生成工具")
    print("="*60)
    print(f"📁 仓库路径: {base_path}")

    # 确定处理类型
    if args.app:
        types_to_process = ['apps']
        print(f"🎯 目标应用: {args.app}")
    elif args.script:
        types_to_process = ['scripts']
        print(f"🎯 目标脚本: {args.script}")
    elif args.type == 'all':
        types_to_process = ['apps', 'scripts']
        print(f"🎯 目标类型: 全部 (apps + scripts)")
    else:
        types_to_process = [args.type]
        print(f"🎯 目标类型: {args.type}")

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
        total_processed = 0
        for item_type in types_to_process:
            item_name = args.app if item_type == 'apps' else args.script
            processed_count = generate_files_json_for_type(
                base_path,
                item_type,
                item_name,
                args.dry_run
            )
            total_processed += processed_count

        print(f"\n{'='*60}")
        print(f"✨ 完成!")
        print(f"📊 处理总数: {total_processed}")
        print(f"{'='*60}\n")

        if total_processed == 0:
            print("⚠️  警告: 未处理任何项目，请检查目录结构")
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
