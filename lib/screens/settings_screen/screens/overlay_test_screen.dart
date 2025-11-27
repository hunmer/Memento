import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayTestScreen extends StatefulWidget {
  const OverlayTestScreen({Key? key}) : super(key: key);

  @override
  State<OverlayTestScreen> createState() => _OverlayTestScreenState();
}

class _OverlayTestScreenState extends State<OverlayTestScreen> {
  static const String _kPortNameOverlay = 'OVERLAY';
  static const String _kPortNameHome = 'UI';
  final _receivePort = ReceivePort();
  SendPort? homePort;
  String? latestMessageFromOverlay;
  bool isOverlayActive = false;

  @override
  void initState() {
    super.initState();
    _initCommunication();
  }

  void _initCommunication() {
    if (homePort != null) return;
    final res = IsolateNameServer.registerPortWithName(
      _receivePort.sendPort,
      _kPortNameHome,
    );
    log("$res: OVERLAY");
    _receivePort.listen((message) {
      log("message from OVERLAY: $message");
      setState(() {
        latestMessageFromOverlay = 'Latest Message From Overlay: $message';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('悬浮窗测试'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  final status = await FlutterOverlayWindow.isPermissionGranted();
                  log("Is Permission Granted: $status");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("悬浮窗权限状态: $status")),
                  );
                },
                child: const Text("检查悬浮窗权限"),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () async {
                  final bool? res = await FlutterOverlayWindow.requestPermission();
                  log("status: $res");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("请求权限结果: $res")),
                  );
                },
                child: const Text("请求悬浮窗权限"),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () async {
                  if (await FlutterOverlayWindow.isActive()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("悬浮窗已经在运行")),
                    );
                    return;
                  }
                  await FlutterOverlayWindow.showOverlay(
                    enableDrag: true,
                    overlayTitle: "Memento悬浮窗",
                    overlayContent: '悬浮窗已启用',
                    flag: OverlayFlag.defaultFlag,
                    visibility: NotificationVisibility.visibilityPublic,
                    positionGravity: PositionGravity.auto,
                    height: (MediaQuery.of(context).size.height * 0.6).toInt(),
                    width: WindowSize.matchParent,
                    startPosition: const OverlayPosition(0, -259),
                  );
                  setState(() {
                    isOverlayActive = true;
                  });
                },
                child: const Text("显示悬浮窗"),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () async {
                  final status = await FlutterOverlayWindow.isActive();
                  log("Is Active?: $status");
                  setState(() {
                    isOverlayActive = status;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("悬浮窗活跃状态: $status")),
                  );
                },
                child: const Text("检查悬浮窗状态"),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () async {
                  await FlutterOverlayWindow.resizeOverlay(
                    WindowSize.matchParent,
                    (MediaQuery.of(context).size.height * 0.5).toInt(),
                    false,
                  );
                },
                child: const Text("调整悬浮窗大小"),
              ),
              const SizedBox(height: 10.0),
              TextButton(
                onPressed: () {
                  log('Try to close');
                  FlutterOverlayWindow.closeOverlay()
                      .then((value) {
                        log('STOPPED: value: $value');
                        setState(() {
                          isOverlayActive = false;
                        });
                      });
                },
                child: const Text("关闭悬浮窗"),
              ),
              const SizedBox(height: 20.0),
              TextButton(
                onPressed: () {
                  homePort ??=
                      IsolateNameServer.lookupPortByName(_kPortNameOverlay);
                  homePort?.send('Send to overlay: ${DateTime.now()}');
                },
                child: const Text("发送消息到悬浮窗"),
              ),
              const SizedBox(height: 20.0),
              TextButton(
                onPressed: () {
                  FlutterOverlayWindow.getOverlayPosition().then((value) {
                    log('Overlay Position: $value');
                    setState(() {
                      latestMessageFromOverlay = 'Overlay Position: $value';
                    });
                  });
                },
                child: const Text("获取悬浮窗位置"),
              ),
              const SizedBox(height: 20.0),
              TextButton(
                onPressed: () {
                  FlutterOverlayWindow.moveOverlay(
                    const OverlayPosition(0, 0),
                  );
                },
                child: const Text("移动悬浮窗到(0, 0)"),
              ),
              const SizedBox(height: 20),
              const Text(
                "消息日志:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latestMessageFromOverlay ?? '暂无消息',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isOverlayActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOverlayActive ? Icons.check_circle : Icons.cancel,
                      color: isOverlayActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '悬浮窗状态: ${isOverlayActive ? "运行中" : "已关闭"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOverlayActive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}