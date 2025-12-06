# Toast 服务使用指南

## 概述

这是一个跨平台的 Toast 服务，根据不同平台自动选择最优的实现方式：
- **移动端 (Android/iOS)**: 使用 FlutterToast 原生实现
- **Web 和桌面端**: 使用 SnackBar 实现

## 快速开始

### 1. 基本使用

```dart
import 'package:Memento/core/services/toast_service.dart';

// 显示普通消息
Toast.show('这是一条消息');

// 显示成功消息
Toast.success('操作成功！');

// 显示错误消息
Toast.error('操作失败！');

// 显示警告消息
Toast.warning('请注意！');

// 显示信息消息
Toast.info('提示信息');
```

### 2. 自定义参数

```dart
// 自定义显示时长
Toast.show(
  '这条消息显示5秒',
  duration: const Duration(seconds: 5),
);

// 移动端可以自定义位置
Toast.show(
  '顶部消息',
  gravity: ToastGravity.TOP,
);

// 自定义样式
Toast.show(
  '自定义样式',
  backgroundColor: Colors.purple,
  textColor: Colors.white,
  fontSize: 20,
);
```

### 3. 取消 Toast

```dart
// 取消当前显示的 Toast
Toast.cancel();
```

## API 参考

### Toast 类静态方法

| 方法 | 参数 | 说明 |
|------|------|------|
| `show` | `message`, `type`, `duration`, `gravity`, `backgroundColor`, `textColor`, `fontSize` | 显示普通消息 |
| `success` | `message`, `duration` | 显示成功消息（绿色） |
| `error` | `message`, `duration` | 显示错误消息（红色） |
| `warning` | `message`, `duration` | 显示警告消息（橙色） |
| `info` | `message`, `duration` | 显示信息消息（蓝色） |
| `cancel` | 无 | 取消当前显示的 Toast |
| `setNavigatorKey` | `navigatorKey` | 设置导航键（通常不需要手动调用） |

### ToastType 枚举

- `ToastType.normal` - 普通
- `ToastType.success` - 成功
- `ToastType.error` - 错误
- `ToastType.warning` - 警告
- `ToastType.info` - 信息

### ToastGravity 枚举（仅移动端）

- `ToastGravity.TOP` - 顶部
- `ToastGravity.CENTER` - 居中
- `ToastGravity.BOTTOM` - 底部（默认）

## 平台差异

### 移动端特性
- 支持自定义显示位置（gravity）
- 支持立即取消
- 更接近原生体验

### Web/桌面端特性
- 带图标显示
- 自动适配 Material Design 3
- 支持通过手势关闭

## 使用建议

1. **操作反馈**: 使用不同类型的消息区分操作结果
2. **加载状态**: 配合加载指示器使用
3. **表单验证**: 使用 warning 类型提示输入错误
4. **网络请求**: 在请求开始时 show，成功时 success，失败时 error

## 示例代码

完整的使用示例请参考：`docs/toast_usage_example.dart`