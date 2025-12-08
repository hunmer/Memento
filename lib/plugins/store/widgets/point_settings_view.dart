import 'package:Memento/plugins/store/l10n/store_localizations.dart';
import 'package:flutter/material.dart';
import 'package:Memento/plugins/store/store_plugin.dart';

class PointSettingsView extends StatelessWidget {
  final StorePlugin plugin;

  const PointSettingsView({super.key, required this.plugin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(StoreLocalizations.of(context).pointSettingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '各项行为的积分奖励',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children:
                    plugin.pointAwardSettings.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                plugin.getEventDisplayName(entry.key),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value.toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  suffix: Text(
                                    StoreLocalizations.of(context).points,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) async {
                                  final points =
                                      int.tryParse(value) ?? entry.value;
                                  final newSettings = Map<String, dynamic>.from(
                                    plugin.settings,
                                  );
                                  (newSettings['point_awards']
                                          as Map<String, dynamic>)[entry.key] =
                                      points;
                                  await plugin.updateSettings(newSettings);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
