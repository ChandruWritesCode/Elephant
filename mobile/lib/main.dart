import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:mobile/themes/theme_provider.dart';

import 'core/constants.dart';
import 'services/auth_service.dart';
import 'pages/auth/login_page.dart';
import 'pages/home/home_page.dart';
import 'controllers/auth_state.dart';

import 'controllers/chat/active_chat_controller.dart';
import 'controllers/chat/chat_connection_controller.dart';
import 'controllers/chat/chat_search_controller.dart';
import 'controllers/chat/group_details_controller.dart';
import 'controllers/chat/inbox_controller.dart';
import 'services/chat/chat_event_handler.dart';

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
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => GroupController()),

        ChangeNotifierProvider(create: (_) => InboxController()),
        ChangeNotifierProvider(create: (_) => ActiveChatController()),
        ChangeNotifierProvider(create: (_) => ChatSearchController()),
        ChangeNotifierProvider(create: (_) => GroupDetailsController()),

        ChangeNotifierProxyProvider3<
          AuthState,
          InboxController,
          ActiveChatController,
          ChatConnectionController
        >(
          create: (context) => ChatConnectionController(
            eventHandler: ChatEventHandler(
              inboxController: context.read<InboxController>(),
              activeChatController: context.read<ActiveChatController>(),
              currentUserId: context.read<AuthState>().currentUser?.id ?? '',
            ),
          ),
          update: (context, auth, inbox, activeChat, previousConnection) {
            return previousConnection ??
                ChatConnectionController(
                  eventHandler: ChatEventHandler(
                    inboxController: inbox,
                    activeChatController: activeChat,
                    currentUserId: auth.currentUser?.id ?? '',
                  ),
                );
          },
        ),
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

class _SessionGatewayState extends State<SessionGateway>
    with WidgetsBindingObserver {
  bool _hasCheckedAutoLogin = false;
  String? _lastInitializedToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performInitialAutoLoginCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initChatSession() {
    context.read<ChatConnectionController>().connectWebSocket();
    context.read<InboxController>().loadInbox();
  }

  void _performInitialAutoLoginCheck() async {
    final auth = context.read<AuthState>();
    final token = await auth.checkAutoLogin();

    if (token != null && mounted) {
      _lastInitializedToken = token;
      _initChatSession();
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
        _initChatSession();
      });
    }

    if (authState.token != null) {
      return const HomePage();
    }

    return const LoginPage();
  }
}
