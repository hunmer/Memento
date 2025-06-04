import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Memento/l10n/app_localizations.dart';
import '../../../plugins/chat/l10n/chat_localizations.dart';
import '../../../plugins/day/l10n/day_localizations.dart';
import '../../../plugins/nodes/l10n/nodes_localizations.dart' as nodes_l10n;
import '../../../screens/home_screen/home_screen.dart';

class RebuildController {
  /// 重建应用以应用新的设置
  static Future<void> rebuildApplication({
    required BuildContext currentContext,
    Locale? newLocale,
    ThemeMode? newThemeMode,
  }) async {
    final navigator = Navigator.of(currentContext);
    final currentRoute = ModalRoute.of(currentContext);
    if (currentRoute == null) return;

    // 获取当前或新的主题模式
    final effectiveThemeMode =
        newThemeMode ??
        (Theme.of(currentContext).brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light);

    // 获取当前或新的区域设置
    final effectiveLocale = newLocale ?? Localizations.localeOf(currentContext);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => MaterialApp(
              title: 'Memento',
              debugShowCheckedModeBanner: false,
              home: const HomeScreen(),
              locale: effectiveLocale,
              themeMode: effectiveThemeMode,
              theme: ThemeData(
                colorScheme: const ColorScheme.light(
                  primary: Colors.blue,
                  secondary: Colors.blueAccent,
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  secondary: Colors.blueAccent,
                ),
                useMaterial3: true,
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ChatLocalizations.delegate,
                DayLocalizationsDelegate.delegate,
                nodes_l10n.NodesLocalizationsDelegate.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('zh', ''), Locale('en', '')],
            ),
      ),
    );
  }
}
