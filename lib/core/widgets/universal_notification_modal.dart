import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../features/admin/services/communications_service.dart';
import '../../features/admin/screens/communications/communications_screen.dart';
import '../../features/admin/screens/operations/operations_screen.dart';
import '../../features/admin/screens/finance/finance_hub_screen.dart';
import '../../features/admin/screens/assessments/assessments_screen.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String category; // 'ACADEMIC', 'FINANCE', 'SYSTEM', 'EXAM', 'ATTENDANCE'
  final DateTime timestamp;
  bool isRead;
  final String? route;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.route,
  });
}

class UniversalNotificationModal extends StatefulWidget {
  const UniversalNotificationModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const UniversalNotificationModal(),
    );
  }

  @override
  State<UniversalNotificationModal> createState() => _UniversalNotificationModalState();
}

class _UniversalNotificationModalState extends State<UniversalNotificationModal> {
  bool _isLoading = true;
  String _activeFilter = 'All';
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final broadcasts = await CommunicationsService.getBroadcasts();
      final List<NotificationItem> items = [];

      // Convert remote broadcasts to notifications
      for (final b in broadcasts) {
        items.add(NotificationItem(
          id: 'b_${b['message_id'] ?? b['id'] ?? items.length}',
          title: b['subject'] ?? b['title'] ?? 'Notice',
          message: b['body'] ?? b['content'] ?? '',
          category: 'SYSTEM',
          timestamp: DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: (b['status']?.toString().toUpperCase() == 'READ'),
          route: 'COMMUNICATIONS',
        ));
      }

      // Add default system operational notifications if empty or to augment
      if (items.isEmpty) {
        items.addAll([
          NotificationItem(
            id: 'n_1',
            title: 'Welcome to TutorOS Academy',
            message: 'Your multi-tenant workspace is fully active and ready for classes.',
            category: 'SYSTEM',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: false,
            route: 'COMMUNICATIONS',
          ),
          NotificationItem(
            id: 'n_2',
            title: 'Fee Installments Due',
            message: 'Pending fee invoices require verification in Finance Hub.',
            category: 'FINANCE',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            isRead: false,
            route: 'FINANCE',
          ),
          NotificationItem(
            id: 'n_3',
            title: 'New Class Schedule Published',
            message: 'Timetables for active batches have been updated for this week.',
            category: 'ACADEMIC',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
            route: 'OPERATIONS',
          ),
          NotificationItem(
            id: 'n_4',
            title: 'Assessment Results Ready',
            message: 'Unit test evaluation for active batches is complete.',
            category: 'EXAM',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            isRead: true,
            route: 'ASSESSMENTS',
          ),
        ]);
      }

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  void _markAsRead(NotificationItem item) {
    setState(() {
      item.isRead = true;
    });

    if (item.route != null) {
      Navigator.pop(context);
      _navigateToItem(item.route!);
    }
  }

  void _navigateToItem(String route) {
    Widget? screen;
    switch (route) {
      case 'COMMUNICATIONS':
        screen = const CommunicationsScreen();
        break;
      case 'FINANCE':
        screen = const FinanceHubScreen();
        break;
      case 'OPERATIONS':
        screen = const OperationsScreen();
        break;
      case 'ASSESSMENTS':
        screen = const AssessmentsScreen();
        break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'FINANCE':
        return Icons.account_balance_wallet_outlined;
      case 'ACADEMIC':
        return Icons.school_outlined;
      case 'EXAM':
        return Icons.assignment_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'FINANCE':
        return const Color(0xFF10B981);
      case 'ACADEMIC':
        return AppTheme.electricCobalt;
      case 'EXAM':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filtered = _activeFilter == 'All'
        ? _notifications
        : (_activeFilter == 'Unread'
            ? _notifications.where((n) => !n.isRead).toList()
            : _notifications.where((n) => n.category == _activeFilter).toList());

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.getBorderSubtle(context), width: 1),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getBorderSubtle(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextHeading(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16, color: AppTheme.electricCobalt),
                    label: Text(
                      'Mark all as read',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.electricCobalt,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filter Badges
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('All', _notifications.length),
                const SizedBox(width: 8),
                _buildFilterChip('Unread', unreadCount),
                const SizedBox(width: 8),
                _buildFilterChip('ACADEMIC', _notifications.where((n) => n.category == 'ACADEMIC').length),
                const SizedBox(width: 8),
                _buildFilterChip('FINANCE', _notifications.where((n) => n.category == 'FINANCE').length),
                const SizedBox(width: 8),
                _buildFilterChip('EXAM', _notifications.where((n) => n.category == 'EXAM').length),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // List / Empty State / Loader
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
                : (filtered.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: AppTheme.getBorderSubtle(context).withValues(alpha: 0.5)),
                        itemBuilder: (ctx, idx) {
                          final item = filtered[idx];
                          return _buildNotificationTile(context, item);
                        },
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    final displayLabel = label == 'ACADEMIC' ? 'Academics' : (label == 'FINANCE' ? 'Finance' : (label == 'EXAM' ? 'Exams' : label));

    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricCobalt : AppTheme.getSurfaceSubtle(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.electricCobalt : AppTheme.getBorderSubtle(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.getTextHeading(context),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.getBorderSubtle(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.getTextMuted(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationItem item) {
    final catColor = _getCategoryColor(item.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _markAsRead(item),
      child: Container(
        color: item.isRead
            ? Colors.transparent
            : (isDark
                ? AppTheme.darkSurfaceSubtle.withValues(alpha: 0.4)
                : AppTheme.softBlue.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getCategoryIcon(item.category), color: catColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                            color: AppTheme.getTextHeading(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.getTextMuted(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: item.isRead ? AppTheme.getTextMuted(context) : AppTheme.getTextBody(context),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Read / Unread Indicator Dot
            if (!item.isRead) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.electricCobalt,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceSubtle(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_off_outlined, size: 32, color: AppTheme.getTextMuted(context)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextHeading(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeFilter == 'All'
                  ? "You're all caught up! There are no notifications right now."
                  : 'No $_activeFilter notifications found.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.getTextMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
