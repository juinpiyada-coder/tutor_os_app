import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_image_helper.dart';
import '../services/parent_dashboard_service.dart';

class ParentChildrenScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedChild;
  final Function(Map<String, dynamic>)? onChildChanged;

  const ParentChildrenScreen({
    super.key,
    this.selectedChild,
    this.onChildChanged,
  });

  @override
  State<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends State<ParentChildrenScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _currentChild;
  List<Map<String, dynamic>> _attendance = [];

  @override
  void initState() {
    super.initState();
    _loadChildrenData();
  }

  Future<void> _loadChildrenData() async {
    setState(() => _isLoading = true);
    final list = await ParentDashboardService.getChildrenList();
    final att = await ParentDashboardService.getAttendance();

    if (mounted) {
      setState(() {
        _children = list;
        _attendance = att;
        if (widget.selectedChild != null) {
          _currentChild = _children.firstWhere(
            (c) => c['student_id'] == widget.selectedChild!['student_id'],
            orElse: () => _children.isNotEmpty ? _children.first : {},
          );
        } else if (_children.isNotEmpty) {
          _currentChild = _children.first;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
    }

    final child = _currentChild ?? (_children.isNotEmpty ? _children.first : {});
    final subjects = (child['subjects'] as List?) ?? const [];

    return RefreshIndicator(
      onRefresh: _loadChildrenData,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryNavy, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.level2Shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.electricCobalt,
                        backgroundImage: AvatarImageHelper.getImageProvider(child['avatar_url']),
                        onBackgroundImageError: (exception, stackTrace) {},
                        child: (AvatarImageHelper.getImageProvider(child['avatar_url']) == null)
                            ? Text(
                                child['avatar_initials'] ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${child['grade'] ?? ''} • Roll: ${child['roll_no'] ?? ''}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Color(0xFF93C5FD), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            child['batch_name'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Switch Child Selector
            if (_children.length > 1) ...[
              const Text('Enrolled Children', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
              const SizedBox(height: 10),
              Row(
                children: _children.map((c) {
                  final isSelected = c['student_id'] == child['student_id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentChild = c);
                        if (widget.onChildChanged != null) widget.onChildChanged!(c);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.electricCobalt.withValues(alpha: 0.1) : AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isSelected ? AppTheme.electricCobalt : AppTheme.surfaceSubtle,
                              child: Text(
                                c['avatar_initials'] ?? '',
                                style: TextStyle(color: isSelected ? Colors.white : AppTheme.textHeading, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                c['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppTheme.electricCobalt : AppTheme.textHeading,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Academic Attendance & Key Metrics
            Row(
              children: [
                Expanded(
                  child: _buildInfoMetric(
                    title: 'Overall Attendance',
                    value: child['attendance_rate'] ?? '',
                    subtitle: '',
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.successText,
                    bgColor: AppTheme.successBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoMetric(
                    title: 'Class Faculty Mentor',
                    value: child['mentor'] ?? '',
                    subtitle: '',
                    icon: Icons.person_rounded,
                    color: AppTheme.electricCobalt,
                    bgColor: AppTheme.surfaceSubtle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Enrolled Subjects List
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
                  const Row(
                    children: [
                      Icon(Icons.library_books_rounded, color: AppTheme.electricCobalt, size: 20),
                      SizedBox(width: 8),
                      Text('Enrolled Subjects & Courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map<Widget>((s) {
                      return Chip(
                        label: Text(s.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recent Attendance Logs
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: AppTheme.electricCobalt, size: 18),
                          SizedBox(width: 8),
                          Text('Recent Attendance Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                        ],
                      ),
                      Text('Last 7 Days', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._attendance.take(4).map((att) {
                    final isPresent = att['attendance_status'] == 'PRESENT';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isPresent ? AppTheme.successBg : AppTheme.warningBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPresent ? Icons.check : Icons.access_time,
                              size: 14,
                              color: isPresent ? AppTheme.successText : AppTheme.warningText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(att['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${att['date'] ?? ''} at ${att['time'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPresent ? AppTheme.successBg : AppTheme.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              att['attendance_status'] ?? '',
                              style: TextStyle(
                                color: isPresent ? AppTheme.successText : AppTheme.warningText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMetric({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
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
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
