<p align="center">
  <img src="assets/icon/icon.png" width="128" alt="Memento 图标">
</p>

<h1 align="center">Memento</h1>

<p align="center">
Memento 是一个使用 Flutter 构建的跨平台个人助手应用，集成了聊天、日记和活动追踪功能。
</p>

<p align="center">
  <a href="https://hunmer.github.io/memento_docs/">📖 文档</a> •
  <a href="https://github.com/hunmer/Memento/releases">📦 下载</a>
</p>

## 项目介绍

这是一个使用 Flutter 开发的多功能记录应用集合，旨在降低不同应用间切换的成本。愿景是实现终身使用、持续改进和收集个人数据，利用 AI 进行数据分析和决策以改善生活。

## ✨ 特性

<table>
<tr>
<td align="center" width="33%">

### 🚀 跨平台支持
Android、iOS、Web、Windows、macOS、Linux 全平台覆盖

</td>
<td align="center" width="33%">

### 🔌 插件化架构
18+ 功能插件，可独立开发和维护

</td>
<td align="center" width="33%">

### 🔒 本地优先
支持 WebDAV 同步，数据掌控在用户手中

</td>
</tr>
<tr>
<td align="center">

### 🤖 AI 驱动
完全由 AI 编写，内置多种 AI 助手

</td>
<td align="center">

### 🌍 国际化
内置中英双语支持

</td>
<td align="center">

### 📱 现代 UI
Material Design 3 设计语言

</td>
</tr>
<tr>
<td align="center">

### ⚡ JavaScript 脚本
内置 JavaScript 引擎，支持自定义脚本扩展

</td>
<td align="center">

### 🧩 Web 小程序
支持运行 Web 小程序，无缝集成轻量级应用

</td>
<td align="center">

### 🖥️ 可部署后端
支持部署独立后端服务，提供 API 接口

</td>
</tr>
<tr>
<td align="center">

### 🔑 API Key 管理
内置 API Key 创建和管理，方便第三方应用集成

</td>
<td align="center">

### 🔧 MCP 服务
集成 Model Context Protocol，支持多种 AI 模型接入

</td>
<td align="center">

### 🔗 HTTP/WebSocket SDK
内置 SDK，轻松实现实时通信和 API 集成

</td>
</tr>
</table>

## 🏗️ 项目结构

```
Memento/
├── lib/                    # Flutter 应用代码
│   ├── core/               # 核心功能（插件系统、存储、事件）
│   ├── plugins/            # 功能插件（25+）
│   ├── screens/            # 应用界面
│   └── widgets/            # 通用组件
├── server/                 # Dart 同步服务器
│   ├── admin/              # Web 管理面板
│   └── lib/                # 服务器代码
├── mcp-memento-server/     # MCP Server (AI 集成)
├── shared_models/          # 共享数据模型
└── docs/                   # 文档
```

## 🚀 快速开始

### 移动端/桌面端

1. 安装 [Flutter SDK](https://flutter.dev)
2. 克隆项目并安装依赖
   ```bash
   git clone https://github.com/hunmer/Memento.git
   cd Memento
   flutter pub get
   ```
3. 运行应用
   ```bash
   flutter run
   ```

### 同步服务器

```bash
cd server
dart pub get
dart run bin/server.dart
# 访问 http://localhost:8080/admin/
```

### MCP Server (AI 集成)

```bash
cd mcp-memento-server
npm install
npm run build

# 配置 .env
MEMENTO_SERVER_URL=http://localhost:8080
MEMENTO_API_KEY=mk_live_your_api_key
MEMENTO_ENCRYPTION_KEY=your_encryption_key
```

## 📖 更多文档

- [完整文档](https://hunmer.github.io/memento_docs/)
- [服务器文档](server/CLAUDE.md)
- [MCP Server 文档](mcp-memento-server/README.md)
- [核心功能文档](lib/core/CLAUDE.md)

## 📄 许可证

MIT License