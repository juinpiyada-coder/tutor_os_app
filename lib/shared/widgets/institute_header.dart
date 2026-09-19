import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_service.dart';

class InstituteHeader extends StatelessWidget {
  final String? initials;
  final String? instituteName;
  final String? instituteId;
  final String statusText;

  const InstituteHeader({
    super.key,
    this.initials,
    this.instituteName,
    this.instituteId,
    this.statusText = '',
  });

  @override
  Widget build(BuildContext context) {
    final name = instituteName ?? ApiService.currentInstituteName ?? '';
    final idCode = instituteId ?? ApiStyleFormat.getInstituteIdCode();
    final calculatedInitials = initials ?? ApiStyleFormat.getInitials(name);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.getBorderSubtle(context), width: 1),
        boxShadow: AppTheme.getCardShadow(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  calculatedInitials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.surfaceWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.getTextHeading(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppTheme.electricCobalt, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Institute ID: $idCode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.getTextMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceSubtle(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.swap_horiz, color: AppTheme.getTextHeading(context), size: 20),
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkAcademicBg.withValues(alpha: 0.4) : AppTheme.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText.isNotEmpty ? statusText : 'Active & Online',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.white : AppTheme.primaryNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: isDark ? Colors.white70 : AppTheme.primaryNavy),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ApiStyleFormat {
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String getInstituteIdCode() {
    if (ApiService.currentInstituteCode != null && ApiService.currentInstituteCode!.isNotEmpty) {
      return ApiService.currentInstituteCode!;
    }
    if (ApiService.currentTenantId != null) {
      return 'INST-${ApiService.currentTenantId.toString().padLeft(3, '0')}';
    }
    return '';
  }
}
