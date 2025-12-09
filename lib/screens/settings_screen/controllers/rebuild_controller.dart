import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:Memento/screens/home_screen/home_screen.dart';

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
      NavigationHelper.createRoute(
        MaterialApp(
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
