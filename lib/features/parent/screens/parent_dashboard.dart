import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/module_list_item.dart';
import '../../../shared/widgets/theme_toggle_switch.dart';
import '../../../shared/widgets/avatar_image_helper.dart';
import '../../../../core/network/api_service.dart';
import '../../auth/screens/login_screen.dart';
import '../services/parent_dashboard_service.dart';
import 'parent_children_screen.dart';
import 'parent_academics_screen.dart';
import 'parent_fees_screen.dart';
import 'parent_chat_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final result = await ParentDashboardService.getParentDashboardData(
      studentId: _selectedChild != null ? _selectedChild!['student_id'] : null,
    );
    final kids = (result['children'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    if (mounted) {
      setState(() {
        _data = result;
        _children = kids;
        if (_selectedChild == null && _children.isNotEmpty) {
          _selectedChild = _children.first;
        }
        _isLoading = false;
      });
    }
  }

  Widget _buildTabBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeDashboardTab();
      case 1:
        return ParentChildrenScreen(
          selectedChild: _selectedChild,
          onChildChanged: (child) {
            setState(() => _selectedChild = child);
            _loadDashboardData();
          },
        );
      case 2:
        return ParentAcademicsScreen(selectedChild: _selectedChild);
      case 3:
        return ParentFeesScreen(selectedChild: _selectedChild);
      case 4:
        return ParentChatScreen(selectedChild: _selectedChild);
      default:
        return _buildHomeDashboardTab();
    }
  }

  Widget _buildHomeDashboardTab() {
    final currentChildName = _selectedChild != null ? (_selectedChild!['name'] ?? '') : '';
    final currentChildInitials = _selectedChild != null ? (_selectedChild!['avatar_initials'] ?? '') : '';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            
            // Child Selector Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderSubtle, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0F1C4C),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.softBlue,
                    backgroundImage: AvatarImageHelper.getImageProvider(_selectedChild?['avatar_url']),
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: (AvatarImageHelper.getImageProvider(_selectedChild?['avatar_url']) == null)
                        ? Text(currentChildInitials, style: const TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Viewing progress for', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                        if (_children.isNotEmpty)
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedChild != null ? _selectedChild!['student_id'] : _children.first['student_id'],
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryNavy),
                              dropdownColor: AppTheme.surfaceWhite,
                              isDense: true,
                              items: _children.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c['student_id'] as int,
                                  child: Text(c['name'] ?? '', style: const TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.w800, fontSize: 16)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  final child = _children.firstWhere((c) => c['student_id'] == val);
                                  setState(() => _selectedChild = child);
                                  _loadDashboardData();
                                }
                              },
                            ),
                          )
                        else
                          Text(currentChildName, style: const TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ),
                  const ThemeToggleSwitch(width: 58, height: 30),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Notices',
                    icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryNavy),
                    onPressed: () => setState(() => _currentIndex = 4),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out of TutorOS?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.urgentText,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ApiService.logout();
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Responsive Metrics Grid (4 columns on desktop/tablet, 2 columns on mobile)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final card1 = MetricCard(
                  title: 'Attendance Rate',
                  value: _data['attendanceRate'] ?? '',
                  icon: Icons.check_circle_outline,
                  footerText: '',
                  isPositive: true,
                );
                final card2 = MetricCard(
                  title: 'Pending Fees',
                  value: _data['pendingFees'] ?? '',
                  icon: Icons.receipt_long_outlined,
                  footerText: '',
                  isWarning: true,
                  isPositive: false,
                );
                final card3 = MetricCard(
                  title: 'Academic Standing',
                  value: _data['recentRank'] ?? '',
                  icon: Icons.emoji_events_outlined,
                  footerText: '',
                  isPositive: true,
                );
                final card4 = MetricCard(
                  title: 'Upcoming Test',
                  value: _data['nextExam'] ?? '',
                  icon: Icons.quiz_outlined,
                  footerText: '',
                  isPositive: true,
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 12),
                      Expanded(child: card2),
                      const SizedBox(width: 12),
                      Expanded(child: card3),
                      const SizedBox(width: 12),
                      Expanded(child: card4),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 8),
                        Expanded(child: card2),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: card3),
                        const SizedBox(width: 8),
                        Expanded(child: card4),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions Title
            Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.electricCobalt, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Quick Portal Actions', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickParentButton(
                    icon: Icons.payment_rounded,
                    label: 'Pay Fees',
                    color: const Color(0xFF2563EB),
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickParentButton(
                    icon: Icons.assessment_rounded,
                    label: 'Marksheets',
                    color: const Color(0xFF0D9488),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickParentButton(
                    icon: Icons.event_busy_rounded,
                    label: 'Apply Leave',
                    color: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickParentButton(
                    icon: Icons.family_restroom_rounded,
                    label: 'Children',
                    color: const Color(0xFF059669),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Title
            Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryNavy, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Important Notifications & Actions', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 12),
            
            ModuleGroup(
              items: [
                if (_data['invoices'] is List)
                  for (final inv in (_data['invoices'] as List).cast<Map<String, dynamic>>())
                    if ((inv['status'] ?? '') == 'PENDING' || (inv['status'] ?? '') == 'OVERDUE')
                      ModuleListItem(
                        icon: Icons.payment_outlined,
                        title: 'Pay ${inv['title'] ?? ''}',
                        subtitle: 'Due ${inv['due_date'] ?? ''}',
                        badge: const StatusBadge(text: 'Due Soon', bgColor: AppTheme.urgentBg, textColor: AppTheme.urgentText),
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                if (_data['academics'] is List)
                  for (final ac in (_data['academics'] as List).cast<Map<String, dynamic>>())
                    ModuleListItem(
                      icon: Icons.analytics_outlined,
                      title: '${ac['exam_title'] ?? ''}',
                      subtitle: '${ac['marks_obtained'] ?? ''}/${ac['max_marks'] ?? ''} (${ac['grade'] ?? ''})',
                      badge: const StatusBadge(text: 'Scorecard', bgColor: AppTheme.batchBg, textColor: AppTheme.batchText),
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
              ],
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  NavigationRail(
                    extended: true,
                    minExtendedWidth: 220,
                    backgroundColor: AppTheme.surfaceWhite,
                    selectedIndex: _currentIndex.clamp(0, 4),
                    onDestinationSelected: (int index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCobalt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TutorOS',
                                style: TextStyle(color: AppTheme.electricCobalt, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'Parent Portal',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: Text('Dashboard'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.family_restroom_outlined),
                        selectedIcon: Icon(Icons.family_restroom_rounded),
                        label: Text('Children'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.analytics_outlined),
                        selectedIcon: Icon(Icons.analytics_rounded),
                        label: Text('Academics'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.payments_outlined),
                        selectedIcon: Icon(Icons.payments_rounded),
                        label: Text('Fees'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat_outlined),
                        selectedIcon: Icon(Icons.chat_rounded),
                        label: Text('Chat & Notice'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderSubtle),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _isLoading && _currentIndex == 0
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
                            : _buildTabBody(),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: _isLoading && _currentIndex == 0
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
                        : _buildTabBody(),
                  ),
                  
                  // Bottom Navigation Bar
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _ParentBottomNav(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() { _currentIndex = index; });
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuickParentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickParentButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _ParentBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: AppTheme.level3Shadow,
        border: const Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard', context),
          _buildNavItem(1, Icons.family_restroom_rounded, 'Children', context),
          _buildNavItem(2, Icons.analytics_outlined, 'Academics', context),
          _buildNavItem(3, Icons.payments_outlined, 'Fees', context),
          _buildNavItem(4, Icons.chat_rounded, 'Chat', context),
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
        width: 65,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
