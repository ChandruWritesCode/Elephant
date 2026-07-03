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
          SizedBox(
            width: double.infinity,
            height: 150,
            child: Hero(
              tag: 'User Profile',
              child: const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
                child: CircleAvatar(
                  backgroundColor: Color(0xFFD6E4FF),
                  child: Icon(Icons.person, color: Color(0xFF1890FF)),
                ),
              ),
            ),
          ),
          SizedBox(height: 200),
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
