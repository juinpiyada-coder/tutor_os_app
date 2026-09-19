import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../network/api_service.dart';
import '../../shared/widgets/avatar_image_helper.dart';
import '../../shared/widgets/theme_toggle_switch.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/admin/screens/settings/settings_screen.dart';
import 'universal_search_modal.dart';
import 'universal_notification_modal.dart';

class UniversalOwnerHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onRefresh;
  final String? title;
  final String? subtitle;
  final bool showSearch;
  final bool showNotifications;
  final List<Widget>? customActions;
  final PreferredSizeWidget? bottom;

  const UniversalOwnerHeader({
    super.key,
    this.onOpenDrawer,
    this.onRefresh,
    this.title,
    this.subtitle,
    this.showSearch = true,
    this.showNotifications = true,
    this.customActions,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(74 + (bottom?.preferredSize.height ?? 0.0));

  String _getRoleDisplayName(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return 'SUPER ADMIN';
      case 'ADMIN':
        return 'OWNER / ADMIN';
      case 'SOLO_TUTOR':
        return 'SOLO TUTOR';
      case 'BRANCH_ADMIN':
        return 'BRANCH ADMIN';
      case 'TEACHER':
        return 'TEACHER';
      default:
        return role.toUpperCase();
    }
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return const Color(0xFF6366F1);
      case 'ADMIN':
        return AppTheme.primaryNavy;
      case 'SOLO_TUTOR':
        return const Color(0xFF0D9488);
      case 'BRANCH_ADMIN':
        return const Color(0xFF0284C7);
      case 'TEACHER':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.electricCobalt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 900;
    final canPop = Navigator.canPop(context);

    final userName = ApiService.currentFirstName != null && ApiService.currentFirstName!.isNotEmpty
        ? ApiService.currentFirstName!
        : 'Owner';
    final role = ApiService.currentRole ?? 'ADMIN';
    final instituteName = ApiService.currentInstituteName ?? 'TutorOS Academy';

    final effectiveTitle = title ?? 'Hello, $userName 👋';
    final effectiveSubtitle = subtitle ?? instituteName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.getBorderSubtle(context),
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back Button (if pushed) or Drawer Button (Mobile/Tablet)
                if (canPop && onOpenDrawer == null) ...[
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.getBorderSubtle(context)),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.getTextHeading(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (onOpenDrawer != null && !isDesktop) ...[
                  InkWell(
                    onTap: onOpenDrawer,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfaceSubtle : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.getBorderSubtle(context)),
                      ),
                      child: Icon(
                        Icons.menu_rounded,
                        color: AppTheme.getTextHeading(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

            // Brand & User Context Title
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          effectiveTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isDesktop ? 16.5 : 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getTextHeading(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor(role).withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getRoleBadgeColor(role).withValues(alpha: isDark ? 0.5 : 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getRoleDisplayName(role),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isDark ? Colors.white : _getRoleBadgeColor(role),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.successText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          effectiveSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Universal Search Trigger Bar (Expanded on Desktop, Icon on Mobile)
            if (showSearch) ...[
              if (isDesktop || isTablet)
                InkWell(
                  onTap: () => UniversalSearchModal.show(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: isDesktop ? 260 : 180,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceSubtle(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.getBorderSubtle(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 18, color: AppTheme.getTextMuted(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quick search...',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppTheme.getTextMuted(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceCard(context),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.getBorderSubtle(context)),
                          ),
                          child: Text(
                            '⌘K',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextMuted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Search (Ctrl + K)',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurfaceSubtle(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.getBorderSubtle(context)),
                    ),
                    child: Icon(Icons.search_rounded, size: 18, color: AppTheme.getTextHeading(context)),
                  ),
                  onPressed: () => UniversalSearchModal.show(context),
                ),
              const SizedBox(width: 8),
            ],

            // Day / Night Theme Toggle Switch
            const ThemeToggleSwitch(width: 58, height: 30),
            const SizedBox(width: 6),

            // Refresh Button
            if (onRefresh != null) ...[
              IconButton(
                tooltip: 'Refresh Data',
                icon: Icon(Icons.refresh_rounded, color: AppTheme.getTextHeading(context), size: 20),
                onPressed: onRefresh,
              ),
            ],

            // Notifications
            if (showNotifications) ...[
              IconButton(
                tooltip: 'Notifications',
                icon: Stack(
                  children: [
                    Icon(Icons.notifications_none_rounded, color: AppTheme.getTextHeading(context), size: 22),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.urgentText,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () => UniversalNotificationModal.show(context),
              ),
            ],

            // Custom Action Buttons if provided
            if (customActions != null) ...?customActions,

            // User Profile Avatar & Quick Menu
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Account Menu',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppTheme.getBorderSubtle(context)),
              ),
              color: AppTheme.getSurfaceCard(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.electricCobalt.withValues(alpha: 0.5), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppTheme.electricCobalt.withValues(alpha: 0.15),
                  backgroundImage: AvatarImageHelper.getImageProvider(ApiService.currentAvatarUrl),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: (AvatarImageHelper.getImageProvider(ApiService.currentAvatarUrl) == null)
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.electricCobalt,
                          ),
                        )
                      : null,
                ),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.getTextHeading(context),
                        ),
                      ),
                      Text(
                        instituteName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.getTextMuted(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 18, color: AppTheme.getTextHeading(context)),
                      const SizedBox(width: 10),
                      Text('Settings & Profile', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.getTextHeading(context))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: AppTheme.getTextHeading(context)),
                      const SizedBox(width: 10),
                      Text('Universal Search', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.getTextHeading(context))),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: AppTheme.urgentText),
                      const SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.urgentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                } else if (val == 'search') {
                  UniversalSearchModal.show(context);
                } else if (val == 'logout') {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: AppTheme.getSurfaceCard(context),
                      title: Text(
                        'Confirm Logout',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextHeading(context),
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to log out of TutorOS?',
                        style: GoogleFonts.inter(color: AppTheme.getTextBody(context)),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.getBorderSubtle(context)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.getTextMuted(context))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.urgentText,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.pop(dCtx);
                            ApiService.logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
        if (bottom != null) ...[
          const SizedBox(height: 6),
          bottom!,
        ],
      ],
    ),
  ),
);
  }
}
