import 'package:mob/pages/welcome_page.dart';
import 'package:mob/providers/basic_providers.dart';
import 'package:mob/providers/image_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BasicProviders()),
        ChangeNotifierProvider(create: (_) => ProfileImageProvider())
        ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Elephant',
        theme: ThemeData(
          colorScheme: .fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue[700],
          ),
        ),
        home: WelcomePage(),
      ),
    );
  }
}
