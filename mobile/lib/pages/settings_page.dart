import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/pages/settings%20pages/accounts.dart';
import 'package:mobile/pages/settings%20pages/appearance.dart';
import 'package:mobile/pages/settings%20pages/chats_media.dart';
import 'package:mobile/pages/settings%20pages/help_about.dart';
import 'package:mobile/pages/settings%20pages/notifications_settings.dart';
import 'package:mobile/pages/settings%20pages/privacy_security.dart';
import 'package:mobile/providers/basic_providers.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

void showUserCard(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final user = context.read<AuthState>().currentUser;
      final String qrData = user?.username ?? 'unknown';

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.surface,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share Your QR!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  '@$qrData',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0,
            pinned: true,
            stretch: false,
            stretchTriggerOffset: 0.1,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                enabled: true,
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Theme.of(context).colorScheme.surface),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
            title: Text(
              'Settings',
              style: TextStyle(
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              key: const ValueKey('title'),
            ),

            actions: [
              IconButton(
                onPressed: () {
                  showUserCard(context);
                },
                icon: Icon(Icons.qr_code),
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AccountsSettings()),
                  );
                },
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'User Profile',
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Hero(
                          tag: 'User Data',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Spacer(),
                                Text(
                                  user != null
                                      ? user.displayName
                                      : 'Profile N/A',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user != null
                                      ? '@${user.username}'
                                      : 'Could not load profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    _settingsOption(
                      context: context,
                      icon: Icons.lock,
                      settingName: 'Privacy and Security',
                      whereTo: PrivacySecuritySettingsPage(),
                    ),
                    Divider(),
                    _settingsOption(
                      context: context,
                      icon: Icons.notifications,
                      settingName: 'Notifications',
                      whereTo: NotificationsSettingsPage(),
                      trailing: Consumer<BasicProviders>(
                        builder: (context, basicProvider, child) {
                          return Switch(
                            value: basicProvider.notificationsSwitch,
                            onChanged: (value) {
                              basicProvider.toggleNotifications();
                            },
                          );
                        },
                      ),
                    ),
                    Divider(),
                    _settingsOption(
                      context: context,
                      icon: Icons.chat,
                      settingName: 'Chats & Media',
                      whereTo: ChatsMediaPage(),
                    ),
                    Divider(),
                    _settingsOption(
                      context: context,
                      icon: Icons.format_paint,
                      settingName: 'Appearance',
                      whereTo: AppearanceSettings(),
                    ),
                    Divider(),
                    _settingsOption(
                      context: context,
                      icon: Icons.key,
                      settingName: 'Account',
                      whereTo: AccountsSettings(),
                    ),
                    Divider(),
                    _settingsOption(
                      context: context,
                      icon: Icons.help,
                      settingName: 'Help & About',
                      whereTo: HelpAboutPage(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }
}

Widget _settingsOption({
  required BuildContext context,
  required IconData icon,
  required String settingName,
  Widget trailing = const SizedBox.shrink(),
  Widget? whereTo,
}) {
  return InkWell(
    onTap: () {
      if (whereTo != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => whereTo),
        );
      }
    },
    child: SizedBox(
      width: double.infinity,
      height: 60,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
          Text(
            settingName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          trailing == const SizedBox.shrink()
              ? Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : trailing,
        ],
      ),
    ),
  );
}
