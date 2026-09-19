import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'quick_action_sheet.dart';

class OwnerBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMenuTap;
  final VoidCallback? onActionTap;

  const OwnerBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onMenuTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map selected module index to 5-destination bottom bar
    int navIndex;
    if (selectedIndex == 0) {
      navIndex = 0; // Home
    } else if (selectedIndex == 1) {
      navIndex = 1; // Academics
    } else if (selectedIndex == 2) {
      navIndex = 3; // Directory
    } else {
      navIndex = 4; // Menu / Other modules
    }

    return NavigationBar(
      selectedIndex: navIndex,
      onDestinationSelected: (int index) {
        if (index == 0) {
          onTabSelected(0);
        } else if (index == 1) {
          onTabSelected(1);
        } else if (index == 2) {
          // Direct Action Button in Navigation Bar
          if (onActionTap != null) {
            onActionTap!();
          } else {
            QuickActionSheet.show(context);
          }
        } else if (index == 3) {
          onTabSelected(2);
        } else if (index == 4) {
          onMenuTap();
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Batches',
        ),
        NavigationDestination(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.electricCobalt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
          selectedIcon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppTheme.electricCobalt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
          ),
          label: 'Action',
        ),
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Students',
        ),
        const NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: 'More',
        ),
      ],
    );
  }
}
