import 'dart:async';
import 'package:Memento/l10n/app_localizations.dart';
import 'package:Memento/plugins/tracker/l10n/tracker_localizations.dart';
import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/record.dart';
import '../controllers/tracker_controller.dart';

class TimerDialog extends StatefulWidget {
  final Goal goal;
  final TrackerController controller;

  const TimerDialog({super.key, required this.goal, required this.controller});

  @override
  State<TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _valueController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _seconds = 0;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRecord() async {
    if (_seconds > 0) {
      // 获取用户输入的记录值
      final recordValue = double.tryParse(_valueController.text) ?? 1;

      final record = Record(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: widget.goal.id,
        value: recordValue,
        note: _noteController.text,
        recordedAt: DateTime.now(),
        durationSeconds: _seconds,
      );

      final newGoal = widget.goal.copyWith(
        currentValue: widget.goal.currentValue + recordValue,
      );

      await widget.controller.updateGoal(widget.goal.id, newGoal);
      await widget.controller.addRecord(record, newGoal);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${TrackerLocalizations.of(context)!.timer} - ${widget.goal.name}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(_seconds),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleTimer,
              ),
              IconButton(icon: const Icon(Icons.stop), onPressed: _resetTimer),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: '记录值 (${widget.goal.unitType})',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注 (可选)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _seconds > 0 ? _saveRecord : null,
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
