import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:floating_ball_plugin/floating_ball_plugin.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  bool _autoHideInApp = false;
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
  bool get autoHideInApp => _autoHideInApp;
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
    _autoHideInApp = prefs.getBool('floating_ball_auto_hide_in_app') ?? false;

    final x = prefs.getInt('floating_ball_x');
    final y = prefs.getInt('floating_ball_y');
    if (x != null && y != null) {
      _lastPosition = FloatingBallPosition(x, y);
    }

    // 优先加载已压缩的图片
    final compressedImageBase64 = prefs.getString('floating_ball_image_compressed');
    if (compressedImageBase64 != null && compressedImageBase64.isNotEmpty) {
      _customImageBytes = Uint8List.fromList(base64Decode(compressedImageBase64));
    } else {
      // 如果没有压缩图片，加载原始图片并压缩
      final imageBase64 = prefs.getString('floating_ball_image');
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        var imageBytes = Uint8List.fromList(base64Decode(imageBase64));
        // 如果图片过大（超过 100KB），进行压缩
        if (imageBytes.length > 100 * 1024) {
          imageBytes = await _compressAndSaveFloatingBallImage(imageBytes);
        }
        _customImageBytes = imageBytes;
      }
    }
  }

  /// 重新加载位置数据（用于启动时确保使用最新位置）
  Future<void> _reloadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getInt('floating_ball_x');
    final y = prefs.getInt('floating_ball_y');
    if (x != null && y != null) {
      _lastPosition = FloatingBallPosition(x, y);
      print('重新加载悬浮球位置: x=$x, y=$y');
    } else {
      print('未找到保存的悬浮球位置，使用默认位置');
    }
  }

  /// 加载按钮数据
  Future<void> _loadButtonData() async {
    final prefs = await SharedPreferences.getInstance();
    final buttonDataJson = prefs.getString('floating_ball_buttons');
    if (buttonDataJson != null && buttonDataJson.isNotEmpty) {
      try {
        final List<dynamic> dataList = jsonDecode(buttonDataJson);
        final List<FloatingBallButtonData> loadedButtons = [];

        // 优先加载已压缩的按钮图片
        final compressedButtonImage = prefs.getString('floating_ball_button_image_compressed');

        for (final item in dataList) {
          final map = item as Map<String, dynamic>;
          String? imageBase64 = map['image'] as String?;

          // 优先使用已压缩的图片
          if (compressedButtonImage != null && compressedButtonImage.isNotEmpty) {
            imageBase64 = compressedButtonImage;
          } else if (imageBase64 != null && imageBase64.length > 50 * 1024) {
            // 如果图片过大（超过 50KB），进行压缩并保存
            imageBase64 = await _compressAndSaveButtonImage(imageBase64);
          }

          loadedButtons.add(FloatingBallButtonData(
            title: map['title'] as String? ?? '',
            icon: map['icon'] as String? ?? 'ic_menu_info_details',
            data: map['data'] as Map<String, dynamic>?,
            image: imageBase64,
          ));
        }

        _buttonData = loadedButtons;
      } catch (e) {
        print('加载按钮数据失败: $e');
        _buttonData = [];
      }
    }
  }

  /// 压缩按钮图片并保存到本地
  Future<String?> _compressAndSaveButtonImage(String base64Image) async {
    try {
      final imageBytes = base64Decode(base64Image);
      // 按钮更小，使用 120x120 像素
      const int maxSize = 120;

      final compressedBytes = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(imageBytes),
        minWidth: maxSize,
        minHeight: maxSize,
        quality: 80,
        format: CompressFormat.png,
      );

      final compressedBase64 = base64Encode(compressedBytes);
      print('按钮图片压缩: ${base64Image.length} -> ${compressedBase64.length} chars');

      // 保存压缩后的图片到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('floating_ball_button_image_compressed', compressedBase64);

      return compressedBase64;
    } catch (e) {
      print('按钮图片压缩失败: $e');
      return base64Image;
    }
  }

  /// 保存按钮数据
  Future<void> _saveButtonData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = _buttonData.map((button) => button.toMap()).toList();
    final buttonDataJson = jsonEncode(dataList);
    await prefs.setString('floating_ball_buttons', buttonDataJson);

    // 保存按钮压缩图片（如果有的话）
    final firstButtonWithImage = _buttonData.firstWhere(
      (button) => button.image != null && button.image!.isNotEmpty,
      orElse: () => FloatingBallButtonData(title: '', icon: '', data: null),
    );
    if (firstButtonWithImage.image != null && firstButtonWithImage.image!.isNotEmpty) {
      await prefs.setString('floating_ball_button_image_compressed', firstButtonWithImage.image!);
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('floating_ball_size', _ballSize);
    await prefs.setInt('floating_ball_snap_threshold', _snapThreshold);
    await prefs.setString('floating_ball_icon', _iconName);
    await prefs.setBool('floating_ball_auto_restore', _autoRestore);
    await prefs.setBool('floating_ball_auto_hide_in_app', _autoHideInApp);
    await prefs.setBool('floating_ball_enabled', _isRunning);

    if (_customImageBytes != null) {
      final imageBase64 = base64Encode(_customImageBytes!);
      await prefs.setString('floating_ball_image', imageBase64);
      // 同时保存压缩版本
      await prefs.setString('floating_ball_image_compressed', imageBase64);
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
    // 强制刷新权限状态
    _hasPermission = await Permission.systemAlertWindow.isGranted;

    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        return null;
      }
    }

    String? result;
    if (_isRunning) {
      result = await FloatingBallPlugin.stopFloatingBall();
    } else {
      // 启动前重新加载位置，确保使用最新的位置数据
      await _reloadPosition();

      print('切换悬浮球 - 加载到的位置: startX=${_lastPosition?.x}, startY=${_lastPosition?.y}');

      // 启动时不传递按钮图片，避免 Binder 事务过大
      final config = FloatingBallConfig(
        iconName: _iconName.isEmpty ? null : _iconName,
        size: _ballSize,
        startX: _lastPosition?.x,
        startY: _lastPosition?.y,
        snapThreshold: _snapThreshold,
        buttonData: _getButtonDataWithoutImages(),
      );

      result = await FloatingBallPlugin.startFloatingBall(config: config);

      // 启动后分批设置图片
      await Future.delayed(const Duration(milliseconds: 200));

      // 恢复主悬浮球图片
      if (_customImageBytes != null) {
        await FloatingBallPlugin.setFloatingBallImage(_customImageBytes!);
      }

      // 分批设置按钮图片
      await _setBatchButtonImages();

      _startListeningPosition();
      _startListeningButtonEvents();
    }

    // 先更新状态，再保存（确保保存的是最新状态）
    await _checkStatus();
    await _saveSettings();

    return result;
  }

  /// 启动悬浮球
  Future<String?> startFloatingBall() async {
    // 强制刷新权限状态
    _hasPermission = await Permission.systemAlertWindow.isGranted;

    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        return null;
      }
    }

    // 启动前重新加载位置，确保使用最新的位置数据
    await _reloadPosition();

    // 启动时不传递按钮图片，避免 Binder 事务过大
    final config = FloatingBallConfig(
      iconName: _iconName.isEmpty ? null : _iconName,
      size: _ballSize,
      startX: _lastPosition?.x,
      startY: _lastPosition?.y,
      snapThreshold: _snapThreshold,
      buttonData: _getButtonDataWithoutImages(),
    );

    final result = await FloatingBallPlugin.startFloatingBall(config: config);

    // 启动后分批设置图片
    await Future.delayed(const Duration(milliseconds: 200));

    // 恢复主悬浮球图片
    if (_customImageBytes != null) {
      await FloatingBallPlugin.setFloatingBallImage(_customImageBytes!);
    }

    // 分批设置按钮图片
    await _setBatchButtonImages();

    _startListeningPosition();
    _startListeningButtonEvents();

    // 先更新状态，再保存（确保保存的是最新状态）
    await _checkStatus();
    await _saveSettings();

    return result;
  }

  /// 停止悬浮球
  Future<String?> stopFloatingBall() async {
    final result = await FloatingBallPlugin.stopFloatingBall();
    // 先更新状态，再保存（确保保存的是最新状态）
    await _checkStatus();
    await _saveSettings();
    return result;
  }

  /// 获取不含图片的按钮数据（用于启动时减少数据传输量）
  List<FloatingBallButtonData> _getButtonDataWithoutImages() {
    return _buttonData.map((button) {
      return FloatingBallButtonData(
        title: button.title,
        icon: button.icon,
        data: button.data,
        image: null, // 不传递图片
      );
    }).toList();
  }

  /// 分批设置按钮图片（避免 Binder 事务过大）
  Future<void> _setBatchButtonImages() async {
    for (int i = 0; i < _buttonData.length; i++) {
      final button = _buttonData[i];
      if (button.image != null && button.image!.isNotEmpty) {
        await FloatingBallPlugin.setButtonImage(i, button.image!);
        // 每个按钮之间稍微延迟，避免连续大量传输
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
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

  /// 压缩悬浮球图片并保存到本地
  Future<Uint8List> _compressAndSaveFloatingBallImage(Uint8List imageBytes) async {
    try {
      // 悬浮球最大尺寸 (80dp * 3x = 240px)
      const int maxSize = 240;

      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxSize,
        minHeight: maxSize,
        quality: 85,
        format: CompressFormat.png,
      );

      print('悬浮球图片压缩: ${imageBytes.length} -> ${compressedBytes.length} bytes');

      // 保存压缩后的图片到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final compressedBase64 = base64Encode(compressedBytes);
      await prefs.setString('floating_ball_image_compressed', compressedBase64);

      return compressedBytes;
    } catch (e) {
      print('悬浮球图片压缩失败: $e，使用原图');
      return imageBytes;
    }
  }

  /// 设置自定义图片
  Future<String?> setCustomImage(Uint8List imageBytes) async {
    // 压缩图片并保存到本地
    final compressedBytes = await _compressAndSaveFloatingBallImage(imageBytes);
    _customImageBytes = compressedBytes;
    await _saveSettings();

    if (_isRunning) {
      final result = await FloatingBallPlugin.setFloatingBallImage(compressedBytes);
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

  /// 设置应用内自动隐藏
  void setAutoHideInApp(bool autoHideInApp) {
    _autoHideInApp = autoHideInApp;
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

    // 强制刷新权限状态，确保应用启动时获取准确的权限信息
    _hasPermission = await Permission.systemAlertWindow.isGranted;

    print('performAutoRestore: wasEnabled=$wasEnabled, hasPermission=$_hasPermission');

    if (wasEnabled && _hasPermission) {
      await Future.delayed(const Duration(milliseconds: 500));
      // 启动前重新加载位置，确保使用最新的位置数据
      await _reloadPosition();
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

  /// 更新位置并保存到本地
  void updatePosition(FloatingBallPosition position) {
    _lastPosition = position;

    // 保存位置到本地存储
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('floating_ball_x', position.x);
      prefs.setInt('floating_ball_y', position.y);
    });
  }

  /// 清除位置
  Future<void> clearPosition() async {
    _lastPosition = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('floating_ball_x');
    await prefs.remove('floating_ball_y');
  }

  /// 清除压缩图片数据
  Future<void> clearCompressedImages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('floating_ball_image_compressed');
    await prefs.remove('floating_ball_button_image_compressed');
  }

  /// 清除所有悬浮球数据
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('floating_ball_image');
    await prefs.remove('floating_ball_image_compressed');
    await prefs.remove('floating_ball_button_image_compressed');
    await prefs.remove('floating_ball_buttons');
    await prefs.remove('floating_ball_x');
    await prefs.remove('floating_ball_y');
    await prefs.remove('floating_ball_size');
    await prefs.remove('floating_ball_snap_threshold');
    await prefs.remove('floating_ball_icon');
    await prefs.remove('floating_ball_auto_restore');
    await prefs.remove('floating_ball_auto_hide_in_app');
    await prefs.remove('floating_ball_enabled');
  }

  /// 刷新状态
  Future<void> refreshStatus() async {
    await _checkStatus();
  }
}
