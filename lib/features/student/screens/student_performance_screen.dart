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
    final attendancePct = _data['attendanceRate']?.toString() ?? stats['attendancePct']?.toString() ?? '0%';
    final avgScore = _data['recentTestScore']?.toString().isNotEmpty == true
        ? _data['recentTestScore'].toString()
        : (stats['avgScore'] != null && stats['avgScore'].toString() != 'N/A' ? stats['avgScore'].toString() : '—');
    final exams = (_data['exams'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final assignments = (_data['assignments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final attendance = (_data['attendance'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    for (final a in attendance) {
      final st = (a['attendance_status'] ?? a['status'] ?? '').toString().toUpperCase();
      if (st == 'PRESENT' || st == 'VERIFIED') {
        presentCount++;
      } else if (st == 'LATE') {
        lateCount++;
      } else if (st == 'ABSENT') {
        absentCount++;
      } else {
        presentCount++;
      }
    }

    // Dynamic subject grouping from exams
    final Map<String, List<double>> subjectScores = {};
    for (final e in exams) {
      final subj = (e['subject'] ?? e['subject_name'] ?? 'General').toString();
      final rawScore = e['percentage'] ?? e['score'] ?? e['marks_obtained'];
      if (rawScore != null) {
        final parsed = double.tryParse(rawScore.toString().replaceAll('%', ''));
        if (parsed != null) {
          subjectScores.putIfAbsent(subj, () => []).add(parsed);
        }
      }
    }

    final dynamicSubjects = <Map<String, dynamic>>[];
    if (subjectScores.isNotEmpty) {
      subjectScores.forEach((subj, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        dynamicSubjects.add({
          'subject': subj,
          'progress': (avg / 100.0).clamp(0.0, 1.0),
          'score': '${avg.toStringAsFixed(0)}%',
          'color': avg >= 80 ? const Color(0xFF10B981) : (avg >= 60 ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
        });
      });
    }

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
                          child: const Text('Live Progress', style: TextStyle(color: AppTheme.electricCobalt, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (dynamicSubjects.isNotEmpty)
                      ...dynamicSubjects.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSubjectProgress(s['subject'], s['progress'], s['color'], s['score']),
                          ))
                    else ...[
                      _buildSubjectProgress('Mathematics', 0.85, const Color(0xFF3B82F6), '85%'),
                      const SizedBox(height: 12),
                      _buildSubjectProgress('Physics', 0.80, const Color(0xFF10B981), '80%'),
                      const SizedBox(height: 12),
                      _buildSubjectProgress('Chemistry', 0.75, const Color(0xFFF59E0B), '75%'),
                    ],
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
                    const Text(
                      'Verified by class teachers upon daily check-in.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAttendanceMetric('Present', '$presentCount', const Color(0xFF10B981)),
                        _buildAttendanceMetric('Late', '$lateCount', const Color(0xFFF59E0B)),
                        _buildAttendanceMetric('Absent', '$absentCount', const Color(0xFFEF4444)),
                        _buildAttendanceMetric('Check-in Pct', attendancePct, AppTheme.electricCobalt),
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
