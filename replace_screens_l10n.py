#!/usr/bin/env python3
"""
批量替换 screens 目录中的 ScreensLocalizations.of(context) 为 GetX .tr 调用
"""
import re
import os
from pathlib import Path

# 需要替换的文件列表
FILES_TO_REPLACE = [
    r"D:\Memento\lib\screens\home_screen\widgets\add_widget_dialog.dart",
    r"D:\Memento\lib\screens\home_screen\home_screen.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\background_settings_page.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\folder_dialog.dart",
    r"D:\Memento\lib\screens\intent_test_screen\intent_test_screen.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\layout_manager_dialog.dart",
    r"D:\Memento\lib\screens\json_dynamic_test\json_dynamic_test_screen.dart",
    r"D:\Memento\lib\screens\settings_screen\settings_screen.dart",
    r"D:\Memento\lib\screens\js_console\widgets\example_buttons.dart",
    r"D:\Memento\lib\screens\notification_test\notification_test_page.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\home_grid.dart",
    r"D:\Memento\lib\screens\super_cupertino_test_screen\super_cupertino_test_screen.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\widget_settings_dialog.dart",
    r"D:\Memento\lib\screens\settings_screen\controllers\base_settings_controller.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\home_card.dart",
    r"D:\Memento\lib\screens\js_console\js_console_screen.dart",
    r"D:\Memento\lib\screens\home_screen\widgets\layout_type_selector.dart",
    r"D:\Memento\lib\screens\floating_widget_screen\floating_widget_screen.dart",
]

# 替换映射表（带参数的方法）
PARAMETERIZED_METHODS = {
    'errorHabitNotFound': lambda m: f"'screens_errorHabitNotFound'.trParams({{'id': {m.group(1)}}})",
    'ballSizeDp': lambda m: f"'screens_ballSizeDp'.trParams({{'size': {m.group(1)}.toString()}})",
    'snapThresholdPx': lambda m: f"'screens_snapThresholdPx'.trParams({{'threshold': {m.group(1)}.toString()}})",
    'buttonCount': lambda m: f"'screens_buttonCount'.trParams({{'count': {m.group(1)}.toString()}})",
    'confirmDeleteItem': lambda m: f"'screens_confirmDeleteItem'.trParams({{'itemName': {m.group(1)}}})",
    'dragItemToFolder': lambda m: f"'screens_dragItemToFolder'.trParams({{'item': {m.group(1)}, 'folder': {m.group(2)}}})",
    'confirmDeleteLayout': lambda m: f"'screens_confirmDeleteLayout'.trParams({{'layoutName': {m.group(1)}}})",
    'layoutInfo': lambda m: f"'screens_layoutInfo'.trParams({{'items': {m.group(1)}.toString(), 'columns': {m.group(2)}.toString()}})",
    'bulletScheme': lambda m: f"'screens_bulletScheme'.trParams({{'scheme': {m.group(1)}}})",
    'layoutSaved': lambda m: f"'screens_layoutSaved'.trParams({{'name': {m.group(1)}}})",
    'itemCount': lambda m: f"'screens_itemCount'.trParams({{'count': {m.group(1)}.toString()}})",
    'layoutBackgroundSettings': lambda m: f"'screens_layoutBackgroundSettings'.trParams({{'layoutName': {m.group(1)}}})",
    'clickedButton': lambda m: f"'screens_clickedButton'.trParams({{'buttonName': {m.group(1)}}})",
    'xPositionYPosition': lambda m: f"'screens_xPositionYPosition'.trParams({{'x': {m.group(1)}.toStringAsFixed(0), 'y': {m.group(2)}.toStringAsFixed(0)}})",
    'confirmDeleteSelectedItems': lambda m: f"'screens_confirmDeleteSelectedItems'.trParams({{'count': {m.group(1)}.toString()}})",
    'widgetSize': lambda m: f"'screens_widgetSize'.trParams({{'width': {m.group(1)}.toString(), 'height': {m.group(2)}.toString()}})",
    'itemsDeleted': lambda m: f"'screens_itemsDeleted'.trParams({{'count': {m.group(1)}.toString()}})",
    'itemsMovedToFolder': lambda m: f"'screens_itemsMovedToFolder'.trParams({{'count': {m.group(1)}.toString()}})",
    'gridColumns': lambda m: f"'screens_gridColumns'.trParams({{'count': {m.group(1)}.toString()}})",
    'folderCreated': lambda m: f"'screens_folderCreated'.trParams({{'name': {m.group(1)}}})",
    'moveIn': lambda m: f"'screens_moveIn'.trParams({{'count': {m.group(1)}.toString()}})",
    'fruitIndex': lambda m: f"'screens_fruitIndex'.trParams({{'index': ({m.group(1)} + 1).toString()}})",
}

def replace_import(content):
    """替换导入语句"""
    # 移除 ScreensLocalizations 导入
    content = re.sub(
        r"import 'package:Memento/screens/l10n/screens_localizations\.dart';\n?",
        "",
        content
    )

    # 确保有 GetX 导入
    if "import 'package:get/get.dart';" not in content:
        # 在第一个 import 之前添加
        content = re.sub(
            r"(import 'package:flutter/material\.dart';)",
            r"\1\nimport 'package:get/get.dart';",
            content,
            count=1
        )

    return content

def replace_l10n_usage(content):
    """替换所有的 l10n 使用"""
    # 移除 final l10n = ScreensLocalizations.of(context);
    content = re.sub(
        r"\s*final l10n = ScreensLocalizations\.of\(context\);\n?",
        "",
        content
    )

    # 替换带参数的方法调用
    for method_name, replacer in PARAMETERIZED_METHODS.items():
        # 匹配不同参数数量的模式
        if method_name in ['dragItemToFolder', 'layoutInfo', 'widgetSize', 'xPositionYPosition']:
            # 双参数
            pattern = rf"(?:l10n|ScreensLocalizations\.of\(context\))\.{method_name}\(([^,]+),\s*([^)]+)\)"
            content = re.sub(pattern, lambda m: replacer(m), content)
        else:
            # 单参数
            pattern = rf"(?:l10n|ScreensLocalizations\.of\(context\))\.{method_name}\(([^)]+)\)"
            content = re.sub(pattern, lambda m: replacer(m), content)

    # 替换简单的属性访问 (l10n.xxx 或 ScreensLocalizations.of(context).xxx)
    def replace_property(match):
        property_name = match.group(1)
        return f"'screens_{property_name}'.tr"

    content = re.sub(
        r"(?:l10n|ScreensLocalizations\.of\(context\))\.(\w+)",
        replace_property,
        content
    )

    return content

def process_file(file_path):
    """处理单个文件"""
    print(f"处理文件: {file_path}")

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # 替换导入
        content = replace_import(content)

        # 替换使用
        content = replace_l10n_usage(content)

        # 如果有修改,写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  [OK] Updated")
            return 1
        else:
            print(f"  [SKIP] No changes needed")
            return 0

    except Exception as e:
        print(f"  [ERROR] {e}")
        return 0

def main():
    """主函数"""
    print("Starting batch replacement of screens localization calls...\n")

    updated_count = 0
    for file_path in FILES_TO_REPLACE:
        if os.path.exists(file_path):
            updated_count += process_file(file_path)
        else:
            print(f"File not found: {file_path}")

    print(f"\nDone! Updated {updated_count} files")

if __name__ == "__main__":
    main()
