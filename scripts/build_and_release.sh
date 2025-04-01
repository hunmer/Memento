#!/bin/bash

# 确保脚本在错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

# 检查必要的命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# 检查必要的工具
check_command "flutter"
check_command "gh"
check_command "git"

# 加载配置文件
CONFIG_FILE="scripts/release_config.json"
if [ -f "$CONFIG_FILE" ]; then
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed. Please install it to parse JSON config.${NC}"
        exit 1
    fi
    
    # 读取平台配置
    if jq -e '.build.platforms' "$CONFIG_FILE" &> /dev/null; then
        PLATFORMS=$(jq -r '.build.platforms | join(" ")' "$CONFIG_FILE")
        echo -e "${GREEN}Building for platforms: $PLATFORMS${NC}"
    else
        echo -e "${YELLOW}No platforms specified in config file. Building for current platform only.${NC}"
        PLATFORMS=""
    fi
else
    echo -e "${YELLOW}Config file not found at $CONFIG_FILE. Building for current platform only.${NC}"
    PLATFORMS=""
fi

# 检查平台是否在构建列表中
is_platform_enabled() {
    if [ -z "$PLATFORMS" ]; then
        # 如果没有指定平台，默认构建当前平台
        return 0
    fi
    
    if [[ $PLATFORMS == *"$1"* ]]; then
        return 0
    else
        return 1
    fi
}

# 获取版本号
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
echo -e "${GREEN}Building version: $VERSION${NC}"

# 创建输出目录
OUTPUT_DIR="build/releases"
mkdir -p $OUTPUT_DIR

# 清理之前的构建
echo -e "${YELLOW}Cleaning previous builds...${NC}"
# flutter clean

# 获取依赖
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# 构建 Android
if is_platform_enabled "android"; then
    echo -e "${YELLOW}Building Android APK...${NC}"
    flutter build apk --release
    mkdir -p "$OUTPUT_DIR"
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/app-$VERSION-android.apk"
        echo -e "${GREEN}Successfully built Android APK: $OUTPUT_DIR/app-$VERSION-android.apk${NC}"
    else
        echo -e "${RED}Error: Android APK build failed or file not found${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Skipping Android build (not in platform list)${NC}"
fi

# 构建 Web
if is_platform_enabled "web"; then
    echo -e "${YELLOW}Building Web...${NC}"
    flutter build web --release
    if [ -d "build/web" ]; then
        (cd build/web && zip -r "../../$OUTPUT_DIR/app-$VERSION-web.zip" .)
        echo -e "${GREEN}Successfully built Web: $OUTPUT_DIR/app-$VERSION-web.zip${NC}"
    else
        echo -e "${RED}Error: Web build failed or directory not found${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Skipping Web build (not in platform list)${NC}"
fi

# 检查是否在 macOS 上构建 iOS 和 macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # 构建 iOS
    if is_platform_enabled "ios"; then
        echo -e "${YELLOW}Building iOS...${NC}"
        
        # 检查是否有必要的证书和配置文件
        if [ -z "$APPLE_DEVELOPMENT_TEAM_ID" ] || [ -z "$PROVISIONING_PROFILE_NAME" ]; then
            echo -e "${RED}Error: APPLE_DEVELOPMENT_TEAM_ID and PROVISIONING_PROFILE_NAME must be set for iOS builds${NC}"
            exit 1
        fi

        # 使用xcodebuild构建和打包
        xcodebuild -workspace ios/Runner.xcworkspace \
                   -scheme Runner \
                   -configuration Release \
                   -archivePath build/ios/archive/Runner.xcarchive \
                   archive \
                   CODE_SIGN_IDENTITY="iPhone Developer" \
                   DEVELOPMENT_TEAM="$APPLE_DEVELOPMENT_TEAM_ID" \
                   PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_NAME"

        # 导出 .ipa 文件
        xcodebuild -exportArchive \
                   -archivePath build/ios/archive/Runner.xcarchive \
                   -exportOptionsPlist ios/ExportOptions.plist \
                   -exportPath build/ios/ipa

        if [ -f "build/ios/ipa/Runner.ipa" ]; then
            mkdir -p "$OUTPUT_DIR"
            mv "build/ios/ipa/Runner.ipa" "$OUTPUT_DIR/app-$VERSION-ios.ipa"
            echo -e "${GREEN}Successfully built iOS .ipa: $OUTPUT_DIR/app-$VERSION-ios.ipa${NC}"
        else
            echo -e "${RED}Error: iOS .ipa build failed${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping iOS build (not in platform list)${NC}"
    fi

    # 构建 macOS
    if is_platform_enabled "macos"; then
        echo -e "${YELLOW}Building macOS...${NC}"
        flutter build macos --release
        
        # 确保输出目录存在
        mkdir -p "$OUTPUT_DIR"
        
        # 检查构建目录
        BUILD_DIR="build/macos/Build/Products/Release"
        if [ -d "$BUILD_DIR/Memento.app" ] || [ -d "$BUILD_DIR/Runner.app" ]; then
            # 确定应用名称
            APP_NAME="Runner.app"
            if [ -d "$BUILD_DIR/Memento.app" ]; then
                APP_NAME="Memento.app"
            fi
            
            echo -e "${YELLOW}Packaging $APP_NAME into DMG...${NC}"
            
            # 检查 create-dmg 是否安装
            if ! command -v create-dmg &> /dev/null; then
                echo -e "${RED}Error: create-dmg is not installed. Please install it using 'brew install create-dmg'${NC}"
                exit 1
            fi
            
            # 创建 DMG 文件
            DMG_NAME="Memento-$VERSION.dmg"
            if create-dmg \
              --volname "Memento" \
              --volicon "assets/icon/app_icon.icns" \
              --window-pos 200 120 \
              --window-size 600 400 \
              --icon-size 100 \
              --icon "$APP_NAME" 175 120 \
              --hide-extension "$APP_NAME" \
              --app-drop-link 425 120 \
              "$OUTPUT_DIR/$DMG_NAME" \
              "$BUILD_DIR/$APP_NAME"; then
                echo -e "${GREEN}Successfully created macOS DMG: $OUTPUT_DIR/$DMG_NAME${NC}"
            else
                echo -e "${RED}Error: Failed to create DMG${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Error: macOS build failed or directory not found${NC}"
            echo -e "${YELLOW}Checking build directory content:${NC}"
            ls -la "$BUILD_DIR"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping macOS build (not in platform list)${NC}"
    fi
fi

# 检查是否在 Linux 上构建
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if is_platform_enabled "linux"; then
        echo -e "${YELLOW}Building Linux...${NC}"
        flutter build linux --release
        if [ -d "build/linux/x64/release/bundle" ]; then
            mkdir -p "$OUTPUT_DIR"
            (cd build/linux/x64/release/bundle && tar czf "../../../../$OUTPUT_DIR/app-$VERSION-linux.tar.gz" .)
            echo -e "${GREEN}Successfully built Linux package: $OUTPUT_DIR/app-$VERSION-linux.tar.gz${NC}"
        else
            echo -e "${RED}Error: Linux build failed or directory not found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping Linux build (not in platform list)${NC}"
    fi
fi

# 检查是否在 Windows 上构建
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    if is_platform_enabled "windows"; then
        echo -e "${YELLOW}Building Windows...${NC}"
        flutter build windows --release
        if [ -d "build/windows/x64/runner/Release" ]; then
            mkdir -p "$OUTPUT_DIR"
            (cd build/windows/x64/runner/Release && zip -r "../../../../$OUTPUT_DIR/app-$VERSION-windows.zip" .)
            echo -e "${GREEN}Successfully built Windows package: $OUTPUT_DIR/app-$VERSION-windows.zip${NC}"
        else
            echo -e "${RED}Error: Windows build failed or directory not found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping Windows build (not in platform list)${NC}"
    fi
fi

# 检查GitHub认证
check_github_auth() {
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}"
        echo -e "${YELLOW}Please run 'gh auth login' to authenticate.${NC}"
        exit 1
    fi
}

# 检查GitHub Token
if [ -z "$GITHUB_TOKEN" ]; then
    # 尝试从配置文件读取
    if [ -f "scripts/release_config.json" ]; then
        if command -v jq &> /dev/null; then
            GITHUB_TOKEN=$(jq -r '.github.token' scripts/release_config.json)
        else
            echo -e "${YELLOW}Warning: jq not installed, cannot parse config file${NC}"
        fi
    fi
    
    # 如果仍然没有token，检查GitHub CLI认证
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${YELLOW}GitHub token not found in environment or config file.${NC}"
        echo -e "${YELLOW}Checking GitHub CLI authentication...${NC}"
        check_github_auth
        echo -e "${GREEN}Using GitHub CLI authentication.${NC}"
    else
        # 如果找到token，设置环境变量
        export GITHUB_TOKEN
        echo -e "${GREEN}Using GitHub token from config file.${NC}"
    fi
else
    echo -e "${GREEN}Using GitHub token from environment variable.${NC}"
fi

# 创建 GitHub Release
echo -e "${YELLOW}Creating GitHub Release...${NC}"
RELEASE_NOTES="release_notes.md"

# 生成发布说明
cat > $RELEASE_NOTES << EOL
# Memento $VERSION

## 构建信息
- 构建时间: $(date)
- Flutter 版本: $(flutter --version | head -n 1)

## 下载
- 🌐 Web: app-$VERSION-web.zip
EOL

# 根据操作系统添加额外的下载信息
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "- 🍎 iOS: app-$VERSION-ios.zip" >> $RELEASE_NOTES
    echo "- 🖥️ macOS: app-$VERSION-macos.zip" >> $RELEASE_NOTES
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "- 🐧 Linux: app-$VERSION-linux.tar.gz" >> $RELEASE_NOTES
fi

if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "- 🪟 Windows: app-$VERSION-windows.zip" >> $RELEASE_NOTES
fi

# 创建 GitHub Release
if ! gh release create "v$VERSION" --title "Memento v$VERSION" --notes-file $RELEASE_NOTES; then
    echo -e "${RED}Error: Failed to create GitHub release.${NC}"
    echo -e "${YELLOW}Please check your GitHub CLI authentication and permissions.${NC}"
    exit 1
fi

# 上传构建文件
for file in $OUTPUT_DIR/*; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Uploading $file...${NC}"
        if ! gh release upload "v$VERSION" "$file"; then
            echo -e "${RED}Error: Failed to upload $file.${NC}"
            echo -e "${YELLOW}Please check your GitHub CLI authentication and permissions.${NC}"
            exit 1
        fi
    fi
done

# 清理临时文件
rm $RELEASE_NOTES

echo -e "${GREEN}Release v$VERSION completed successfully!${NC}"

# 提示下一步操作
echo -e "${YELLOW}Next steps:${NC}"
echo "1. 检查 GitHub Releases 页面确认发布状态"
echo "2. 更新 pubspec.yaml 中的版本号为下一个版本"
echo "3. 提交版本更新到代码库"