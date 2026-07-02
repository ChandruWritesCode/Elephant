import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile/controllers/chat.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/widgets/custom_cards.dart';
import 'package:provider/provider.dart';
import 'new_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _isSearchOpen;
  int _page = 1;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSearchOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatController = context.read<ChatController>();
      final authService = AuthService();
      final token = await authService.getToken();

      if (token != null) {
        // Initialize WebSocket session immediately on app load
        await chatController.initSession(token);
        // Load the initial inbox
        await chatController.loadInbox();
      }
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
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? const Color(0xFF1890FF) : Colors.black54,
                  size: 24,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.decelerate,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF1890FF)
                          : Colors.black54,
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
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1890FF).withValues(alpha: 0.03),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 3;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        left: _page * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1890FF,
                                  ).withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
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
                            icon: Icons.amp_stories_outlined,
                            activeIcon: Icons.amp_stories,
                            label: 'Story',
                            width: tabWidth,
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.chat_bubble_outline,
                            activeIcon: Icons.chat_bubble,
                            label: 'Chat',
                            width: tabWidth,
                          ),
                          _buildNavItem(
                            index: 2,
                            icon: Icons.call_outlined,
                            activeIcon: Icons.call,
                            label: 'Call',
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

  Widget buildHomeTab(ChatController chatState) {
    return RefreshIndicator(
      color: const Color(0xFF1890FF),
      onRefresh: () => chatState.loadInbox(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                enabled: true,
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 10.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFD6E4FF),
                child: Icon(Icons.person, color: Color(0xFF1890FF), size: 18),
              ),
            ),
            leadingWidth: 52,
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
                        key: const ValueKey('search'),
                        autofocus: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: const TextStyle(color: Colors.black38),
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
                    if (!_isSearchOpen) _searchController.clear();
                  });
                },
                icon: Icon(
                  _isSearchOpen ? Icons.close : Icons.search,
                  color: Colors.black87,
                ),
              ),
              if (!_isSearchOpen)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  onPressed: () {},
                ),
              const SizedBox(width: 4),
            ],
          ),

          chatState.inbox.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No conversations yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: chatState.inbox.length,
                  itemBuilder: (context, index) {
                    final thread = chatState.inbox[index];
                    return CustomChatCard(conversation: thread);
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
    final chatState = context.watch<ChatController>();

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: IndexedStack(
        index: _page,
        children: [
          const Center(
            child: Text(
              "No stories available",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
          buildHomeTab(chatState),
          const Center(
            child: Text(
              "No recent calls",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ],
      ),
      floatingActionButton: _page == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: FloatingActionButton(
                heroTag: "fab_pen",
                backgroundColor: const Color(0xFF1890FF),
                child: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewChatPage()),
                  );
                },
              ),
            )
          : null,
      bottomNavigationBar: buildGlassNavigationBar(),
    );
  }
}
