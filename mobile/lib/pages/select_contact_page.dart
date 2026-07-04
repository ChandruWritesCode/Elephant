import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:provider/provider.dart';

class SelectContactPage extends StatefulWidget {
  const SelectContactPage({super.key});

  @override
  State<SelectContactPage> createState() => _SelectContactPageState();
}

class _SelectContactPageState extends State<SelectContactPage> {
  final Map<String, Map<String, String>> _selectedContacts = {};

  Timer? _debounceTimer;
  bool _isSearchOpen = false;
  final _searchController = TextEditingController();

  void _onSearchChanged(String value, ChatController chatState) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      chatState.queryUsers(value);
    });
  }

  void _toggleSelection(String id, String displayName, String username) {
    setState(() {
      if (_selectedContacts.containsKey(id)) {
        _selectedContacts.remove(id);
      } else {
        _selectedContacts[id] = {
          'displayName': displayName,
          'username': username,
        };
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildContactTile({
    required String id,
    required String displayName,
    required String username,
  }) {
    final bool isSelected = _selectedContacts.containsKey(id);

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blue.withValues(alpha: 0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD6E4FF),
            child: Icon(Icons.person, color: Color(0xFF1890FF)),
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
            ),
        ],
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
      onTap: () => _toggleSelection(id, displayName, username),
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
        scrolledUnderElevation: 0,
        title: AnimatedSwitcher(
          switchInCurve: Curves.decelerate,
          switchOutCurve: Curves.decelerate,
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final tween = Tween<Offset>(
              begin: const Offset(0.5, 0.0),
              end: Offset.zero,
            );
            final offsetAnimation = tween.animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _isSearchOpen
              ? SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _onSearchChanged(val, chatState),
                    style: const TextStyle(color: Colors.black87),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Name, username or number",
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 15,
                      ),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.black38,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                chatState.queryUsers("");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              : const Text(
                  'Select Contacts',
                  style: TextStyle(
                    letterSpacing: 0.5,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  key: ValueKey('title'),
                ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  chatState.queryUsers("");
                }
              });
            },
            icon: Icon(
              _isSearchOpen ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _selectedContacts.isNotEmpty
                ? Container(
                    width: double.infinity,
                    color: Colors.blue.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '${_selectedContacts.length} selected',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
                            final String id =
                                (user['id'] ?? user['user_id'] ?? '')
                                    .toString();
                            final String displayName =
                                user['display_name'] ?? 'User';
                            final String username = user['username'] ?? '';

                            if (id.isEmpty) return const SizedBox.shrink();

                            return _buildContactTile(
                              id: id,
                              displayName: displayName,
                              username: username,
                            );
                          },
                        ))
                : ListView(
                    children: [
                      if (_selectedContacts.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 16,
                            top: 20,
                            bottom: 8,
                          ),
                          child: Text(
                            "Selected Contacts",
                            style: TextStyle(
                              color: Colors.black38,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ..._selectedContacts.entries.map(
                          (entry) => _buildContactTile(
                            id: entry.key,
                            displayName: entry.value['displayName']!,
                            username: entry.value['username']!,
                          ),
                        ),
                      ],

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
                        ...chatState.inbox
                            .where(
                              (thread) => !_selectedContacts.containsKey(
                                thread.chatUserId,
                              ),
                            )
                            .map(
                              (thread) => _buildContactTile(
                                id: thread.chatUserId,
                                displayName: thread.displayName,
                                username: thread.username,
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedContacts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.blue,
              elevation: 4,
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            )
          : null,
    );
  }
}
