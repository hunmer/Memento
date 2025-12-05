# iOS NFC配置指南

本文档详细说明了在Memento应用中使用memento_nfc插件时所需的iOS配置。

## 已完成的配置

### 1. Info.plist 配置 ✅

已在 `/Users/Zhuanz/Documents/Memento/ios/Runner/Info.plist` 中添加NFC权限描述：

```xml
<key>NFCReaderUsageDescription</key>
<string>此应用需要访问NFC以读取和写入NFC标签</string>
```

### 2. CocoaPods 配置 ✅

memento_nfc插件的 `pubspec.yaml` 已正确配置：

```yaml
s.platform = :ios, '13.0'
s.frameworks = 'CoreNFC'
s.dependency 'Flutter'
s.swift_version = '5.0'
```

### 3. iOS部署目标 ✅

主应用的iOS部署目标已设置为13.0，与NFC插件要求一致。

### 4. iOS项目代码 ✅

已完成iOS原生代码修复：

#### 修复的方法签名问题
- ✅ 修复了 `readerSession(_:didDetectNDEFMessages:)` 方法名
- ✅ 正确实现为 `readerSession(_:didDetectNDEFs:)`

#### 修复的NFC写入逻辑
- ✅ 正确实现iOS NFC写入流程
- ✅ 添加 `pendingMessage` 变量存储待写入的消息
- ✅ 在检测到NFC标签时执行写入操作
- ✅ 正确处理异步写入结果
- ✅ 使用 `weak self` 避免内存泄漏

## iOS NFC功能说明

### 读取NFC
- 用户点击"读取NFC"按钮
- 应用启动NFC扫描会话
- 用户将iPhone靠近NFC标签
- 系统调用 `readerSession(_:didDetectNDEFs:)` 方法
- 解析NDEF消息并返回结果

### 写入NFC
- 用户输入要写入的数据
- 应用创建NDEF消息并存储在 `pendingMessage` 中
- 启动NFC扫描会话，显示提示信息
- 用户将iPhone靠近NFC标签
- 系统调用 `readerSession(_:didDetectNDEFs:)` 方法
- 应用连接到标签并执行写入操作
- 返回写入结果

## 测试建议

### 功能测试
1. **NFC支持检查**
   ```swift
   // 在iOS设备上测试
   let supported = NFCNDEFReaderSession.readingAvailable
   print("NFC支持: \(supported)")
   ```

2. **NFC读取测试**
   - 使用NDEF格式的NFC标签
   - 将iPhone靠近标签
   - 验证数据正确读取

3. **NFC写入测试**
   - 准备可重写的NDEF标签
   - 输入测试数据
   - 验证写入成功

### 兼容性测试
- iPhone 7及以上设备（支持NFC的设备）
- iOS 13.0及以上系统版本
- 各种NDEF标签类型

## 故障排除

### 常见问题

**Q1: 编译时提示 "Instance method 'readerSession(_:didDetectNDEFs:)' has different argument labels"**
✅ **已解决**: 修复了方法签名为正确格式

**Q2: NFC扫描无响应**
- 检查设备是否支持NFC
- 确认iOS版本 ≥ 13.0
- 验证权限描述是否正确添加

**Q3: 写入NFC失败**
- 检查NFC标签是否支持NDEF格式
- 确认标签未被写保护
- 验证设备靠近标签时间足够长

**Q4: 读取到乱码数据**
- 确认NFC标签编码格式为UTF-8
- 检查payload解析逻辑

### 调试工具

```swift
// 在readerSession方法中添加调试信息
print("检测到 \(messages.count) 个NDEF消息")
for (index, message) in messages.enumerated() {
    print("消息 \(index): 包含 \(message.records.count) 条记录")
}
```

## 部署前检查清单

- ✅ Info.plist中添加NFC权限描述
- ✅ iOS部署目标设置为13.0+
- ✅ CocoaPods配置CoreNFC框架
- ✅ Swift代码方法签名正确
- ✅ NFC读写逻辑完整实现
- ✅ 错误处理机制完整
- ✅ 内存泄漏防护（使用weak self）

## 注意事项

1. **iOS限制**: iOS上的NFC功能有以下限制
   - 仅支持NDEF格式的NFC标签
   - 写入功能需要用户手动将设备靠近标签
   - 不支持所有类型的NFC标签

2. **用户体验**: iOS要求用户在扫描时手动将设备靠近标签，这与Android的自动触发不同

3. **后台限制**: NFC扫描会话在应用进入后台时会自动结束

## 总结

所有iOS NFC配置已完成，应用现在可以正确编译和使用NFC功能。主要修复包括：

1. ✅ 修复Swift方法签名错误
2. ✅ 完善NFC写入逻辑
3. ✅ 正确配置权限和框架
4. ✅ 添加错误处理和调试支持

应用已准备好在iOS设备上进行NFC功能测试。
