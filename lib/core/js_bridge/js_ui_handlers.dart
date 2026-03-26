import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
// 条件导入：默认 Web 平台存根，有 IO 库时（移动/桌面）使用真实实现
import 'platform/mobile_js_engine_stub.dart'
    if (dart.library.io) 'platform/mobile_js_engine.dart';
import 'package:Memento/widgets/picker/location_picker.dart';

/// JavaScript Bridge UI 处理器
/// 提供 Alert/Dialog/Location 的实现（Toast 已在 MobileJSEngine 中直接处理）
class JSUIHandlers {
  final BuildContext context;

  JSUIHandlers(this.context);

  /// 注册 UI 处理器到 JSEngine
  /// 注意：Toast 已在 MobileJSEngine 中直接处理，这里只注册 Alert/Dialog/Location
  void register(MobileJSEngine engine) {
    engine.setAlertHandler(_handleAlert);
    engine.setDialogHandler(_handleDialog);
    engine.setLocationHandler(_handleLocation);
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

  /// Location 处理器
  Future<Map<String, dynamic>?> _handleLocation(String mode) async {
    // 判断是否为移动端
    final isMobile = UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

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
              final firstPoi = pois[0];
              return {
                'name': firstPoi['name'],
                'address': firstPoi['address'] ?? '',
                'location': firstPoi['location'],
                'latitude': latitude,
                'longitude': longitude,
              };
            } else {
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
        return {
          'name': selectedLocation,
          'address': selectedLocation,
        };
      }

      return null;
    }
  }
}
