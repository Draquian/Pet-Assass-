import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PetoAssessiApp());
}

class PetoAssessiApp extends StatelessWidget {
  const PetoAssessiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spore Games – Petó Assassí',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SplashScreen(),
    );
  }
}
