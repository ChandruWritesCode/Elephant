import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';
import '../controllers/chat.dart';
import 'home_page.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showServerConfigSheet() {
    final hostController = TextEditingController(text: Env.host);
    final portController = TextEditingController(text: Env.port);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 24.0,
          left: 24.0,
          right: 24.0,
          bottom: 24.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Server Configuration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: hostController, decoration: const InputDecoration(labelText: "Server Address", hintText: "elephant.commandlinecoding.in")),
            const SizedBox(height: 12),
            TextField(controller: portController, decoration: const InputDecoration(labelText: "Port", hintText: "80"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await Env.updateConfig(hostController.text, portController.text);
                if (context.mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text("Save Server Settings"),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final auth = context.read<AuthState>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    final success = await auth.handleLogin(username, password);
    if (success && mounted) {
      final token = await auth.checkAutoLogin();
      if (token != null) {
        await context.read<ChatController>().initSession(token);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? "Authentication failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Elephant Chat", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showServerConfigSheet,
              child: Text(
                "Connected to: ${Env.host}:${Env.port} ⚙️",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 24),
            auth.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _submit, child: const Text("Login")),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text("Create an account"),
            )
          ],
        ),
      ),
    );
  }
}