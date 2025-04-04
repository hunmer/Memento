<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="Memento Logo">
</p>

<h1 align="center">Memento</h1>

<p align="center">
  <a href="https://github.com/hunmer/Memento/stargazers">
    <img src="https://img.shields.io/github/stars/hunmer/Memento?style=flat-square" alt="Stars">
  </a>
  <a href="https://github.com/hunmer/Memento/releases">
    <img src="https://img.shields.io/github/downloads/hunmer/Memento/total?style=flat-square" alt="Downloads">
  </a>
  <br>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/android-supported-success.svg?style=flat-square" alt="Android">
  </a>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/ios-supported-success.svg?style=flat-square" alt="iOS">
  </a>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/web-supported-success.svg?style=flat-square" alt="Web">
  </a>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/windows-supported-success.svg?style=flat-square" alt="Windows">
  </a>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/macos-supported-success.svg?style=flat-square" alt="macOS">
  </a>
  <a href="#支持平台">
    <img src="https://img.shields.io/badge/linux-supported-success.svg?style=flat-square" alt="Linux">
  </a>
</p>

Memento 是一款使用 Flutter 构建的跨平台个人助理应用，集成了聊天、日记和活动追踪等功能。

[English](README.md)

## 功能特性

- 💬 **聊天**：多用户聊天和消息管理
- 📝 **日记**：记录每日心情和生活时刻
- 📅 **活动追踪**：监控和管理个人活动
- 🔌 **插件系统**：支持功能扩展
- 💾 **本地存储**：确保数据安全
- 🌐 **跨平台**：支持 Android、iOS、Web、Windows、macOS 和 Linux

## 项目结构

```
lib/
├── core/          # 核心功能
├── models/        # 数据模型
├── plugins/       # 插件系统
├── screens/       # 页面
├── utils/         # 工具类
└── widgets/       # 通用组件
```

## 开发要求

- Flutter SDK：最新稳定版
- Dart SDK：最新稳定版
- 支持的 IDE：Android Studio、VS Code

## 快速开始

1. 配置 GitHub 发布设置
```bash
# 复制配置文件示例
cp scripts/release_config.example.json scripts/release_config.json

# 编辑配置文件，填入你的 GitHub token 和详细信息
# 注意：不要将此文件提交到 git！
```

2. 克隆项目
```bash
git clone https://github.com/hunmer/Memento.git
cd Memento
```

2. 获取依赖
```bash
flutter pub get
```

3. 运行项目
```bash
# 调试模式
flutter run

# 特定平台运行
flutter run -d chrome  # Web
flutter run -d windows # Windows
flutter run -d macos   # macOS
flutter run -d linux   # Linux
```

## 发布构建

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 插件开发

Memento 支持插件系统。按照以下步骤开发新插件：

1. 在 `lib/plugins` 中创建新的插件目录
2. 实现 `BasePlugin` 接口
3. 在 `plugin.json` 中配置插件信息
4. 重启应用以加载新插件

## 贡献

欢迎提交 Pull Request 和 Issue！

## 截图

| 聊天 | 日记 | 活动追踪 |
|:----:|:-----:|:-----------------:|
| ![聊天](screenshots/chat.jpg) | ![日记](screenshots/diary.jpg) | ![活动](screenshots/activity.jpg) |

## 许可证

本项目采用 MIT 许可证