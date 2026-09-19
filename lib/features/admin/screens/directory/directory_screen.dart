import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/universal_owner_header.dart';
import 'widgets/student_list_view.dart';
import 'widgets/staff_list_view.dart';
import 'widgets/parent_list_view.dart';
import 'add_student_screen.dart';
import 'add_staff_screen.dart';
import 'student_academic_enrollment_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final int initialIndex;
  final VoidCallback? onOpenDrawer;
  const DirectoryScreen({super.key, this.initialIndex = 0, this.onOpenDrawer});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ParentListViewState> _parentListKey = GlobalKey<ParentListViewState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialIndex >= 0 && widget.initialIndex < 3) ? widget.initialIndex : 0,
    );
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkCanvasBackground : AppTheme.canvasBackground,
      appBar: UniversalOwnerHeader(
        onOpenDrawer: widget.onOpenDrawer,
        title: 'People Directory',
        subtitle: 'Students, Faculty Staff & Guardian Profiles',
        customActions: [
          IconButton(
            tooltip: 'Student Academic Enrollment',
            icon: const Icon(Icons.how_to_reg_outlined, color: AppTheme.electricCobalt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentAcademicEnrollmentScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Staff'),
            Tab(text: 'Parents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudentListView(key: UniqueKey()),
          StaffListView(key: UniqueKey()),
          ParentListView(key: _parentListKey),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.level3Shadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (_tabController.index == 0) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStudentScreen()),
              );
              if (result == true) setState(() {});
            } else if (_tabController.index == 1) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStaffScreen()),
              );
              if (result == true) setState(() {});
            } else {
              _parentListKey.currentState?.openAddEditParentModal();
            }
          },
          elevation: 0,
          backgroundColor: AppTheme.electricCobalt,
          foregroundColor: AppTheme.surfaceWhite,
          icon: const Icon(Icons.add),
          label: Text(
            _tabController.index == 0
                ? 'Add Student'
                : (_tabController.index == 1 ? 'Add Staff' : 'Add Parent'),
          ),
        ),
      ),
    );
  }
}
