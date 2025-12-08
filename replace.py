import os
import re

# 配置
package_name = 'Memento'  # 替换成你的实际包名
root_dir = 'lib'  # 通常Dart文件在lib下，调整如果需要
dry_run = True  # 先设置为True，只打印变化，不实际修改

def normalize_path(relative_path):
    # 移除前导的 '../' 并标准化路径
    parts = relative_path.split('/')
    while '..' in parts:
        parts.remove('..')
    return '/'.join(parts)

for subdir, _, files in os.walk(root_dir):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(subdir, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 匹配相对导入：import '相对路径';
            new_content = re.sub(
                r"import\s+'(\.\./)+([^']+)';",
                lambda m: f"import 'package:{package_name}/{normalize_path(m.group(2))}';",
                content
            )
            
            if new_content != content:
                print(f"Changes in {file_path}:")
                print(new_content)  # 打印预览
                
                if not dry_run:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)

print("替换完成。先运行dry_run=True预览变化。")