import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mob/pages/settings_page.dart';
import 'package:mob/controllers/chat.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _isSearchOpen;
  int _page = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSearchOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatController>().loadInbox();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required double width,
  }) {
    final isSelected = _page == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _page = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.blueAccent : Colors.black54,
                size: 24,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.decelerate,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.blueAccent : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGlassNavigationBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: const Color.fromARGB(40, 255, 255, 255),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 3;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        left: _page * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_filled,
                            label: 'Home',
                            width: tabWidth,
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.call_outlined,
                            activeIcon: Icons.call,
                            label: 'Call',
                            width: tabWidth,
                          ),
                          _buildNavItem(
                            index: 2,
                            icon: Icons.settings_outlined,
                            activeIcon: Icons.settings,
                            label: 'Settings',
                            width: tabWidth,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHomeTab() {
    final chatState = context.watch<ChatController>();

    return RefreshIndicator(
      onRefresh: () => chatState.loadInbox(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                enabled: true,
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: const Color.fromARGB(78, 255, 255, 255)),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 15),
            leading: const Icon(Icons.security, color: Colors.black87),
            title: AnimatedSwitcher(
              switchInCurve: Curves.decelerate,
              switchOutCurve: Curves.decelerate,
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final tween = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
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
                        key: const ValueKey('search'),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    )
                  : const Text(
                      'Elephant',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
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
                    if (!_isSearchOpen) _searchController.clear();
                  });
                },
                icon: Icon(
                  _isSearchOpen ? Icons.close : Icons.search,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          chatState.inbox.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text("No conversations found", style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ),
                )
              : SliverList.builder(
                  itemCount: chatState.inbox.length,
                  itemBuilder: (context, index) {
                    final thread = chatState.inbox[index];

                    return InkWell(
                      onTap: () {
                        context.read<ChatController>().openChat(thread.chatUserId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatUserId: thread.chatUserId,
                              displayName: thread.displayName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundColor: Color(0xFFD6E4FF),
                              child: Icon(Icons.person, color: Color(0xFF1890FF)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    thread.displayName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    thread.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: thread.unreadCount > 0 ? Colors.black87 : Colors.black54,
                                      fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${thread.lastMessageTime.hour}:${thread.lastMessageTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                                if (thread.unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: const BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${thread.unreadCount}",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          SliverList(
            delegate: SliverChildListDelegate([const SizedBox(height: 120)]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: IndexedStack(
        index: _page,
        children: [
          buildHomeTab(),
          const Center(child: Text("Call Page Content")),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: buildGlassNavigationBar(),
    );
  }
}