# WebView 本地 HTTP 服务器使用指南

## 概述

WebView 插件集成了本地 HTTP 服务器，用于在 Windows 等平台上提供本地 HTML 文件的访问，绕过 `file://` 协议的安全限制。

## 架构设计

### 1. 统一的 HTTP 根目录

所有本地项目都存储在统一的目录下：
```
{app_data}/webview/http_server/
├── project1/
│   ├── index.html
│   ├── style.css
│   └── script.js
├── project2/
│   └── main.html
└── test_project/
    └── test.html
```

### 2. URL 格式

- **相对路径格式**：`./项目名称/文件名.html`
- **HTTP URL 格式**：`http://localhost:8080/项目名称/文件名.html`

### 3. 自动转换机制

当加载 URL 时，系统会自动处理：
1. 检测 `./` 开头的相对路径
2. 确保 HTTP 服务器已启动
3. 自动转换为 `http://localhost:8080/` 开头的 URL

## 使用方法

### 添加本地 HTML 项目

1. **打开 WebView 插件**
2. **点击添加按钮**（右下角 FAB）
3. **填写卡片信息**：
   - **标题**：项目显示名称（如 "我的网页应用"）
   - **项目名称**：英文名称（如 "my_app"，只允许字母、数字、下划线、连字符）
   - **URL**：点击文件夹图标选择本地 HTML 文件
   - **描述**：可选的项目描述

4. **选择本地文件**：
   - 点击 URL 输入框右侧的文件夹图标
   - 选择 `.html` 或 `.htm` 文件
   - 系统会自动：
     - 切换到"本地文件"模式
     - 填充标题（如果为空）
     - 生成项目名称（如果为空）
     - 将 URL 设置为只读

5. **确认添加**：
   - 点击"保存"按钮
   - 系统会自动：
     - 将文件复制到 `http_server/项目名称/` 目录
     - 生成 `./项目名称/文件名.html` 格式的 URL
     - 创建卡片并保存

### 打开本地项目

1. **点击卡片**打开项目
2. **系统自动处理**：
   - 检测到 `./` 开头的 URL
   - 启动 HTTP 服务器（如果尚未运行）
   - 转换为 `http://localhost:8080/...` URL
   - 在 InAppWebView 中加载

### 管理本地项目

#### 查看项目列表
```dart
final projects = await WebViewPlugin.instance.getHttpProjects();
// 返回: ['project1', 'project2', 'test_project']
```

#### 删除项目
```dart
await WebViewPlugin.instance.deleteHttpProject('project1');
```

## 技术细节

### 服务器特性

- **端口**：8080（如果被占用会自动尝试 8081-8089）
- **根目录**：`{app_data}/webview/http_server/`
- **MIME 类型**：自动识别（HTML、CSS、JS、图片等）
- **CORS 支持**：允许跨域请求
- **缓存控制**：开发环境不缓存（`no-cache`）

### 文件复制规则

1. **单个文件**：
   - 复制到 `http_server/项目名称/文件名.html`
   - 返回路径：`./项目名称/文件名.html`

2. **目录**（暂不支持，计划中）：
   - 递归复制整个目录
   - 跳过隐藏文件（以 `.` 开头）
   - 自动查找入口文件（index.html 或第一个 .html 文件）

### 项目名称规则

- **允许字符**：字母（a-z, A-Z）、数字（0-9）、下划线（_）、连字符（-）
- **不允许**：空格、中文、特殊符号
- **推荐格式**：
  - `my_project`（推荐）
  - `test-app`
  - `demo123`

## 示例

### 示例 1：添加简单 HTML 文件

```
原始文件：D:/Downloads/test.html
项目名称：test
复制后：{app_data}/webview/http_server/test/test.html
卡片 URL：./test/test.html
实际访问：http://localhost:8080/test/test.html
```

### 示例 2：添加带资源的项目（计划中）

```
原始目录：D:/Projects/my_app/
  ├── index.html
  ├── style.css
  └── script.js

项目名称：my_app
复制后：{app_data}/webview/http_server/my_app/
  ├── index.html
  ├── style.css
  └── script.js

卡片 URL：./my_app/index.html
实际访问：http://localhost:8080/my_app/index.html
```

## 故障排查

### 问题 1：页面无法加载（404 错误）

**可能原因**：
- 文件未正确复制到 HTTP 服务器目录
- 项目名称或文件名不匹配

**解决方法**：
1. 检查 HTTP 服务器目录：`{app_data}/webview/http_server/`
2. 确认项目目录和文件是否存在
3. 检查卡片 URL 是否正确（应为 `./项目名称/文件名.html`）

### 问题 2：服务器未启动

**可能原因**：
- 端口被占用
- 初始化失败

**解决方法**：
1. 检查控制台日志：
   ```
   [WebViewPlugin] 本地 HTTP 服务器启动成功: http://localhost:8080
   ```
2. 如果启动失败，检查 8080-8089 端口是否都被占用
3. 重启应用

### 问题 3：CSS/JS 资源无法加载

**可能原因**：
- 资源文件未复制
- 路径不正确

**解决方法**：
1. 确保所有资源文件都在项目目录下
2. 使用相对路径引用资源：
   ```html
   <link rel="stylesheet" href="style.css">  <!-- 正确 -->
   <link rel="stylesheet" href="/style.css"> <!-- 错误 -->
   ```

## API 参考

### WebViewPlugin

#### `copyToHttpServer`
```dart
Future<String> copyToHttpServer({
  required String sourcePath,
  required String projectName,
})
```
复制本地文件/目录到 HTTP 服务器目录。

**参数**：
- `sourcePath`: 源文件或目录的绝对路径
- `projectName`: 项目名称（字母、数字、下划线、连字符）

**返回**：复制后的相对路径（如 `./projectName/index.html`）

#### `getHttpProjects`
```dart
Future<List<String>> getHttpProjects()
```
获取所有本地项目列表。

**返回**：项目名称列表

#### `deleteHttpProject`
```dart
Future<void> deleteHttpProject(String projectName)
```
删除指定的本地项目。

**参数**：
- `projectName`: 项目名称

#### `convertUrlIfNeeded`
```dart
String convertUrlIfNeeded(String url)
```
自动转换 URL（`./` -> `http://localhost:8080/`）。

**参数**：
- `url`: 原始 URL

**返回**：转换后的 URL

#### `getHttpServerRootDir`
```dart
String getHttpServerRootDir()
```
获取 HTTP 服务器根目录路径。

**返回**：根目录绝对路径

## 注意事项

1. **平台限制**：
   - Web 平台不支持本地文件操作
   - 仅在非 Web 平台（Windows、macOS、Linux）启动 HTTP 服务器

2. **安全性**：
   - 服务器仅绑定到 `127.0.0.1`（本地回环）
   - 不接受外部网络连接
   - 建议仅用于开发和测试

3. **性能**：
   - 服务器为简单实现，不适合大流量
   - 适用于个人使用和小型项目

4. **存储空间**：
   - 文件会被复制到应用数据目录
   - 大型项目会占用额外存储空间
   - 定期清理不需要的项目

## 未来改进

- [ ] 支持选择目录（而不仅是单个文件）
- [ ] 文件更新检测和同步
- [ ] 项目配置（自定义入口文件、端口等）
- [ ] 开发者工具集成（实时重载等）
- [ ] 项目模板和示例

## 相关文件

- **服务器实现**：`lib/plugins/webview/services/local_http_server.dart`
- **插件主文件**：`lib/plugins/webview/webview_plugin.dart`
- **主界面**：`lib/plugins/webview/screens/webview_main_screen.dart`
- **浏览器界面**：`lib/plugins/webview/screens/webview_browser_screen.dart`
