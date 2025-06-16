import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';

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
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
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
          'http://restapi.amap.com/v3/geocode/regeo?key=dad6a772bf826842c3049e9c7198115c&location=${position.longitude},${position.latitude}&poitype=&radius=1000&extensions=all&batch=false&roadlevel=0',
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
                'address': poi['address'] ?? '无地址信息',
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
          'https://restapi.amap.com/v3/place/text?key=dad6a772bf826842c3049e9c7198115c&keywords=$query&types=&city=&children=&offset=20&page=1&extensions=base',
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
                    'address': poi['address'] ?? '无地址信息',
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
    return AlertDialog(
      title: const Text('选择位置'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '搜索位置',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed:
                                () => _searchLocation(_searchController.text),
                          ),
                          IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: _getCurrentLocation,
                            tooltip: '获取当前位置',
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: _searchLocation,
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading:
                          result['isCurrent']
                              ? const Icon(Icons.my_location)
                              : null,
                      title: Text(result['name']),
                      subtitle: Text(result['address']),
                      selected: _selectedLocation == result['address'],
                      onTap: () {
                        setState(() {
                          _selectedLocation = result['address'];
                          _searchController.text = result['address'];
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('确定'),
          onPressed: () {
            if (_selectedLocation != null) {
              widget.onLocationSelected(_selectedLocation!);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
