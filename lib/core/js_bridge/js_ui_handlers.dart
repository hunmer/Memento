import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'platform/mobile_js_engine.dart';
import 'package:Memento/widgets/picker/location_picker.dart';

/// JavaScript Bridge UI 处理器
/// 提供默认的 Toast/Alert/Dialog 实现
class JSUIHandlers {
  final BuildContext context;

  JSUIHandlers(this.context);

  /// 注册所有 UI 处理器到 JSEngine
  void register(MobileJSEngine engine) {
    engine.setToastHandler(_handleToast);
    engine.setAlertHandler(_handleAlert);
    engine.setDialogHandler(_handleDialog);
    engine.setLocationHandler(_handleLocation);
  }

  /// Toast 处理器
  void _handleToast(String message, String duration, String gravity) {
    final durationMs = _parseDuration(duration);
    final alignment = _parseGravity(gravity);

    // 使用 Overlay 实现真正的 Toast（支持任意位置）
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        // 根据位置选择不同的布局策略
        if (alignment == Alignment.center) {
          // 中间：使用 Positioned.fill + Center
          return Positioned.fill(
            child: Center(
              child: _buildToastContent(message),
            ),
          );
        } else if (alignment == Alignment.topCenter) {
          // 顶部：距离顶部 50px
          return Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildToastContent(message),
              ),
            ),
          );
        } else {
          // 底部：距离底部 50px
          return Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildToastContent(message),
              ),
            ),
          );
        }
      },
    );

    overlay.insert(overlayEntry);

    // 自动移除
    Future.delayed(Duration(milliseconds: durationMs), () {
      overlayEntry.remove();
    });
  }

  /// 构建 Toast 内容
  Widget _buildToastContent(String message) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Alert 处理器
  Future<bool> _handleAlert(
    String message, {
    String? title,
    String? confirmText,
    String? cancelText,
    bool showCancel = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: Text(message),
          actions: [
            if (showCancel)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText ?? '取消'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText ?? '确定'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Dialog 处理器
  Future<dynamic> _handleDialog(
    String? title,
    String? content,
    List<Map<String, dynamic>> actions,
  ) async {
    if (actions.isEmpty) {
      return null;
    }

    final result = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null ? Text(title) : null,
          content: content != null ? Text(content) : null,
          actions: actions.map((action) {
            final text = action['text'] as String? ?? '';
            // value 可以是任意类型（布尔值、数字、字符串等）
            final value = action['value'];
            final isDestructive = action['isDestructive'] as bool? ?? false;

            return TextButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: Text(
                text,
                style: TextStyle(
                  color: isDestructive ? Colors.red : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    return result;
  }

  // ==================== 辅助方法 ====================

  /// 解析 duration 参数
  int _parseDuration(String duration) {
    switch (duration.toLowerCase()) {
      case 'short':
        return 2000;
      case 'long':
        return 4000;
      default:
        // 尝试解析为数字
        return int.tryParse(duration) ?? 2000;
    }
  }

  /// 解析 gravity 参数
  Alignment _parseGravity(String gravity) {
    switch (gravity.toLowerCase()) {
      case 'top':
        return Alignment.topCenter;
      case 'center':
        return Alignment.center;
      case 'bottom':
      default:
        return Alignment.bottomCenter;
    }
  }

  /// Location 处理器
  Future<Map<String, dynamic>?> _handleLocation(String mode) async {
    // 判断是否为移动端
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (mode == 'auto') {
      // 自动模式：获取当前位置并返回第一个搜索结果
      try {
        // 获取当前位置
        final location = Location();

        // 检查服务是否可用
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            return {'error': 'Location services are disabled'};
          }
        }

        // 检查权限状态
        PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            return {'error': 'Location permissions are denied'};
          }
        }

        // 获取当前位置
        final locationData = await location.getLocation();
        final latitude = locationData.latitude ?? 0;
        final longitude = locationData.longitude ?? 0;

        // 使用高德地图 API 进行逆地理编码
        final response = await http.get(
          Uri.parse(
            'http://restapi.amap.com/v3/geocode/regeo?key=dad6a772bf826842c3049e9c7198115c&location=$longitude,$latitude&poitype=&radius=1000&extensions=all&batch=false&roadlevel=0',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == '1' && data['regeocode'] != null) {
            final regeocode = data['regeocode'];
            final pois = regeocode['pois'] as List?;

            if (pois != null && pois.isNotEmpty) {
              // 返回第一个 POI
              final firstPoi = pois[0];
              return {
                'name': firstPoi['name'],
                'address': firstPoi['address'] ?? '',
                'location': firstPoi['location'],
                'latitude': latitude,
                'longitude': longitude,
              };
            } else {
              // 没有 POI，返回当前位置的地址
              return {
                'name': '当前位置',
                'address': regeocode['formatted_address'],
                'location': '$longitude,$latitude',
                'latitude': latitude,
                'longitude': longitude,
              };
            }
          }
        }

        // 如果 API 调用失败，返回基本位置信息
        return {
          'name': '当前位置',
          'address': '',
          'location': '$longitude,$latitude',
          'latitude': latitude,
          'longitude': longitude,
        };
      } catch (e) {
        print('Auto location error: $e');
        return {'error': e.toString()};
      }
    } else {
      // manual 模式：显示对话框让用户选择
      String? selectedLocation;

      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return LocationPicker(
            isMobile: isMobile,
            onLocationSelected: (location) {
              selectedLocation = location;
            },
          );
        },
      );

      if (selectedLocation != null) {
        // 返回选中的位置信息
        return {
          'name': selectedLocation,
          'address': selectedLocation,
        };
      }

      return null; // 用户取消
    }
  }
}
