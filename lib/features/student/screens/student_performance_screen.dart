import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/metric_card.dart';
import '../services/student_dashboard_service.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() => _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState extends State<StudentPerformanceScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    final res = await StudentDashboardService.getStudentDashboardData();
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
    }

    final stats = _data['stats'] as Map<String, dynamic>? ?? {};
    final attendancePct = stats['attendancePct']?.toString() ?? '92%';
    final avgScore = stats['avgScore']?.toString() ?? '84%';
    final exams = (_data['exams'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final assignments = (_data['assignments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('My Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPerformanceData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPerformanceData,
        color: AppTheme.electricCobalt,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // High-level Performance Metrics
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Avg Exam Score',
                      value: avgScore,
                      icon: Icons.trending_up_rounded,
                      footerText: 'Across all subjects',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Attendance Rate',
                      value: attendancePct,
                      icon: Icons.fact_check_rounded,
                      footerText: 'Total verified check-ins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Assignments Done',
                      value: '${assignments.where((a) => (a['status'] ?? '').toString().toUpperCase() == 'SUBMITTED' || (a['status'] ?? '').toString().toUpperCase() == 'GRADED').length}/${assignments.length}',
                      icon: Icons.assignment_turned_in_rounded,
                      footerText: 'Submitted tasks',
                      isWarning: assignments.isNotEmpty && assignments.any((a) => (a['status'] ?? '') == 'PENDING'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: 'Tests Taken',
                      value: '${exams.where((e) => (e['status'] ?? '') == 'COMPLETED').length}',
                      icon: Icons.quiz_rounded,
                      footerText: 'Finished exams',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subject Breakdown / Grade Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.6)),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subject-wise Mastery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.electricCobalt.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Term 1', style: TextStyle(color: AppTheme.electricCobalt, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSubjectProgress('Mathematics (Calculus & Algebra)', 0.88, const Color(0xFF3B82F6), '88%'),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Physics (Mechanics & Waves)', 0.82, const Color(0xFF10B981), '82%'),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Chemistry (Organic & Periodic)', 0.79, const Color(0xFFF59E0B), '79%'),
                    const SizedBox(height: 12),
                    _buildSubjectProgress('Computer Science (Algorithms)', 0.94, const Color(0xFF8B5CF6), '94%'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Attendance & Verification Health
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.6)),
                  boxShadow: AppTheme.level1Shadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      'Verified by class teachers upon daily check-in.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceMetric('Present', '24', const Color(0xFF10B981)),
                        _buildAttendanceMetric('Late', '2', const Color(0xFFF59E0B)),
                        _buildAttendanceMetric('Absent', '1', const Color(0xFFEF4444)),
                        _buildAttendanceMetric('Check-in Pct', '96%', AppTheme.electricCobalt),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectProgress(String subject, double progress, Color color, String score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Text(score, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
