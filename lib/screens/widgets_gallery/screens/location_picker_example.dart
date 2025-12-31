import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:Memento/widgets/picker/location_picker.dart';

/// 位置选择器示例
class LocationPickerExample extends StatefulWidget {
  const LocationPickerExample({super.key});

  @override
  State<LocationPickerExample> createState() => _LocationPickerExampleState();
}

class _LocationPickerExampleState extends State<LocationPickerExample> {
  String? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('位置选择器')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LocationPicker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('这是一个位置选择器组件，支持地图选择和当前位置。'),
            const SizedBox(height: 8),
            const Text('需要高德地图 API Key 和定位权限。'),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '已选择位置',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (selectedLocation != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedLocation!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('未选择位置', style: TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showLocationPicker,
                icon: const Icon(Icons.location_on),
                label: const Text('选择位置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() async {
    await showDialog(
      context: context,
      builder:
          (context) => LocationPicker(
            isMobile: UniversalPlatform.isAndroid || UniversalPlatform.isIOS,
            onLocationSelected: (location) {
              setState(() {
                selectedLocation = location;
              });
            },
          ),
    );
  }
}
