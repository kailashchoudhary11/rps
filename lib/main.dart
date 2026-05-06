import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/code_entry_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kick off AdMob init in the background — we don't need to block first
  // paint on it. By the time the gallery screen mounts and asks for a
  // banner, initialization has finished.
  unawaited(MobileAds.instance.initialize());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pic Studios',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange.shade700,
          secondary: Colors.deepOrange,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const CodeEntryScreen(),
    );
  }
}
