#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""验证核心模块国际化实现"""

import os
import re
import sys

# 设置 stdout 为 UTF-8 编码
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("验证核心模块国际化实现")
print("=" * 60)

# 1. 检查国际化文件是否存在
print("\n1. 检查国际化文件...")
i18n_files = [
    'lib/core/l10n/core_localizations.dart',
    'lib/core/l10n/core_localizations_zh.dart',
    'lib/core/l10n/core_localizations_en.dart'
]

for file_path in i18n_files:
    if os.path.exists(file_path):
        print(f"  [OK] {file_path}")
    else:
        print(f"  [FAIL] {file_path} - 文件不存在")

# 2. 检查 main.dart 中的注册
print("\n2. 检查 main.dart 中的注册...")
main_path = 'lib/main.dart'
with open(main_path, 'r', encoding='utf-8') as f:
    main_content = f.read()

if 'import \'package:Memento/core/l10n/core_localizations.dart\';' in main_content:
    print("  [OK] 核心模块国际化导入已添加")
else:
    print("  [FAIL] 核心模块国际化导入未找到")

if 'CoreLocalizationsDelegate()' in main_content:
    print("  [OK] 核心模块国际化委托已注册")
else:
    print("  [FAIL] 核心模块国际化委托未找到")

# 3. 检查各文件中的硬编码文本替换
print("\n3. 检查硬编码文本替换...")
files_to_check = [
    {
        'path': 'lib/core/action/action_executor.dart',
        'checks': [
            ("CoreLocalizations.of(context)!.inputJavaScriptCode", "输入JavaScript代码"),
            ("CoreLocalizations.of(context)!.cancel", "取消"),
            ("CoreLocalizations.of(context)!.execute", "执行")
        ]
    },
    {
        'path': 'lib/core/action/examples/custom_action_examples.dart',
        'checks': [
            ("CoreLocalizations.of(context)!.inputJavaScriptCode", "输入JavaScript代码"),
            ("CoreLocalizations.of(context)!.save", "保存"),
            ("CoreLocalizations.of(context)!.executionResult", "执行结果")
        ]
    },
    {
        'path': 'lib/core/floating_ball/screens/floating_button_manager_screen.dart',
        'checks': [
            ("CoreLocalizations.of(context)!.confirmDelete", "确认删除"),
            ("CoreLocalizations.of(context)!.floatingButtonManager", "悬浮按钮管理")
        ]
    }
]

for file_info in files_to_check:
    path = file_info['path']
    print(f"\n  文件: {path}")

    if not os.path.exists(path):
        print(f"    [WARN] 文件不存在")
        continue

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    for check in file_info['checks']:
        if check[0] in content:
            print(f"    [OK] 已替换: {check[1]}")
        else:
            # 检查是否还有硬编码文本
            if check[1] in content and f"const Text('{check[1]}')" in content:
                print(f"    [FAIL] 仍有硬编码: {check[1]}")
            else:
                print(f"    [INFO] 未找到相关文本: {check[1]}")

print("\n" + "=" * 60)
print("验证完成！")
print("=" * 60)