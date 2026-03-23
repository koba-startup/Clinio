import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ClinioApp());
}

class ClinioApp extends StatelessWidget {
  const ClinioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinio by Koba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(child: Text('Bienvenido a Clinio')),
      ),
    );
  }
}
