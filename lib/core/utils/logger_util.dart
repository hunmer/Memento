import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerUtil {
  static final LoggerUtil _instance = LoggerUtil._internal();
  late Directory _logDirectory;
  late File _logFile;
  late StreamController<String> _logStreamController;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  factory LoggerUtil() => _instance;

  LoggerUtil._internal() {
    _logStreamController = StreamController.broadcast();
    _init().catchError((e) {
      print('Logger initialization failed: $e');
    });
  }

  Future<void> _init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _logDirectory = Directory(p.join(appDocDir.path, 'app_data', 'logs'));
    if (!await _logDirectory.exists()) {
      await _logDirectory.create(recursive: true);
    }

    final today = DateTime.now();
    final logFileName = 'log_${today.year}-${today.month}-${today.day}.txt';
    _logFile = File('${_logDirectory.path}/$logFileName');
    if (!await _logFile.exists()) {
      await _logFile.create();
    }
  }

  Stream<String> get logStream => _logStreamController.stream;

  Future<void> log(String message, {String level = 'INFO'}) async {
    final timestamp = _dateFormat.format(DateTime.now());
    final logMessage = '[$timestamp] [$level] $message\n';

    try {
      // 确保日志文件已初始化
      if (!_logFile.existsSync()) {
        await _init();
      }
      await _logFile.writeAsString(logMessage, mode: FileMode.append);
      _logStreamController.add(logMessage);
    } catch (e) {
      print('Failed to write log: $e');
      // 尝试重新初始化并再次写入
      try {
        await _init();
        await _logFile.writeAsString(logMessage, mode: FileMode.append);
      } catch (e) {
        print('Retry failed: $e');
      }
    }
  }

  Future<List<String>> getLogFiles() async {
    if (!await _logDirectory.exists()) return [];

    final files =
        await _logDirectory
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.txt'))
            .map((entity) => entity.path)
            .toList();

    files.sort((a, b) => b.compareTo(a)); // 按文件名倒序排序
    return files;
  }

  Future<String> readLogFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'Log file not found';
    } catch (e) {
      return 'Error reading log file: $e';
    }
  }

  Future<void> clearLogs() async {
    try {
      if (await _logDirectory.exists()) {
        // 关闭日志流控制器
        _logStreamController.close();

        // 获取所有日志文件
        final files =
            await _logDirectory
                .list()
                .where((entity) => entity is File)
                .map((entity) => File(entity.path))
                .toList();

        // 通过打开写入流并立即关闭来释放文件句柄
        for (final file in files) {
          try {
            final sink = file.openWrite(mode: FileMode.append);
            await sink.close();
          } catch (_) {}
        }

        // 等待一段时间确保文件释放
        await Future.delayed(const Duration(milliseconds: 100));

        // 尝试删除目录
        await _logDirectory.delete(recursive: true);

        // 重新初始化日志系统
        _logStreamController = StreamController.broadcast();
        await _init();
      }
    } catch (e) {
      print('Failed to clear logs: $e');
      rethrow;
    }
  }
}
