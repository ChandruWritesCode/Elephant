import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/controllers/auth_state.dart';
import 'package:mobile/controllers/chat/chat_search_controller.dart';
import 'package:mobile/controllers/chat/group_details_controller.dart';
import 'package:mobile/controllers/chat/inbox_controller.dart';
import 'package:mobile/pages/chat/chat_page.dart';
import 'package:mobile/providers/group_controller_provider.dart';
import 'package:mobile/services/signal_service.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
        context.read<GroupDetailsController>().fetchGroupMembers(widget.chatId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetailsState = context.watch<GroupDetailsController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                _buildGroupMembersSection(groupDetailsState)
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
            onTap: () {
              Navigator.pop(context, 'start_search');
            },
          ),
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
          children: [Text('0'), Icon(Icons.chevron_right)],
        ),
        onTap: () {},
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
              'Messages and calls are end-to-end encrypted. Tap to verify.',
            ),
            onTap: () async {
              final currentUserId = context.read<AuthState>().currentUser?.id;
              if (currentUserId == null) return;

              final safetyNumber = await SignalService().getSafetyNumber(
                currentUserId, 
                widget.chatId
              );

              if (!context.mounted) return;

              if (safetyNumber == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Send a message first to establish a secure session.')),
                );
                return;
              }

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Verify Security Code",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: QrImageView(
                          data: safetyNumber,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        safetyNumber,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16, 
                          letterSpacing: 2, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "To verify that messages and calls are end-to-end encrypted, scan this code on your contact's phone, or compare the number above.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset Secure Session', style: TextStyle(color: Colors.orange)),
            subtitle: const Text('Use this if messages are failing to decrypt.'),
            onTap: () async {
               await SignalService().forceResetSession(widget.chatId);
               if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Secure session reset. Send a new message to reconnect.')),
                 );
               }
            },
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

  Widget _buildGroupMembersSection(GroupDetailsController groupState) {
    final members = groupState.currentGroupMembers;
    final isLoading = groupState.isLoadingDetails;

    final currentUserId = context.read<AuthState>().currentUser?.id;
    final currentUserMember = members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final isCurrentUserAdmin = currentUserMember?.role == 'admin';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${members.length} participants',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (isCurrentUserAdmin)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Add participants'),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (context) =>
                      _AddParticipantSheet(chatId: widget.chatId),
                );
              },
            ),

          if (isLoading && members.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 32.0),
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
                  title: Text(member.displayName),
                  subtitle: isThisUserAdmin
                      ? Text(
                          'Admin',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
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

  void _showMemberDetailsDialog(ChatMember member, bool isCurrentUserAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Message @${member.username}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatUserId: member.userId,
                            displayName: member.displayName,
                            isGroup: false,
                          ),
                        ),
                      );
                    },
                  ),
                  if (isCurrentUserAdmin &&
                      member.userId !=
                          context.read<AuthState>().currentUser?.id)
                    ListTile(
                      title: const Text(
                        'Remove from group',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Participant'),
                            content: Text(
                              'Are you sure you want to remove ${member.displayName} from this group?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removing member...'),
                              duration: Duration(seconds: 1),
                            ),
                          );

                          final success = await context
                              .read<GroupController>()
                              .removeMemberFromGroup(
                                widget.chatId,
                                member.userId,
                              );

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${member.displayName} removed.'),
                              ),
                            );
                            context
                                .read<GroupDetailsController>()
                                .fetchGroupMembers(widget.chatId);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to remove member.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
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
    return Material(color: Theme.of(context).colorScheme.surface, child: child);
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback? onTap;

  const _ActionIcon({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AddParticipantSheet extends StatefulWidget {
  final String chatId;

  const _AddParticipantSheet({required this.chatId});

  @override
  State<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<_AddParticipantSheet> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, ChatSearchController searchState) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (value.length >= 3) {
        searchState.queryUsers(value);
      }
    });
    setState(() {});
  }

  Future<void> _addMember(String userId, String displayName) async {
    FocusScope.of(context).unfocus();

    final groupCtrl = context.read<GroupController>();
    final groupDetailsCtrl = context.read<GroupDetailsController>();

    final success = await groupCtrl.addMemberToGroup(widget.chatId, userId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName added to the group!')),
      );
      groupDetailsCtrl.fetchGroupMembers(widget.chatId);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add $displayName.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDetailsState = context.watch<GroupDetailsController>();
    final searchState = context.watch<ChatSearchController>();
    final inboxState = context.watch<InboxController>();
    final groupState = context.watch<GroupController>();

    final String searchInput = _searchController.text.trim();
    final bool isSearching = searchInput.isNotEmpty;
    final bool hasValidQueryLength = searchInput.length >= 3;

    final currentMemberIds = groupDetailsState.currentGroupMembers
        .map((m) => m.userId)
        .toSet();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                const Text(
                  'Add Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _onSearchChanged(val, searchState),
                    decoration: InputDecoration(
                      hintText: "Search name or username",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                searchState.queryUsers("");
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (groupState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),

                Expanded(
                  child: isSearching
                      ? _buildSearchResults(
                          searchState,
                          currentMemberIds,
                          hasValidQueryLength,
                        )
                      : _buildRecentContacts(inboxState, currentMemberIds),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    ChatSearchController searchState,
    Set<String> currentMemberIds,
    bool hasValidQueryLength,
  ) {
    if (!hasValidQueryLength) {
      return const Center(
        child: Text("Type at least 3 characters to search..."),
      );
    }
    if (searchState.isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = searchState.contactSearchResults
        .where((user) => !currentMemberIds.contains(user['id']))
        .toList();

    if (results.isEmpty) {
      return const Center(child: Text("No new users found."));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        final String displayName = user['display_name'] ?? 'User';
        final String username = user['username'] ?? '';
        final String uid = user['id'];

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(displayName),
          subtitle: Text("@$username"),
          trailing: IconButton(
            icon: Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _addMember(uid, displayName),
          ),
        );
      },
    );
  }

  Widget _buildRecentContacts(
    InboxController inboxState,
    Set<String> currentMemberIds,
  ) {
    final recents = inboxState.inbox
        .where(
          (thread) => !thread.isGroup && !currentMemberIds.contains(thread.id),
        )
        .toList();

    if (recents.isEmpty) {
      return const Center(child: Text("No recent contacts to add."));
    }

    return ListView.builder(
      itemCount: recents.length,
      itemBuilder: (context, index) {
        final thread = recents[index];
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  "Recent Contacts",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              _buildRecentListTile(thread),
            ],
          );
        }
        return _buildRecentListTile(thread);
      },
    );
  }

  Widget _buildRecentListTile(dynamic thread) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(thread.title),
      subtitle: Text("@${thread.username}"),
      trailing: IconButton(
        icon: Icon(
          Icons.add_circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: () => _addMember(thread.id, thread.title),
      ),
    );
  }
}
