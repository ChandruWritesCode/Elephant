import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'controllers/auth.dart';
import 'controllers/chat.dart';
import 'pages/login.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ChatController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elephant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const SessionGateway(),
    );
  }
}

class SessionGateway extends StatefulWidget {
  const SessionGateway({super.key});

  @override
  State<SessionGateway> createState() => _SessionGatewayState();
}

class _SessionGatewayState extends State<SessionGateway> {
  late Future<String?> _loginCheck;

  @override
  void initState() {
    super.initState();
    _loginCheck = context.read<AuthState>().checkAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loginCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          final token = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ChatController>().initSession(token);
          });
          return const HomePage();
        }
        
        return const LoginPage();
      },
    );
  }
}