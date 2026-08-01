import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/controllers/chat/chat_search_controller.dart';
import 'package:mobile/controllers/chat/inbox_controller.dart';
import 'package:mobile/pages/chat/chat_page.dart';
import 'package:mobile/providers/group_controller_provider.dart';
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
  final _groupNameController = TextEditingController();

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ChatSearchController>().queryUsers(value);
      }
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
    _groupNameController.dispose();
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
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        displayName,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        username.startsWith('@') ? username : "@$username",
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      onTap: () => _toggleSelection(id, displayName, username),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = context.watch<ChatSearchController>();
    final inboxState = context.watch<InboxController>();
    final bool isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            return SlideTransition(
              position: tween.animate(animation),
              child: child,
            );
          },
          child: _isSearchOpen
              ? SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Name, username or number",
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 15,
                      ),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<ChatSearchController>().queryUsers(
                                  "",
                                );
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
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
              : Text(
                  'Select Contacts',
                  style: TextStyle(
                    letterSpacing: 0.5,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  key: const ValueKey('title'),
                ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  context.read<ChatSearchController>().queryUsers("");
                }
              });
            },
            icon: Icon(
              _isSearchOpen ? Icons.close : Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '${_selectedContacts.length} selected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: isSearching
                ? (searchState.isSearchLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : searchState.contactSearchResults.isEmpty
                      ? Center(
                          child: Text(
                            "No users found (try entering at least 3 characters to search)",
                            textAlign: TextAlign.center,
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
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 20,
                            bottom: 8,
                          ),
                          child: Text(
                            "Selected Contacts",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
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
                            .where(
                              (thread) =>
                                  !thread.isGroup &&
                                  !_selectedContacts.containsKey(thread.id),
                            )
                            .map(
                              (thread) => _buildContactTile(
                                id: thread.id,
                                displayName: thread.title,
                                username: thread.username ?? "",
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedContacts.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 4,
              child: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                context.read<GroupController>().setContacts(_selectedContacts);

                showModalBottomSheet(
                  backgroundColor: Colors.transparent,
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (BuildContext bottomSheetContext) {
                    return Consumer<GroupController>(
                      builder: (modalContext, groupState, child) {
                        return ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.85),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(
                                    bottomSheetContext,
                                  ).viewInsets.bottom,
                                  left: 16,
                                  right: 16,
                                  top: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'New Group',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                      controller: _groupNameController,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: 'Enter group name',
                                        hintStyle: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        FilledButton(
                                          onPressed: groupState.isLoading
                                              ? null
                                              : () async {
                                                  final groupName =
                                                      _groupNameController.text
                                                          .trim();
                                                  if (groupName.isEmpty) return;

                                                  final memberIds =
                                                      _selectedContacts.keys
                                                          .toList();

                                                  final rootNavigator =
                                                      Navigator.of(context);

                                                  final newGroup =
                                                      await modalContext
                                                          .read<
                                                            GroupController
                                                          >()
                                                          .createGroup(
                                                            groupName:
                                                                groupName,
                                                            memberIds:
                                                                memberIds,
                                                          );

                                                  if (newGroup != null) {
                                                    if (!context.mounted)
                                                      return;

                                                    context
                                                        .read<InboxController>()
                                                        .loadInbox();

                                                    Navigator.of(
                                                      bottomSheetContext,
                                                    ).pop();

                                                    _groupNameController
                                                        .clear();

                                                    rootNavigator
                                                        .pushReplacement(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => ChatPage(
                                                                  isNew: true,
                                                                  chatUserId:
                                                                      newGroup
                                                                          .id,
                                                                  displayName:
                                                                      newGroup
                                                                          .name,
                                                                  isGroup: true,
                                                                ),
                                                          ),
                                                        );
                                                  } else {
                                                    if (!context.mounted)
                                                      return;
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to create group',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: groupState.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Text(
                                                  'Create',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : null,
    );
  }
}
