import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../teacher/screens/teacher_batches_screen.dart';
import '../../teacher/screens/teacher_assignments_screen.dart';
import 'directory/directory_screen.dart';
import 'directory/add_student_screen.dart';
import 'academics/add_batch_screen.dart';
import 'operations/operations_screen.dart';
import 'assessments/assessments_screen.dart';
import 'finance/finance_hub_screen.dart';
import 'communications/communications_screen.dart';
import 'settings/settings_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/widgets/universal_owner_header.dart';
import '../widgets/owner_bottom_nav_bar.dart';

class SoloTutorDashboard extends StatefulWidget {
  const SoloTutorDashboard({super.key});

  @override
  State<SoloTutorDashboard> createState() => _SoloTutorDashboardState();
}

class _SoloTutorDashboardState extends State<SoloTutorDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fetchSoloData();
  }

  Future<void> _fetchSoloData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSoloDashboardStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stats = {
            'students_count': 0,
            'batches_count': 0,
            'classes_today_count': 0,
            'fees_collected': '₹0',
            'fees_pending': '₹0',
            'open_doubts_count': 0,
            'batches': [],
            'today_schedule': [],
            'assignments': [],
          };
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load dashboard. Showing empty state.'),
            backgroundColor: AppTheme.urgentText,
          ),
        );
      }
    }
  }

  Widget _buildTabBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeOverview();
      case 1:
        return const DirectoryScreen(); // Students / Parents
      case 2:
        return const TeacherBatchesScreen(); // Batches
      case 3:
        return const OperationsScreen(); // Classes & Timetable Schedule
      case 4:
        return const OperationsScreen(); // Attendance
      case 5:
        return const TeacherAssignmentsScreen(); // Assignments / Homework
      case 6:
        return const AssessmentsScreen(); // Performance & Exams
      case 7:
        return const FinanceHubScreen(); // Fees & Payments
      case 8:
        return const CommunicationsScreen(); // Messages & Announcements
      case 9:
        return const FinanceHubScreen(); // Reports
      case 10:
        return const SettingsScreen(); // Settings & Profile
      case 11:
        return const SettingsScreen(); // My Profile
      default:
        return _buildHomeOverview();
    }
  }

  // Quick Action Dialogs
  void _openAddStudent() {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddStudentScreen())).then((_) => _fetchSoloData());
  }

  void _openAddBatch() {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddBatchScreen())).then((_) => _fetchSoloData());
  }

  void _openMarkAttendance() {
    setState(() => _currentIndex = 4);
  }

  void _openCollectFee() {
    setState(() => _currentIndex = 7);
  }

  Widget _buildQuickActionBar({bool isMobile = false}) {
    final buttons = [
      _buildQuickButton(
        icon: Icons.person_add_alt_1_rounded,
        label: '+ Student',
        color: const Color(0xFF0D9488),
        onTap: _openAddStudent,
      ),
      _buildQuickButton(
        icon: Icons.groups_rounded,
        label: '+ Batch',
        color: const Color(0xFF0284C7),
        onTap: _openAddBatch,
      ),
      _buildQuickButton(
        icon: Icons.how_to_reg_rounded,
        label: '+ Attendance',
        color: const Color(0xFF7C3AED),
        onTap: _openMarkAttendance,
      ),
      _buildQuickButton(
        icon: Icons.account_balance_wallet_rounded,
        label: '+ Fee',
        color: const Color(0xFF059669),
        onTap: _openCollectFee,
      ),
    ];

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: buttons
              .map((b) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: b,
                  ))
              .toList(),
        ),
      );
    }

    return Row(
      children: buttons
          .map((b) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: b,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeOverview() {
    final schedule = (_stats['today_schedule'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    return RefreshIndicator(
      onRefresh: _fetchSoloData,
      color: const Color(0xFF0D9488),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Action Toolbar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getSurfaceCard(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderSubtle(context)),
                boxShadow: AppTheme.getCardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF0D9488)),
                      const SizedBox(width: 6),
                      Text(
                        'QUICK ACTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActionBar(isMobile: !isDesktop),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metrics Grid
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'My Students',
                    value: '${_stats['students_count'] ?? 0}',
                    icon: Icons.people_alt_rounded,
                    footerText: 'Direct Enrolled',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    title: 'Active Batches',
                    value: '${_stats['batches_count'] ?? 0}',
                    icon: Icons.groups_rounded,
                    footerText: 'Under Tuition',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Fees Collected',
                    value: '${_stats['fees_collected'] ?? ''}',
                    icon: Icons.account_balance_wallet_rounded,
                    footerText: 'Tuition Earnings',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    title: 'Pending Fees',
                    value: '${_stats['fees_pending'] ?? ''}',
                    icon: Icons.pending_actions_rounded,
                    footerText: 'To Be Collected',
                    isWarning: true,
                    isPositive: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Classes Today',
                    value: '${_stats['classes_today_count'] ?? 0}',
                    icon: Icons.access_time_filled_rounded,
                    footerText: 'Scheduled Lectures',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    title: 'Open Doubts',
                    value: '${_stats['open_doubts_count'] ?? 0}',
                    icon: Icons.question_answer_rounded,
                    footerText: 'Student Inquiries',
                    isWarning: true,
                    isPositive: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Solo Desk Hub
            Text(
              'Solo Command Center',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textHeading,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 6 : 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                _buildActionItem(Icons.groups_rounded, 'Batches', const Color(0xFF0D9488), () => setState(() => _currentIndex = 2)),
                _buildActionItem(Icons.calendar_month_rounded, 'Classes', const Color(0xFF0284C7), () => setState(() => _currentIndex = 3)),
                _buildActionItem(Icons.how_to_reg_rounded, 'Attendance', const Color(0xFF7C3AED), () => setState(() => _currentIndex = 4)),
                _buildActionItem(Icons.assignment_turned_in_rounded, 'Assignments', const Color(0xFFEA580C), () => setState(() => _currentIndex = 5)),
                _buildActionItem(Icons.analytics_rounded, 'Performance', const Color(0xFF6366F1), () => setState(() => _currentIndex = 6)),
                _buildActionItem(Icons.account_balance_wallet_rounded, 'Fees', const Color(0xFF059669), () => setState(() => _currentIndex = 7)),
                _buildActionItem(Icons.forum_rounded, 'Messages', const Color(0xFFD97706), () => setState(() => _currentIndex = 8)),
                _buildActionItem(Icons.people_alt_rounded, 'Students', const Color(0xFF2563EB), () => setState(() => _currentIndex = 1)),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Timetable Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: AppTheme.level1Shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0D9488), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Today\'s Teaching Schedule',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                          ),
                        ],
                      ),
                      Text(
                        '${schedule.length} Sessions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (schedule.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_available_rounded, size: 36, color: isDark ? Colors.white38 : Colors.black26),
                            const SizedBox(height: 8),
                            const Text('No teaching sessions scheduled for today.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: schedule.length,
                      separatorBuilder: (context, index) => const Divider(height: 12),
                      itemBuilder: (ctx, i) {
                        final s = schedule[i];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s['start_time'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['batch_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(s['subject_name'] ?? '', style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final meetUrl = s['meet_url'];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(meetUrl != null && meetUrl.toString().isNotEmpty
                                        ? 'Opening live class: $meetUrl'
                                        : 'Live class starting now.'),
                                    backgroundColor: const Color(0xFF0D9488),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.videocam_rounded, size: 14),
                              label: const Text('Start', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sidebar Drawer for Solo Teacher
  Widget _buildSoloSidebar() {
    final academyName = ApiService.currentInstituteName ?? '';

    return Drawer(
      backgroundColor: AppTheme.getSurfaceCard(context),
      child: Column(
        children: [
          // Header: TutorOS & Coaching Brand
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cast_for_education_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎓 TutorOS',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        academyName,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Navigation List (Clean Solo Teacher Version)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildSidebarItem(1, Icons.people_alt_rounded, 'Students'),
                _buildSidebarItem(2, Icons.groups_rounded, 'Batches'),
                _buildSidebarItem(3, Icons.calendar_month_rounded, 'Classes'),
                _buildSidebarItem(4, Icons.how_to_reg_rounded, 'Attendance'),
                _buildSidebarItem(5, Icons.assignment_turned_in_rounded, 'Assignments'),
                _buildSidebarItem(6, Icons.analytics_rounded, 'Performance'),
                _buildSidebarItem(7, Icons.account_balance_wallet_rounded, 'Fees'),
                _buildSidebarItem(8, Icons.forum_rounded, 'Messages'),
                _buildSidebarItem(9, Icons.insert_chart_outlined_rounded, 'Reports'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildSidebarItem(10, Icons.settings_rounded, 'Settings'),
                _buildSidebarItem(11, Icons.person_rounded, 'My Profile'),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: AppTheme.textMuted, size: 22),
                  title: Text(
                    'Help & Support',
                    style: GoogleFonts.inter(fontSize: 13.5, color: AppTheme.textMuted),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('TutorOS Helpdesk: support@tutoros.local'), backgroundColor: Color(0xFF0D9488)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Logout Option
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFF87171)),
              title: Text('Logout', style: GoogleFonts.inter(color: const Color(0xFFF87171), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                ApiService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF0D9488) : AppTheme.textMuted;
    final bgColor = isSelected ? const Color(0xFF0D9488).withValues(alpha: 0.1) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: bgColor,
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0D9488) : AppTheme.textHeading,
          ),
        ),
        onTap: () {
          setState(() => _currentIndex = index);
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getCanvasBackground(context),
      appBar: UniversalOwnerHeader(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onRefresh: _fetchSoloData,
      ),
      drawer: _buildSoloSidebar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : Row(
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 250,
                    child: _buildSoloSidebar(),
                  ),
                if (isDesktop) VerticalDivider(width: 1, thickness: 1, color: AppTheme.getBorderSubtle(context)),
                Expanded(child: _buildTabBody()),
              ],
            ),
      bottomNavigationBar: !isDesktop
          ? OwnerBottomNavBar(
              selectedIndex: () {
                if (_currentIndex == 0) return 0;
                if (_currentIndex == 2 || _currentIndex == 3) return 1;
                if (_currentIndex == 1) return 2;
                return 4;
              }(),
              onTabSelected: (int index) {
                if (index == 0) {
                  setState(() => _currentIndex = 0);
                } else if (index == 1) {
                  setState(() => _currentIndex = 2);
                } else if (index == 2) {
                  setState(() => _currentIndex = 1);
                }
              },
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
    );
  }
}

