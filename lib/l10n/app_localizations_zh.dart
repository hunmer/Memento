// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'memento';

  @override
  String get pluginManager => '插件管理器';

  @override
  String get backupOptions => '备份选项';

  @override
  String get selectBackupMethod => '请选择备份方式';

  @override
  String get exportAppData => '导出应用数据';

  @override
  String get fullBackup => '完整备份';

  @override
  String get webdavSync => 'WebDAV同步';

  @override
  String get selectDate => '选择日期';

  @override
  String get showAll => '显示全部';

  @override
  String get ok => '确定';

  @override
  String get select => '选择';

  @override
  String get no => '否';

  @override
  String get yes => '是';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get close => '关闭';

  @override
  String get delete => '删除';

  @override
  String get reset => '重置';

  @override
  String get apply => '应用';

  @override
  String get settings => '设置';

  @override
  String get startTime => '开始时间';

  @override
  String get endTime => '结束时间';

  @override
  String get interval => '间隔';

  @override
  String get minutes => '分钟';

  @override
  String get tags => '标签';

  @override
  String get confirm => '确认';

  @override
  String get confirmDelete => '确认删除？';

  @override
  String get week => '周';

  @override
  String get month => '月';

  @override
  String get date => '日期';

  @override
  String get edit => '编辑';

  @override
  String get retry => '重试';

  @override
  String get rename => '重命名';

  @override
  String get copy => '复制';

  @override
  String get done => '完成';

  @override
  String get create => '新建';

  @override
  String get adjustCardSize => '调整卡片大小';

  @override
  String get width => '宽度';

  @override
  String get height => '高度';

  @override
  String get home => '首页';

  @override
  String get noPluginsAvailable => '没有可用的插件';

  @override
  String get backupInProgress => '正在备份';

  @override
  String completed(Object percentage) {
    return '已完成: $percentage%';
  }

  @override
  String get exportCancelled => '导出已取消';

  @override
  String get exportSuccess => '数据导出成功';

  @override
  String exportFailed(Object error) {
    return '导出失败: $error';
  }

  @override
  String get warning => '警告';

  @override
  String get importWarning => '导入操作将完全覆盖当前的应用数据。\n建议在导入前备份现有数据。\n\n是否继续？';

  @override
  String get stillContinue => '继续';

  @override
  String get importCancelled => '已取消导入操作';

  @override
  String get selectBackupFile => '请选择备份文件';

  @override
  String get noFileSelected => '未选择文件';

  @override
  String get importInProgress => '正在导入';

  @override
  String get processingBackupFile => '正在处理备份文件...';

  @override
  String get importSuccess => '数据导入成功，请重启应用';

  @override
  String get restartRequired => '需要重启';

  @override
  String get exportingData => '正在导出数据';

  @override
  String get importingData => '正在导入数据';

  @override
  String get pleaseWait => '请等待';

  @override
  String get restartMessage => '数据已导入完成，需要重启应用才能生效。';

  @override
  String fileSelectionFailed(Object error) {
    return '文件选择失败: $error';
  }

  @override
  String get importFailed => '导入失败';

  @override
  String get importTimeout => '导入超时：文件可能过大或无法访问';

  @override
  String get filesystemError => '文件系统错误：无法读取或写入文件';

  @override
  String get invalidBackupFile => '无效的备份文件：文件可能已损坏';

  @override
  String dataExportedTo(Object path) {
    return '数据已导出到: $path';
  }

  @override
  String exportFailedWithError(Object error) {
    return '导出失败: $error';
  }

  @override
  String get noPluginDataFound => '没有找到可导入的插件数据';

  @override
  String importFailedWithError(Object error) {
    return '导入失败: $error';
  }

  @override
  String permissionRequired(Object permission) {
    return '需要$permission权限';
  }

  @override
  String permissionRequiredForApp(Object permission) {
    return '应用需要$permission权限来正常工作，是否授予权限？';
  }

  @override
  String get notNow => '暂不授予';

  @override
  String get grantPermission => '授予权限';

  @override
  String permissionRequiredInSettings(Object permission) {
    return '需要$permission权限才能继续。请在系统设置中授予权限。';
  }

  @override
  String get storagePermissionRequired => '需要存储权限才能继续。请在系统设置中授予权限。';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get moveSuccess => '移动成功';

  @override
  String moveFailed(Object error) {
    return '移动失败: $error';
  }

  @override
  String renameFailed(Object error) {
    return '重命名失败: $error';
  }

  @override
  String exportSuccessTo(Object path) {
    return '导出成功到: $path';
  }

  @override
  String get selectFolderToImport => '选择要导入的文件夹';

  @override
  String get selectPluginToExport => '选择要导出的插件';

  @override
  String get selectImage => '选择图片';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get testForegroundTask => '测试前台任务';

  @override
  String failedToLoadPlugins(Object error) {
    return '加载插件失败: $error';
  }

  @override
  String get setBackupSchedule => '设置备份计划';

  @override
  String day(Object day) {
    return '第$day天';
  }

  @override
  String get selectBackgroundColor => '选择背景颜色';

  @override
  String get nodeColor => '节点颜色';

  @override
  String selectPluginToImport(Object mode) {
    return '选择要导入的插件 ($mode)';
  }

  @override
  String dataSize(Object size) {
    return '数据大小: $size';
  }

  @override
  String get import => '导入';

  @override
  String get selectLocation => '选择位置';

  @override
  String get selectGroup => '选择分组';

  @override
  String videoLoadFailed(Object error) {
    return '视频加载失败: $error';
  }

  @override
  String get loadingVideo => '正在加载视频...';

  @override
  String get pleaseEnterTitle => '请输入标题';

  @override
  String get selectPluginsToImport => '选择插件导入';

  @override
  String get mergeMode => '合并模式';

  @override
  String get overwriteMode => '覆盖模式';

  @override
  String get titleRequired => '请输入标题';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutDescription => 'Memento是一款生产力应用，旨在帮助您组织和记住重要事项。';

  @override
  String get projectLinkTitle => '项目链接';

  @override
  String get projectLink => 'https://github.com/hunmer/memento';
}
