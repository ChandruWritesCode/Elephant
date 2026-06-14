import 'package:elephant_frontend/pages/welcome_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elephant',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue[700],
        ),
      ),
      home: WelcomePage(),
    );
  }
}
