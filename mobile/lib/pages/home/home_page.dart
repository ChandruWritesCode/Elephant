import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile/controllers/chat_controller.dart';
import 'package:mobile/pages/settings/settings_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/widgets/home_page_widgets.dart';
import 'package:provider/provider.dart';
import '../new chat/new_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late bool _isSearchOpen;
  int _page = 1;
  final _searchController = TextEditingController();
  final Set<String> _selectedChatIds = {};

  late final ScrollController _scrollController;
  bool _isFabVisible = true;

  bool get _isSelectionMode => _selectedChatIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _isSearchOpen = false;

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatController = context.read<ChatController>();

      final token = await AuthService().getToken();

      if (!mounted) return;

      if (token != null) {
        await chatController.initSession();
        chatController.loadInbox();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required double width,
  }) {
    final theme = Theme.of(context);
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
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
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

  Widget buildGlassNavigationBar({Key? key}) {
    final theme = Theme.of(context);
    return SafeArea(
      key: key,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.04),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.03),
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
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 20,
                                  // offset: const Offset(0, 0),
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
    final theme = Theme.of(context);
    final isOffline = chatState.isOffline;

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _isSelectionMode ? () async {} : () => chatState.loadInbox(),
      child: CustomScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
                child: Container(color: theme.colorScheme.surface),
              ),
            ),
            leading: _isSelectionMode
                ? null
                : InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    child: Hero(
                      tag: 'User Profile',
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          top: 10.0,
                          bottom: 10.0,
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
            leadingWidth: 52,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSelectionMode
                  ? Text(
                      '${_selectedChatIds.length} Selected',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    )
                  : AnimatedSwitcher(
                      switchInCurve: Curves.decelerate,
                      switchOutCurve: Curves.decelerate,
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        final tween = Tween<Offset>(
                          begin: const Offset(0.5, 0.0),
                          end: Offset.zero,
                        );
                        final offsetAnimation = tween.animate(animation);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                      child: _isSearchOpen
                          ? SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _searchController,
                                key: const ValueKey('search'),
                                autofocus: true,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search conversations...',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.08),
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
                          : Text(
                              'Elephant',
                              style: TextStyle(
                                letterSpacing: 0.5,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              key: const ValueKey('title'),
                            ),
                    ),
            ),
            actions: [
              _isSelectionMode
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                          if (!_isSearchOpen) _searchController.clear();
                        });
                      },
                      icon: Icon(
                        _isSearchOpen ? Icons.close : Icons.search,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
              if (!_isSearchOpen)
                !_isSelectionMode
                    ? PopupMenuButton<String>(
                        iconColor: theme.colorScheme.onSurface,
                        color: theme.scaffoldBackgroundColor,
                        onSelected: (String value) {},
                        borderRadius: BorderRadius.circular(20),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'starred',
                            child: Text('Starred messages'),
                          ),
                          const PopupMenuItem(
                            value: 'read all',
                            child: Text('Read all'),
                          ),
                        ],
                      )
                    : PopupMenuButton<String>(
                        iconColor: theme.colorScheme.onSurface,
                        onSelected: (String value) {
                          switch (value) {
                            case 'Select all':
                              setState(() {
                                for (final thread in chatState.inbox) {
                                  _selectedChatIds.add(thread.id);
                                }
                              });
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Select all',
                            child: Text("Select all"),
                          ),
                          const PopupMenuItem(
                            value: 'Favorite',
                            child: Text("Favorite"),
                          ),
                          const PopupMenuItem(
                            value: 'Read',
                            child: Text("Read"),
                          ),
                          const PopupMenuItem(
                            value: 'Delete',
                            child: Text("Delete"),
                          ),
                        ],
                      ),
              const SizedBox(width: 4),
            ],
          ),
          if (isOffline)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.redAccent,
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                child: const Text(
                  "You are offline. Showing cached chats.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          chatState.inbox.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No conversations yet",
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: chatState.inbox.length,
                  itemBuilder: (context, index) {
                    final thread = chatState.inbox[index];

                    final bool isSelected = _selectedChatIds.contains(
                      thread.id,
                    );

                    return CustomChatCard(
                      isSelectionMode: _isSelectionMode,
                      conversation: thread,
                      isSelected: isSelected,
                      onLongPress: () {
                        if (!_isSearchOpen) {
                          setState(() {
                            _selectedChatIds.add(thread.id);
                          });
                        }
                      },
                      onTapInSelection: () {
                        setState(() {
                          if (_selectedChatIds.contains(thread.id)) {
                            _selectedChatIds.remove(thread.id);
                          } else {
                            _selectedChatIds.add(thread.id);
                          }
                        });
                      },
                    );
                  },
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatController>();
    final theme = Theme.of(context);
    return PopScope(
      canPop: _selectedChatIds.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _selectedChatIds.clear();
        });
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: IndexedStack(
          index: _page,
          children: [
            Center(
              child: Text(
                "No stories available",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
            buildHomeTab(chatState),
            Center(
              child: Text(
                "No recent calls",
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _page == 1
            ? AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: (_isFabVisible && !_isSelectionMode)
                    ? Offset.zero
                    : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (_isFabVisible && !_isSelectionMode) ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.5),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NewChatPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          transitionBuilder: (child, animation) {
            final tween = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            );
            final offsetAnimation = tween.animate(animation);
            return SlideTransition(position: offsetAnimation, child: child);
          },
          child: _isSelectionMode
              ? const SizedBox.shrink(key: ValueKey('nav_hidden'))
              : buildGlassNavigationBar(key: const ValueKey('nav_visible')),
        ),
      ),
    );
  }
}
