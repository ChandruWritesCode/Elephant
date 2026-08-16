import 'package:flutter/material.dart';
import 'package:mobile/services/signal_service.dart';

class PrivacySecuritySettingsPage extends StatelessWidget {
  const PrivacySecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and security')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.lock_person,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Your privacy is protected",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Elephant uses the Signal Protocol to secure your messages. Nobody, not even Elephant, can read your messages or listen to your calls.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.timer),
            title: Text('Disappearing messages'),
            subtitle: Text('Off'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Reset All Secure Sessions',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Fixes widespread decryption errors.'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Reset All Sessions?"),
                  content: const Text(
                    "This will delete all local cryptographic sessions. Your chat history will remain, but you will need to exchange new messages to re-establish secure connections with your contacts.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await SignalService().clearAllSessions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All secure sessions have been reset.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
