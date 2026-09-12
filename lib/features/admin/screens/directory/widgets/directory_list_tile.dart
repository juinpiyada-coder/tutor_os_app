import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/avatar_image_helper.dart';

class DirectoryListTile extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String status;
  final String email;
  final String phone;
  final String subtitle1; // e.g. Batch or Role
  final String? subtitle2; // e.g. Department
  final String? location; // e.g. Current Location / Address
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DirectoryListTile({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.email,
    required this.phone,
    required this.subtitle1,
    this.subtitle2,
    this.location,
    this.avatarUrl,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
    final isActive = status.toUpperCase() == 'ACTIVE';
    final imageProvider = AvatarImageHelper.getImageProvider(avatarUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: AppTheme.level1Shadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isActive ? AppTheme.surfaceSubtle : const Color(0xFFF1F5F9),
              backgroundImage: imageProvider,
              onBackgroundImageError: imageProvider != null ? (exception, stackTrace) {} : null,
              child: imageProvider == null ? Text(
                initials,
                style: TextStyle(
                  color: isActive ? AppTheme.electricCobalt : AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ) : null,
            ),
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$firstName $lastName',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successBg : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isActive ? AppTheme.successText : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle2 != null ? '$subtitle1 • $subtitle2' : subtitle1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (location != null && location!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.electricCobalt),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location!,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textBody, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _buildContactItem(Icons.email_outlined, email),
                      _buildContactItem(Icons.phone_outlined, phone),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  onEdit!();
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (onEdit != null)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppTheme.electricCobalt),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.urgentText),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.urgentText)),
                      ],
                    ),
                  ),
                PopupMenuItem<String>(
                  value: isActive ? 'deactivate' : 'activate',
                  child: Text(isActive ? 'Deactivate' : 'Activate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
