import 'package:flutter/material.dart';
import 'package:mobile/themes/app_themes.dart';
import 'package:mobile/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Glass effect color
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a Theme',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65, // Makes the cards taller like a phone
                  children: [
                    _ThemeCard(
                      title: 'Frost',
                      type: ThemeType.frost,
                      themeData: AppThemes.frost,
                      isSelected: themeProvider.currentTheme == ThemeType.frost,
                    ),
                    _ThemeCard(
                      title: 'Aura',
                      type: ThemeType.aura,
                      themeData: AppThemes.aura,
                      isSelected: themeProvider.currentTheme == ThemeType.aura,
                    ),
                    _ThemeCard(
                      title: 'Onyx',
                      type: ThemeType.onyx,
                      themeData: AppThemes.onyx,
                      isSelected: themeProvider.currentTheme == ThemeType.onyx,
                    ),
                    _ThemeCard(
                      title: 'Nebula',
                      type: ThemeType.nebula,
                      themeData: AppThemes.nebula,
                      isSelected:
                          themeProvider.currentTheme == ThemeType.nebula,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final ThemeType type;
  final ThemeData themeData;
  final bool isSelected;

  const _ThemeCard({
    required this.title,
    required this.type,
    required this.themeData,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ThemeProvider>().setTheme(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: themeData.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? themeData.colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ]
              : [const BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              // Mock Chat bubble
              Positioned(
                right: 16,
                top: 60,
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Mock Glass AppBar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  color: themeData.colorScheme.surface,
                ),
              ),
              // Mock Glass NavBar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  color: themeData.colorScheme.surface,
                ),
              ),
              // Theme Title
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
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
}
