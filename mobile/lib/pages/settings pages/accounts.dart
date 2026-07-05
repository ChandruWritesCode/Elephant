import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:mobile/main.dart';
import 'package:provider/provider.dart';

class AccountsSettings extends StatelessWidget {
  const AccountsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const SizedBox(
            width: double.infinity,
            height: 150,
            child: Hero(
              tag: 'User Profile',
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
                child: CircleAvatar(
                  backgroundColor: Color(0xFFD6E4FF),
                  child: Icon(Icons.person, color: Color(0xFF1890FF), size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
          FilledButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
            ),
            onPressed: () async {
              await context.read<AuthState>().logout();
              await context.read<BasicProviders>().logOutSave();

              if (context.mounted) {
                // context.read<AuthState>().clearSessionData();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SessionGateway(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
