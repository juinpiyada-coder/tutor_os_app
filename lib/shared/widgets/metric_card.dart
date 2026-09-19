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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorderSubtle(context), width: 1),
        boxShadow: AppTheme.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.getTextMuted(context),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceSubtle(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 14, color: AppTheme.electricCobalt),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextHeading(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (footerIcon != null) ...[
                Icon(footerIcon, size: 12, color: footerColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  footerText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: footerColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
