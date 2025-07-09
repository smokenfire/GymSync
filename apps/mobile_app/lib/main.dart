import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'screens/home_screen.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final themeValue = prefs.getString('theme_mode');
  ThemeMode initialTheme;
  if (themeValue == 'dark') {
    initialTheme = ThemeMode.dark;
  } else if (themeValue == 'light') {
    initialTheme = ThemeMode.light;
  } else {
    initialTheme = ThemeMode.system;
  }
  themeModeNotifier.value = initialTheme;

  await FlutterBackground.initialize(
    androidConfig: const FlutterBackgroundAndroidConfig(
      notificationTitle: "GymSync Running",
      notificationText: "Your workout is being monitored in the background.",
      enableWifiLock: true,
    ),
  );
  await FlutterBackground.enableBackgroundExecution();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'GymSync App',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}