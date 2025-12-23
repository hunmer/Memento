# iOS NFC 实现检查清单

## ✅ 已实现的方法

### 基础方法
- [x] `getPlatformVersion` - 获取平台版本
- [x] `isNfcSupported` - 检查 NFC 硬件支持
- [x] `isNfcEnabled` - 检查 NFC 是否启用

### 读取方法
- [x] `readNfc` - 读取 NFC 标签（支持 NDEF 格式）

### 写入方法
- [x] `writeNfc` - 写入通用数据
- [x] `writeNdefUrl` - 写入 URL 记录
- [x] `writeNdefText` - 写入文本记录
- [x] `writeNfcRecords` - 写入多条记录（支持混合类型）

### 辅助方法
- [x] `openNfcSettings` - 打开系统设置

## 📋 支持的 NFC 记录类型

1. **URI** - 链接和 URI
   - 使用 `NFCNDEFPayload.wellKnownTypeURIPayload`
   - 示例：`https://example.com`

2. **TEXT** - 纯文本
   - 使用 `NFCNDEFPayload.wellKnownTypeTextPayload`
   - 支持多语言（自动使用当前语言环境）

3. **MIME** - MIME 类型数据
   - 格式：`mime_type|content`
   - 示例：`text/plain|Hello World`

4. **AAR** - Android Application Record
   - iOS 通过外部类型记录模拟
   - 格式：`android.com:pkg`

5. **EXTERNAL** - 外部类型记录
   - 格式：`domain:type|content`
   - 示例：`memento:data|custom_data`

## 🔧 配置要求

### Info.plist
```xml
<key>NFCReaderUsageDescription</key>
<string>此应用需要访问NFC以读取和写入NFC标签</string>
```

### Entitlements（必需）
```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
  <string>NDEF</string>
  <string>TAG</string>
</array>
```

### 最低要求
- iOS 13.0+
- iPhone 7 及以上（支持 NFC 硬件）
- CoreNFC 框架

## 📝 实现细节

### 读取流程
1. 创建 `NFCNDEFReaderSession`
2. 实现 `NFCNDEFReaderSessionDelegate`
3. 处理 `didDetectNDEFs` 回调
4. 解析多种格式：Text、URI、UTF-8、Base64

### 写入流程
1. 准备 `NFCNDEFMessage`
2. 使用 `didDetect tags` 方法（iOS 13+）
3. 检查标签状态（readWrite, capacity）
4. 执行 `writeNDEF` 操作

### 错误处理
- 设备不支持 NFC
- NFC 未启用
- 标签只读/不支持
- 容量不足
- 用户取消操作

## 🧪 测试建议

### 单元测试
- [ ] 测试所有方法调用
- [ ] 测试参数验证
- [ ] 测试错误处理

### 集成测试
- [ ] 在真机上测试读取功能
- [ ] 在真机上测试写入功能
- [ ] 测试多记录写入
- [ ] 测试各种记录类型

### 兼容性测试
- [ ] iOS 13.0 - 15.x
- [ ] iOS 16.x - 17.x
- [ ] iOS 18.x
- [ ] 不同 iPhone 型号（7, 8, X, 11, 12, 13, 14, 15, 16）

## ⚠️ 已知限制

1. **AAR 记录**：iOS 不原生支持，使用外部类型模拟
2. **设置页面**：iOS 没有专门的 NFC 设置，打开通用设置
3. **后台读取**：iOS 不支持后台 NFC 读取
4. **写入限制**：某些标签可能被写保护

## 📚 参考资料

- [CoreNFC Framework](https://developer.apple.com/documentation/corenfc)
- [NFCNDEFReaderSession](https://developer.apple.com/documentation/corenfc/nfcndefreadersession)
- [NFCNDEFPayload](https://developer.apple.com/documentation/corenfc/nfcndefpayload)
