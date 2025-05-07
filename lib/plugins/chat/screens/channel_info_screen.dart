import 'package:flutter/material.dart';
import '../models/channel.dart';

class ChannelInfoScreen extends StatelessWidget {
  final Channel channel;

  const ChannelInfoScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('频道信息')),
      body: ListView(
        children: [
          // 频道基本信息
          _buildChannelBasicInfo(),
        ],
      ),
    );
  }

  Widget _buildChannelBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: channel.backgroundColor,
                radius: 30,
                child: Icon(channel.icon, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '频道描述',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('这是一个频道的详细描述信息...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
