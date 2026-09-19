import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../../auth/screens/login_screen.dart';
import '../admin_dashboard.dart';
import '../directory/directory_screen.dart';
import '../directory/add_student_screen.dart';
import '../directory/add_staff_screen.dart';
import '../directory/student_academic_enrollment_screen.dart';
import '../academics/academics_screen.dart';
import '../academics/add_batch_screen.dart';
import '../academics/academic_structure_screen.dart';
import '../academics/lesson_plans_screen.dart';
import '../operations/operations_screen.dart';
import '../operations/campus_rooms_screen.dart';
import '../finance/finance_hub_screen.dart';
import '../assessments/assessments_screen.dart';
import '../communications/communications_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/owner_bottom_nav_bar.dart';

class BranchAdminMainScreen extends StatefulWidget {
  const BranchAdminMainScreen({super.key});

  @override
  State<BranchAdminMainScreen> createState() => _BranchAdminMainScreenState();
}

class _BranchAdminMainScreenState extends State<BranchAdminMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    // 10 Distinct Core Modules for Branch Admin
    final List<Widget> screens = [
      AdminDashboard(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 0. Dashboard
      DirectoryScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 1. Students & Directory
      DirectoryScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 2. Teachers / Staff
      AcademicsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 3. Classes & Batches
      OperationsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 4. Schedule & Timetables
      OperationsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 5. Attendance
      FinanceHubScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 6. Fees & Payments
      LessonPlansScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 7. Academics (Lessons, Materials, Assignments)
      AssessmentsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 8. Examinations & Results
      CommunicationsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 9. Communication (Branch level)
      ReportsScreen(isBranchAdmin: true, onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 10. Reports
      SettingsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()), // 11. Branch Settings
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      drawer: _buildBranchAdminDrawer(context, isDark),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: true,
              backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.surfaceWhite,
              selectedIndex: _selectedIndex > 11 ? 0 : _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
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
                          color: AppTheme.electricCobalt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TutorOS', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.electricCobalt)),
                          Text('Branch Admin', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: Text('Students')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Teachers')),
                NavigationRailDestination(icon: Icon(Icons.class_outlined), selectedIcon: Icon(Icons.class_), label: Text('Classes & Batches')),
                NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Schedule')),
                NavigationRailDestination(icon: Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg), label: Text('Attendance')),
                NavigationRailDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: Text('Fees & Payments')),
                NavigationRailDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: Text('Academics')),
                NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Examinations')),
                NavigationRailDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: Text('Communication')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart_rounded), selectedIcon: Icon(Icons.bar_chart), label: Text('Reports')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Branch Settings')),
              ],
            ),
          if (isDesktop)
            VerticalDivider(thickness: 1, width: 1, color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle),
          
          Expanded(
            child: screens[_selectedIndex < screens.length ? _selectedIndex : 0],
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? OwnerBottomNavBar(
              selectedIndex: () {
                if (_selectedIndex == 0) return 0;
                if (_selectedIndex == 3 || _selectedIndex == 7) return 1;
                if (_selectedIndex == 1 || _selectedIndex == 2) return 2;
                return 4;
              }(),
              onTabSelected: (int index) {
                if (index == 0) {
                  setState(() => _selectedIndex = 0);
                } else if (index == 1) {
                  setState(() => _selectedIndex = 3);
                } else if (index == 2) {
                  setState(() => _selectedIndex = 1);
                }
              },
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
    );
  }

  /// Branch Admin Dedicated 11-Step Data Flow Drawer
  Widget _buildBranchAdminDrawer(BuildContext context, bool isDark) {
    final instituteName = ApiService.currentInstituteName ?? 'Branch Academy';
    final adminName = '${ApiService.currentFirstName ?? 'Branch'} ${ApiService.currentLastName ?? 'Admin'}'.trim();

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurfaceCard : AppTheme.surfaceWhite,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.electricCobalt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TutorOS',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.electricCobalt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BRANCH ADMIN',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    instituteName,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Signed in as $adminName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'Branch performance & overview',
                    onTap: () => _navigateToIndex(0),
                    isSelected: _selectedIndex == 0,
                  ),
                  const Divider(height: 16),

                  // 1. STUDENTS
                  _buildSectionHeader('STUDENT LIFECYCLE'),
                  _buildDrawerItem(
                    icon: Icons.school_rounded,
                    title: 'Students',
                    subtitle: 'Admissions, profiles & fee status',
                    onTap: () => _navigateToIndex(1),
                    isSelected: _selectedIndex == 1,
                    trailingBadge: 'Directory',
                  ),
                  _buildSubDrawerItem(
                    title: '+ Direct Student Admission',
                    onTap: () => _pushScreen(const AddStudentScreen()),
                  ),
                  _buildSubDrawerItem(
                    title: 'Batch Enrollment & Linking',
                    onTap: () => _pushScreen(const StudentAcademicEnrollmentScreen()),
                  ),

                  // 2. TEACHERS
                  const SizedBox(height: 8),
                  _buildSectionHeader('FACULTY MANAGEMENT'),
                  _buildDrawerItem(
                    icon: Icons.person_search_rounded,
                    title: 'Teachers',
                    subtitle: 'Branch instructors & faculty allocations',
                    onTap: () => _navigateToIndex(2),
                    isSelected: _selectedIndex == 2,
                  ),
                  _buildSubDrawerItem(
                    title: '+ Onboard Branch Teacher',
                    onTap: () => _pushScreen(const AddStaffScreen()),
                  ),

                  // 3. CLASSES & BATCHES
                  const SizedBox(height: 8),
                  _buildSectionHeader('ACADEMIC BATCHES & OPS'),
                  _buildDrawerItem(
                    icon: Icons.class_rounded,
                    title: 'Classes & Batches',
                    subtitle: 'Class 10, subjects & teacher assignments',
                    onTap: () => _navigateToIndex(3),
                    isSelected: _selectedIndex == 3,
                  ),
                  _buildSubDrawerItem(
                    title: '+ Create New Batch',
                    onTap: () => _pushScreen(const AddBatchScreen()),
                  ),
                  _buildSubDrawerItem(
                    title: 'Academic Structure (Years & Grades)',
                    onTap: () => _pushScreen(const AcademicStructureScreen()),
                  ),

                  // 4. SCHEDULE & ATTENDANCE
                  _buildDrawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Schedule & Timetable',
                    subtitle: 'Weekly timetable, batch & room slots',
                    onTap: () => _navigateToIndex(4),
                    isSelected: _selectedIndex == 4,
                  ),
                  _buildDrawerItem(
                    icon: Icons.how_to_reg_rounded,
                    title: 'Attendance',
                    subtitle: 'Mark present, absent & late sessions',
                    onTap: () => _navigateToIndex(5),
                    isSelected: _selectedIndex == 5,
                  ),
                  _buildSubDrawerItem(
                    title: 'Classroom & Lab Allocation',
                    onTap: () => _pushScreen(const CampusRoomsScreen()),
                  ),

                  // 5. FEES & PAYMENTS
                  const SizedBox(height: 8),
                  _buildSectionHeader('FINANCE & REVENUE'),
                  _buildDrawerItem(
                    icon: Icons.payments_rounded,
                    title: 'Fees & Payments',
                    subtitle: 'Invoices, dues, collections & receipts',
                    onTap: () => _navigateToIndex(6),
                    isSelected: _selectedIndex == 6,
                  ),

                  // 6. ACADEMICS
                  const SizedBox(height: 8),
                  _buildSectionHeader('TEACHING & CURRICULUM'),
                  _buildDrawerItem(
                    icon: Icons.menu_book_rounded,
                    title: 'Academics',
                    subtitle: 'Lessons, materials & assignments',
                    onTap: () => _navigateToIndex(7),
                    isSelected: _selectedIndex == 7,
                  ),

                  // 7. EXAMINATIONS
                  const SizedBox(height: 8),
                  _buildSectionHeader('ASSESSMENTS & EVALUATION'),
                  _buildDrawerItem(
                    icon: Icons.assignment_turned_in_rounded,
                    title: 'Examinations',
                    subtitle: 'Question banks, tests & grading results',
                    onTap: () => _navigateToIndex(8),
                    isSelected: _selectedIndex == 8,
                  ),

                  // 8. COMMUNICATION
                  const SizedBox(height: 8),
                  _buildSectionHeader('ENGAGEMENT'),
                  _buildDrawerItem(
                    icon: Icons.campaign_rounded,
                    title: 'Communication',
                    subtitle: 'Broadcast alerts to batches & parents',
                    onTap: () => _navigateToIndex(9),
                    isSelected: _selectedIndex == 9,
                  ),

                  // 9. REPORTS & SETTINGS
                  const SizedBox(height: 8),
                  _buildSectionHeader('AUDIT & ADMINISTRATION'),
                  _buildDrawerItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports & Analytics',
                    subtitle: 'Fee reports, attendance audits & scores',
                    onTap: () => _navigateToIndex(10),
                    isSelected: _selectedIndex == 10,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Branch Settings',
                    subtitle: 'Branch profile & local preferences',
                    onTap: () => _navigateToIndex(11),
                    isSelected: _selectedIndex == 11,
                  ),
                ],
              ),
            ),

            // Drawer Footer / Sign Out
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorderSubtle : AppTheme.borderSubtle,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleSwitch(width: 50, height: 26),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.urgentText,
                    ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 1.0,
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
    String? trailingBadge,
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
          fontSize: 14,
          color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailingBadge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailingBadge,
                style: const TextStyle(fontSize: 10, color: AppTheme.electricCobalt, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSubDrawerItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 36.0, right: 8.0, bottom: 2.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
