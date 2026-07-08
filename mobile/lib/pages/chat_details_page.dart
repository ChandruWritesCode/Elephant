import 'dart:async';

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

  void _showAddParticipantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Add Participants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (query) {
                      // TODO: Implement your user search logic here
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Consumer<GroupController>(
                    builder: (context, groupController, child) {
                      if (groupController.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // TODO: Replace with your actual searched users list
                      final searchedUsers =
                          []; // e.g., authController.searchedUsers

                      if (searchedUsers.isEmpty) {
                        return const Center(
                          child: Text('Search for users to add.'),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: searchedUsers.length,
                        itemBuilder: (context, index) {
                          final user = searchedUsers[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(user.displayName),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.teal,
                              ),
                              onPressed: () async {
                                final success = await context
                                    .read<GroupController>()
                                    .addMemberToGroup(widget.chatId, user.id);

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${user.displayName} added!',
                                      ),
                                    ),
                                  );
                                  // Refresh the group members list behind the sheet
                                  context
                                      .read<ChatController>()
                                      .fetchGroupMembers(widget.chatId);
                                  Navigator.pop(context); // Close sheet
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
            onTap: (){
              Navigator.pop(context, 'start_search');
            }
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

          if (isCurrentUserAdmin)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text('Add participants'),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => _AddParticipantSheet(chatId: widget.chatId),
                );
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
                  title: Text(member.displayName),
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
                            onPressed: () => Navigator.pop(context, true),
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
                          .removeMemberFromGroup(widget.chatId, member.userId);

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${member.displayName} removed.'),
                          ),
                        );
                        context.read<ChatController>().fetchGroupMembers(
                          widget.chatId,
                        );
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

  void _onSearchChanged(String value, ChatController chatState) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (value.length >= 3) {
        chatState.queryUsers(value);
      }
    });
    setState(() {
      
    }); 
  }

  Future<void> _addMember(String userId, String displayName) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final groupCtrl = context.read<GroupController>();
    final chatCtrl = context.read<ChatController>();

    final success = await groupCtrl.addMemberToGroup(widget.chatId, userId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName added to the group!')),
      );
      // Refresh the group members list
      chatCtrl.fetchGroupMembers(widget.chatId);
      Navigator.pop(context); // Close the sheet
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add $displayName.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();
    final groupState = context.watch<GroupController>();

    final String searchInput = _searchController.text.trim();
    final bool isSearching = searchInput.isNotEmpty;
    final bool hasValidQueryLength = searchInput.length >= 3;

    // Get current member IDs to filter them out of search results & recents
    final currentMemberIds = chatState.currentGroupMembers
        .map((m) => m.userId)
        .toSet();

    return Padding(
      // Ensure the sheet rises with the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height:
            MediaQuery.of(context).size.height * 0.7, // Take up 70% of screen
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
                onChanged: (val) => _onSearchChanged(val, chatState),
                decoration: InputDecoration(
                  hintText: "Search name or username",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            chatState.queryUsers("");
                            setState((){});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Show Loading Indicator for Add API call
            if (groupState.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),

            Expanded(
              child: isSearching
                  ? _buildSearchResults(
                      chatState,
                      currentMemberIds,
                      hasValidQueryLength,
                    )
                  : _buildRecentContacts(chatState, currentMemberIds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    ChatController chatState,
    Set<String> currentMemberIds,
    bool hasValidQueryLength,
  ) {
    if (!hasValidQueryLength) {
      return const Center(
        child: Text("Type at least 3 characters to search..."),
      );
    }
    if (chatState.isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter out users who are already in the group
    final results = chatState.contactSearchResults
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
            icon: const Icon(Icons.add_circle, color: Colors.teal),
            onPressed: () => _addMember(uid, displayName),
          ),
        );
      },
    );
  }

  Widget _buildRecentContacts(
    ChatController chatState,
    Set<String> currentMemberIds,
  ) {
    // Filter to only 1-on-1 chats of users NOT currently in the group
    final recents = chatState.inbox
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
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  "Recent Contacts",
                  style: TextStyle(
                    color: Colors.black38,
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
        icon: const Icon(Icons.add_circle, color: Colors.teal),
        onPressed: () => _addMember(thread.id, thread.title),
      ),
    );
  }
}
