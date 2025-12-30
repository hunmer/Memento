[根目录](../../../CLAUDE.md) > [lib](../../) > [screens](../) > **settings_screen**

---

# 设置屏幕 (Settings Screen) - 模块文档

## 模块职责

设置屏幕提供应用级和插件级的配置管理：

- **数据管理**：导入/导出、备份/恢复、WebDAV 同步
- **插件设置**：各插件的独立设置界面
- **应用设置**：主题、语言、通知、权限
- **自动更新**：检查新版本并下载更新
- **关于信息**：版本号、开源协议、贡献者

---

## 入口与启动

**主文件**: `settings_screen.dart`

**路由**: `/settings`

**界面结构**:
```
SettingsScreen
├── AppBar (标题: 设置)
├── ScrollView
│   ├── 数据管理卡片
│   │   ├── WebDAV 同步
│   │   ├── 导入/导出
│   │   └── 完整备份
│   ├── 插件设置列表
│   │   ├── 聊天插件设置
│   │   ├── AI 助手设置
│   │   └── ... (其他插件)
│   ├── 应用设置
│   │   ├── 主题切换
│   │   ├── 语言选择
│   │   └── 权限管理
│   ├── 高级设置
│   │   ├── 自动更新
│   │   └── 清理缓存
│   └── 关于
└── Footer
```

---

## 核心功能

### WebDAV 同步

**控制器**: `controllers/webdav_sync_controller.dart`

**功能**:
- 连接 WebDAV 服务器（NextCloud、坚果云等）
- 自动/手动同步应用数据
- 冲突检测与解决
- 同步进度显示

**配置模型**: `models/webdav_config.dart`

```dart
class WebDAVConfig {
  String url;              // WebDAV 服务器地址
  String username;         // 用户名
  String password;         // 密码
  String dataPath;         // 远程数据路径
  bool enabled;            // 是否启用
  bool autoSync;           // 自动同步
  int syncInterval;        // 同步间隔（分钟）

  Map<String, dynamic> toJson();
  factory WebDAVConfig.fromJson(Map<String, dynamic> json);
}
```

**关键方法**:

```dart
// 测试连接
Future<bool> testConnection(WebDAVConfig config) async {
  final client = WebDAVClient(config);
  return await client.testConnection();
}

// 上传数据
Future<void> uploadData() async {
  final localData = await _getLocalData();
  await _webdavClient.upload(config.dataPath, localData);
}

// 下载数据
Future<void> downloadData() async {
  final remoteData = await _webdavClient.download(config.dataPath);
  await _applyRemoteData(remoteData);
}

// 自动同步
void enableAutoSync() {
  _syncTimer = Timer.periodic(
    Duration(minutes: config.syncInterval),
    (_) => syncData(),
  );
}
```

---

### 数据导入/导出

**控制器**:
- `controllers/export_controller.dart`
- `controllers/import_controller.dart`

**功能**:
- 导出所有插件数据为 ZIP 文件
- 选择性导出（指定插件）
- 导入数据并合并/覆盖
- 导入前预览数据

**导出流程**:
```
用户点击 "导出数据"
  ↓
ExportController.exportAllData()
  ↓
遍历所有插件，读取数据文件
  ↓
使用 archive 包打包为 ZIP
  ↓
保存到用户选择的位置
  ↓
显示成功提示
```

**导入流程**:
```
用户选择 ZIP 文件
  ↓
ImportController.importData(file)
  ↓
解压 ZIP 文件
  ↓
显示导入预览对话框
  ↓
用户确认后写入数据
  ↓
重新初始化插件
  ↓
显示导入结果
```

---

### 完整备份

**控制器**: `controllers/full_backup_controller.dart`

**功能**:
- 备份整个应用目录（包括配置、数据、资源）
- 定时自动备份
- 备份历史管理
- 从备份恢复

**备份��式**:
```
memento_backup_2025-11-13.zip
├── configs/
├── chat/
├── diary/
├── activity/
└── ... (所有插件数据)
```

---

### 自动更新

**控制器**: `controllers/auto_update_controller.dart`

**功能**:
- 检查 GitHub Releases 的最新版本
- 对比当前版本号
- 下载更新安装包
- 显示更新日志
- Android: 自动安装 APK
- 其他平台: 提示手动下载

**关键方法**:

```dart
// 检查更新
Future<bool> checkForUpdates() async {
  final latestVersion = await _fetchLatestVersion();
  final currentVersion = await PackageInfo.fromPlatform();

  return _compareVersions(latestVersion, currentVersion.version);
}

// 显示更新对话框
void showUpdateDialog({bool skipCheck = false}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('发现新版本'),
      content: Column(
        children: [
          Text('版本: $latestVersion'),
          Text('更新内容:\n$changelog'),
        ],
      ),
      actions: [
        TextButton(
          child: Text('稍后'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('立即更新'),
          onPressed: () => downloadAndInstall(),
        ),
      ],
    ),
  );
}
```

---

### ���限管理

**控制器**: `controllers/permission_controller.dart`

**功能**:
- 检查和请求运行时权限
- 引导用户到系统设置
- 权限状态持久化

**请求的权限**:
- 存储（读写文件）
- 相机（拍照）
- 麦克风（录音）
- 位置（地理标记）
- 通知（提醒）

**关键代码**:

```dart
Future<void> checkAndRequestPermissions() async {
  final permissions = [
    Permission.storage,
    Permission.camera,
    Permission.microphone,
    Permission.location,
    Permission.notification,
  ];

  for (final permission in permissions) {
    if (await permission.isDenied) {
      await permission.request();
    }
  }
}
```

---

## 数据模型

### WebDAVConfig

见上文 "WebDAV 同步" 部分。

---

## 界面组件

### WebDAVSettingsDialog (WebDAV 设置对话框)

**文件**: `widgets/webdav_settings_dialog.dart`

**表单字段**:
- 服务器地址 (URL)
- 用户名
- 密码 (加密显示)
- 数据路径
- 启用开关
- 自动同步开关
- 同步间隔选择器

**国际化**: `widgets/l10n/webdav_localizations.dart`

---

### BackupProgressDialog (备份进度对话框)

**文件**: `widgets/backup_progress_dialog.dart`

**显示信息**:
- 当前正在备份的插件
- 进度条（百分比）
- 已备份文件数
- 估计剩余时间

---

### FolderSelectionDialog (文件夹选择对话框)

**文件**: `widgets/folder_selection_dialog.dart`

**用途**:
- 选择导出/导入的目标路径
- 选择备份保存位置

---

## 关键依赖

- `webdav_client`: WebDAV 协议客户端
- `permission_handler`: 权限请求
- `package_info_plus`: 获取应用版本信息
- `file_picker`: 文件选择器
- `archive`: ZIP 压缩/解压
- `dio`: HTTP 下载

---

## 测试与质量

### 已知问题

1. **WebDAV 冲突处理**: 简单覆盖策略，未实现三方合并
2. **大数据导出**: 超过 100MB ��能导致 OOM
3. **自动更新**: iOS 不支持（App Store 限制）

### 测试建议

- WebDAV 连接测试（各大服务商兼容性）
- 导入/导出的数据完整性校验
- 自动更新的版本对比逻辑

---

## 常见问题

### Q1: 如何配置 WebDAV 同步？

1. 进入 设置 > 数据管理 > WebDAV 设置
2. 填写服务器信息：
   - 坚果云: `https://dav.jianguoyun.com/dav/`
   - NextCloud: `https://your-domain.com/remote.php/dav/files/username/`
3. 点击 "测试连接"
4. 成功后启用并设置自动同步

### Q2: 导入数据会覆盖现有数据吗？

默认会提示选择：
- **合并**: 保留现有数据，只添加新数据
- **覆盖**: 完全替换为导入的数据
- **取消**: 放弃导入

### Q3: 如何禁用自动更新？

设置 > 高级设置 > 自动更新 > 关闭开关

---

## 相关文件清单

### 控制器 (7个)
- `controllers/webdav_sync_controller.dart`
- `controllers/webdav_controller.dart`
- `controllers/export_controller.dart`
- `controllers/import_controller.dart`
- `controllers/full_backup_controller.dart`
- `controllers/auto_update_controller.dart`
- `controllers/permission_controller.dart`

### 模型
- `models/webdav_config.dart`

### 界面
- `settings_screen.dart`
- `screens/data_management_screen.dart`

### 组件
- `widgets/webdav_settings_dialog.dart`
- `widgets/webdav_settings_section.dart`
- `widgets/backup_progress_dialog.dart`
- `widgets/folder_selection_dialog.dart`
- `widgets/plugin_selection_dialog.dart`

### 国际化
- `l10n/settings_screen_localizations.dart`
- `screens/data_management_localizations.dart`
- `widgets/l10n/webdav_localizations.dart`

---

## 变更记录

- **2025-11-14**: 移除日志系统相关功能和文件
- **2025-11-13T04:06:10+00:00**: 初始化设置屏幕文档

---

**上级目录**: [返回根文档](../../../CLAUDE.md)
