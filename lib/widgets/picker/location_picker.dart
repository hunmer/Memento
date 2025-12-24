import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定义Position类
class Position {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final double speedAccuracy;

  Position({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
  });
}

class LocationPicker extends StatefulWidget {
  final ValueChanged<String> onLocationSelected;
  final bool isMobile;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    required this.isMobile,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _apiKey = 'dad6a772bf826842c3049e9c7198115c'; // 默认 API Key
  // String? _selectedLocation; // No longer needed for single tap select

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    // Auto-load current location or recent? maybe not to save data/permissions
    // _getCurrentLocation();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('location_api_key') ?? 'dad6a772bf826842c3049e9c7198115c';
    });
  }

  Future<Position> _getCurrentPosition() async {
    final location = Location();

    // 检查服务是否可用
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        throw Exception('Location services are disabled');
      }
    }

    // 检查权限状态
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint('Location permissions are denied');
        throw Exception('Location permissions are denied');
      }
    }

    // 获取当前位置
    try {
      final locationData = await location.getLocation();
      return Position(
        latitude: locationData.latitude ?? 0,
        longitude: locationData.longitude ?? 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          locationData.time?.toInt() ?? 0,
        ),
        accuracy: locationData.accuracy ?? 0,
        altitude: locationData.altitude ?? 0,
        heading: locationData.heading ?? 0,
        speed: locationData.speed ?? 0,
        speedAccuracy: locationData.speedAccuracy ?? 0,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      rethrow;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final position = await _getCurrentPosition();
      final response = await http.get(
        Uri.parse(
          'http://restapi.amap.com/v3/geocode/regeo?key=$_apiKey&location=${position.longitude},${position.latitude}&poitype=&radius=1000&extensions=all&batch=false&roadlevel=0',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['regeocode'] != null) {
          final regeocode = data['regeocode'];
          final currentLocation = {
            'name': '当前位置',
            'address': regeocode['formatted_address'],
            'location': '${position.longitude},${position.latitude}',
            'isCurrent': true,
          };

          // 添加周边POI信息
          final pois = <Map<String, dynamic>>[];
          if (regeocode['pois'] != null) {
            for (var poi in regeocode['pois']) {
              pois.add({
                'name': poi['name'],
                'address': poi['address'] ?? 'location_picker_noAddressInfo'.tr,
                'location': poi['location'],
                'isCurrent': false,
              });
            }
          }

          setState(() {
            _searchResults = [currentLocation, ...pois];
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://restapi.amap.com/v3/place/text?key=$_apiKey&keywords=$query&types=&city=&children=&offset=20&page=1&extensions=base',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['pois'] != null) {
          setState(() {
            _searchResults =
                (data['pois'] as List).map((poi) {
                  return {
                    'name': poi['name'],
                    'address':
                        poi['address'] ?? 'location_picker_noAddressInfo'.tr,
                    'location': poi['location'],
                    'isCurrent': false,
                  };
                }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        // 拖拽指示器
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // 标题栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'app_cancel'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Text(
                'app_selectLocation'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 40), // 占位保持标题居中
            ],
          ),
        ),
        // 搜索框
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'location_picker_searchLocation'.tr,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location, color: Colors.blue),
                onPressed: _getCurrentLocation,
                tooltip: 'location_picker_getCurrentLocation'.tr,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: _searchLocation,
          ),
        ),
        // 内容区域
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isNotEmpty
                  ? ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _searchResults.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        leading:
                            result['isCurrent'] == true
                                ? const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                )
                                : const Icon(Icons.place, color: Colors.grey),
                        title: Text(
                          result['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          result['address'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          widget.onLocationSelected(result['address']);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  )
                  : Center(
                    child: Text(
                      '暂无搜索结果',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
        ),
      ],
    ),
    );
  }
}
