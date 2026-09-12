import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../services/student_dashboard_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await StudentDashboardService.getStudentDashboardData();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = ApiService.currentFirstName ?? 'Student';
    final lastName = ApiService.currentLastName ?? '';
    final email = ApiService.currentEmail ?? 'student@tutoros.local';
    final institute = ApiService.currentInstituteName ?? 'TutorOS Coaching Academy';
    final tenantId = ApiService.currentTenantId ?? 1;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('My Student Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header Card
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
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text('$firstName $lastName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Enrolled Student', style: TextStyle(color: AppTheme.electricCobalt, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Academic & Identity Info
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
                          leading: const Icon(Icons.school_rounded, color: AppTheme.electricCobalt),
                          title: const Text('Coaching Academy'),
                          subtitle: Text(institute),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.fingerprint_rounded, color: AppTheme.electricCobalt),
                          title: const Text('Student ID'),
                          subtitle: Text('STU-${ApiService.currentUserId ?? '101'}'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.domain_rounded, color: AppTheme.electricCobalt),
                          title: const Text('Tenant Account'),
                          subtitle: Text('TNT-$tenantId'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.verified_user_rounded, color: AppTheme.electricCobalt),
                          title: const Text('Account Status'),
                          subtitle: const Text('Active • Verified Student'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Academic Stats
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Attendance', _data['attendanceRate'] ?? '0%'),
                        _buildStat('Classes', '${_data['classesCount'] ?? '0'}'),
                        _buildStat('Assignments', '${_data['assignmentsDue'] ?? '0'}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.electricCobalt)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}
