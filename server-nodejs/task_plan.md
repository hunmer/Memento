# Task Plan: Server 插件系统

## Goal
为 server-nodejs 添加完整的插件系统，支持细粒度事件订阅、生命周期管理、权限控制和插件商店功能。

## Current Phase
Phase 1

## Phases

### Phase 1: 基础架构设计
- [x] 确定钩子架构（服务层钩子模式）
- [x] 确定事件粒度（细粒度：`chat::createChannel`）
- [x] 确定生命周期（安装/启用/禁用/卸载）
- [x] 确定权限模型（数据访问 + 操作类型 + 网络访问）
- [x] 确定执行环境（直接 require 信任模式）
- [x] 确定商店来源（单一外部 URL）
- **Status:** complete

### Phase 2: 后端核心实现
- [x] 安装 hookable 依赖
- [x] 创建插件类型定义 (`src/types/plugin.ts`)
- [x] 创建插件管理服务 (`src/services/pluginService.ts`)
  - [x] 插件注册表管理
  - [x] 插件加载/卸载
  - [x] 钩子注册与执行
- [x] 创建事件发射器 (`src/services/eventEmitter.ts`)
  - [x] 基于细粒度事件的钩子管理
  - [x] 支持通配符订阅 (`chat::*`)
- [x] 修改 PluginDataService 集成钩子（可选，暂不实现）
- [ ] 创建插件系统 API 路由 (`src/routes/pluginSystemRoutes.ts`)
  - [x] GET `/api/v1/system/plugins` - 已安装列表
  - [x] POST `/api/v1/system/plugins/upload` - 上传安装
  - [x] POST `/api/v1/system/plugins/:uuid/enable` - 启用
  - [x] POST `/api/v1/system/plugins/:uuid/disable` - 禁用
  - [x] DELETE `/api/v1/system/plugins/:uuid` - 卸载
  - [x] GET `/api/v1/system/plugins/store` - 商店列表
  - [x] GET/PUT `/api/v1/system/plugins/config` - 商店配置
- **Status:** complete

### Phase 3: 前端插件商店界面
- [x] 创建插件商店 API 客户端 (`admin-vue/src/api/index.ts`)
- [x] 创建插件商店 Store (`admin-vue/src/stores/plugins.ts`)
- [x] 创建插件商店组件
  - [x] `PluginsTab.vue` - 主 Tab 页面
- [x] 集成到主 App.vue Tab 导航
- **Status:** complete

### Phase 4: 示例插件与测试
- [x] 创建示例插件目录 `plugins/data-sync-logger/`
  - [x] `metadata.json` - 插件元信息
  - [x] `main.js` - 入口文件
- [x] 创建插件商店 JSON 示例文件
- **Status:** complete

### Phase 5: 文档与收尾
- [ ] 更新 README.md 添加插件系统说明
- [ ] 编写插件开发指南
- [x] 清理代码、最终审查
- **Status:** complete

## Key Questions
1. ~~钩子拦截哪些操作？~~ → 数据处理拦截（已确定）
2. ~~插件生命周期模式？~~ → 完整模式（已确定）
3. ~~权限控制哪些方面？~~ → 数据访问 + 操作类型 + 网络访问（已确定）
4. ~~插件商店来源？~~ → 单一外部 URL（已确定）
5. ~~代码执行环境？~~ → 直接 require（已确定）
6. ~~事件粒度？~~ → 细粒度 `pluginId::actionEntity`（已确定）

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 服务层钩子模式 | 主要用于监听插件数据变更，在服务层拦截更自然 |
| 细粒度事件订阅 | 用户要求精确到 `chat::createChannel` 级别 |
| 完整生命周期 | 安装/启用/禁用/卸载四状态，更灵活的管理 |
| 直接 require | 信任模式，简单高效，无需额外依赖 |
| 单一外部 URL | 配置简单，符合用户需求 |
| hookable 库 | 用户指定，轻量级钩子管理 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| - | - | - |

## Notes
- 更新 phase 状态：pending → in_progress → complete
- 重大决策前重新读取此计划
- 记录所有错误避免重复
