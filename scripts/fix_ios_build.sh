#!/bin/bash
# iOS 构建前修复脚本
# 用于解决 Xcode 16+ 中 Swift 模块接口与 bridging headers 的冲突问题

set -e

echo "正在修复 iOS 构建问题..."

# 进入 iOS 目录
cd ios

# 检查是否在正确的目录
if [ ! -f "Podfile" ]; then
    echo "错误：未找到 Podfile，请在项目根目录运行此脚本"
    exit 1
fi

# 1. 重新运行 pod install 以确保配置正确
echo "正在重新运行 pod install..."
pod install --verbose 2>&1 | tail -20

# 2. 修复 Pods 项目中的 SWIFT_COMPILATION_MODE
echo "正在修复 Pods 项目的 Swift 编译模式..."
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/SWIFT_COMPILATION_MODE = wholemodule;/SWIFT_COMPILATION_MODE = singlefile;/g' Pods/Pods.xcodeproj/project.pbxproj
    echo "✅ 已将 SWIFT_COMPILATION_MODE 修改为 singlefile"
else
    echo "⚠️  警告：未找到 Pods 项目文件"
fi

# 3. 确保 SWIFT_EMIT_MODULE_INTERFACE 被设置为 NO
if [ -f "Pods/Pods.xcodeproj/project.pbxproj" ]; then
    # 检查是否已经设置为 NO
    if grep -q "SWIFT_EMIT_MODULE_INTERFACE = YES" Pods/Pods.xcodeproj/project.pbxproj; then
        sed -i '' 's/SWIFT_EMIT_MODULE_INTERFACE = YES;/SWIFT_EMIT_MODULE_INTERFACE = NO;/g' Pods/Pods.xcodeproj/project.pbxproj
        echo "✅ 已将 SWIFT_EMIT_MODULE_INTERFACE 修改为 NO"
    else
        echo "✅ SWIFT_EMIT_MODULE_INTERFACE 已经正确设置"
    fi
fi

# 4. 确保 Runner 项目的 SWIFT_COMPILATION_MODE 也被修改
echo "正在修复 Runner 项目的 Swift 编译模式..."
if [ -f "Runner.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/SWIFT_COMPILATION_MODE = wholemodule;/SWIFT_COMPILATION_MODE = singlefile;/g' Runner.xcodeproj/project.pbxproj
    echo "✅ 已将 Runner 项目的 SWIFT_COMPILATION_MODE 修改为 singlefile"
else
    echo "⚠️  警告：未找到 Runner 项目文件"
fi

# 5. 创建或更新隐私包占位文件
echo "正在创建隐私包占位文件..."
ruby create_privacy_bundles.rb 2>/dev/null || true

# 运行 bundle 修复脚本
if [ -f "fix_bundles.rb" ]; then
    ruby fix_bundles.rb 2>/dev/null || true
fi

echo ""
echo "✅ iOS 构建修复完成！"
echo "现在可以运行: flutter build ios"
