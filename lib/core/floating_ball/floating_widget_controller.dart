import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

/// 悬浮球控制器
/// 统一管理悬浮球的启动、停止、配置、状态等操作
class FloatingWidgetController {
  static final FloatingWidgetController _instance =
      FloatingWidgetController._internal();

  factory FloatingWidgetController() => _instance;

  FloatingWidgetController._internal();

  // 状态
  bool _isRunning = false;
  bool _hasPermission = false;
  FloatingBallPosition? _lastPosition;

  // 监听器
  StreamSubscription<FloatingBallPosition>? _positionSubscription;
  StreamSubscription<FloatingBallButtonEvent>? _buttonSubscription;

  // 位置变化监听器
  final StreamController<FloatingBallPosition> _positionController =
      StreamController<FloatingBallPosition>.broadcast();
  Stream<FloatingBallPosition> get positionChanges =>
      _positionController.stream;

  // 按钮事件监听器
  final StreamController<FloatingBallButtonEvent> _buttonController =
      StreamController<FloatingBallButtonEvent>.broadcast();
  Stream<FloatingBallButtonEvent> get buttonEvents => _buttonController.stream;

  // 运行状态监听器
  final StreamController<bool> _runningController =
      StreamController<bool>.broadcast();
  Stream<bool> get runningChanges => _runningController.stream;

  // 权限状态监听器
  final StreamController<bool> _permissionController =
      StreamController<bool>.broadcast();
  Stream<bool> get permissionChanges => _permissionController.stream;

  // 配置参数
  double _ballSize = 80.0;
  int _snapThreshold = 50;
  String _iconName = '';
  bool _autoRestore = true;
  Uint8List? _customImageBytes;
  List<FloatingBallButtonData> _buttonData = [];

  // Getters
  bool get isRunning => _isRunning;
  bool get hasPermission => _hasPermission;
  FloatingBallPosition? get lastPosition => _lastPosition;
  double get ballSize => _ballSize;
  int get snapThreshold => _snapThreshold;
  String get iconName => _iconName;
  bool get autoRestore => _autoRestore;
  Uint8List? get customImageBytes => _customImageBytes;
  List<FloatingBallButtonData> get buttonData => List.unmodifiable(_buttonData);

  /// 初始化控制器
  /// [defaultButtons] 默认按钮数据，如果不提供则使用内置按钮
  Future<void> initialize({
    List<FloatingBallButtonData>? defaultButtons,
  }) async {
    await _loadSettings();

    // 从本地存储加载按钮数据
    await _loadButtonData();

    // 如果本地没有数据，使用默认按钮
    if (_buttonData.isEmpty) {
      if (defaultButtons != null && defaultButtons.isNotEmpty) {
        _buttonData = defaultButtons;
      } else {
        _buttonData = _getDefaultButtons();
      }
      // 保存默认按钮数据
      await _saveButtonData();
    }

    await _checkStatus();
    // 确保按钮事件监听器始终被设置
    _startListeningButtonEvents();
  }

  /// 获取默认按钮
  List<FloatingBallButtonData> _getDefaultButtons() {
    return [
      FloatingBallButtonData(
        title: '聊天',
        icon: 'ic_menu_send',
        data: {'action': 'openPlugin', 'args': {'plugin': 'chat'}},
      ),
      FloatingBallButtonData(
        title: '日记',
        icon: 'ic_menu_edit',
        data: {'action': 'openPlugin', 'args': {'plugin': 'diary'}},
      ),
      FloatingBallButtonData(
        title: '设置',
        icon: 'ic_menu_preferences',
        data: {'action': 'openSettings'},
      ),
    ];
  }

  /// 清理资源
  void dispose() {
    _positionSubscription?.cancel();
    _buttonSubscription?.cancel();
    _positionController.close();
    _buttonController.close();
    _runningController.close();
    _permissionController.close();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _ballSize = prefs.getDouble('floating_ball_size') ?? 80.0;
    _snapThreshold = prefs.getInt('floating_ball_snap_threshold') ?? 50;
    _iconName = prefs.getString('floating_ball_icon') ?? '';
    _autoRestore = prefs.getBool('floating_ball_auto_restore') ?? true;

    final x = prefs.getInt('floating_ball_x');
    final y = prefs.getInt('floating_ball_y');
    if (x != null && y != null) {
      _lastPosition = FloatingBallPosition(x, y);
    }

    final imageBase64 = prefs.getString('floating_ball_image');
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      _customImageBytes = Uint8List.fromList(base64Decode(imageBase64));
    }
  }

  /// 加载按钮数据
  Future<void> _loadButtonData() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonDataJson = prefs.getString('floating_ball_buttons');
    if (buttonDataJson != null && buttonDataJson.isNotEmpty) {
      try {
        final List<dynamic> dataList = jsonDecode(buttonDataJson);
        _buttonData = dataList.map((item) {
          final map = item as Map<String, dynamic>;
          return FloatingBallButtonData(
            title: map['title'] as String? ?? '',
            icon: map['icon'] as String? ?? 'ic_menu_info_details',
            data: map['data'] as Map<String, dynamic>?,
            image: map['image'] as String?,
          );
        }).toList();
      } catch (e) {
        print('加载按钮数据失败: $e');
        _buttonData = [];
      }
    }
  }

  /// 保存按钮数据
  Future<void> _saveButtonData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = _buttonData.map((button) => button.toMap()).toList();
    final buttonDataJson = jsonEncode(dataList);
    await prefs.setString('floating_ball_buttons', buttonDataJson);
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('floating_ball_size', _ballSize);
    await prefs.setInt('floating_ball_snap_threshold', _snapThreshold);
    await prefs.setString('floating_ball_icon', _iconName);
    await prefs.setBool('floating_ball_auto_restore', _autoRestore);
    await prefs.setBool('floating_ball_enabled', _isRunning);

    if (_customImageBytes != null) {
      final imageBase64 = base64Encode(_customImageBytes!);
      await prefs.setString('floating_ball_image', imageBase64);
    }

    if (_lastPosition != null) {
      await prefs.setInt('floating_ball_x', _lastPosition!.x);
      await prefs.setInt('floating_ball_y', _lastPosition!.y);
    }
  }

  /// 检查状态
  Future<void> _checkStatus() async {
    final hasPermission = await Permission.systemAlertWindow.isGranted;
    final isRunning = await FloatingBallPlugin.isRunning();

    final prevPermission = _hasPermission;
    final prevRunning = _isRunning;

    _hasPermission = hasPermission;
    _isRunning = isRunning;

    // 通知状态变化
    if (prevPermission != hasPermission) {
      _permissionController.add(hasPermission);
    }

    if (prevRunning != isRunning) {
      _runningController.add(isRunning);
    }

    if (isRunning) {
      _startListeningPosition();
    }
  }

  /// 开始监听位置变化
  void _startListeningPosition() {
    _positionSubscription?.cancel();
    _positionSubscription = FloatingBallPlugin.listenPositionChanges().listen(
      (position) {
        try {
          _lastPosition = position;
          _positionController.add(position);

          // 自动保存位置
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt('floating_ball_x', position.x);
            prefs.setInt('floating_ball_y', position.y);
          });
        } catch (e) {
          // 忽略错误，避免崩溃
        }
      },
      onError: (error) {
        // 忽略错误，避免崩溃
      },
    );
  }

  /// 开始监听按钮事件
  void _startListeningButtonEvents() {
    _buttonSubscription?.cancel();
    _buttonSubscription = FloatingBallPlugin.listenButtonEvents().listen(
      (event) {
        try {
          print(
            "FloatingWidgetController: 收到按钮事件 - title: ${event.title}, data: ${event.data}",
          );
          _buttonController.add(event);
        } catch (e) {
          // 忽略错误，避免崩溃
        }
      },
      onError: (error) {
        // 忽略错误，避免崩溃
      },
    );
  }

  /// 切换悬浮球状态
  Future<String?> toggleFloatingBall() async {
    if (!_hasPermission) {
      await requestPermission();
      return null;
    }

    String? result;
    if (_isRunning) {
      result = await FloatingBallPlugin.stopFloatingBall();
    } else {
      final config = FloatingBallConfig(
        iconName: _iconName.isEmpty ? null : _iconName,
        size: _ballSize,
        startX: _lastPosition?.x,
        startY: _lastPosition?.y,
        snapThreshold: _snapThreshold,
        buttonData: _buttonData,
      );

      result = await FloatingBallPlugin.startFloatingBall(config: config);

      // 启动后恢复自定义图片
      if (_customImageBytes != null) {
        await Future.delayed(const Duration(milliseconds: 200));
        await FloatingBallPlugin.setFloatingBallImage(_customImageBytes!);
      }

      _startListeningPosition();
      _startListeningButtonEvents();
    }

    await _saveSettings();
    await _checkStatus();

    return result;
  }

  /// 启动悬浮球
  Future<String?> startFloatingBall() async {
    if (!_hasPermission) {
      await requestPermission();
      return null;
    }

    final config = FloatingBallConfig(
      iconName: _iconName.isEmpty ? null : _iconName,
      size: _ballSize,
      startX: _lastPosition?.x,
      startY: _lastPosition?.y,
      snapThreshold: _snapThreshold,
      buttonData: _buttonData,
    );

    final result = await FloatingBallPlugin.startFloatingBall(config: config);

    if (_customImageBytes != null) {
      await Future.delayed(const Duration(milliseconds: 200));
      await FloatingBallPlugin.setFloatingBallImage(_customImageBytes!);
    }

    _startListeningPosition();
    _startListeningButtonEvents();

    await _saveSettings();
    await _checkStatus();

    return result;
  }

  /// 停止悬浮球
  Future<String?> stopFloatingBall() async {
    final result = await FloatingBallPlugin.stopFloatingBall();
    await _saveSettings();
    await _checkStatus();
    return result;
  }

  /// 请求悬浮窗权限
  Future<bool> requestPermission() async {
    final status = await Permission.systemAlertWindow.request();
    final granted = status.isGranted;
    _hasPermission = granted;
    _permissionController.add(granted);
    return granted;
  }

  /// 更新悬浮球配置
  Future<String?> updateConfig() async {
    final config = FloatingBallConfig(
      iconName: _iconName.isEmpty ? null : _iconName,
      size: _ballSize,
      snapThreshold: _snapThreshold,
      buttonData: _buttonData,
    );

    final result = await FloatingBallPlugin.updateConfig(config);
    await _saveSettings();
    return result;
  }

  /// 设置自定义图片
  Future<String?> setCustomImage(Uint8List imageBytes) async {
    _customImageBytes = imageBytes;
    await _saveSettings();

    if (_isRunning) {
      final result = await FloatingBallPlugin.setFloatingBallImage(imageBytes);
      return result;
    }
    return null;
  }

  /// 选择并设置图片
  Future<String?> pickAndSetImage(ImagePicker picker) async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        return await setCustomImage(bytes);
      }
      return null;
    } catch (e) {
      return '选择图片失败: $e';
    }
  }

  /// 设置球大小
  void setBallSize(double size) {
    _ballSize = size;
  }

  /// 设置吸附阈值
  void setSnapThreshold(int threshold) {
    _snapThreshold = threshold;
  }

  /// 设置图标名称
  void setIconName(String iconName) {
    _iconName = iconName;
  }

  /// 设置自动恢复
  void setAutoRestore(bool autoRestore) {
    _autoRestore = autoRestore;
  }

  /// 添加按钮
  void addButton(FloatingBallButtonData button) {
    _buttonData.add(button);
  }

  /// 移除按钮
  void removeButtonAt(int index) {
    if (index >= 0 && index < _buttonData.length) {
      _buttonData.removeAt(index);
    }
  }

  /// 更新按钮数据
  Future<void> updateButtonData(List<FloatingBallButtonData> buttons) async {
    _buttonData = buttons;
    await _saveButtonData();
  }

  /// 自动恢复悬浮球状态（用于应用启动时）
  Future<void> performAutoRestore() async {
    // 仅在 Android 平台支持
    if (!UniversalPlatform.isAndroid) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final wasEnabled = prefs.getBool('floating_ball_enabled') ?? false;

    if (wasEnabled && _hasPermission) {
      await Future.delayed(const Duration(milliseconds: 500));
      await startFloatingBall();
    }
  }

  /// 检查是否应该自动恢复
  Future<bool> shouldAutoRestore() async {
    if (!_autoRestore) return false;

    final prefs = await SharedPreferences.getInstance();
    final wasEnabled = prefs.getBool('floating_ball_enabled') ?? false;

    return wasEnabled && _hasPermission;
  }

  /// 更新位置
  void updatePosition(FloatingBallPosition position) {
    _lastPosition = position;
  }

  /// 清除位置
  Future<void> clearPosition() async {
    _lastPosition = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('floating_ball_x');
    await prefs.remove('floating_ball_y');
  }

  /// 刷新状态
  Future<void> refreshStatus() async {
    await _checkStatus();
  }
}
