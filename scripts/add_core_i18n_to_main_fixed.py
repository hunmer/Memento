#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""向 main.dart 添加核心模块国际化支持"""

import re
import os
import sys

# 设置 stdout 为 UTF-8 编码
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# 读取 main.dart 文件
main_path = 'lib/main.dart'
with open(main_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. 添加导入语句
# 在 floating_ball_localizations.dart 导入后添加
import_pattern = r"(import 'package:Memento/core/floating_ball/l10n/floating_ball_localizations.dart';)"
if 'import \'package:Memento/core/l10n/core_localizations.dart\';' not in content:
    content = re.sub(
        import_pattern,
        r"\1\nimport 'package:Memento/core/l10n/core_localizations.dart';",
        content
    )
    print("[OK] Added core module import")

# 2. 添加国际化委托
# 在 FloatingBallLocalizations.delegate 后添加
delegate_pattern = r"(FloatingBallLocalizations\.delegate,)"
if 'CoreLocalizationsDelegate(),' not in content:
    content = re.sub(
        delegate_pattern,
        r"\1\n              CoreLocalizationsDelegate(),",
        content
    )
    print("[OK] Added core module localization delegate")

# 写回文件
with open(main_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n[SUCCESS] main.dart updated successfully!")