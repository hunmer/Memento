
  问题根源

  1. Pods xcconfig 设置了 BUILD_LIBRARY_FOR_DISTRIBUTION = YES
  2. Runner 项目 使用了 Runner-Bridging-Header.h
  3. Swift 编译器不允许同时使用 bridging headers 和模块接口

  解决方案

  1. 简化 Podfile (ios/Podfile)：
  - 移除了复杂的全局模块接口禁用配置
  - 只保留基础兼容性设置（iOS 部署目标、禁用 bitcode）

  2. 更新 SwiftFix.xcconfig (ios/Runner/SwiftFix.xcconfig)：
  SWIFT_VERSION = 5.0

  // 禁用 Runner 的模块接口，因为它使用了 bridging header
  BUILD_LIBRARY_FOR_DISTRIBUTION = NO
  SWIFT_EMIT_MODULE_INTERFACE = NO

  这样 Pods 可以保留它们需要的模块接口设置，而 Runner 项目则禁用模块接口以兼容 bridging
  header。

  ---
  相关资源：
  - https://pub.dev/packages/awesome_notifications
  - https://stackoverflow.com/questions/78957157/swift-compiler-error-when-using-flutter-awes
  ome-notification-in-ios-14