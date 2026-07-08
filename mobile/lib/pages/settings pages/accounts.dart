import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:provider/provider.dart';

class AccountsSettings extends StatelessWidget {
  const AccountsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
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
            child: Padding(
              // Moved padding OUTSIDE the Hero
              padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
              child: Hero(
                tag: 'User Profile',
                child: CircleAvatar(
                  backgroundColor: Color(0xFFD6E4FF),
                  child: Icon(Icons.person, color: Color(0xFF1890FF), size: 40),
                ),
              ),
            ),
          ),
          Center(
            child: Hero(
              tag: 'User Data',
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      user != null ? user.displayName : 'Profile N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: user!.username),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Copied to clipboard!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        user != null
                            ? '@${user.username}'
                            : 'Could not load profile',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "Details",
              style: TextStyle(
                color: Colors.black38,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          // Email Tile
          ListTile(
            leading: const Icon(Icons.email_outlined, color: Colors.black54),
            title: const Text("Email"),
            subtitle: Text(
              user?.email != null && user!.email!.isNotEmpty
                  ? user.email!
                  : "Not provided",
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.black38),
            onTap: () {
              // TODO: Navigate to edit email page
            },
          ),

          // Phone Number Tile
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: Colors.black54),
            title: const Text("Phone Number"),
            subtitle: const Text(
              "Not provided",
              style: TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.black38),
            onTap: () {},
          ),

          // Bio Tile
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.black54),
            title: const Text("About"),
            subtitle: const Text(
              "Hey there! I am using Elephant.",
              style: TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.edit, size: 18, color: Colors.black38),
            onTap: () {},
          ),

          const SizedBox(height: 30),
          FilledButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
            ),
            onPressed: () async {
              await context.read<AuthState>().logout();

              if (context.mounted) {
                context.read<ChatController>().clearSessionData();
                context.read<GroupController>().clearGroupData();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SessionGateway(),
                  ),
                  (Route<dynamic> route) => false,
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
