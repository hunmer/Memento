#!/bin/bash

# 自动创建 Xcode 16.2 需要的 Bundle 文件
# 这是一个临时解决方案，用于修复 Flutter + Xcode 16.2 的兼容性问题

set -e

BUILD_DIR="$BUILT_PRODUCTS_DIR"

# 如果 BUILD_DIR 未设置，使用默认路径
if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="$(pwd)/../build/ios/$CONFIGURATION-iphonesimulator"
fi

echo "🔧 创建缺失的 Bundle 文件..."
echo "构建目录: $BUILD_DIR"

# 检查构建目录是否存在
if [ ! -d "$BUILD_DIR" ]; then
    echo "⚠️  构建目录不存在，跳过 Bundle 创建"
    exit 0
fi

cd "$BUILD_DIR"

# 创建所有缺失的 bundle 文件
count=0
for bundle in */*.bundle; do
    if [ -d "$bundle" ]; then
        filename=$(basename "$bundle" .bundle)
        if [ ! -f "$bundle/$filename" ]; then
            touch "$bundle/$filename"
            echo "✓ 创建: $bundle/$filename"
            ((count++))
        fi
    fi
done

if [ $count -eq 0 ]; then
    echo "✅ 所有 Bundle 文件已存在"
else
    echo "✅ 成功创建 $count 个 Bundle 文件"
fi

exit 0
