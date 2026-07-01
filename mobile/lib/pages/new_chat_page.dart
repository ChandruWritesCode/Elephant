import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/controllers/chat.dart';
import 'chat_page.dart';

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

  void _onSearchChanged(String value, ChatController chatState) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      chatState.queryUsers(value);
    });
  }

  void _triggerUsernameSearchDialog() {
    final inputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Find by Username",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: inputController,
          autofocus: true,
          style: const TextStyle(color: Colors.black87),
          decoration: const InputDecoration(
            hintText: "Enter exact username...",
            hintStyle: TextStyle(color: Colors.black38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1890FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1890FF),
            ),
            onPressed: () {
              final text = inputController.text.trim();
              if (text.isNotEmpty) {
                context.read<ChatController>().queryUsers(text);
                setState(() {
                  _searchController.text = text;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Search", style: TextStyle(color: Colors.white)),
          ),
        ],
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
        backgroundColor: const Color(0xFFF0F2F5),
        child: Icon(icon, color: Colors.black54, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'New message',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _onSearchChanged(val, chatState),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Name, username or number",
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black38),
                        onPressed: () {
                          _searchController.clear();
                          chatState.queryUsers("");
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
                ? (chatState.isSearchLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1890FF),
                          ),
                        )
                      : chatState.contactSearchResults.isEmpty
                      ? const Center(
                          child: Text(
                            "No users found",
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView.builder(
                          itemCount: chatState.contactSearchResults.length,
                          itemBuilder: (context, index) {
                            final user = chatState.contactSearchResults[index];
                            final String displayName =
                                user['display_name'] ?? 'User';
                            final String username = user['username'] ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFD6E4FF),
                                child: Icon(
                                  Icons.person,
                                  color: Color(0xFF1890FF),
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "@$username",
                                style: const TextStyle(color: Colors.black45),
                              ),
                              onTap: () {
                                final String uid = user['id'];
                                chatState.openChat(uid);
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
                        onTap: () {},
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
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 20, bottom: 8),
                        child: Text(
                          "Recent Contacts",
                          style: TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (chatState.inbox.isNotEmpty)
                        ...chatState.inbox.map(
                          (thread) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8E8E8),
                              child: Icon(Icons.person, color: Colors.black54),
                            ),
                            title: Text(
                              thread.displayName,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "@${thread.username}",
                              style: const TextStyle(color: Colors.black45),
                            ),
                            onTap: () {
                              chatState.openChat(thread.chatUserId);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    chatUserId: thread.chatUserId,
                                    displayName: thread.displayName,
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
