import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: AppTheme.level3Shadow,
        border: const Border(top: BorderSide(color: AppTheme.surfaceSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home', context),
          _buildNavItem(1, Icons.people_alt_rounded, 'Students', context),
          // Center Action FAB
          GestureDetector(
            onTap: () {}, // Center action
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.electricCobalt,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x592563EB), // 35% opacity
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          _buildNavItem(3, Icons.class_rounded, 'Batches', context),
          _buildNavItem(4, Icons.menu_rounded, 'More', context),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, BuildContext context) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppTheme.electricCobalt : AppTheme.textMuted;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
