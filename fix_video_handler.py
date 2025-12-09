#!/usr/bin/env python3
"""
修复 LocalVideoHandlerLocalizations 引用
"""
import os
import re
from pathlib import Path

def fix_file(file_path):
    """修复单个文件"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # 映射翻译键
    replacements = {
        'LocalVideoHandlerLocalizations.getText(\\s*context,\\s*LocalVideoHandlerLocalizations.videoCantBeSelectedOnWeb\\s*)': "'chat_videoCantBeSelectedOnWeb'.tr",
        'LocalVideoHandlerLocalizations.getText(\\s*context,\\s*LocalVideoHandlerLocalizations.videoFileNotExist\\s*)': "'chat_videoFileNotExist'.tr",
        'LocalVideoHandlerLocalizations.getText(\\s*context,\\s*LocalVideoHandlerLocalizations.videoSent\\s*)': "'chat_videoSent'.tr",
        'LocalVideoHandlerLocalizations.getText(\\s*context,\\s*LocalVideoHandlerLocalizations.videoProcessingFailed,\\s*([^)]+)\\s*)': r"'${'chat_videoProcessingFailed'.tr}: \1'",
        'LocalVideoHandlerLocalizations.getText(\\s*context,\\s*LocalVideoHandlerLocalizations.videoSelectionFailed,\\s*([^)]+)\\s*)': r"'${'chat_videoSelectionFailed'.tr}: \1'",
    }

    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)

    # 特殊处理带格式化的情况
    content = re.sub(
        r"\'\$\{LocalVideoHandlerLocalizations\.getText\(context, LocalVideoHandlerLocalizations\.videoSent\)\}: \$\{path\.basename\(video\.path\)\}\'",
        r"'${'chat_videoSent'.tr}: ${path.basename(video.path)}'",
        content
    )

    # 如果内容有变化，写回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    """主函数"""
    files = [
        Path('D:/Memento/lib/plugins/chat/screens/chat_screen/widgets/message_input_actions/handlers/video_handler.dart'),
    ]

    fixed_count = 0
    for file_path in files:
        if file_path.exists():
            try:
                if fix_file(str(file_path)):
                    fixed_count += 1
                    print(f"[OK] Fixed: {file_path.name}")
            except Exception as e:
                print(f"[ERROR] {file_path.name}: {e}")

    print(f"\nTotal fixed: {fixed_count} files")

if __name__ == '__main__':
    main()
