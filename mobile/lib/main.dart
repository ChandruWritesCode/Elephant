import 'package:flutter/material.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:mobile/providers/group_controller_provider.dart';
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
        ChangeNotifierProvider(create: (_) => BasicProviders()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => GroupController()),
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
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0052CC),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
      ),
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
  bool _hasCheckedAutoLogin = false;
  String? _lastInitializedToken;

  @override
  void initState() {
    super.initState();
    _performInitialAutoLoginCheck();
  }

  void _performInitialAutoLoginCheck() async {
    final auth = context.read<AuthState>();
    final token = await auth.checkAutoLogin();

    if (token != null && mounted) {
      _lastInitializedToken = token;
      context.read<ChatController>().initSession(token);
    }

    if (mounted) {
      setState(() {
        _hasCheckedAutoLogin = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedAutoLogin) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0052CC)),
        ),
      );
    }

    final authState = context.watch<AuthState>();

    if (authState.token != null && authState.token != _lastInitializedToken) {
      _lastInitializedToken = authState.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatController>().initSession(authState.token!);
      });
    }

    if (authState.token != null) {
      return const HomePage();
    }

    return const LoginPage();
  }
}
