[根目录](../../../CLAUDE.md) > [plugins](../) > **nfc**

# NFC 插件 - AI 上下文文档

> **变更记录 (Changelog)**
> - **2025-12-17T12:04:39+08:00**: 初始化 NFC 插件文档，完成全模块扫描

---

## 模块职责

NFC 插件提供近场通信（NFC）标签的读写功能，支持：
- NFC 标签数据的读取和写入
- 多种记录类型支持（URI、文本、MIME、AAR、外部类型）
- 与其他插件深度集成的快捷操作（签到、物品使用、习惯计时等）
- 深度链接生成，扫描标签自动触发应用内操作

---

## 入口与启动

### 核心文件
- **`nfc_plugin.dart`** - 插件主入口，继承自 `PluginBase`
- **`nfc_controller.dart`** - NFC 业务逻辑控制器，封装了 `memento_nfc` 包的调用

### 初始化流程
```dart
// 插件注册（main.dart）
plugins.add(NfcPlugin());

// 启动时自动检查 NFC 状态
await _controller.checkNfcStatus();
```

### 依赖项
- `memento_nfc` - 底层 NFC 功能包
- `plugin_data_selector` - 用于选择要写入 NFC 的数据项

---

## 对外接口

### NfcController API

```dart
class NfcController {
  // 状态检查
  Future<void> checkNfcStatus()
  bool get isNfcSupported
  bool get isNfcEnabled

  // 读写操作
  Future<NfcReadResult> readNfc()
  Future<NfcWriteResult> writeNfcRecords(List<Map<String, String>> records)

  // 工具方法
  Future<void> openNfcSettings()
  void showError(String message)
  void showSuccess(String message)
}
```

### 支持的 NFC 记录类型

```dart
enum NfcRecordType {
  uri('URI', '链接/URI', Icons.link),
  text('TEXT', '纯文本', Icons.text_fields),
  mime('MIME', 'MIME类型', Icons.data_object),
  aar('AAR', '应用记录', Icons.android),
  external_('EXTERNAL', '外部类型', Icons.extension);
}
```

---

## 关键依赖与配置

### 深度链接协议
插件使用 `memento://` 协议生成深度链接，支持的格式：
- `memento://checkin/item?itemId=<id>&action=checkin` - 快速签到
- `memento://goods/usage?itemId=<id>&action=add_usage` - 记录物品使用
- `memento://habit/timer?habitId=<id>&action=start_timer` - 启动习惯计时
- `memento://tracker/progress?goalId=<id>&action=update` - 更新追踪进度

### AAR 记录
所有快捷操作都会同时写入 AAR（Android Application Record）记录，确保扫描时自动启动 Memento 应用：
```
'aar': 'github.hunmer.memento'
```

---

## 数据模型

### NfcRecordItem
```dart
class NfcRecordItem {
  NfcRecordType type;      // 记录类型
  String data;             // 记录数据
  TextEditingController controller;  // 文本控制器

  Map<String, String> toMap()  // 转换为写入格式
}
```

### 读写结果
```dart
class NfcReadResult {
  final bool success;
  final String? data;     // 读取到的数据
  final String? error;    // 错误信息
}

class NfcWriteResult {
  final bool success;
  final String? error;    // 错误信息
}
```

---

## 卡片处理器系统

插件采用卡片处理器模式，每种 NFC 操作都由独立的处理器实现：

### 基础架构
```dart
abstract class BaseCardHandler {
  String get name;                    // 卡片名称
  String get description;             // 卡片描述
  IconData get icon;                  // 卡片图标
  Color get color;                    // 卡片颜色
  Future<void> executeWrite(BuildContext context);  // 执行写入
  Widget buildCard(BuildContext context, bool isEnabled, bool isWriting);  // 构建UI
}
```

### 已实现的处理器
1. **ReadCardHandler** - 读取 NFC 标签数据
2. **CustomWriteCardHandler** - 自定义数据写入（支持多条记录）
3. **CheckinCardHandler** - 写入签到快捷操作
4. **GoodsUsageCardHandler** - 写入物品使用记录快捷操作
5. **HabitTimerCardHandler** - 写入习惯计时快捷操作
6. **TrackerProgressCardHandler** - 写入目标追踪进度快捷操作

---

## 测试与质量

### 当前状态
- **单元测试**: 无
- **集成测试**: 无
- **国际化支持**: 完整（中文、英文）

### 测试建议
1. 为 `NfcController` 添加单元测试，模拟各种 NFC 场景
2. 为每个 `CardHandler` 添加 widget 测试
3. 集成测试：完整的 NFC 读写流程

### 平台兼容性
- **Android**: 完全支持
- **iOS**: 需要 entitlements 配置
- **Web/桌面**: 不支持 NFC（自动禁用）

---

## 常见问题 (FAQ)

### Q: 如何添加新的卡片处理器？
A: 继承 `BaseCardHandler` 并实现所有抽象方法，参考现有处理器实现。

### Q: NFC 写入失败怎么办？
A: 检查：
1. NFC 是否已启用
2. 标签是否为 NDEF 格式
3. 标签容量是否足够
4. 是否靠近标签中心

### Q: 如何扩展支持的记录类型？
A: 在 `NfcRecordType` 枚举中添加新类型，并更新 `NfcWriteDialog` 中的提示文本。

---

## 相关文件清单

```
lib/plugins/nfc/
├── nfc_plugin.dart              # 插件主类和主视图
├── nfc_controller.dart          # NFC 控制器
├── models/
│   ├── nfc_record_type.dart     # 记录类型枚举
│   ├── nfc_record_item.dart     # 记录数据模型
│   ├── habits_weekly_widget_config.dart  # 习惯周报配置
│   └── habits_weekly_widget_data.dart    # 习惯周报数据
├── card_handlers/
│   ├── base_card_handler.dart       # 卡片处理器基类
│   ├── read_card_handler.dart       # 读取卡片
│   ├── custom_write_card_handler.dart # 自定义写入卡片
│   ├── checkin_card_handler.dart    # 签到卡片
│   ├── goods_usage_card_handler.dart # 物品使用卡片
│   ├── habit_timer_card_handler.dart # 习惯计时卡片
│   └── tracker_progress_card_handler.dart # 追踪进度卡片
├── widgets/
│   └── nfc_write_dialog.dart       # NFC 写入对话框
└── l10n/
    ├── nfc_translations.dart       # 国际化总类
    ├── nfc_translations_zh.dart    # 中文翻译
    └── nfc_translations_en.dart    # 英文翻译
```

---

## 变更记录 (Changelog)

### 2025-12-17T12:04:39+08:00
- 初始化 NFC 插件文档
- 完成模块全扫描，识别 16 个文件
- 记录卡片处理器架构设计
- 整理深度链接协议规范

---

**最后更新**: 2025-12-17T12:04:39+08:00
**模块维护**: NFC 插件
**依赖的底层包**: memento_nfc