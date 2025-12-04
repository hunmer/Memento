#!/usr/bin/env python3
"""
复制Material Icons到Flutter Assets目录
将 png/black 子目录下的各个 baseline-4x.png 文件复制到flutter资源目录下，
并重命名为对应的图标名称
"""

import os
import shutil
from pathlib import Path

def main():
    # 定义路径
    source_dir = Path(__file__).parent.parent / "png" / "black"
    dest_dir = Path(__file__).parent.parent / "assets" / "icons" / "material"

    # 创建目标目录
    dest_dir.mkdir(parents=True, exist_ok=True)

    # 检查源目录是否存在
    if not source_dir.exists():
        print(f"❌ 源目录不存在: {source_dir}")
        return

    # 统计信息
    copied_count = 0
    skipped_count = 0
    failed_count = 0

    # 遍历所有子目录
    for icon_dir in source_dir.iterdir():
        if not icon_dir.is_dir():
            continue

        icon_name = icon_dir.name
        baseline_4x_file = icon_dir / "baseline-4x.png"

        # 检查baseline-4x.png是否存在
        if not baseline_4x_file.exists():
            print(f"[SKIP] {icon_name}: baseline-4x.png not found")
            skipped_count += 1
            continue

        # 目标文件名
        dest_file = dest_dir / f"{icon_name}.png"

        try:
            # 复制文件
            shutil.copy2(baseline_4x_file, dest_file)
            print(f"[OK] {icon_name}.png")
            copied_count += 1
        except Exception as e:
            print(f"[FAIL] {icon_name}: {e}")
            failed_count += 1

    # 输出统计信息
    print("\n" + "="*50)
    print(f"Copy completed!")
    print(f"  Success: {copied_count} icons")
    print(f"  Skipped: {skipped_count} icons")
    print(f"  Failed: {failed_count} icons")
    print(f"Target dir: {dest_dir}")
    print("="*50)

if __name__ == "__main__":
    main()
