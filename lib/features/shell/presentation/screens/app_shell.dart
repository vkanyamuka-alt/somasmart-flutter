import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';
import '../../../../core/widgets/floating_ask_me_button.dart';

/// Main App Shell hosting the top bar, persistent 5-tab bottom navigation, and floating "Ask me" button.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      appBar: const AppTopBar(),
      body: Stack(
        children: [
          // Current Tab Viewport
          Positioned.fill(
            child: navigationShell,
          ),

          // Floating "Ask me" Button (sparkles pill) positioned right above bottom nav
          const Positioned(
            right: 16,
            bottom: 14,
            child: FloatingAskMeButton(),
          ),
        ],
      ),
      bottomNavigationBar: SomaSmartBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
      ),
    );
  }
}
