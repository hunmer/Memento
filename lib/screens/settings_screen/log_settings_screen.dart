
import 'package:flutter/material.dart';
import 'package:Memento/core/utils/logger_util.dart';
import '../settings_screen/controllers/settings_screen_controller.dart';

class LogSettingsScreen extends StatefulWidget {
  const LogSettingsScreen({super.key});

  @override
  State<LogSettingsScreen> createState() => _LogSettingsScreenState();
}

class _LogSettingsScreenState extends State<LogSettingsScreen> {
  late SettingsScreenController _controller;
  final LoggerUtil _logger = LoggerUtil();

  @override
  void initState() {
    super.initState();
    _controller = SettingsScreenController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日志设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('启用日志记录'),
            subtitle: const Text('记录应用运行日志'),
            trailing: Switch(
              value: _controller.enableLogging,
              onChanged: (value) => setState(() {
                _controller.enableLogging = value;
              }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('查看历史日志'),
            subtitle: const Text('查看应用运行日志记录'),
            onTap: () => _showLogHistory(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('清除所有日志'),
            subtitle: const Text('删除所有日志文件'),
            onTap: () => _clearAllLogs(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogHistory(BuildContext context) async {
    final logFiles = await _logger.getLogFiles();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史日志'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: logFiles.length,
            itemBuilder: (context, index) {
              final fileName = logFiles[index].split('/').last;
              return ListTile(
                title: Text(fileName),
                onTap: () async {
                  final content = await _logger.readLogFile(logFiles[index]);
                  if (!context.mounted) return;
                  
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(fileName),
                      content: SingleChildScrollView(
                        child: Text(content),
                      ),
                      actions: [
                        TextButton(
                          child: const Text('关闭'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('清除日志'),
            onPressed: () async {
              await _logger.clearLogs();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已清除')),
              );
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllLogs(BuildContext context) async {
    await _logger.clearLogs();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('所有日志已清除')),
    );
  }
}
