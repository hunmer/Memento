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
  <a href="#platforms">
    <img src="https://img.shields.io/badge/android-supported-success.svg?style=flat-square" alt="Android">
  </a>
  <a href="#platforms">
    <img src="https://img.shields.io/badge/ios-supported-success.svg?style=flat-square" alt="iOS">
  </a>
  <a href="#platforms">
    <img src="https://img.shields.io/badge/web-supported-success.svg?style=flat-square" alt="Web">
  </a>
  <a href="#platforms">
    <img src="https://img.shields.io/badge/windows-supported-success.svg?style=flat-square" alt="Windows">
  </a>
  <a href="#platforms">
    <img src="https://img.shields.io/badge/macos-supported-success.svg?style=flat-square" alt="macOS">
  </a>
  <a href="#platforms">
    <img src="https://img.shields.io/badge/linux-supported-success.svg?style=flat-square" alt="Linux">
  </a>
</p>

Memento is a cross-platform personal assistant application built with Flutter, integrating chat, diary, and activity tracking features.

[简体中文](README_zh.md)

## Features

- 💬 **Chat**: Multi-user chat and message management
- 📝 **Diary**: Record daily moods and life moments
- 📅 **Activity Tracking**: Monitor and manage personal activities
- 🔌 **Plugin System**: Support for feature extensions
- 💾 **Local Storage**: Ensure data security
- 🌐 **Cross-Platform**: Support for Android, iOS, Web, Windows, macOS, and Linux

## Project Structure

```
lib/
├── core/          # Core functionality
├── models/        # Data models
├── plugins/       # Plugin system
├── screens/       # Pages
├── utils/         # Utilities
└── widgets/       # Common components
```

## Development Requirements

- Flutter SDK: Latest stable version
- Dart SDK: Latest stable version
- Supported IDEs: Android Studio, VS Code

## Quick Start

1. Configure GitHub Release Settings
```bash
# Copy the example config file
cp scripts/release_config.example.json scripts/release_config.json

# Edit the config file with your GitHub token and details
# DO NOT commit this file to git!
```

2. Clone the project
```bash
git clone https://github.com/hunmer/Memento.git
cd Memento
```

2. Get dependencies
```bash
flutter pub get
```

3. Run the project
```bash
# Debug mode
flutter run

# Platform-specific runs
flutter run -d chrome  # Web
flutter run -d windows # Windows
flutter run -d macos   # macOS
flutter run -d linux   # Linux
```

## Building for Release

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

## Plugin Development

Memento supports a plugin system. Follow these steps to develop a new plugin:

1. Create a new plugin directory in `lib/plugins`
2. Implement the `BasePlugin` interface
3. Configure plugin information in `plugin.json`
4. Restart the application to load the new plugin

## Contributing

Pull requests and issues are welcome!

## Screenshots

| Chat | Diary | Activity Tracking |
|:----:|:-----:|:-----------------:|
| ![Chat](screenshots/chat.jpg) | ![Diary](screenshots/diary.jpg) | ![Activity](screenshots/activity.jpg) |

## License

This project is licensed under the MIT License