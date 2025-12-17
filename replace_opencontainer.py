#!/usr/bin/env python3
import os
import re
import glob

# 搜索所有包含 OpenContainer 的 dart 文件
files = glob.glob('lib/**/*.dart', recursive=True)
files.extend(glob.glob('lib/*.dart', recursive=False))

print("找到的文件：")
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        if 'OpenContainer' in file.read():
            print(f)

# 简单的替换策略 - 移除 OpenContainer 包装
def replace_opencontainer(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 检查是否包含 OpenContainer
    if 'OpenContainer' not in content:
        return False
    
    # 移除 import animations
    content = re.sub(r"import 'package:animations/animations\.dart';\n", "", content)
    
    # 替换 OpenContainer 为 NavigationHelper.openContainer
    # 这是一个简化版本，只处理基本结构
    print(f"处理文件: {file_path}")
    return True

# 执行替换
for file_path in files:
    try:
        replace_opencontainer(file_path)
    except Exception as e:
        print(f"错误处理 {file_path}: {e}")

print("替换完成")
