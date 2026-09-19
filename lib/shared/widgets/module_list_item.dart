import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
        ),
      ),
    );
  }
}

class ModuleListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final StatusBadge? badge;
  final VoidCallback? onTap;

  const ModuleListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Leading Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10), // rounded-xl
              ),
              child: Icon(icon, color: const Color(0xFF1E40AF), size: 20),
            ),
            const SizedBox(width: 16),
            // Text Lockup
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            // Trailing Badges and Chevron
            if (badge != null) ...[
              badge!,
              const SizedBox(width: 12),
            ],
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class ModuleGroup extends StatelessWidget {
  final List<ModuleListItem> items;

  const ModuleGroup({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorderSubtle(context), width: 1),
        boxShadow: AppTheme.getCardShadow(context),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index < items.length - 1)
                Divider(height: 1, thickness: 1, color: AppTheme.getBorderSubtle(context), indent: 72),
            ],
          );
        }),
      ),
    );
  }
}
