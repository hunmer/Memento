# Findings & Decisions

## Requirements

### 核心需求
- 后端开启插件系统 API（列表/安装/卸载/启用/禁用）
- 安装插件：上传 zip，包含 `main.js` 入口和 `metadata.json` 信息
- 插件生命周期：安装 → 启用 → 禁用 → 卸载
- 前端插件商店界面，可配置商店 JSON URL
- 编写示例插件并添加到商店列表

### 插件元信息
```
uuid, title, author, description, website, permissions, updateURL, version, priority
```

### 权限控制
- 数据访问权限：限制可访问的插件 ID
- 操作类型权限：create/read/update/delete
- 网络访问权限：是否允许 HTTP 请求

### 事件订阅
- 细粒度事件：`chat::createChannel`, `todo::deleteTask` 等
- 支持通配符：`chat::*` 订阅某插件所有事件
- before/after 钩子：操作前可拦截/修改，操作后仅通知

## Research Findings

### 项目结构
```
server-nodejs/
├── src/
│   ├── index.ts              # 入口，服务初始化
│   ├── services/             # 服务层
│   │   ├── pluginDataService.ts  # 插件数据 CRUD
│   │   ├── authService.ts    # 认证服务
│   │   └── fileStorageService.ts # 文件存储
│   ├── routes/               # 路由层
│   │   ├── authRoutes.ts
│   │   ├── syncRoutes.ts
│   │   └── pluginRoutes/     # 19个插件路由
│   └── middleware/           # 中间件
├── admin-vue/                # Vue 前端
│   └── src/
│       ├── components/       # UI 组件
│       ├── stores/           # Pinia stores
│       └── api/              # API 客户端
└── data/                     # 数据目录
```

### 现有插件列表（19个）
chat, notes, activity, goods, bill, todo, agent_chat, calendar_album, calendar, checkin, contact, database, day, diary, nodes, openai, store, timer, tracker

### 技术栈
- 后端：Express + TypeScript
- 前端：Vue 3 + Naive UI + Pinia
- 存储：JSON 文件
- 认证：JWT

### hookable 库使用
```typescript
import { createHooks } from 'hookable'

const hooks = createHooks()
hooks.hook('event', handler)
await hooks.callHook('event', payload)
```

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| 服务层钩子模式 | 用户主要监听插件数据变更，在 PluginDataService 层拦截更自然 |
| 细粒度事件 `pluginId::actionEntity` | 用户明确要求精确到 `chat::createChannel` 级别 |
| 完整生命周期（安装/启用/禁用/卸载） | 更灵活的插件管理，保留配置但停用代码 |
| 直接 require 执行 | 信任模式，简单高效，无需额外沙箱依赖 |
| 单一外部 URL 商店 | 配置简单，用户明确选择此方案 |
| hookable 库 | 用户指定，轻量级钩子管理 |

### 事件系统设计
```typescript
// 事件命名
'{pluginId}::{action}{Entity}'
// 示例
'chat::createChannel', 'todo::deleteTask'

// 钩子类型
before{Action}{Entity} - 可拦截、可修改数据
after{Action}{Entity}  - 仅通知

// 插件注册
module.exports = {
  events: ['chat::*', 'todo::createTask'],
  handlers: {
    'chat::createChannel': async (ctx) => ctx,
    'todo::createTask': async (ctx) => ctx,
  },
  onLoad: async () => {},
  onUnload: async () => {},
}
```

## Issues Encountered

| Issue | Resolution |
|-------|------------|
| - | - |

## Resources

- [hookable npm](https://www.npmjs.com/package/hookable)
- 现有代码：`src/services/pluginDataService.ts`
- 前端组件：`admin-vue/src/components/`

## Visual/Browser Findings

（无）

---

*2-Action Rule: 每 2 次查看/搜索操作后更新此文件*
