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
}
