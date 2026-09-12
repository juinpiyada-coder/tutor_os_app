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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: AppTheme.level1Shadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Monogram Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  calculatedInitials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.surfaceWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & Verification
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
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.electricCobalt, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Institute ID: $idCode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              // Switch Button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz, color: AppTheme.textBody, size: 20),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Meta Tray
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.canvasBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.electricCobalt,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.electricCobalt, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
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
