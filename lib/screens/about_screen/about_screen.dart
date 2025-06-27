import 'package:Memento/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset('assets/icon/icon.png', width: 100, height: 100),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Memento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Version 1.1.6',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            AppLocalizations.of(context)!.aboutDescription,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Text(
            AppLocalizations.of(context)!.projectLinkTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              launchUrl(Uri.parse('https://github.com/hunmer/Memento'));
            },
            child: Text(
              AppLocalizations.of(context)!.projectLink,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
