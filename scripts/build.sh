#!/bin/bash

# 确保脚本在错误时退出
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 解析命令行参数
CLEAR_BUILD=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --clear) CLEAR_BUILD=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# 检查必要的命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        exit 1
    fi
}

# 检查必要的工具
check_command "flutter"

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
if [ "$CLEAR_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning previous builds...${NC}"
    flutter clean
else
    echo -e "${YELLOW}Skipping clean (use --clear to clean previous builds)${NC}"
fi

# 获取依赖
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# 构建 Android
if is_platform_enabled "android"; then
    echo -e "${YELLOW}Building Android APK...${NC}"
    
    # 设置签名密钥变量
    KEYSTORE_PATH="android/app/upload-keystore.jks"
    KEY_ALIAS="upload"
    STORE_PASSWORD="android"
    KEY_PASSWORD="android"
    
    # 检查密钥库是否存在
    if [ ! -f "$KEYSTORE_PATH" ]; then
        echo -e "${YELLOW}Creating new keystore...${NC}"
        
        # 创建目录（如果不存在）
        mkdir -p android/app
        
        # 生成新的密钥库
        keytool -genkey -v \
                -keystore "$KEYSTORE_PATH" \
                -alias "$KEY_ALIAS" \
                -keyalg RSA \
                -keysize 2048 \
                -validity 10000 \
                -storepass "$STORE_PASSWORD" \
                -keypass "$KEY_PASSWORD" \
                -dname "CN=hunmer, OU=Your Organization, O=Your Company, L=Your City, S=Your State, C=Your Country"
    fi
    
    # 创建或更新 key.properties 文件
    echo -e "${YELLOW}Creating key.properties...${NC}"
    cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=upload-keystore.jks
EOF
    
    flutter build apk --release --no-tree-shake-icons
    mkdir -p "$OUTPUT_DIR"
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        cp "build/app/outputs/flutter-apk/app-release.apk" "$OUTPUT_DIR/memento-$VERSION-android.apk"
        echo -e "${GREEN}Successfully built Android APK: $OUTPUT_DIR/memento-$VERSION-android.apk${NC}"
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
    flutter build web --release --no-tree-shake-icons
    if [ -d "build/web" ]; then
        (cd build/web && zip -r "../../$OUTPUT_DIR/memento-$VERSION-web.zip" .)
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
            mv "build/ios/ipa/Runner.ipa" "$OUTPUT_DIR/apmementop-$VERSION-ios.ipa"
            echo -e "${GREEN}Successfully built iOS .ipa: $OUTPUT_DIR/memento-$VERSION-ios.ipa${NC}"
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
        flutter build macos --release --no-tree-shake-icons
        
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
            DMG_NAME="memento-$VERSION.dmg"
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
        flutter build linux --release --no-tree-shake-icons
        if [ -d "build/linux/x64/release/bundle" ]; then
            mkdir -p "$OUTPUT_DIR"
            (cd build/linux/x64/release/bundle && tar czf "../../../../$OUTPUT_DIR/apmementop-$VERSION-linux.tar.gz" .)
            echo -e "${GREEN}Successfully built Linux package: $OUTPUT_DIR/memento-$VERSION-linux.tar.gz${NC}"
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
        flutter build windows --release --no-tree-shake-icons
        if [ -d "build/windows/x64/runner/Release" ]; then
            mkdir -p "$OUTPUT_DIR"
            (cd build/windows/x64/runner/Release && zip -r "../../../../$OUTPUT_DIR/memento-$VERSION-windows.zip" .)
            echo -e "${GREEN}Successfully built Windows package: $OUTPUT_DIR/memento-$VERSION-windows.zip${NC}"
        else
            echo -e "${RED}Error: Windows build failed or directory not found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Skipping Windows build (not in platform list)${NC}"
    fi
fi

echo -e "${GREEN}Build process completed successfully!${NC}"