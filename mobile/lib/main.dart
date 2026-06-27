import 'package:mob/pages/home_page.dart';
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
        ChangeNotifierProvider(create: (_) => ProfileImageProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Elephant',
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 196, 195, 200),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue[700],
          ),
        ),
        home: Consumer<BasicProviders>(
          builder: (context, value, child) {
            if (!value.isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return value.hasLoggedIn ? const HomePage() : const WelcomePage();
          },
        ),
      ),
    );
  }
}
