# WebView 插件 - AI 上下文文档

[根目录](../../../CLAUDE.md) > [plugins](../../) > [webview](../) > **webview**

> **变更记录 (Changelog)**
> - **2025-12-17T12:05:09+08:00**: 初始化 WebView 插件文档 - 完成全仓扫描，识别核心功能模块

---

## 模块职责

WebView 插件是 Memento 的内置浏览器和应用商店解决方案，提供：

- **多标签页浏览**：支持最多 10 个并发标签页，状态持久化
- **网址卡片管理**：在线 URL 和本地 HTML 文件的统一管理
- **Mento JS Bridge**：网页与原生功能的双向通信
- **本地 HTTP 服务器**：Windows 平台绕过 file:// 限制
- **小应用商店**：应用的发现、下载、安装和管理
- **代理支持**：Android 平台的自定义代理配置

---

## 入口与启动

### 主入口文件
- `webview_plugin.dart` - 插件主类，继承自 `BasePlugin` 和 `JSBridgePlugin`
  - 初始化所有服务（TabManager、CardManager、LocalHttpServer 等）
  - 管理 JS API 注册
  - 处理本地文件复制和 HTTP 服务器启动

### 启动流程
1. **初始化服务**（第 72-116 行）
   - TabManager（标签页管理）
   - CardManager（卡片管理）
   - ProxyControllerService（代理控制）
   - LocalHttpServer（本地 HTTP 服务器）
   - AppStoreManager（应用商店）
   - DownloadManager（下载管理）

2. **加载配置**（第 95-96 行）
   - WebView 设置（proxy、恢复标签页等）
   - 应用代理配置

3. **恢复状态**（第 109-111 行）
   - 恢复上次打开的标签页
   - 加载保存的卡片列表

4. **启动服务器**（第 114-116 行）
   - 非 Web 平台启动本地 HTTP 服务器（端口 8080）

5. **注册 JS Bridge**（第 122-144 行）
   - 等待 JSBridgeManager 初始化
   - 加载所有本地应用的 preload.js 脚本

---

## 对外接口

### JavaScript Bridge API

网页可通过以下方式调用原生功能：

```javascript
// 1. 检查 Bridge 就绪
Memento_ready()

// 2. 调用插件方法
Memento_plugin_call({
  pluginId: 'chat',
  method: 'sendMessage',
  params: { content: 'Hello' }
})

// 3. 调用系统 API
Memento_system_call({
  method: 'getVersion',
  params: {}
})

// 4. UI 交互
Memento_ui_toast({ message: '操作成功' })
Memento_ui_alert({ message: '确认删除？', options: { title: '提示' } })

// 5. 存储 API
Memento_storage_read({ key: 'userConfig' })
Memento_storage_write({ key: 'userConfig', value: { theme: 'dark' } })
Memento_storage_delete({ key: 'userConfig' })
```

### WebView 插件 JS API

```javascript
// 卡片管理
Memento.webview.getCards()
Memento.webview.addCard({ title, url, type })
Memento.webview.deleteCard({ cardId })
Memento.webview.updateCard({ cardId, changes })

// 标签页管理
Memento.webview.getTabs()
Memento.webview.createTab({ url, title })
Memento.webview.closeTab({ tabId })
Memento.webview.switchTab({ tabId })

// 导航控制
Memento.webview.navigate({ url })
Memento.webview.goBack()
Memento.webview.goForward()
Memento.webview.reload()
```

---

## 关键依赖与配置

### 核心依赖
- `flutter_inappwebview`: WebView 引擎
- `provider`: 状态管理
- `file_picker`: 文件选择（Android 11+ 支持）
- `http`: HTTP 请求（应用商店）
- `crypto`: MD5 校验（下载验证）

### 配置文件
- `webview/settings.json` - WebView 设置
  - proxySettings: 代理配置
  - restoreTabsOnStartup: 启动时恢复标签页
  - enableJavaScript: JS 开关
  - enableJSBridge: JS Bridge 开关

- `webview/tabs.json` - 标签页状态
- `webview/cards.json` - 卡片数据
- `webview/app_sources.json` - 应用商店源配置

### 存储结构
```
app_data/webview/
├── http_server/          # 本地 HTTP 服务器根目录
│   ├── app1/            # 已安装的应用
│   └── app2/
├── local_files/         # 本地文件存储
└── settings/            # 配置文件
```

---

## 数据模型

### WebViewCard（卡片模型）
- **类型**：在线 URL / 本地文件
- **属性**：
  - `id`: UUID 标识
  - `title`: 显示标题
  - `url`: 访问地址
  - `type`: CardType 枚举
  - `sourcePath`: 原始路径（本地文件同步用）
  - `openCount`: 打开次数
  - `isPinned`: 是否固定
  - `tags`: 标签列表

### WebViewTab（标签页模型）
- **属性**：
  - `id`: UUID 标识
  - `url`: 当前 URL
  - `title`: 页面标题
  - `isActive`: 是否活动
  - `scrollPosition`: 滚动位置
  - `canGoBack/Forward`: 导航状态
  - `cardId`: 关联的卡片 ID

### MiniApp（小应用模型）
- **属性**：
  - `id`: 应用唯一标识
  - `title`: 应用名称
  - `version`: 版本号
  - `filesUrl`: 文件列表 URL
  - `md5`: 文件校验和
  - `tags`: 分类标签

---

## 测试与质量

### 测试文件位置
```
assets/
├── test_jsbridge.html   # JS Bridge 功能测试
└── test_simple.html     # 基础 WebView 测试
```

### 测试覆盖
- JS Bridge 通信测试
- 本地文件加载测试
- 应用商店功能测试
- 代理配置测试

### 已知限制
1. **代理功能**：仅 Android 平台支持
2. **本地 HTTP 服务器**：非 Web 平台启用
3. **文件访问**：Android 11+ 需要通过 SAF 选择文件
4. **标签页数量**：硬编码最大 10 个

---

## 常见问题 (FAQ)

**Q: 如何添加本地 HTML 项目？**
A: 点击添加按钮 → 选择"本地文件"类型 → 选择 index.html → 输入项目名称 → 系统自动复制到 http_server 目录

**Q: JS Bridge 不工作怎么办？**
A: 检查控制台日志中的 "[WebViewPlugin] ✓ JSBridgeManager 初始化完成" 消息，确保网页中正确注入了 bridge.js

**Q: Windows 上本地文件无法访问？**
A: 本地 HTTP 服务器会自动启动（端口 8080），URL 会从 file:// 自动转换为 http://localhost:8080

**Q: 如何更新已安装的应用？**
A: 目前需要先卸载再安装。应用商店显示已安装版本，支持版本比较

**Q: 代理设置不生效？**
A: 确认在 Android 平台，且 WebView 设置中已启用代理功能

---

## 相关文件清单

### 核心文件
- `webview_plugin.dart` - 插件主类（945 行）
- `screens/webview_main_screen.dart` - 主界面（956 行）
- `screens/webview_browser_screen.dart` - 浏览器界面
- `screens/webview_settings_screen.dart` - 设置界面

### 服务层
- `services/tab_manager.dart` - 标签页管理
- `services/card_manager.dart` - 卡片管理
- `services/local_http_server.dart` - 本地 HTTP 服务器
- `services/app_store_manager.dart` - 应用商店管理
- `services/download_manager.dart` - 下载管理
- `services/js_bridge_injector.dart` - JS Bridge 注入
- `services/proxy_controller_service.dart` - 代理控制

### 数据模型
- `models/webview_card.dart` - 卡片模型
- `models/webview_tab.dart` - 标签页模型
- `models/webview_settings.dart` - 设置模型
- `models/app_store_models.dart` - 应用商店模型
- `models/proxy_settings.dart` - 代理设置模型

### 界面组件
- `screens/components/webview_card_item.dart` - 卡片项组件
- `screens/tab_manager_screen.dart` - 标签页管理界面
- `screens/proxy_settings_screen.dart` - 代理设置界面
- `screens/app_store/` - 应用商店相关界面
  - `app_store_screen.dart` - 商城主界面
  - `app_detail_sheet.dart` - 应用详情
  - `source_management_screen.dart` - 源管理

### 国际化
- `l10n/webview_translations_zh.dart` - 中文翻译（128 条）
- `l10n/webview_translations_en.dart` - 英文翻译

### 文档
- `HTTP_SERVER_GUIDE.md` - 本地 HTTP 服务器使用指南

---

## 下一步建议

1. **测试覆盖**：为核心服务（TabManager、CardManager、DownloadManager）添加单元测试
2. **功能增强**：
   - 支持应用的热更新
   - 添加浏览器历史记录
   - 实现书签导入/导出
3. **性能优化**：
   - 标签页的懒加载
   - 大文件的分块下载
   - WebView 预加载池
4. **平台扩展**：
   - iOS 代理支持
   - 桌面平台的系统集成（系统通知、快捷键）

---

**最后更新**: 2025-12-17T12:05:09+08:00