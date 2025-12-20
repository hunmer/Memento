/// Chinese (Simplified) translations for app-level strings
///
/// All keys are prefixed with 'app_' to avoid conflicts with plugin translations.
/// Parameterized translations use @paramName format for GetX.
const Map<String, String> appTranslationsZh = {
  // App basics
  'app_appTitle': 'memento',
  'app_pluginManager': '插件管理器',
  'app_home': '首页',
  'app_settings': '设置',
  'app_version': '版本',

  // Common actions
  'app_ok': '确定',
  'app_select': '选择',
  'app_no': '否',
  'app_yes': '是',
  'app_cancel': '取消',
  'app_save': '保存',
  'app_close': '关闭',
  'app_delete': '删除',
  'app_reset': '重置',
  'app_apply': '应用',
  'app_edit': '编辑',
  'app_retry': '重试',
  'app_rename': '重命名',
  'app_copy': '复制',
  'app_done': '完成',
  'app_create': '新建',
  'app_confirm': '确认',
  'app_import': '导入',

  // Delete confirmation
  'app_confirmDelete': '确认删除?',

  // Date and time
  'app_selectDate': '选择日期',
  'app_startTime': '开始时间',
  'app_endTime': '结束时间',
  'app_interval': '间隔',
  'app_minutes': '分钟',
  'app_week': '周',
  'app_month': '月',
  'app_date': '日期',
  'app_day': '第@day天',

  // Display options
  'app_showAll': '显示全部',
  'app_adjustCardSize': '调整卡片大小',
  'app_width': '宽度',
  'app_height': '高度',

  // Tags and categories
  'app_tags': '标签',
  'app_selectGroup': '选择分组',
  'app_selectLocation': '选择位置',

  // Backup and export
  'app_backupOptions': '备份选项',
  'app_selectBackupMethod': '请选择备份方式',
  'app_exportAppData': '导出应用数据',
  'app_fullBackup': '完整备份',
  'app_webdavSync': 'WebDAV同步',
  'app_setBackupSchedule': '设置备份计划',

  // Backup progress
  'app_backupInProgress': '正在备份',
  'app_completed': '已完成: @percentage%',
  'app_exportingData': '正在导出数据',
  'app_importingData': '正在导入数据',
  'app_pleaseWait': '请等待',

  // Export messages
  'app_exportCancelled': '导出已取消',
  'app_exportSuccess': '数据导出成功',
  'app_exportFailed': '导出失败: @error',
  'app_dataExportedTo': '数据已导出到: @path',
  'app_exportFailedWithError': '导出失败: @error',
  'app_exportSuccessTo': '导出成功到: @path',

  // Import messages
  'app_warning': '警告',
  'app_importWarning': '导入操作将完全覆盖当前的应用数据。\n建议在导入前备份现有数据。\n\n是否继续?',
  'app_stillContinue': '继续',
  'app_importCancelled': '已取消导入操作',
  'app_selectBackupFile': '请选择备份文件',
  'app_noFileSelected': '未选择文件',
  'app_importInProgress': '正在导入',
  'app_processingBackupFile': '正在处理备份文件...',
  'app_importSuccess': '数据导入成功,请重启应用',
  'app_restartRequired': '需要重启',
  'app_restartMessage': '数据已导入完成,需要重启应用才能生效。',
  'app_fileSelectionFailed': '文件选择失败: @error',
  'app_importFailed': '导入失败',
  'app_importTimeout': '导入超时:文件可能过大或无法访问',
  'app_filesystemError': '文件系统错误:无法读取或写入文件',
  'app_invalidBackupFile': '无效的备份文件:文件可能已损坏',
  'app_noPluginDataFound': '没有找到可导入的插件数据',
  'app_importFailedWithError': '导入失败: @error',

  // Plugin management
  'app_noPluginsAvailable': '没有可用的插件',
  'app_failedToLoadPlugins': '加载插件失败: @error',
  'app_selectPluginToExport': '选择要导出的插件',
  'app_selectPluginToImport': '选择要导入的插件 (@mode)',
  'app_selectPluginsToImport': '选择插件导入',
  'app_selectFolderToImport': '选择要导入的文件夹',
  'app_dataSize': '数据大小: @size',
  'app_mergeMode': '合并模式',
  'app_overwriteMode': '覆盖模式',

  // Permissions
  'app_permissionRequired': '需要@permission权限',
  'app_permissionRequiredForApp': '应用需要@permission权限来正常工作,是否授予权限?',
  'app_notNow': '暂不授予',
  'app_grantPermission': '授予权限',
  'app_permissionRequiredInSettings': '需要@permission权限才能继续。请在系统设置中授予权限。',
  'app_storagePermissionRequired': '需要存储权限才能继续。请在系统设置中授予权限。',
  'app_permissionsTitle': '权限授权',
  'app_permissionsDescription': '为了正常备份、导入和接收提醒，请授予以下权限。',
  'app_permissionsGrantAll': '一次性授权全部权限',
  'app_permissionsGranted': '已授权',
  'app_permissionsRequest': '去授权',
  'app_permissionsOpenSettings': '打开系统设置',
  'app_permissionsManageDescription': '查看并管理多媒体与通知权限。',
  'app_permission_photosTitle': '照片',
  'app_permission_photosDescription': '用于在日记、打卡等插件中选择和备份图片。',
  'app_permission_videosTitle': '视频',
  'app_permission_videosDescription': '用于录制、选择和导出视频文件。',
  'app_permission_audioTitle': '音频',
  'app_permission_audioDescription': '用于录音、语音笔记及附加音频文件。',
  'app_permission_notificationsTitle': '通知',
  'app_permission_notificationsDescription': '用于发送提醒、倒计时等系统通知。',
  'app_permission_storageTitle': '存储',
  'app_permission_storageDescription': '用于读写备份、导入导出所需的文件。',

  // File operations
  'app_downloadCancelled': '下载已取消',
  'app_moveSuccess': '移动成功',
  'app_moveFailed': '移动失败: @error',
  'app_renameFailed': '重命名失败: @error',

  // Media selection
  'app_selectImage': '选择图片',
  'app_selectFromGallery': '从相册选择',
  'app_takePhoto': '拍照',
  'app_loadingVideo': '正在加载视频...',
  'app_videoLoadFailed': '视频加载失败: @error',

  // Form validation
  'app_pleaseEnterTitle': '请输入标题',
  'app_titleRequired': '请输入标题',

  // Colors
  'app_selectBackgroundColor': '选择背景颜色',
  'app_nodeColor': '节点颜色',

  // Testing
  'app_testForegroundTask': '测试前台任务',

  // About
  'app_aboutTitle': '关于',
  'app_aboutDescription': 'Memento是一款生产力应用,旨在帮助您组织和记住重要事项。',
  'app_projectLinkTitle': '项目链接',
  'app_projectLink': 'https://github.com/hunmer/memento',
  'app_feedbackTitle': '反馈与建议',
  'app_feedbackLink': 'https://github.com/hunmer/Memento/issues',
  'app_documentationTitle': '项目文档',
  'app_documentationLink': 'https://github.com/hunmer/Memento#readme',

  // Home Widget Categories
  'home_categoryRecord': '记录',
  'home_categoryTools': '工具',
  'home_categoryCommunication': '通讯',
  'home_categoryFinance': '财务',
  'home_categoryLife': '生活',
  'home_loadFailed': '加载失败',
};
