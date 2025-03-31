#!/bin/bash

# 设置变量
KEYSTORE_PATH="android/app/upload-keystore.jks"
KEY_ALIAS="upload"
STORE_PASSWORD="android"
KEY_PASSWORD="android"

# 检查密钥库是否存在
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo "Creating new keystore..."
    
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
            -dname "CN=Your Name, OU=Your Organization, O=Your Company, L=Your City, S=Your State, C=Your Country"
fi

# 创建或更新 key.properties 文件
echo "Creating key.properties..."
cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=upload-keystore.jks
EOF

# 构建发布版APK
echo "Building release APK..."
flutter build apk --target-platform android-arm64 --release

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
else
    echo "Build failed!"
fi