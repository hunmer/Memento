import 'package:flutter/material.dart';
import 'package:Memento/core/utils/logger_util.dart';
import '../settings_screen/controllers/settings_screen_controller.dart';
import 'l10n/log_settings_localizations.dart';

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
      appBar: AppBar(title: Text(LogSettingsLocalizations.of(context).title)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(LogSettingsLocalizations.of(context).enableLogging),
            subtitle: Text(
              LogSettingsLocalizations.of(context).enableLoggingSubtitle,
            ),
            trailing: Switch(
              value: _controller.enableLogging,
              onChanged:
                  (value) => setState(() {
                    _controller.enableLogging = value;
                  }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(LogSettingsLocalizations.of(context).viewLogHistory),
            subtitle: Text(
              LogSettingsLocalizations.of(context).viewLogHistorySubtitle,
            ),
            onTap: () => _showLogHistory(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(LogSettingsLocalizations.of(context).clearAllLogs),
            subtitle: Text(
              LogSettingsLocalizations.of(context).clearAllLogsSubtitle,
            ),
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
      builder:
          (context) => AlertDialog(
            title: Text(LogSettingsLocalizations.of(context).logHistoryTitle),
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
                      final content = await _logger.readLogFile(
                        logFiles[index],
                      );
                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(fileName),
                              content: SingleChildScrollView(
                                child: Text(content),
                              ),
                              actions: [
                                TextButton(
                                  child: Text(
                                    LogSettingsLocalizations.of(context).close,
                                  ),
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
                child: Text(LogSettingsLocalizations.of(context).clearLogs),
                onPressed: () async {
                  await _logger.clearLogs();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LogSettingsLocalizations.of(context).logsCleared,
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(LogSettingsLocalizations.of(context).close),
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
      SnackBar(
        content: Text(LogSettingsLocalizations.of(context).allLogsCleared),
      ),
    );
  }
}
