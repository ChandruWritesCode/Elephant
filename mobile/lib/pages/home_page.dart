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
                color: Colors.black87,
                size: 24,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.decelerate,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  Widget _buildGlassNavigationBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 60,
              color: const Color.fromARGB(78, 255, 255, 255),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 3;

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.decelerate,
                        left: _page * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(123, 255, 255, 255),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                  ).withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 0),
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

  Widget _buildHomeTab() {
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
          leading: const Icon(Icons.security),
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
                ? TextField(
                    controller: _searchController,
                    key: const ValueKey('search'),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  )
                : const Text(
                    'Elephant',
                    style: TextStyle(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w400,
                    ),
                    key: ValueKey('title'),
                  ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearchOpen = !_isSearchOpen;
                });
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        SliverList.builder(
          itemCount: 20,
          itemBuilder: (context, index) => chatCard(),
        ),
        SliverList(delegate: SliverChildListDelegate([SizedBox(height: 100)])),
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
          _buildHomeTab(),
          const Center(child: Text("Call Page Content")),
          SettingsPage(),
        ],
      ),

      bottomNavigationBar: _buildGlassNavigationBar(),
    );
  }
}
