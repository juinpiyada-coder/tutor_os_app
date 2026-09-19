import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/avatar_image_helper.dart';
import '../../../shared/widgets/theme_toggle_switch.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/owner_bottom_nav_bar.dart';
import 'admin_dashboard.dart';
import 'directory/directory_screen.dart';
import 'directory/add_student_screen.dart';
import 'directory/add_staff_screen.dart';
import 'directory/student_academic_enrollment_screen.dart';
import 'academics/academics_screen.dart';
import 'academics/add_batch_screen.dart';
import 'academics/academic_structure_screen.dart';
import 'academics/lesson_plans_screen.dart';
import 'operations/operations_screen.dart';
import 'operations/campus_rooms_screen.dart';
import 'assessments/assessments_screen.dart';
import 'communications/communications_screen.dart';
import 'finance/finance_hub_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _academicsTab = 0;
  int _directoryTab = 0;
  int _operationsTab = 0;
  int _financeTab = 0;
  int _assessmentsTab = 0;

  void _navigateToIndex(int index, {int tabIndex = 0}) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) _academicsTab = tabIndex;
      if (index == 2) _directoryTab = tabIndex;
      if (index == 3) _operationsTab = tabIndex;
      if (index == 4) _financeTab = tabIndex;
      if (index == 5) _assessmentsTab = tabIndex;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _pushScreen(Widget screen) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of screens: Home first, then Academics, Directory, etc.
    final List<Widget> screens = [
      AdminDashboard(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      AcademicsScreen(
        key: ValueKey('academics_$_academicsTab'),
        initialIndex: _academicsTab,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      DirectoryScreen(
        key: ValueKey('directory_$_directoryTab'),
        initialIndex: _directoryTab,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      OperationsScreen(
        key: ValueKey('operations_$_operationsTab'),
        initialIndex: _operationsTab,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      FinanceHubScreen(
        key: ValueKey('finance_$_financeTab'),
        initialIndex: _financeTab,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      AssessmentsScreen(
        key: ValueKey('assessments_$_assessmentsTab'),
        initialIndex: _assessmentsTab,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      CommunicationsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      SettingsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      ReportsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
    ];

    // Determine if we should show a sidebar (wide screen) or bottom nav / drawer
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getCanvasBackground(context),
      drawer: _buildCoachingAdminDrawer(context),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: true,
              backgroundColor: AppTheme.getSurfaceCard(context),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: AppTheme.surfaceWhite, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TutorOS',
                            style: GoogleFonts.outfit(
                              color: AppTheme.electricCobalt,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Coaching Admin',
                            style: GoogleFonts.inter(
                              color: AppTheme.getTextMuted(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Batches'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Students'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('Finance'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.apps_outlined),
                  selectedIcon: Icon(Icons.apps),
                  label: Text('More'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: Text('Assessments'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Communications'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Reports'),
                ),
              ],
            ),
          // Vertical divider
          if (isDesktop)
            const VerticalDivider(thickness: 1, width: 1, color: AppTheme.borderSubtle),
          
          // Main content area
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? OwnerBottomNavBar(
              selectedIndex: _selectedIndex,
              onTabSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
    );
  }

  /// Comprehensive Coaching Center Admin Data Flow Drawer
  Widget _buildCoachingAdminDrawer(BuildContext context) {
    final instituteName = ApiService.currentInstituteName ?? 'Coaching Academy';
    final instituteCode = ApiService.currentInstituteCode ?? 'INS-${ApiService.currentTenantId ?? 1}';
    final adminName = '${ApiService.currentFirstName ?? 'Institute'} ${ApiService.currentLastName ?? 'Director'}'.trim();

    return Drawer(
      backgroundColor: AppTheme.surfaceWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Coaching Center Profile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                boxShadow: AppTheme.level1Shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          image: AvatarImageHelper.getImageProvider(ApiService.currentAvatarUrl) != null
                              ? DecorationImage(
                                  image: AvatarImageHelper.getImageProvider(ApiService.currentAvatarUrl)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: AvatarImageHelper.getImageProvider(ApiService.currentAvatarUrl) == null
                            ? Text(
                                instituteName.isNotEmpty ? instituteName.substring(0, instituteName.length >= 2 ? 2 : 1).toUpperCase() : 'CO',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instituteName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ID: $instituteCode',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          adminName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Center Admin',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 7-Module Coaching Center Dependency Flow List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Main Dashboard Link
                  ListTile(
                    leading: const Icon(Icons.dashboard_rounded, color: AppTheme.electricCobalt),
                    title: const Text('Admin Command Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    selected: _selectedIndex == 0,
                    selectedTileColor: AppTheme.electricCobalt.withValues(alpha: 0.08),
                    onTap: () => _navigateToIndex(0),
                  ),
                  const Divider(height: 12),

                  // 1. SETUP
                  _buildSectionHeader('1. CENTER SETUP & INFRASTRUCTURE'),
                  _buildDrawerItem(
                    icon: Icons.domain_rounded,
                    title: 'Institute & Branches',
                    subtitle: 'Campus centers & branch management',
                    onTap: () => _navigateToIndex(7),
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Academic Years',
                    subtitle: 'Academic calendar & terms',
                    onTap: () => _pushScreen(const AcademicStructureScreen(initialIndex: 0)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.class_outlined,
                    title: 'Classes & Course Programs',
                    subtitle: 'Grade levels, standards & curricula',
                    onTap: () => _pushScreen(const AcademicStructureScreen(initialIndex: 1)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Subjects & Syllabus',
                    subtitle: 'Master subject catalogue',
                    onTap: () => _navigateToIndex(1, tabIndex: 1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.meeting_room_rounded,
                    title: 'Classrooms & Labs',
                    subtitle: 'Room capacity & geofenced labs',
                    onTap: () => _pushScreen(const CampusRoomsScreen()),
                  ),

                  const Divider(height: 16),

                  // 2. STAFF & FACULTY
                  _buildSectionHeader('2. STAFF & FACULTY MANAGEMENT'),
                  _buildDrawerItem(
                    icon: Icons.badge_outlined,
                    title: 'Teachers & Faculty Directory',
                    subtitle: 'Teaching staff, profiles & subjects',
                    onTap: () => _navigateToIndex(2, tabIndex: 1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Onboard New Faculty / Staff',
                    subtitle: 'Register teacher credentials',
                    onTap: () => _pushScreen(const AddStaffScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.security_rounded,
                    title: 'Roles & Permissions',
                    subtitle: 'Access control and role scopes',
                    onTap: () => _navigateToIndex(7),
                  ),

                  const Divider(height: 16),

                  // 3. BATCH MANAGEMENT
                  _buildSectionHeader('3. BATCH & SCHEDULE MANAGEMENT'),
                  _buildDrawerItem(
                    icon: Icons.groups_rounded,
                    title: 'Academic Batches',
                    subtitle: 'Batch rosters, grades & subjects',
                    onTap: () => _navigateToIndex(1, tabIndex: 0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create New Batch',
                    subtitle: 'Setup multi-course academic batch',
                    onTap: () => _pushScreen(const AddBatchScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Batch Student Enrollment',
                    subtitle: 'Assign students to active batches',
                    onTap: () => _pushScreen(const StudentAcademicEnrollmentScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.schedule_rounded,
                    title: 'Timetable & Class Schedules',
                    subtitle: 'Daily recurring class timetable',
                    onTap: () => _navigateToIndex(3, tabIndex: 0),
                  ),

                  const Divider(height: 16),

                  // 4. ADMISSIONS & CRM
                  _buildSectionHeader('4. ADMISSIONS & CRM PIPELINE'),
                  _buildDrawerItem(
                    icon: Icons.people_alt_rounded,
                    title: 'Student Directory',
                    subtitle: 'Enrolled students & 360 profile',
                    onTap: () => _navigateToIndex(2, tabIndex: 0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.family_restroom_rounded,
                    title: 'Parents & Guardians',
                    subtitle: 'Parent contacts & linked children',
                    onTap: () => _navigateToIndex(2, tabIndex: 2),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add_rounded,
                    title: 'New Student Admission',
                    subtitle: 'Instant onboarding & WhatsApp invite',
                    onTap: () => _pushScreen(const AddStudentScreen()),
                  ),

                  const Divider(height: 16),

                  // 5. FINANCE & FEES
                  _buildSectionHeader('5. FINANCE & FEE OPERATIONS'),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Fee Structure & Invoices',
                    subtitle: 'Batch fees, installment plans & dues',
                    onTap: () => _navigateToIndex(4, tabIndex: 0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Payments & Receipts',
                    subtitle: 'Digital receipts & WhatsApp receipts',
                    onTap: () => _navigateToIndex(4, tabIndex: 1),
                  ),

                  const Divider(height: 16),

                  // 6. ACADEMICS & DAILY WORK
                  _buildSectionHeader('6. ACADEMICS, ATTENDANCE & LESSONS'),
                  _buildDrawerItem(
                    icon: Icons.co_present_rounded,
                    title: 'Batch Attendance & Kiosk',
                    subtitle: 'Daily student attendance records',
                    onTap: () => _navigateToIndex(3, tabIndex: 1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.auto_stories_rounded,
                    title: 'Lesson Plans & Syllabus',
                    subtitle: 'Curriculum chapters & progress',
                    onTap: () => _pushScreen(const LessonPlansScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.assignment_rounded,
                    title: 'Homework & Assignments',
                    subtitle: 'Submissions & evaluations',
                    onTap: () => _navigateToIndex(5, tabIndex: 1),
                  ),

                  const Divider(height: 16),

                  // 7. EXAMINATIONS & RESULTS
                  _buildSectionHeader('7. EXAMINATIONS & RESULTS'),
                  _buildDrawerItem(
                    icon: Icons.quiz_rounded,
                    title: 'Exams & Test Series',
                    subtitle: 'Periodic assessments & question banks',
                    onTap: () => _navigateToIndex(5, tabIndex: 0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.assessment_rounded,
                    title: 'Grading & Report Cards',
                    subtitle: 'Student marks and performance',
                    onTap: () => _navigateToIndex(5, tabIndex: 0),
                  ),

                  const Divider(height: 16),

                  // COMMUNICATIONS & SETTINGS
                  _buildSectionHeader('COMMUNICATIONS & SYSTEM'),
                  _buildDrawerItem(
                    icon: Icons.campaign_rounded,
                    title: 'Notices & WhatsApp Broadcasts',
                    subtitle: 'Announcements & alerts',
                    onTap: () => _navigateToIndex(6),
                  ),
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports & Analytics',
                    subtitle: 'Comprehensive center & financial reports',
                    onTap: () => _navigateToIndex(8),
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_suggest_rounded,
                    title: 'System Settings',
                    subtitle: 'Institute profile & branding',
                    onTap: () => _navigateToIndex(7),
                  ),
                ],
              ),
            ),

            // Footer with Theme Switch & Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.canvasBackground,
                border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleSwitch(width: 54, height: 28),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out of TutorOS?'),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.urgentText, size: 18),
                    label: const Text('Sign Out', style: TextStyle(color: AppTheme.urgentText, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppTheme.electricCobalt.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.electricCobalt, size: 19),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      dense: true,
      onTap: onTap,
    );
  }
}

