import 'package:flutter/material.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:mobile/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'controllers/auth.dart';
import 'controllers/chat.dart';
import 'services/auth.dart';
import 'pages/login.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.init();
  await AuthService().initTokens();

  final themeProvider = ThemeProvider();

  while (!themeProvider.isInitialized) {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
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
      theme: context.watch<ThemeProvider>().themeData,
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
      context.read<ChatController>().initSession();
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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final authState = context.watch<AuthState>();

    if (authState.token != null && authState.token != _lastInitializedToken) {
      _lastInitializedToken = authState.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatController>().initSession();
      });
    }

    if (authState.token != null) {
      return const HomePage();
    }

    return const LoginPage();
  }
}
