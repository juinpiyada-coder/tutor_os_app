import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/module_list_item.dart';
import '../../../shared/widgets/theme_toggle_switch.dart';
import '../services/student_dashboard_service.dart';
import '../../../../core/network/api_service.dart';
import '../../auth/screens/login_screen.dart';
import 'student_classes_screen.dart';
import 'student_schedule_screen.dart';
import 'student_attendance_screen.dart';
import 'student_study_screen.dart';
import 'student_tests_screen.dart';
import 'student_performance_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    final result = await StudentDashboardService.getStudentDashboardData();
    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  Widget _buildTabBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeDashboardTab();
      case 1:
        return const StudentClassesScreen();
      case 2:
        return const StudentScheduleScreen();
      case 3:
        return const StudentAttendanceScreen();
      case 4:
        return const StudentStudyScreen(); // Contains 4 tabs: Lessons, Study Materials, Assignments, My Doubts
      case 5:
        return const StudentTestsScreen(); // Contains 3 tabs: Upcoming Exams, My Exams, Results
      case 6:
        return const StudentPerformanceScreen();
      case 7:
        return _buildNotificationsTab();
      case 8:
        return const StudentProfileScreen();
      default:
        return _buildHomeDashboardTab();
    }
  }

  Widget _buildNotificationsTab() {
    final notifications = [
      {
        'title': 'Attendance Verified',
        'desc': 'Rahul Sir verified your attendance for Mathematics (X-MATH-A) as Present.',
        'time': '10 mins ago',
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Upcoming Exam Alert',
        'desc': 'Calculus Mid-Term examination is scheduled for tomorrow at 10:00 AM.',
        'time': '2 hours ago',
        'icon': Icons.quiz_rounded,
        'color': AppTheme.electricCobalt,
      },
      {
        'title': 'New Study Material',
        'desc': 'Lecture notes on Electrostatics Chapter 3 uploaded by Physics Dept.',
        'time': 'Yesterday',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Assignment Evaluated',
        'desc': 'Chemistry Homework #4 graded: Score 18/20 (A Grade).',
        'time': '2 days ago',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final n = notifications[idx];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.5)),
              boxShadow: AppTheme.level1Shadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                          Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['desc'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeDashboardTab() {
    if (_isLoading && _data.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
    }

    final studentName = '${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'.trim();

    final classes = (_data['upcomingClasses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final nextClass = classes.isNotEmpty ? classes.first : null;
    final nextClassTime = nextClass?['time']?.toString() ?? '';
    final nextClassTitle = nextClass?['title']?.toString() ?? '';

    final assignmentsList = (_data['assignments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pendingAssignments = assignmentsList.where((a) {
      final status = (a['status'] ?? '').toString().toUpperCase();
      return status != 'SUBMITTED' && status != 'GRADED';
    }).toList();

    final examsList = (_data['exams'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final completedExams = examsList.where((e) => (e['status'] ?? '') == 'COMPLETED').toList();
    final recentExam = completedExams.isNotEmpty ? completedExams.first : null;
    final recentExamTitle = recentExam?['title']?.toString() ?? recentExam?['subject']?.toString() ?? '';

    final stats = _data['stats'] as Map<String, dynamic>? ?? {};
    final attendancePct = _data['attendanceRate']?.toString() ?? stats['attendancePct']?.toString() ?? '0%';
    final attendanceSummary = _data['attendanceSummary']?.toString() ?? stats['attendanceSummary']?.toString() ?? 'Verified check-ins';
    final latestScore = _data['recentTestScore']?.toString().isNotEmpty == true 
        ? _data['recentTestScore'].toString() 
        : (stats['avgScore'] != null && stats['avgScore'].toString() != 'N/A' ? stats['avgScore'].toString() : '—');
    final batchName = nextClass?['batch_name']?.toString() ?? nextClass?['batch']?.toString() ?? '';

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

            // Header Profile Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded, color: AppTheme.primaryNavy),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.electricCobalt, AppTheme.deepBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
                          Text(studentName.isNotEmpty ? studentName : 'Student', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textHeading)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const ThemeToggleSwitch(width: 58, height: 30),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppTheme.textHeading),
                        onPressed: () {
                          setState(() => _currentIndex = 7);
                        },
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        icon: const Icon(Icons.logout_rounded, color: AppTheme.urgentText),
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
                                    if (mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    }
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Class Check-in Banner / Hero
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, color: Colors.amberAccent, size: 14),
                            SizedBox(width: 4),
                            Text("Today's Schedule & Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: nextClass != null ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          nextClass != null ? 'ACTIVE SESSION' : 'TODAY', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nextClassTitle.isNotEmpty ? nextClassTitle : "Today's Academic Session",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextClassTime.isNotEmpty 
                        ? 'Time: $nextClassTime${batchName.isNotEmpty ? '  •  Batch: $batchName' : ''}'
                        : 'Check in for your scheduled batch class to submit attendance.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Mark Class Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            setState(() => _currentIndex = 3);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white30),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          setState(() => _currentIndex = 2);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Next Class',
                    value: nextClassTime.isNotEmpty ? nextClassTime : (classes.isNotEmpty ? 'Scheduled' : 'None'),
                    footerText: nextClassTitle.isNotEmpty ? nextClassTitle : (classes.isNotEmpty ? 'Class' : 'No upcoming classes'),
                    icon: Icons.access_time_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Attendance',
                    value: attendancePct,
                    footerText: attendanceSummary,
                    icon: Icons.fact_check_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Assignments',
                    value: '${pendingAssignments.length} Pending',
                    footerText: '${assignmentsList.length} Total tasks',
                    icon: Icons.assignment_turned_in_rounded,
                    isWarning: pendingAssignments.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Latest Score',
                    value: latestScore,
                    footerText: recentExamTitle.isNotEmpty ? recentExamTitle : (completedExams.isNotEmpty ? 'Exam' : 'No graded exams'),
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quick Navigation Hub
            const Text('Academic Modules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.play_lesson_rounded,
                    label: 'My Classes',
                    color: const Color(0xFF2563EB),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.schedule_rounded,
                    label: 'Schedule',
                    color: const Color(0xFF0D9488),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Attendance',
                    color: const Color(0xFF10B981),
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.menu_book_rounded,
                    label: 'Learning',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => setState(() => _currentIndex = 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.quiz_rounded,
                    label: 'Examinations',
                    color: const Color(0xFFE11D48),
                    onTap: () => setState(() => _currentIndex = 5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Performance',
                    color: const Color(0xFFD97706),
                    onTap: () => setState(() => _currentIndex = 6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    color: const Color(0xFF0284C7),
                    onTap: () => setState(() => _currentIndex = 7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    color: const Color(0xFF4F46E5),
                    onTap: () => setState(() => _currentIndex = 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Daily Routine & Next Scheduled Classes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Routine / Classes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading)),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('View Timetable'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (classes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text('No more classes scheduled for today', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: classes.take(3).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = classes[index];
                  return ModuleListItem(
                    icon: Icons.play_lesson_rounded,
                    title: c['title'] ?? 'Class Session',
                    subtitle: '${c['time'] ?? ''} • ${c['teacher'] ?? 'Faculty'} • ${c['room'] ?? 'Room 101'}',
                    badge: StatusBadge(
                      text: c['status'] ?? 'Scheduled',
                      bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                      textColor: const Color(0xFF10B981),
                    ),
                    onTap: () => setState(() => _currentIndex = 3),
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSidebarDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surfaceWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.electricCobalt, Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TutorOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.electricCobalt)),
                        Text('Student Portal', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sidebar Menu Items matching the user's hierarchy
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                children: [
                  _buildDrawerItem(0, Icons.home_rounded, 'Dashboard'),
                  const Divider(height: 16, thickness: 0.5, color: AppTheme.borderSubtle),

                  _buildDrawerItem(1, Icons.play_lesson_rounded, 'My Classes'),
                  _buildDrawerItem(2, Icons.access_time_rounded, 'My Schedule'),
                  _buildDrawerItem(3, Icons.fact_check_rounded, 'Attendance'),

                  const Divider(height: 16, thickness: 0.5, color: AppTheme.borderSubtle),

                  // Learning Expansion / Group
                  _buildDrawerGroup(
                    icon: Icons.menu_book_rounded,
                    title: 'Learning',
                    initiallyExpanded: _currentIndex == 4,
                    children: [
                      _buildDrawerSubItem('Lessons', 4),
                      _buildDrawerSubItem('Study Materials', 4),
                      _buildDrawerSubItem('Assignments', 4),
                      _buildDrawerSubItem('My Doubts', 4),
                    ],
                  ),

                  // Examinations Expansion / Group
                  _buildDrawerGroup(
                    icon: Icons.assignment_rounded,
                    title: 'Examinations',
                    initiallyExpanded: _currentIndex == 5,
                    children: [
                      _buildDrawerSubItem('Upcoming Exams', 5),
                      _buildDrawerSubItem('My Exams', 5),
                      _buildDrawerSubItem('Results', 5),
                    ],
                  ),

                  const Divider(height: 16, thickness: 0.5, color: AppTheme.borderSubtle),

                  _buildDrawerItem(6, Icons.bar_chart_rounded, 'My Performance'),
                  _buildDrawerItem(7, Icons.notifications_rounded, 'Notifications'),
                  _buildDrawerItem(8, Icons.person_rounded, 'My Profile'),
                ],
              ),
            ),

            // Footer Logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppTheme.urgentText),
                title: const Text('Logout', style: TextStyle(color: AppTheme.urgentText, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  ApiService.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.electricCobalt : AppTheme.textBody, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.electricCobalt.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = index);
      },
    );
  }

  Widget _buildDrawerGroup({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppTheme.textBody, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textHeading, fontSize: 14),
      ),
      initiallyExpanded: initiallyExpanded,
      childrenPadding: const EdgeInsets.only(left: 36),
      children: children,
    );
  }

  Widget _buildDrawerSubItem(String title, int targetIndex) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentIndex = targetIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.canvasBackground,
      drawer: _buildStudentSidebarDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildTabBody(),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StudentBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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

class _StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _StudentBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: AppTheme.level3Shadow,
        border: const Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home', context),
          _buildNavItem(1, Icons.play_lesson_rounded, 'Classes', context),
          _buildNavItem(2, Icons.access_time_rounded, 'Schedule', context),
          _buildNavItem(3, Icons.fact_check_rounded, 'Attendance', context),
          _buildNavItem(4, Icons.menu_book_rounded, 'Learning', context),
          _buildNavItem(5, Icons.quiz_rounded, 'Exams', context),
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
        width: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 10,
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
