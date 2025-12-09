#!/bin/bash
# 迁移单个插件的脚本
# 用法: ./migrate_plugin.sh <plugin_id> <LocalizationsClass>

PLUGIN_ID=$1
LOCAL_CLASS=$2

if [ -z "$PLUGIN_ID" ] || [ -z "$LOCAL_CLASS" ]; then
    echo "用法: $0 <plugin_id> <LocalizationsClass>"
    exit 1
fi

PLUGIN_DIR="D:/Memento/lib/plugins/$PLUGIN_ID"

echo "处理插件: $PLUGIN_ID"

# 查找所有dart文件(排除l10n目录)
find "$PLUGIN_DIR" -name "*.dart" -not -path "*/l10n/*" -type f | while read file; do
    # 检查文件是否包含旧的localizations调用
    if grep -q "${LOCAL_CLASS}\.of(context)" "$file"; then
        echo "  处理: $(basename $file)"
        
        # 1. 删除旧的localizations导入
        sed -i "/import.*l10n\/${PLUGIN_ID}_localizations\.dart/d" "$file"
        
        # 2. 添加GetX导入(如果不存在)
        if ! grep -q "import 'package:get/get.dart';" "$file"; then
            # 在第一个import后添加
            sed -i "0,/^import /s//import 'package:get\/get.dart';\nimport /" "$file"
        fi
        
        # 3. 替换localizations调用
        # 使用perl进行高级替换
        perl -i -pe "s/${LOCAL_CLASS}\.of\(context\)\.(\w+)/'${PLUGIN_ID}_\$1'.tr/g" "$file"
    fi
done

echo "完成: $PLUGIN_ID"
