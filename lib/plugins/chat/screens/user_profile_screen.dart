import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user.username), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.iconPath != null)
              CircleAvatar(
                backgroundImage: AssetImage(user.iconPath!),
                radius: 60,
              )
            else
              CircleAvatar(
                radius: 60,
                child: Text(
                  user.username[0],
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              user.username,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'ID: ${user.id}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
