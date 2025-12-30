# Memento 小应用仓库

这是 Memento WebView 插件的官方小应用仓库，包含可在 Memento 中运行的各种小应用。

## 仓库结构

```
online/
├── apps.json                    # 应用列表配置文件
├── generate_files_json.py       # 文件列表生成工具
├── README.md                    # 本文档
└── password_manager/            # 密码管理器应用目录
    ├── files.json              # 文件列表和校验信息
    ├── index.html              # 应用主页面
    └── preload.js              # 预加载脚本
```

## 应用列表格式

`apps.json` 文件包含所有可用应用的元数据：

```json
[
  {
    "id": "password_manager",           // 应用唯一标识
    "title": "密码管理器",              // 应用名称
    "desc": "应用描述...",              // 应用描述
    "files": "password_manager/files.json",  // 文件列表JSON路径
    "version": "1.0.0",                 // 版本号
    "tags": ["工具", "安全", "密码"],    // 标签
    "permissions": ["storage"]          // 所需权限
  }
]
```

## 文件列表格式

每个应用的 `files.json` 文件包含所有文件的信息：

```json
[
  {
    "path": "index.html",               // 文件相对路径
    "md5": "b93effa69809a3fbbae9910ad1be6cbb",  // MD5校验值
    "size": 25223                       // 文件大小（字节）
  }
]
```

## 如何使用

### 在 Memento 中添加应用源

1. 打开 Memento 应用
2. 进入 WebView 插件的应用商店
3. 添加新的应用源，配置如下：
   - **源名称**: 本地仓库（或自定义名称）
   - **JSON URL**: `file:///path/to/online/apps.json`
   - **基础URL**: `file:///path/to/online/`

### 开发新应用

#### 方式一：使用自动化工具（推荐）

1. 在 `online/` 目录下创建新的应用目录
2. 添加应用文件（至少需要 `index.html`）
3. 使用自动化工具生成 `files.json`：
   ```bash
   # 处理所有应用
   python3 generate_files_json.py

   # 只处理指定应用
   python3 generate_files_json.py --app your_app

   # 预览模式（不实际写入文件）
   python3 generate_files_json.py --app your_app --dry-run
   ```
4. 在 `apps.json` 中添加应用配置

#### 方式二：手动创建

1. 在 `online/` 目录下创建新的应用目录
2. 添加应用文件（至少需要 `index.html`）
3. 计算文件的 MD5 和大小：
   ```bash
   md5 your_app/index.html
   stat -f%z your_app/index.html  # macOS
   # 或
   md5sum your_app/index.html
   stat -c%s your_app/index.html  # Linux
   ```
4. 手动创建 `your_app/files.json` 文件列表
5. 在 `apps.json` 中添加应用配置

#### 自动化工具说明

`generate_files_json.py` 脚本功能：
- 自动扫描应用目录中的所有文件
- 计算每个文件的 MD5 校验值和大小
- 生成标准格式的 `files.json` 文件
- 支持批量处理或单个应用处理
- 自动排除系统文件和配置文件

使用示例：
```bash
# 查看帮助信息
python3 generate_files_json.py --help

# 处理所有应用
python3 generate_files_json.py

# 只处理密码管理器
python3 generate_files_json.py --app password_manager

# 预览模式，查看将生成的内容
python3 generate_files_json.py --app my_app --dry-run
```

## 已包含的应用

### 密码管理器 (password_manager)

- **版本**: 1.0.0
- **功能**: 本地密码存储、分类管理、搜索
- **权限**: storage
- **标签**: 工具、安全、密码

一个简单安全的本地密码管理工具，所有数据都存储在本地，确保密码安全。

## 权限说明

应用可能需要以下权限：

- `storage`: 访问本地存储API
- `network`: 发起网络请求
- `camera`: 访问相机
- `location`: 访问位置信息
- `notification`: 显示通知

## 注意事项

1. **安全性**: 请仔细审查应用源码，确保不包含恶意代码
2. **权限**: 仅授予应用必需的权限
3. **数据备份**: 定期备份应用数据
4. **更新**: 及时更新应用以获得新功能和安全修复

## 贡献

欢迎贡献新的应用！请确保：

- 应用功能明确、实用
- 代码简洁、可维护
- 遵循 Web 标准
- 提供完整的文件校验信息
- 清晰说明所需权限

## 许可证

各应用的许可证请参考应用目录中的 LICENSE 文件。
