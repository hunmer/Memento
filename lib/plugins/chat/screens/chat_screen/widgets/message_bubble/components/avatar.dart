import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/path_utils.dart';

class MessageAvatar extends StatelessWidget {
  final String? iconPath;
  final String username;
  final VoidCallback? onTap;

  const MessageAvatar({
    super.key,
    this.iconPath,
    required this.username,
    this.onTap,
  });

  Widget _buildDefaultAvatar(BuildContext context) {
    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: iconPath != null
              ? FutureBuilder<String>(
                  future: getAbsolutePath(iconPath!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ClipOval(
                        child: Image.file(
                          File(snapshot.data!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return _buildDefaultAvatar(context);
                  },
                )
              : _buildDefaultAvatar(context),
        ),
      ),
    );
  }
}