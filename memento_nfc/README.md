# memento_nfc

Flutter NFC插件，支持Android和iOS平台的NFC标签读写功能。

## 功能特性

- ✅ NFC设备支持检测
- ✅ NFC启用状态检查
- ✅ NFC标签数据读取（NDEF格式）
- ✅ NFC标签数据写入（NDEF格式）
  - 通用文本写入
  - URL写入
  - 纯文本写入
- ✅ 完整的错误处理
- ✅ 异步操作支持

## 平台支持

- ✅ Android (API Level 21+)
- ✅ iOS (13.0+)

## 安装

在Flutter项目的`pubspec.yaml`中添加依赖：

```yaml
dependencies:
  memento_nfc:
    path: ./memento_nfc
```

## 使用方法

### 基本用法

```dart
import 'package:memento_nfc/memento_nfc.dart';

final nfc = MementoNfc();

// 检查NFC支持状态
bool supported = await nfc.isNfcSupported();
print('支持NFC: $supported');

// 检查NFC是否启用
bool enabled = await nfc.isNfcEnabled();
print('NFC已启用: $enabled');
```

### 读取NFC标签

```dart
// 读取NFC标签数据
NfcReadResult result = await nfc.readNfc();

if (result.success) {
  print('读取成功: ${result.data}');
} else {
  print('读取失败: ${result.error}');
}
```

### 写入NFC标签

```dart
// 写入通用数据
NfcWriteResult writeResult = await nfc.writeNfc('Hello NFC!');
if (writeResult.success) {
  print('写入成功');
} else {
  print('写入失败: ${writeResult.error}');
}

// 写入URL
NfcWriteResult urlResult = await nfc.writeNdefUrl('https://example.com');
if (urlResult.success) {
  print('URL写入成功');
}

// 写入文本
NfcWriteResult textResult = await nfc.writeNdefText('这是要写入的文本');
if (textResult.success) {
  print('文本写入成功');
}
```

## API文档

### 类: MementoNfc

#### 方法

##### `Future<bool> isNfcSupported()`
检查设备是否支持NFC功能。

**返回值**: `bool` - 如果支持NFC则返回true，否则返回false

##### `Future<bool> isNfcEnabled()`
检查NFC功能是否已启用。

**返回值**: `bool` - 如果NFC已启用则返回true，否则返回false

##### `Future<NfcReadResult> readNfc()`
读取NFC标签数据。

**返回值**: `NfcReadResult` - 包含读取结果的对象

##### `Future<NfcWriteResult> writeNfc(String data, {String formatType = 'NDEF'})`
写入数据到NFC标签。

**参数**:
- `data`: 要写入的数据
- `formatType`: NFC格式类型（默认'NDEF'）

**返回值**: `NfcWriteResult` - 包含写入结果的对象

##### `Future<NfcWriteResult> writeNdefUrl(String url)`
写入URL到NFC标签。

**参数**:
- `url`: 要写入的URL

**返回值**: `NfcWriteResult` - 包含写入结果的对象

##### `Future<NfcWriteResult> writeNdefText(String text)`
写入文本到NFC标签。

**参数**:
- `text`: 要写入的文本

**返回值**: `NfcWriteResult` - 包含写入结果的对象

### 类: NfcReadResult

#### 属性

- `bool success`: 读取是否成功
- `String? data`: 读取到的数据（成功时）
- `String? error`: 错误信息（失败时）

### 类: NfcWriteResult

#### 属性

- `bool success`: 写入是否成功
- `String? error`: 错误信息（失败时）

## 平台配置

### Android

插件已自动配置NFC权限。如果需要，在Android项目的`AndroidManifest.xml`中已经包含：

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

### iOS

在iOS项目的`Info.plist`中添加NFC权限描述：

```xml
<key>NFCReaderUsageDescription</key>
<string>此应用需要访问NFC以读取和写入NFC标签</string>
```

## 注意事项

1. **NFC功能需要硬件支持**：确保设备具有NFC功能
2. **权限要求**：确保在系统设置中启用了NFC
3. **NFC标签兼容性**：插件主要支持NDEF格式的NFC标签
4. **iOS限制**：iOS上的NFC写入功能有限制，请测试设备兼容性

## 示例项目

请查看`example/`目录中的完整示例代码。

## 故障排除

### 常见问题

**Q: 读取NFC时提示"No NFC tag detected"**
A: 确保将手机靠近NFC标签，保持几秒钟直到检测到

**Q: 写入NFC时失败**
A: 检查NFC标签是否支持NDEF格式，以及是否未被写保护

**Q: iOS设备无法写入NFC**
A: iOS对NFC写入有严格限制，某些操作可能不被支持

## 贡献

欢迎提交Issue和Pull Request来帮助改进此插件。

## 许可证

本项目基于MIT许可证开源。
