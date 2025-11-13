[根目录](../../CLAUDE.md) > **scripts**

---

# 构建与发布脚本 - 模块文档

## 模块职责

提供自动化的多平台构建与发布流程：

- **自动构建**: 一键构建所有目标平台
- **版本管理**: 自动从 `pubspec.yaml` 读取版本号
- **平台选择**: 通过配置文件指定构建平台
- **签名处理**: Android 自动生成/使用签名密钥
- **打包优化**: 自动生成分架构 APK、DMG、ZIP 等
- **GitHub 发布**: 自动创建 Release 并上传构建产物

---

## 脚本清单

### build.sh (构建脚本)

**路径**: `scripts/build.sh`

**功能**:
- 读取 `release_config.json` 配置
- 多平台并行/串行构建
- 自动处理平台特定配置（签名、图标等）
- 输出标准化的发布文件

**支持的平台**:
- ✅ Android (APK - arm64-v8a, armeabi-v7a, x86_64)
- ✅ iOS (IPA - 需 macOS 和 Xcode)
- ✅ Web (ZIP)
- ✅ Windows (ZIP)
- ✅ macOS (DMG)
- ✅ Linux (tar.gz)

**使用方法**:

```bash
# 基本用法
./scripts/build.sh

# 清理后构建
./scripts/build.sh --clear

# 仅构建特定平台（需配置 release_config.json）
# 见下文配置说明
```

**输出目录**:
```
build/releases/
├── memento-v1.1.6-android-arm64-v8a.apk
├── memento-v1.1.6-android-armeabi-v7a.apk
├── memento-v1.1.6-android-x86_64.apk
├── memento-v1.1.6-web.zip
├── memento-v1.1.6-macos.dmg
├── memento-v1.1.6-windows.zip
└── memento-v1.1.6-linux.tar.gz
```

---

### release.sh (发布脚本)

**路径**: `scripts/release.sh`

**功能**:
- 创建 GitHub Release
- 上传 `build/releases/` 下的所有文件
- 自动生成 Release Notes
- 支持草稿模式

**使用方法**:

```bash
# 发布到 GitHub（需设置 GITHUB_TOKEN 环境变量）
./scripts/release.sh

# 创建草稿 Release
./scripts/release.sh --draft
```

**环境变量**:
- `GITHUB_TOKEN`: GitHub Personal Access Token (需要 `repo` 权限)

---

### deploy_to_vercel.sh (Vercel 部署脚本)

**路径**: `scripts/deploy_to_vercel.sh`

**功能**:
- 部署 Web 版本到 Vercel
- 自动构建并推送

**使用方法**:

```bash
# 部署到 Vercel（需安装 Vercel CLI）
./scripts/deploy_to_vercel.sh
```

---

## 配置文件

### release_config.json

**路径**: `scripts/release_config.json`

**示例**:

```json
{
  "build": {
    "platforms": ["android", "web", "macos"],
    "android": {
      "splitPerAbi": true,
      "targetSdk": 34
    },
    "ios": {
      "teamId": "YOUR_TEAM_ID",
      "provisioningProfile": "YOUR_PROFILE_NAME"
    },
    "macos": {
      "signIdentity": "Developer ID Application: Your Name"
    }
  },
  "release": {
    "repository": "hunmer/Memento",
    "draft": false,
    "prerelease": false
  }
}
```

**配置项说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `build.platforms` | string[] | 要构建的平台列表 |
| `build.android.splitPerAbi` | boolean | 是否为每个架构生成单独的 APK |
| `build.ios.teamId` | string | Apple 开发者团队 ID |
| `build.ios.provisioningProfile` | string | 预配描述文件名称 |
| `build.macos.signIdentity` | string | macOS 签名身份 |
| `release.repository` | string | GitHub 仓库（格式：owner/repo） |
| `release.draft` | boolean | 是否创建草稿 Release |
| `release.prerelease` | boolean | 是否标记为预发布版本 |

**创建配置文件**:

```bash
# 复制示例配置
cp scripts/release_config.example.json scripts/release_config.json

# 编辑配置
nano scripts/release_config.json
```

---

## 构建流程

### Android 构建详解

```bash
# 1. 检查/生成签名密钥
if [ ! -f "android/app/upload-keystore.jks" ]; then
    keytool -genkey -v \
        -keystore android/app/upload-keystore.jks \
        -alias upload \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000
fi

# 2. 创建 key.properties
cat > android/key.properties << EOF
storePassword=android
keyPassword=android
keyAlias=upload
storeFile=upload-keystore.jks
EOF

# 3. 构建分架构 APK
flutter build apk --release --split-per-abi

# 4. 重命名并移动到输出目录
mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
   build/releases/memento-v1.1.6-android-arm64-v8a.apk
```

**签名密钥说明**:
- 密钥库路径: `android/app/upload-keystore.jks`
- 密钥别名: `upload`
- 默认密码: `android` (生产环境请修改！)

---

### iOS 构建详解

```bash
# 1. 构建 iOS 应用（无签名）
flutter build ios --release --no-codesign

# 2. 创建 IPA（手动打包）
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r build/releases/memento-v1.1.6-ios.ipa Payload
rm -rf Payload
```

**注意事项**:
- iOS 构建需要 macOS 系统
- 完整签名需要配置 `teamId` 和 `provisioningProfile`
- 上传 App Store 需额外步骤

---

### macOS 构建详解

```bash
# 1. 构建 macOS 应用
flutter build macos --release

# 2. 使用 create-dmg 打包 DMG
create-dmg \
    --volname "Memento" \
    --window-size 600 400 \
    --icon "Runner.app" 175 120 \
    --app-drop-link 425 120 \
    build/releases/memento-v1.1.6-macos.dmg \
    build/macos/Build/Products/Release/Runner.app
```

**依赖工具**:
- `create-dmg`: 安装命令 `brew install create-dmg`

---

### Web 构建详解

```bash
# 1. 构建 Web 应用
flutter build web --release

# 2. 压缩为 ZIP
cd build/web
zip -r ../../build/releases/memento-v1.1.6-web.zip .
cd ../..
```

---

## 常见问题

### Q1: 构建失败：找不到 jq 命令

**解决方案**:
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq

# Windows (Git Bash)
# 下载 jq.exe 并放入 PATH
```

---

### Q2: Android 签名错误

**检查清单**:
1. 确认 `android/app/upload-keystore.jks` 存在
2. 检查 `android/key.properties` 配置
3. 验证密钥别名和密码

**重新生成密钥**:
```bash
rm android/app/upload-keystore.jks
./scripts/build.sh
```

---

### Q3: iOS 构建卡在 Pod Install

**解决方案**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
flutter build ios --release
```

---

### Q4: macOS DMG 创建失败

**可能原因**:
- 未安装 `create-dmg`
- 应用未签名导致打包失败

**解决方案**:
```bash
# 安装工具
brew install create-dmg

# 跳过 DMG 创建，直接使用 .app
cp -r build/macos/Build/Products/Release/Runner.app \
      build/releases/Memento.app
zip -r build/releases/memento-v1.1.6-macos.zip \
       build/releases/Memento.app
```

---

### Q5: Web 部署后图标丢失

**原因**: 构建时开启了 `--tree-shake-icons`

**解决方案**:
```bash
# 禁用图标树摇动
flutter build web --release --no-tree-shake-icons
```

---

## GitHub Actions 集成

### 工作流示例

**.github/workflows/build.yml**:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.7.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Build
        run: ./scripts/build.sh

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release-${{ matrix.os }}
          path: build/releases/*
```

---

## 最佳实践

### 发布前检查清单

- [ ] 更新 `pubspec.yaml` 版本号
- [ ] 更新 `CHANGELOG.md`
- [ ] 运行 `flutter analyze` 检查代码
- [ ] 测试所有平台的构建
- [ ] 验证签名密钥有效性
- [ ] 备份签名密钥（Android 和 iOS）
- [ ] 准备 Release Notes

### 版本号规范

遵循 [Semantic Versioning 2.0.0](https://semver.org/):

- **主版本号 (MAJOR)**: 不兼容的 API 变更
- **次版本号 (MINOR)**: 向后兼容的功能新增
- **修订号 (PATCH)**: 向后兼容的 bug 修复

示例: `1.2.3+456`
- `1.2.3`: 版本号
- `456`: 构建号

---

## 相关文件清单

- `build.sh` - 主构建脚本
- `release.sh` - GitHub 发布脚本
- `deploy_to_vercel.sh` - Vercel 部署脚本
- `release_config.example.json` - 配置文件示例
- `release_config.json` - 实际配置（.gitignore 已忽略）

---

## 变更记录

- **2025-11-13T04:06:10+00:00**: 初始化构建脚本文档

---

**上级目录**: [返回根文档](../../CLAUDE.md)
