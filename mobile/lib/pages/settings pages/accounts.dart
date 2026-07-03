import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/main.dart';
import 'package:provider/provider.dart';

class AccountsSettings extends StatelessWidget {
  const AccountsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accounts')),
      body: ListView(
        children: [
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red),
            ),
            onPressed: () {
              context.read<AuthState>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SessionGateway()),
                (route) => false,
              );
            },
            child: Text('Log out'),
          ),
        ],
      ),
    );
  }
}
