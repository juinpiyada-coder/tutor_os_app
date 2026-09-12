import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String footerText;
  final bool isPositive;
  final bool isWarning;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.footerText,
    this.isPositive = true,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    Color footerColor = AppTheme.textMuted;
    IconData? footerIcon;

    if (isWarning) {
      footerColor = const Color(0xFFD97706); // Warning Orange
    } else if (isPositive) {
      footerColor = AppTheme.successText;
      footerIcon = Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14), // rounded-xl
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: AppTheme.level1Shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Zone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Icon(icon, size: 16, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          // Center Value
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          // Bottom Status Footer
          Row(
            children: [
              if (footerIcon != null) ...[
                Icon(footerIcon, size: 12, color: footerColor),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  footerText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: footerColor,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
