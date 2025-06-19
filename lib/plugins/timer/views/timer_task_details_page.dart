import 'package:Memento/plugins/timer/models/timer_item.dart';
import 'package:flutter/material.dart';
import '../models/timer_task.dart';
import '../../../../core/event/event_manager.dart';
import '../../../../core/event/event_args.dart';

class TimerTaskDetailsPage extends StatefulWidget {
  final TimerTask task;
  final VoidCallback onReset;
  final VoidCallback onResume;

  const TimerTaskDetailsPage({
    super.key,
    required this.task,
    required this.onReset,
    required this.onResume,
  });

  @override
  State<TimerTaskDetailsPage> createState() => _TimerTaskDetailsPageState();
}

class _TimerTaskDetailsPageState extends State<TimerTaskDetailsPage> {
  late TimerTask _currentTask;
  late String _subscriptionId;
  late String _progressSubscriptionId;
  late String _startSubscriptionId;
  late int _currentTimerIndex = 0;
  late bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _currentTimerIndex = _currentTask.getCurrentIndex();
    if (_currentTimerIndex == -1) _currentTimerIndex = 0;
    // 订阅任务变更事件
    _subscriptionId = EventManager.instance.subscribe(
      'timer_task_changed',
      onTimerTaskChanged,
    );
    // 订阅计时器进度更新事件
    _progressSubscriptionId = EventManager.instance.subscribe(
      'timer_item_progress',
      onTimerItemProgress,
    );
    // 订阅计时器开始事件
    _startSubscriptionId = EventManager.instance.subscribe(
      'timer_item_changed',
      onTimerItemChanged,
    );
  }

  onTimerItemProgress(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.contains(args.timer)) {
      setState(() {});
    }
  }

  void onTimerTaskChanged(EventArgs args) {
    if (args is TimerTaskEventArgs && args.task.id == _currentTask.id) {
      setState(() {
        _currentTask = args.task;
        _isRunning = _currentTask.isRunning;
      });
    }
  }

  void onTimerItemChanged(EventArgs args) {
    if (args is TimerItemEventArgs &&
        _currentTask.timerItems.contains(args.timer)) {
      setState(() {
        _currentTimerIndex = _currentTask.timerItems.indexOf(args.timer);
      });
    }
  }

  @override
  void dispose() {
    // 取消所有订阅
    EventManager.instance.unsubscribe('timer_task_changed', onTimerTaskChanged);
    EventManager.instance.unsubscribe(
      'timer_item_progress',
      onTimerItemProgress,
    );
    EventManager.instance.unsubscribe('timer_item_changed', onTimerItemChanged);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final currentTimer = _currentTask.timerItems[_currentTimerIndex];
    return Scaffold(
      appBar: AppBar(title: Text(_currentTask.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间显示
              Center(
                child: Text(
                  _currentTask.timerItems.isNotEmpty
                      ? '${_formatDuration(currentTimer.completedDuration)}'
                          '/${_formatDuration(currentTimer.duration)}'
                      : _formatDuration(currentTimer.completedDuration),
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
              const SizedBox(height: 24),

              // 控制按钮
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      onPressed: widget.onResume,
                      tooltip: '切换状态',
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: widget.onReset,
                      tooltip: '重置',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 步骤显示
              if (_currentTask.timerItems.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Stepper(
                    currentStep: _currentTimerIndex,
                    controlsBuilder: (
                      BuildContext context,
                      ControlsDetails details,
                    ) {
                      return Container(width: 0, height: 0);
                    },
                    type: StepperType.horizontal,
                    steps:
                        _currentTask.timerItems.map((timer) {
                          return Step(
                            title: Text(timer.name),
                            content: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width - 32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (timer.description != null &&
                                      timer.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '描述: ${timer.description}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            isActive:
                                _currentTimerIndex ==
                                _currentTask.timerItems.indexOf(timer),
                          );
                        }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
