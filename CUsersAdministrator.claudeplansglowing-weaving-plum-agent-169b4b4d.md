# Memento 动作管理器 (Action Manager) 实施计划

## 项目概述

### 目标
将 `floating_ball_service.dart` 和 `floating_ball_manager.dart` 中的重复动作逻辑合并，创建统一的动作管理系统，支持动作注册、配置、验证和组合执行。

### 核心价值
1. **消除代码重复** - 合并 openPlugin, goBack, goHome 等重复实现
2. **统一接口** - 提供一致的动作注册和执行 API
3. **增强灵活性** - 支持动作表单配置和多动作组合
4. **提升用户体验** - 改进动作选择界面

---

## 第一阶段：架构设计与核心实现 (0-2天)

### 1.1 核心数据结构设计

#### 动作定义类 (ActionDefinition)
```dart
class ActionDefinition {
  final String id;              // 动作唯一标识
  final String title;           // 动作显示名称
  final String? description;    // 动作描述
  final ActionForm? form;       // 表单配置（用于配置动作参数）
  final ActionValidator? validator; // 验证器
  final List<String> categories; // 分类标签
}
```

#### 动作表单类 (ActionForm)
```dart
class ActionForm {
  final Map<String, FormFieldConfig> fields;
  final String? customBuilder;  // 自定义表单构造器
}
```

#### 动作实例类 (ActionInstance)
```dart
class ActionInstance {
  final String actionId;        // 动作定义ID
  final Map<String, dynamic> data; // 动作数据
  final bool enabled;           // 是否启用
}
```

#### 动作组类 (ActionGroup)
```dart
class ActionGroup {
  final String title;           // 组标题
  final List<ActionInstance> actions; // 子动作列表
  final ActionGroupOperator operator; // 执行方式：并行/顺序
}
```

### 1.2 动作管理器核心类

#### ActionManager 单例
**路径**: `lib/core/action/action_manager.dart`

**核心职责**:
- 动作注册与发现
- 动作验证与执行
- 动作组管理
- 存储与持久化

**关键方法**:
```dart
class ActionManager {
  // 注册动作
  void registerAction(ActionDefinition definition);
  
  // 执行动作
  Future<void> executeAction(BuildContext context, ActionInstance action);
  
  // 验证动作数据
  bool validateAction(String actionId, Map<String, dynamic> data);
  
  // 执行动作组
  Future<void> executeGroup(BuildContext context, ActionGroup group);
  
  // 获取所有可用动作
  List<ActionDefinition> getAllActions();
  
  // 按分类获取动作
  List<ActionDefinition> getActionsByCategory(String category);
}
```

### 1.3 预定义动作迁移

#### 从 floating_ball_manager.dart 迁移 (54-133行)
| 动作名称 | 迁移方式 | 备注 |
|---------|---------|------|
| 打开上次插件 | 合并到 openPlugin 动作 | 使用 exclude 参数 |
| 选择打开插件 | 保持独立动作 | 需要插件列表表单 |
| 返回上一页 | 保持独立动作 | 使用 Navigator API |
| 返回首页 | 保持独立动作 | 使用 Navigator API |
| 刷新页面 | 保持独立动作 | 发送刷新事件 |
| 路由历史记录 | 保持独立动作 | 显示历史对话框 |
| 打开上个路由 | 保持独立动作 | 恢复上次页面 |

#### 从 floating_ball_service.dart 迁移 (44-130行)
| 动作 | 迁移方式 | 备注 |
|------|---------|------|
| openPlugin | 合并到 openPlugin 动作 | 使用 plugin 参数 |
| openSettings | 保持独立动作 | 打开设置页面 |
| goHome | 合并到返回首页动作 | 同名合并 |
| goBack | 合并到返回上一页动作 | 同名合并 |

### 1.4 动作执行引擎

#### 动作执行器 (ActionExecutor)
**路径**: `lib/core/action/action_executor.dart`

**职责**:
- 将动作定义转换为可执行的 Dart 代码
- 处理动作间的依赖关系
- 支持异步动作执行
- 错误处理和日志记录

**执行流程**:
```
ActionInstance → 数据验证 → 解析参数 → 调用执行器 → 返回结果
```

### 1.5 数据持久化层

#### 动作配置存储
**路径**: `lib/core/action/action_storage.dart`

**存储结构**:
```json
{
  "version": 1,
  "actions": {
    "tap": {
      "type": "group",
      "config": {
        "title": "自定义动作1",
        "actions": [
          {"action": "openPlugin", "data": {"plugin": "chat"}},
          {"action": "openSettings", "data": {}}
        ]
      }
    },
    "swipeUp": {
      "type": "single",
      "config": {
        "action": "goHome",
        "data": {}
      }
    }
  }
}
```

---

## 第二阶段：UI 界面与交互 (2-3天)

### 2.1 动作选择对话框 (ActionSelectorDialog)

#### 设计目标
基于用户需求，创建改进的动作选择界面，支持：
- 展示已添加的动作列表
- 添加新动作按钮
- 动态表单配置
- 动作预览

#### 界面布局
```
┌─────────────────────────────┐
│ 选择动作                      │
├─────────────────────────────┤
│ [已配置动作列表]               │
│ ┌─ 动作1 ──────────── [编辑] │
│ └─ 动作2 ──────────── [编辑] │
│                             │
│ [+ 添加动作]                  │
├─────────────────────────────┤
│ [取消]            [保存]    │
└─────────────────────────────┘
```

#### 核心组件
**路径**: `lib/core/action/widgets/action_selector_dialog.dart`

### 2.2 动作配置表单 (ActionConfigForm)

#### 功能特性
1. **动态字段渲染**
   - 根据 ActionForm 生成表单控件
   - 支持多类型字段：text, select, checkbox, number
   - 自定义验证规则

2. **插件选择器**
   - 参考 `plugin_list_dialog.dart`
   - 支持搜索和过滤
   - 显示插件图标和名称

3. **验证与预览**
   - 实时验证输入
   - 显示动作执行预览
   - 错误提示

#### 核心组件
**路径**: `lib/core/action/widgets/action_config_form.dart`

### 2.3 设置界面改造

#### 修改 FloatingBallSettingsScreen
**路径**: `lib/core/floating_ball/settings_screen.dart`

**改造内容**:
- 替换第138-157行的下拉选择器
- 集成 ActionSelectorDialog
- 保持向下兼容（现有配置自动迁移）

---

## 第三阶段：系统集成与测试 (3-4天)

### 3.1 悬浮球服务集成

#### 迁移 FloatingBallService
**路径**: `lib/core/app_widgets/floating_ball_service.dart`

**改造策略**:
- 保留现有事件监听机制
- 将 action/args 转换为 ActionInstance
- 调用 ActionManager.executeAction 执行动作

**执行流程**:
```
buttonEvent → 解析事件数据 → 创建 ActionInstance → 调用 ActionManager → 执行动作
```

#### 迁移 FloatingBallManager
**路径**: `lib/core/floating_ball/floating_ball_manager.dart`

**改造策略**:
- 保留配置持久化逻辑
- 集成 ActionManager
- 迁移预定义动作到新系统

### 3.2 动作执行优化

#### 支持多动作组合
```dart
// 顺序执行（默认）
ActionGroup(
  title: "打开插件并返回首页",
  operator: ActionGroupOperator.sequence,
  actions: [
    ActionInstance(actionId: "openPlugin", data: {"plugin": "chat"}),
    ActionInstance(actionId: "goHome", data: {})
  ]
)

// 并行执行
ActionGroup(
  title: "批量操作",
  operator: ActionGroupOperator.parallel,
  actions: [...]
)
```

#### 错误处理与回退
- 动作执行失败时的回退机制
- 详细的错误日志记录
- 用户友好的错误提示

### 3.3 配置迁移工具

#### 自动迁移现有配置
**路径**: `lib/core/action/migration/migration_tool.dart`

**迁移策略**:
1. 检测旧版配置文件
2. 解析现有动作映射
3. 转换为新格式
4. 备份原配置
5. 应用新配置

---

## 实施细节

### 关键文件清单

#### 需要创建的文件
```
lib/core/action/
├── action_manager.dart              # 动作管理器核心
├── action_executor.dart             # 动作执行引擎
├── action_storage.dart              # 动作存储管理
├── models/
│   ├── action_definition.dart       # 动作定义模型
│   ├── action_instance.dart         # 动作实例模型
│   ├── action_form.dart             # 动作表单模型
│   └── action_group.dart            # 动作组模型
├── widgets/
│   ├── action_selector_dialog.dart  # 动作选择对话框
│   ├── action_config_form.dart      # 动作配置表单
│   └── action_preview_card.dart     # 动作预览卡片
├── validators/
│   └── action_validators.dart       # 动作验证器
└── migration/
    └── migration_tool.dart          # 配置迁移工具
```

#### 需要修改的文件
```
lib/core/app_widgets/floating_ball_service.dart     # 集成 ActionManager
lib/core/floating_ball/floating_ball_manager.dart  # 集成 ActionManager
lib/core/floating_ball/settings_screen.dart        # 改造UI
```

### 依赖关系图

```
┌──────────────────────┐
│ ActionManager        │ (核心单例)
└──────┬───────────────┘
       │
       ├─ 注册动作 ──→ ActionDefinition
       ├─ 执行动作 ──→ ActionExecutor
       ├─ 存储管理 ──→ ActionStorage
       └─ 配置迁移 ──→ MigrationTool
       
┌──────────────────────┐
│ FloatingBallService  │ (悬浮球服务)
└──────┬───────────────┘
       │
       └─ 执行动作 ──→ ActionManager
       
┌──────────────────────┐
│ SettingsScreen       │ (设置界面)
└──────┬───────────────┘
       │
       ├─ 选择动作 ──→ ActionSelectorDialog
       └─ 配置表单 ──→ ActionConfigForm
```

### 数据流程图

```
旧配置 → 迁移工具 → 新格式 → 存储 → 加载 → UI显示 → 用户操作 → 执行动作 → 结果反馈
```

### 测试计划

#### 单元测试 (覆盖率 > 80%)
- ActionManager 的注册、验证、执行逻辑
- ActionStorage 的读写、序列化
- ActionExecutor 的动作执行
- 迁移工具的完整性

#### 集成测试
- 悬浮球手势触发动作
- 动作表单配置流程
- 多动作组合执行
- 错误处理机制

#### 手动测试
- 现有配置迁移验证
- 新旧界面对比测试
- 性能测试（大量动作场景）

---

## 风险评估与应对策略

### 高风险项
1. **配置迁移失败** - 备份原配置，提供回滚机制
2. **现有功能破坏** - 保持向后兼容，逐步迁移
3. **性能影响** - 动作缓存优化，懒加载机制

### 中风险项
1. **UI 适配问题** - 多设备测试，响应式设计
2. **动作冲突** - 动作ID唯一性检查，冲突警告
3. **数据一致性** - 事务性写入，写后验证

### 低风险项
1. **国际化缺失** - 使用现有本地化系统
2. **文档不完整** - 逐步完善，迭代更新
3. **代码风格不一致** - 遵循项目规范，静态检查

---

## 成功标准

### 功能标准
- [ ] 成功合并两个文件的重复逻辑
- [ ] 支持动作表单配置
- [ ] 支持多动作组合执行
- [ ] UI 改进符合用户需求
- [ ] 配置迁移100%成功

### 质量标准
- [ ] 代码覆盖率 > 80%
- [ ] 零崩溃和严重错误
- [ ] 响应时间 < 100ms
- [ ] 内存占用稳定

### 兼容标准
- [ ] 保持现有配置可用
- [ ] 现有手势继续工作
- [ ] 插件系统无影响
- [ ] 跨平台一致性

---

## 时间线总结

| 阶段 | 时间 | 里程碑 |
|------|------|--------|
| 第一阶段 | Day 0-2 | 核心架构完成，基础动作迁移 |
| 第二阶段 | Day 2-3 | UI组件完成，界面改造 |
| 第三阶段 | Day 3-4 | 系统集成，测试验证 |
| 第四阶段 | Day 4-5 | 文档完善，发布准备 |

**总预计工期**: 5个工作日

---

## 后续优化方向

1. **动作市场** - 社区分享动作配置
2. **动作宏** - 录制和回放动作序列
3. **智能建议** - 基于使用习惯的动作推荐
4. **性能监控** - 动作执行统计和分析
5. **云端同步** - 跨设备的动作配置同步
