import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../controllers/auth.dart';
import '../controllers/chat.dart';
import 'home_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RegisterPageBody();
  }
}

class _RegisterPageBody extends StatefulWidget {
  const _RegisterPageBody({super.key});

  @override
  State<_RegisterPageBody> createState() => _RegisterPageBodyState();
}

class _RegisterPageBodyState extends State<_RegisterPageBody> {
  final _usernameController = TextEditingController();
  final _displayController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthState>();
    final user = _usernameController.text.trim();
    final display = _displayController.text.trim();
    final pass = _passwordController.text.trim();

    if (user.isEmpty || display.isEmpty || pass.isEmpty) return;

    final String? assignedUsername = await auth.handleRegister(user, display, pass);

    if (assignedUsername != null && mounted) {
      final token = await auth.checkAutoLogin();
      if (token != null) {
        await context.read<ChatController>().initSession(token);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Registration Successful!"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Please save your unique system username. You will need it to log in next time:"),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        assignedUsername,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                    child: const Text("Continue to Chat"),
                  ),
                ],
              );
            },
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? "Registration failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Server: ${Env.host}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Register Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
              const SizedBox(height: 16),
              TextField(controller: _displayController, decoration: const InputDecoration(labelText: "Display Name")),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
              const SizedBox(height: 32),
              auth.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _submit, child: const Text("Sign Up")),
            ],
          ),
        ),
      ),
    );
  }
}