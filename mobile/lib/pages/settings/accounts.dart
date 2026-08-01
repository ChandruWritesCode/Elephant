import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/controllers/auth_state.dart';
import 'package:mobile/controllers/chat/chat_connection_controller.dart';
import 'package:mobile/controllers/chat/group_details_controller.dart';
import 'package:mobile/controllers/chat/inbox_controller.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:provider/provider.dart';

class AccountsSettings extends StatelessWidget {
  const AccountsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Accounts',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          SizedBox(
            width: double.infinity,
            height: 150,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                top: 10.0,
                bottom: 10.0,
              ),
              child: Hero(
                tag: 'User Profile',
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 40,
                  ),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "Details",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          // Email Tile
          ListTile(
            leading: Icon(
              Icons.email_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text("Email"),
            subtitle: Text(
              user?.email != null && user!.email!.isNotEmpty
                  ? user.email!
                  : "Not provided",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: Navigate to edit email page
            },
          ),

          // Phone Number Tile
          ListTile(
            leading: Icon(
              Icons.phone_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text("Phone Number"),
            subtitle: Text(
              "Not provided",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () {},
          ),

          // Bio Tile
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text("About"),
            subtitle: Text(
              "Hey there! I am using Elephant.",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () {},
          ),

          const SizedBox(height: 30),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(theme.colorScheme.error),
              foregroundColor: WidgetStatePropertyAll(
                theme.colorScheme.onError,
              ),
            ),
            onPressed: () async {
              await context.read<AuthState>().logout();

              if (context.mounted) {
                context.read<ChatConnectionController>().disconnectWebSocket();

                context.read<GroupDetailsController>().clearCache();

                context.read<InboxController>().clearInbox();

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
