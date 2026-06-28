import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mob/pages/settings_page.dart';
import 'package:mob/widgets/custom_cards.dart';

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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
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
            // LOWERED BLUR: from 20 to 12
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                // LOWERED OPACITY: from 150 to 40
                color: const Color.fromARGB(40, 255, 255, 255),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  // LOWERED BORDER OPACITY: from 0.6 to 0.3
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
                              // Using a highly transparent white for the active tab pill
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
    return CustomScrollView(
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
                        // Kept search background subtle
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
        SliverList.builder(
          itemCount: 20,
          itemBuilder: (context, index) => chatCard(context),
        ),
        SliverList(
          delegate: SliverChildListDelegate([const SizedBox(height: 120)]),
        ),
      ],
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
