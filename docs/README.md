# Memento 开发文档

本目录包含 Memento 项目的所有技术文档。

## 📚 文档索引

### Android 小组件

| 文档 | 说明 | 适用版本 |
|------|------|---------|
| **[小组件迁移指南](./WIDGET_MIGRATION_GUIDE.md)** | 📘 **新版完整指南** - 新架构详细说明、API 参考、完整示例 | **2.0+** ⭐ |
| **[小组件快速参考 (新版)](./WIDGET_QUICK_REFERENCE_NEW.md)** | 📝 **快速查阅** - 常用 API、代码片段、速查表 | **2.0+** ⭐ |
| [小组件实现指南](./WIDGET_IMPLEMENTATION_GUIDE.md) | 原始实现文档（旧架构） | 1.x |
| [小组件快速参考 (旧版)](./WIDGET_QUICK_REFERENCE.md) | 旧版快速参考 | 1.x |

**推荐阅读顺序**:
1. 新用户：[快速参考 (新版)](./WIDGET_QUICK_REFERENCE_NEW.md) → [完整指南](./WIDGET_MIGRATION_GUIDE.md)
2. 从 1.x 迁移：[迁移指南](./WIDGET_MIGRATION_GUIDE.md#迁移指南)

---

### AI 集成

| 文档 | 说明 |
|------|------|
| [AI Prompt 指南](./AI_PROMPT_GUIDE.md) | AI 提示词设计与使用 |
| [Prompt 数据规范](./PROMPT_DATA_SPEC.md) | Prompt 数据结构定义 |
| [JSAPI 过滤集成](./JSAPI_FILTER_INTEGRATION.md) | JavaScript API 过滤器集成 |

---

### 平台特定

| 文档 | 说明 |
|------|------|
| [Windows TTS 指南](./windows_tts_guide.md) | Windows 平台语音合成配置 |

---

## 🚀 快速开始

### 添加小组件支持到插件

**新版本 (推荐)**:

```dart
import 'package:memento_widgets/memento_widgets.dart';

final widgetData = PluginWidgetData(
  pluginId: 'your_plugin',
  pluginName: '插件名称',
  iconCodePoint: Icons.star.codePoint,
  colorValue: Colors.blue.value,
  stats: [
    WidgetStatItem(id: 'total', label: '总数', value: '42'),
  ],
);

await SystemWidgetService.instance.updateWidgetData('your_plugin', widgetData);
```

详见: [小组件快速参考 (新版)](./WIDGET_QUICK_REFERENCE_NEW.md)

---

## 📖 架构说明

### Memento 2.0 小组件架构

```
主应用 (Flutter)
    ↓ 调用
SystemWidgetService
    ↓ 使用
memento_widgets 插件
    ├── Flutter API (MyWidgetManager)
    ├── 数据模型 (PluginWidgetData)
    └── Android 原生 (Kotlin Providers)
        ↓ 渲染
    系统桌面小组件
```

**关键改进**:
- ✅ 插件化架构 - 代码独立可复用
- ✅ 类型安全 - 使用 Dart 数据模型
- ✅ 统一 API - 简化调用方式
- ✅ 易于维护 - 清晰的职责分离

---

## 📝 贡献指南

添加新文档时：
1. 创建 Markdown 文件到 `docs/` 目录
2. 在本 README 中添加索引条目
3. 使用清晰的标题和代码示例
4. 添加更新日期和版本信息

---

## 🔗 相关资源

- **项目主页**: [Memento](https://github.com/hunmer/Memento)
- **Flutter 文档**: [flutter.dev](https://flutter.dev)
- **home_widget 插件**: [pub.dev/packages/home_widget](https://pub.dev/packages/home_widget)

---

**最后更新**: 2025-11-30
**维护者**: Memento 开发团队
