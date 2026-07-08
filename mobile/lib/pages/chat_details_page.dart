import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:provider/provider.dart';

class ChatMember {
  final String userId;
  final String username;
  final String displayName;
  final String role;
  final String? avatarUrl;

  ChatMember({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    this.avatarUrl,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      userId: json['user_id'].toString(),
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? json['username'] ?? 'Unknown',
      role: json['role'] ?? 'member',
      avatarUrl: json['avatarUrl'],
    );
  }
}

class ChatDetailsPage extends StatefulWidget {
  final bool isGroup;
  final String chatName;
  final String chatImageUrl;
  final String chatId;

  const ChatDetailsPage({
    super.key,
    required this.isGroup,
    required this.chatName,
    required this.chatImageUrl,
    required this.chatId,
  });

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.isGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatController>().fetchGroupMembers(widget.chatId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = context.watch<ChatController>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 10),
              _buildCommonActions(),
              const SizedBox(height: 10),
              _buildMediaSection(),
              const SizedBox(height: 10),
              _buildNotificationSettings(),
              const SizedBox(height: 10),

              if (widget.isGroup)
                _buildGroupMembersSection(chatController)
              else
                _buildOneOnOneDetails(),

              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(widget.chatName),
        background: Hero(
          tag: 'profile',
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: CircleAvatar(child: Icon(Icons.person, size: 100)),
          ),
        ),
      ),
    );
  }

  Widget _buildCommonActions() {
    return _SectionContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionIcon(icon: Icons.call, label: 'Audio'),
          _ActionIcon(icon: Icons.videocam, label: 'Video'),
          _ActionIcon(
            icon: Icons.search,
            label: 'Search',
          ), // Search in chat feature
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return _SectionContainer(
      child: ListTile(
        title: const Text('Media, links, and docs'),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('0'), // Replace with actual count later
            Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: Navigate to Media Page (API calls later)
        },
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _SectionContainer(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_off),
            title: const Text('Mute notifications'),
            trailing: Switch(value: false, onChanged: (val) {}),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Custom notifications'),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Media visibility'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOneOnOneDetails() {
    return _SectionContainer(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Encryption'),
            subtitle: const Text(
              'Messages and calls are end-to-end encrypted.',
            ),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About and phone number'),
            subtitle: const Text(
              '+1 234 567 8900\nHey there! I am using this app.',
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGroupMembersSection(ChatController chatController) {
    final members = chatController.currentGroupMembers;
    final isLoading = chatController.isLoadingDetails;

    // Check if the CURRENT user is an admin by finding their ID in the members list
    final currentUserId = context.read<AuthState>().currentUser?.id;
    final currentUserMember = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final isCurrentUserAdmin = currentUserMember?.role == 'admin';

    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${members.length} participants',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Only show Add button if the current user has the 'admin' role
          if (isCurrentUserAdmin)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text('Add participants'),
              onTap: () {
                // TODO: Trigger Add Member Flow
              },
            ),

          if (isLoading && members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isThisUserAdmin = member.role == 'admin';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.avatarUrl != null
                        ? NetworkImage(member.avatarUrl!)
                        : null,
                    child: member.avatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  // FIXED: Using display_name instead of name
                  title: Text(member.displayName),
                  // FIXED: Dynamically rendering Admin tag based on API role
                  subtitle: isThisUserAdmin
                      ? const Text(
                          'Admin',
                          style: TextStyle(color: Colors.teal, fontSize: 12),
                        )
                      : null,
                  onTap: () =>
                      _showMemberDetailsDialog(member, isCurrentUserAdmin),
                );
              },
            ),
        ],
      ),
    );
  }

  // Action when clicking a group member
  void _showMemberDetailsDialog(ChatMember member, bool isCurrentUserAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Message ${member.displayName}'),
                onTap: () {
                  /* Navigate to 1-on-1 chat */
                },
              ),
              ListTile(
                title: Text('View Profile (@${member.username})'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (isCurrentUserAdmin &&
                  member.userId != context.read<AuthState>().currentUser?.id)
                ListTile(
                  title: const Text(
                    'Remove from group',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await context
                        .read<GroupController>()
                        .removeMemberFromGroup(widget.chatId, member.userId);
                    if (success && mounted) {
                      context.read<ChatController>().fetchGroupMembers(
                        widget.chatId,
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// --- Reusable Helper Widgets ---

class _SectionContainer extends StatelessWidget {
  final Widget child;
  const _SectionContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, child: child);
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
