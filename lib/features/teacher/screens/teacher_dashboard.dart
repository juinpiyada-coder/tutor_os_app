import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/theme_toggle_switch.dart';
import '../../../../core/network/api_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../admin/screens/admin_main_screen.dart';
import '../../admin/screens/academics/lesson_plans_screen.dart';
import '../../admin/screens/communications/communications_screen.dart';
import '../../admin/screens/reports/reports_screen.dart';
import '../services/teacher_dashboard_service.dart';
import 'teacher_batches_screen.dart';
import 'teacher_assignments_screen.dart';
import 'teacher_exams_screen.dart';
import 'teacher_doubts_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final int initialModuleIndex;
  const TeacherDashboard({super.key, this.initialModuleIndex = 0});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialModuleIndex;
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    final result = await TeacherDashboardService.getTeacherDashboardData();
    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchMeeting(String? urlStr) async {
    final url = urlStr ?? '';
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meeting link available for this session.'),
            backgroundColor: AppTheme.urgentText,
          ),
        );
      }
      return;
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening classroom meeting: $url'), backgroundColor: AppTheme.electricCobalt),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Launching classroom meeting: $url'), backgroundColor: AppTheme.electricCobalt),
        );
      }
    }
  }

  Widget _buildTabBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeDashboardTab();
      case 1:
        return const TeacherBatchesScreen(); // My Classes & Batches
      case 2:
        return const TeacherBatchesScreen(); // My Students
      case 3:
        return _buildScheduleTab(); // My Schedule
      case 4:
        return const TeacherBatchesScreen(); // Attendance
      case 5:
        return _buildAcademicsHubTab(); // Academics (Lessons, Materials, Assignments, Doubts)
      case 6:
        return const TeacherExamsScreen(); // Examinations (Question Bank, Exams, Evaluation, Results)
      case 7:
        return const CommunicationsScreen(); // Communication (Announcements, Reminders)
      case 8:
        return const ReportsScreen(isBranchAdmin: false); // Reports (Teacher level)
      case 9:
        return _buildProfileTab(); // My Profile
      default:
        return _buildHomeDashboardTab();
    }
  }

  Widget _buildHomeDashboardTab() {
    final teacherName = '${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'.trim();
    final schedule = (_data['schedule'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final nextSession = schedule.isNotEmpty ? schedule.first : null;
    final nextSessionText = [
      nextSession?['time']?.toString() ?? '',
      nextSession?['topic']?.toString() ?? '',
    ].where((p) => p.isNotEmpty).join(' • ');

    final assignmentsList = (_data['assignments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final ungraded = assignmentsList.where((a) => (int.tryParse('${a['pending_grading'] ?? 0}') ?? 0) > 0).toList();
    final gradingSummaryText = ungraded.isNotEmpty
        ? '${ungraded.first['title'] ?? ''} Submissions'
        : '';

    return RefreshIndicator(
      onRefresh: _loadTeacherData,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Faculty Profile Header Card
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
                  IconButton(
                    tooltip: 'Teacher Navigation Menu',
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.primaryNavy, size: 26),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.electricCobalt, AppTheme.deepBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.school_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherName.isNotEmpty ? teacherName : 'Faculty Educator',
                          style: const TextStyle(color: AppTheme.textHeading, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ApiService.currentInstituteName ?? 'TutorOS Coaching Center'} • Faculty',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const ThemeToggleSwitch(width: 54, height: 28),
                  const SizedBox(width: 4),
                  if (Navigator.canPop(context) || ApiService.isAdmin || ApiService.isSuperAdmin)
                    IconButton(
                      tooltip: 'Admin Portal',
                      icon: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryNavy),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminMainScreen()),
                          );
                        }
                      },
                    ),
                  IconButton(
                    tooltip: 'Doubts Queue',
                    icon: const Icon(Icons.forum_outlined, color: AppTheme.primaryNavy),
                    onPressed: () => _navigateToIndex(5),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out of TutorOS Teacher Portal?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
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

            // Live Metrics Row 1
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Active Batches',
                    value: '${_data['batchesCount'] ?? ''}',
                    icon: Icons.groups_rounded,
                    footerText: _data['studentsCount'] != null ? '${_data['studentsCount']} Enrolled Students' : '',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    title: 'Classes Today',
                    value: '${_data['classesToday'] ?? ''}',
                    icon: Icons.access_time_rounded,
                    footerText: nextSessionText,
                    isPositive: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Live Metrics Row 2
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Doubts to Answer',
                    value: '${_data['pendingDoubts'] ?? ''}',
                    icon: Icons.help_outline_rounded,
                    footerText: 'Requires Faculty Reply',
                    isWarning: true,
                    isPositive: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    title: 'Pending Grading',
                    value: '${_data['pendingGrading'] ?? ''}',
                    icon: Icons.grading_rounded,
                    footerText: gradingSummaryText,
                    isWarning: true,
                    isPositive: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Portal Actions Title
            Row(
              children: [
                Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.electricCobalt, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Teacher Workflow Actions', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickTeacherButton(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Attendance',
                    color: const Color(0xFF2563EB),
                    onTap: () => _navigateToIndex(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickTeacherButton(
                    icon: Icons.menu_book_rounded,
                    label: 'Academics',
                    color: const Color(0xFF059669),
                    onTap: () => _navigateToIndex(5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickTeacherButton(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Exams',
                    color: const Color(0xFF86198F),
                    onTap: () => _navigateToIndex(6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickTeacherButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reports',
                    color: const Color(0xFFD97706),
                    onTap: () => _navigateToIndex(8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Class Schedule Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryNavy, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('Today\'s Classes & Schedule', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigateToIndex(3),
                  child: const Text('View Schedule →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (schedule.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: AppTheme.electricCobalt, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No active classes scheduled today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Check your upcoming batches and lesson curriculum in My Schedule tab.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...schedule.map((session) {
                final isLive = (session['status'] ?? '').toString().toUpperCase() == 'LIVE';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isLive ? AppTheme.electricCobalt.withValues(alpha: 0.6) : AppTheme.borderSubtle, width: isLive ? 1.5 : 1),
                    boxShadow: AppTheme.level1Shadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(session['batch_name'] ?? 'Assigned Batch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.electricCobalt)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLive ? AppTheme.urgentBg : AppTheme.successBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session['status'] ?? 'SCHEDULED',
                              style: TextStyle(
                                color: isLive ? AppTheme.urgentText : AppTheme.successText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session['topic'] ?? 'Class Session',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(session['time'] ?? '10:00 AM', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(width: 14),
                          const Icon(Icons.room_rounded, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(session['room'] ?? 'Room 204', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive ? AppTheme.urgentText : AppTheme.electricCobalt,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 16),
                        label: Text(isLive ? 'Start / Join Live Meeting Now' : 'Launch Classroom Session Link', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchMeeting(session['meet_url']),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // 3. My Schedule Tab
  Widget _buildScheduleTab() {
    final schedule = (_data['schedule'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teaching Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Teaching Timetable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('View upcoming class slots, room numbers, and curriculum timings.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Upcoming Scheduled Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
            const SizedBox(height: 12),
            if (schedule.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No classes currently assigned to your timetable.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ...schedule.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: AppTheme.level1Shadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: AppTheme.electricCobalt, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['topic'] ?? 'Class Session', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading)),
                            const SizedBox(height: 4),
                            Text('${item['batch_name'] ?? ''} • Room: ${item['room'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Text(item['time'] ?? '10:00 AM', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt, fontSize: 13)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // 5. Academics Hub Tab (Lessons, Study Materials, Assignments, Doubts)
  Widget _buildAcademicsHubTab() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academics & Teaching Hub'),
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppTheme.electricCobalt,
            indicatorColor: AppTheme.electricCobalt,
            tabs: [
              Tab(text: 'Lessons & Plans', icon: Icon(Icons.auto_stories_rounded, size: 20)),
              Tab(text: 'Study Materials', icon: Icon(Icons.folder_shared_rounded, size: 20)),
              Tab(text: 'Assignments', icon: Icon(Icons.assignment_turned_in_rounded, size: 20)),
              Tab(text: 'Student Doubts', icon: Icon(Icons.help_center_rounded, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LessonPlansScreen(),
            _TeacherStudyMaterialsTab(),
            TeacherAssignmentsScreen(),
            TeacherDoubtsScreen(),
          ],
        ),
      ),
    );
  }

  // 9. My Profile Tab
  Widget _buildProfileTab() {
    final firstName = ApiService.currentFirstName ?? 'Educator';
    final lastName = ApiService.currentLastName ?? '';
    final email = ApiService.currentEmail ?? 'teacher@tutoros.local';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: AppTheme.level1Shadow,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.electricCobalt,
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('$firstName $lastName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Verified Faculty Member', style: TextStyle(color: AppTheme.electricCobalt, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business_rounded, color: AppTheme.electricCobalt),
                    title: const Text('Campus Academy'),
                    subtitle: Text(ApiService.currentInstituteName ?? 'TutorOS Institute'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_rounded, color: AppTheme.electricCobalt),
                    title: const Text('Faculty Role'),
                    subtitle: Text(ApiService.currentRole ?? 'TEACHER'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppTheme.electricCobalt),
                    title: const Text('Faculty ID'),
                    subtitle: Text('TCH-${ApiService.currentUserId ?? '101'}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDrawer(BuildContext context, bool isDark) {
    final teacherName = '${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'.trim();

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.surfaceWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppTheme.primaryNavy,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.electricCobalt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TutorOS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          teacherName.isNotEmpty ? teacherName : 'Teacher Portal',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'Today\'s classes & summary metrics',
                    onTap: () => _navigateToIndex(0),
                    isSelected: _currentIndex == 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.groups_rounded,
                    title: 'My Classes',
                    subtitle: 'All batches, schedules & students',
                    onTap: () => _navigateToIndex(1),
                    isSelected: _currentIndex == 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_search_rounded,
                    title: 'My Students',
                    subtitle: 'Student profiles & academic progress',
                    onTap: () => _navigateToIndex(2),
                    isSelected: _currentIndex == 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'My Schedule',
                    subtitle: 'Timetable, slots & class calendar',
                    onTap: () => _navigateToIndex(3),
                    isSelected: _currentIndex == 3,
                  ),
                  _buildDrawerItem(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Attendance',
                    subtitle: 'Take live attendance for batches',
                    onTap: () => _navigateToIndex(4),
                    isSelected: _currentIndex == 4,
                  ),
                  _buildDrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Academics',
                    subtitle: 'Lessons, materials, tasks & doubts',
                    onTap: () => _navigateToIndex(5),
                    isSelected: _currentIndex == 5,
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Examinations',
                    subtitle: 'Question bank, tests & evaluation',
                    onTap: () => _navigateToIndex(6),
                    isSelected: _currentIndex == 6,
                  ),
                  _buildDrawerItem(
                    icon: Icons.campaign_rounded,
                    title: 'Communication',
                    subtitle: 'Announcements to batches & parents',
                    onTap: () => _navigateToIndex(7),
                    isSelected: _currentIndex == 7,
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports',
                    subtitle: 'Attendance & student performance',
                    onTap: () => _navigateToIndex(8),
                    isSelected: _currentIndex == 8,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'My Profile',
                    subtitle: 'Teacher profile & preferences',
                    onTap: () => _navigateToIndex(9),
                    isSelected: _currentIndex == 9,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleSwitch(width: 50, height: 26),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.urgentText),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      ApiService.logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppTheme.electricCobalt.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: isSelected ? AppTheme.electricCobalt : AppTheme.primaryNavy, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      drawer: _buildTeacherDrawer(context, isDark),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: true,
              backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.surfaceWhite,
              selectedIndex: _currentIndex > 9 ? 0 : _currentIndex,
              onDestinationSelected: (int index) => setState(() => _currentIndex = index),
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCobalt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TutorOS',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppTheme.textHeading,
                          ),
                        ),
                        const Text(
                          'Teacher Desk',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: Text('My Classes')),
                NavigationRailDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search_rounded), label: Text('My Students')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: Text('My Schedule')),
                NavigationRailDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg_rounded), label: Text('Attendance')),
                NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: Text('Academics')),
                NavigationRailDestination(icon: Icon(Icons.assignment_turned_in_outlined), selectedIcon: Icon(Icons.assignment_turned_in_rounded), label: Text('Examinations')),
                NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: Text('Communication')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: Text('Reports')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: Text('My Profile')),
              ],
            ),
          Expanded(
            child: _isLoading && _currentIndex == 0
                ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
                : _buildTabBody(),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _TeacherBottomNav(
              currentIndex: _currentIndex.clamp(0, 4),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
    );
  }
}

class _TeacherStudyMaterialsTab extends StatelessWidget {
  const _TeacherStudyMaterialsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Study Materials & Lesson Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Upload Material'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload Material Modal opened. Select PDF/Document/Video link.'), backgroundColor: AppTheme.electricCobalt),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMaterialCard(
            title: 'Calculus & Integration Master Formula Sheet',
            subject: 'Mathematics',
            batch: 'Class 12 - MATH-B',
            type: 'PDF Document',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
          ),
          _buildMaterialCard(
            title: 'Rotational Dynamics Lecture Notes & Problem Set',
            subject: 'Physics',
            batch: 'Class 11 - PHY-A',
            type: 'Study Material PPTX',
            icon: Icons.slideshow_rounded,
            color: Colors.orangeAccent,
          ),
          _buildMaterialCard(
            title: 'Organic Chemistry Reactions Reference Chart',
            subject: 'Chemistry',
            batch: 'Class 12 - CHEM-A',
            type: 'Cheat Sheet PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard({
    required String title,
    required String subject,
    required String batch,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.level1Shadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                const SizedBox(height: 4),
                Text('$subject • $batch • $type', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.electricCobalt),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _QuickTeacherButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTeacherButton({
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

class _TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _TeacherBottomNav({required this.currentIndex, required this.onTap});

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
          _buildNavItem(1, Icons.groups_rounded, 'Classes', context),
          _buildNavItem(3, Icons.calendar_month_rounded, 'Schedule', context),
          _buildNavItem(4, Icons.how_to_reg_rounded, 'Attendance', context),
          _buildNavItem(5, Icons.menu_book_rounded, 'Academics', context),
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
