#!/bin/bash

# 获取当前日期和时间，用于提交信息
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# 检查是否有更改
git status lib/ --porcelain

if [ -z "$(git status lib/ --porcelain)" ]; then
    echo "没有检测到lib/目录下的文件更改。"
else
    # 添加lib目录下的所有更改
    git add lib/
    
    # 提交更改
    git commit -m "Backup lib/ files: $TIMESTAMP"
    
    echo "已成功备份lib/目录下的文件更改。"
    
    # 显示最近的提交
    echo -e "\n最近的提交记录:"
    git log -1 --stat
fi