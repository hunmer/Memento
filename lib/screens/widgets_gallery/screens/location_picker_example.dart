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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width - 32;

    return Scaffold(
      appBar: AppBar(title: const Text('位置选择器')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: SingleChildScrollView(
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

              // 小尺寸
              _buildSectionTitle('小尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 200,
                  height: 150,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          if (selectedLocation != null) ...[
                            Expanded(
                              child: Text(
                                selectedLocation!,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const Expanded(
                              child: Center(
                                child: Text(
                                  '未选择',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _showLocationPicker,
                            icon: const Icon(Icons.location_on, size: 16),
                            label: const Text('选择', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 中尺寸
              _buildSectionTitle('中尺寸'),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).primaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          if (selectedLocation != null) ...[
                            Expanded(
                              child: Text(
                                selectedLocation!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            const Expanded(
                              child: Center(
                                child: Text(
                                  '未选择位置',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showLocationPicker,
                            icon: const Icon(Icons.location_on),
                            label: const Text('选择位置'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 中宽尺寸
              _buildSectionTitle('中宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: screenWidth,
                height: 180,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '已选择位置',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              if (selectedLocation != null) ...[
                                Text(
                                  selectedLocation!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                const Text(
                                  '未选择位置',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showLocationPicker,
                          icon: const Icon(Icons.map),
                          label: const Text('选择'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 大宽尺寸
              _buildSectionTitle('大宽尺寸'),
              const SizedBox(height: 8),
              SizedBox(
                width: screenWidth,
                height: 220,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '当前位置',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  if (selectedLocation != null) ...[
                                    Text(
                                      selectedLocation!,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else ...[
                                    const Text(
                                      '尚未选择位置',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLocationPicker,
                            icon: const Icon(Icons.map),
                            label: const Text('在地图中选择位置'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
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
