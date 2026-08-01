import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/controllers/chat/active_chat_controller.dart';
import 'package:mobile/controllers/chat/chat_search_controller.dart';
import 'package:mobile/controllers/chat/inbox_controller.dart';
import 'package:mobile/pages/new%20chat/select_contact_page.dart';
import 'package:mobile/pages/settings/settings_page.dart';
import 'package:provider/provider.dart';
import '../chat/chat_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value, ChatSearchController searchChat) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      searchChat.queryUsers(value);
    });
  }

  void _triggerUsernameSearchDialog() {
    final inputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Find by Username",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: inputController,
            autofocus: true,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: "Enter minimum 3 characters...",
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                final text = inputController.text.trim();
                if (text.length >= 3) {
                  context.read<ChatSearchController>().queryUsers(text);
                  setState(() {
                    _searchController.text = text;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Search query must be at least 3 characters.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                  );
                }
              },
              child: Text(
                "Search",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = context.watch<ChatSearchController>();
    final inboxState = context.watch<InboxController>();
    final activeChatState = context.read<ActiveChatController>();
    final String searchInput = _searchController.text.trim();
    final bool isSearching = searchInput.isNotEmpty;
    final bool hasValidQueryLength = searchInput.length >= 3;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          'New message',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                case 'qr':
                  showUserCard(context);
                  break;
                default:
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'qr',
                child: Text("Share username by QR"),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _onSearchChanged(val, searchState),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Name, username or number",
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          searchState.queryUsers("");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isSearching
                ? (!hasValidQueryLength
                      ? Center(
                          child: Text(
                            "Type at least 3 characters to search...",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : searchState.isSearchLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : searchState.contactSearchResults.isEmpty
                      ? Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchState.contactSearchResults.length,
                          itemBuilder: (context, index) {
                            final user =
                                searchState.contactSearchResults[index];
                            final String displayName =
                                user['display_name'] ?? 'User';
                            final String username = user['username'] ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "@$username",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () {
                                final String uid = user['id'];
                                activeChatState.openChat(uid);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      chatUserId: uid,
                                      displayName: displayName,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ))
                : ListView(
                    children: [
                      _buildActionRow(
                        icon: Icons.group,
                        label: "New group",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SelectContactPage(),
                            ),
                          );
                        },
                      ),
                      _buildActionRow(
                        icon: Icons.alternate_email,
                        label: "Find by username",
                        onTap: _triggerUsernameSearchDialog,
                      ),
                      _buildActionRow(
                        icon: Icons.tag,
                        label: "Find by phone number",
                        onTap: () {},
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          top: 20,
                          bottom: 8,
                        ),
                        child: Text(
                          "Recent Contacts",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (inboxState.inbox.isNotEmpty)
                        ...inboxState.inbox
                            .where((thread) => !thread.isGroup)
                            .map(
                              (thread) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                title: Text(
                                  thread.title,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  "@${thread.username}",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                onTap: () {
                                  activeChatState.openChat(thread.id);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        chatUserId: thread.id,
                                        displayName: thread.title,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
