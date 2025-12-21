import 'dart:async';
import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:uuid/uuid.dart';

class LiveActivitiesTestScreen extends StatefulWidget {
  const LiveActivitiesTestScreen({super.key});

  @override
  State<LiveActivitiesTestScreen> createState() =>
      _LiveActivitiesTestScreenState();
}

class _LiveActivitiesTestScreenState extends State<LiveActivitiesTestScreen> {
  final LiveActivities _liveActivitiesPlugin = LiveActivities();
  bool _isInitialized = false;
  bool _isSupported = false;
  String? _activityId;
  final Uuid _uuid = const Uuid();
  Timer? _updateTimer;
  double _progress = 0.0;
  String _status = '准备开始';

  @override
  void initState() {
    super.initState();
    _initPlugin();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPlugin() async {
    try {
      // 初始化插件 - 使用自定义的App Group ID和URL Scheme
      await _liveActivitiesPlugin.init(
        appGroupId: 'group.github.hunmer.memento', // 需要在Xcode中配置
        urlScheme: 'memento', // 使用应用中已定义的scheme
        requireNotificationPermission: true,
      );

      // 检查设备是否支持Live Activities
      final isSupported = await _liveActivitiesPlugin.areActivitiesEnabled();

      setState(() {
        _isInitialized = true;
        _isSupported = isSupported;
      });

      // 监听URL Scheme事件
      _liveActivitiesPlugin.urlSchemeStream().listen((schemeData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('收到URL Scheme: ${schemeData.url}'),
            duration: const Duration(seconds: 3),
          ),
        );
      });

      // 监听活动更新
      _liveActivitiesPlugin.activityUpdateStream.listen((event) {
        event.map(
          active: (activity) {
            print('活动激活: ${activity.activityId}');
            print('推送令牌: ${activity.activityToken}');
          },
          ended: (activity) {
            print('活动结束: ${activity.activityId}');
            setState(() {
              _activityId = null;
              _progress = 0.0;
              _status = '活动已结束';
            });
          },
          stale: (activity) {
            print('活动过期: ${activity.activityId}');
            setState(() {
              _activityId = null;
              _progress = 0.0;
              _status = '活动已过期';
            });
          },
          unknown: (activity) {
            print('未知活动状态: ${activity.activityId}');
          },
        );
      });
    } catch (e) {
      print('初始化失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('初始化失败: $e')));
      }
    }
  }

  Future<void> _createActivity() async {
    if (!_isSupported) {
      _showMessage('设备不支持Live Activities');
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final activityId = _uuid.v4();

      // 准备活动数据
      final Map<String, dynamic> activityModel = {
        'title': 'Memento 任务',
        'subtitle': '正在处理中...',
        'progress': _progress,
        'status': _status,
        'timestamp': timestamp,
        'iconUrl': 'https://via.placeholder.com/64x64.png?text=M',
      };

      final id = await _liveActivitiesPlugin.createActivity(
        activityId,
        activityModel,
        staleIn: const Duration(minutes: 10),
      );

      setState(() {
        _activityId = id;
      });

      _showMessage('活动创建成功: $id');

      // 开始定期更新
      _startUpdateTimer();
    } catch (e) {
      _showMessage('创建活动失败: $e');
    }
  }

  Future<void> _updateActivity() async {
    if (_activityId == null) {
      _showMessage('请先创建活动');
      return;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final Map<String, dynamic> activityModel = {
        'title': 'Memento 任务',
        'subtitle': '进度更新',
        'progress': _progress,
        'status': _status,
        'timestamp': timestamp,
      };

      await _liveActivitiesPlugin.updateActivity(_activityId!, activityModel);

      _showMessage('活动更新成功');
    } catch (e) {
      _showMessage('更新活动失败: $e');
    }
  }

  Future<void> _endActivity() async {
    if (_activityId == null) {
      _showMessage('请先创建活动');
      return;
    }

    try {
      await _liveActivitiesPlugin.endActivity(_activityId!);

      setState(() {
        _activityId = null;
        _progress = 0.0;
        _status = '活动已结束';
      });

      _updateTimer?.cancel();

      _showMessage('活动已结束');
    } catch (e) {
      _showMessage('结束活动失败: $e');
    }
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _progress += 0.1;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _status = '任务完成';
          timer.cancel();
        } else {
          _status = '进度: ${(_progress * 100).toInt()}%';
        }
      });

      if (_activityId != null) {
        _updateActivity();
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Activities 测试')),
      body:
          !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 支持状态
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _isSupported ? Icons.check_circle : Icons.error,
                        color: _isSupported ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        _isSupported
                            ? '支持 Live Activities'
                            : '不支持 Live Activities',
                      ),
                      subtitle: Text(
                        _isSupported
                            ? '设备支持 iOS 16.1+ 或 Android API 24+'
                            : '设备版本过低或功能未启用',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 活动控制
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '活动控制',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_circle),
                                  label: const Text('创建活动'),
                                  onPressed: _createActivity,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.stop_circle),
                                  label: const Text('结束活动'),
                                  onPressed: _endActivity,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 活动状态
                  if (_activityId != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '活动状态',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('活动ID: $_activityId'),
                            const SizedBox(height: 8),
                            Text('进度: ${(_progress * 100).toInt()}%'),
                            const SizedBox(height: 8),
                            Text('状态: $_status'),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(value: _progress),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.update),
                              label: const Text('手动更新'),
                              onPressed: _updateActivity,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // 说明
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '使用说明',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '1. iOS 需要配置:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('   - Widget Extension'),
                          const Text('   - App Group ID'),
                          const Text('   - Push Notifications'),
                          const Text('   - NSSupportsLiveActivities'),
                          const SizedBox(height: 8),
                          const Text(
                            '2. Android 需要配置:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('   - CustomLiveActivityManager'),
                          const Text('   - live_activity.xml 布局'),
                          const Text('   - Foreground Service 权限'),
                          const SizedBox(height: 8),
                          const Text(
                            '3. 使用方法:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text('   - 点击"创建活动"开始测试'),
                          const Text('   - 活动会自动更新进度'),
                          const Text('   - 可在锁屏或动态岛查看'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
