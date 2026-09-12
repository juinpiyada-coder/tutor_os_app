import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/student_dashboard_service.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  String _selectedFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final data = await StudentDashboardService.getClasses();
    if (mounted) {
      setState(() {
        _classes = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _joinMeeting(String? urlStr) async {
    final url = urlStr ?? '';
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meeting link available for this class.'),
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
            SnackBar(
              content: Text('Opening class session: $url'),
              backgroundColor: AppTheme.electricCobalt,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launching class link: $url'),
            backgroundColor: AppTheme.electricCobalt,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _classes;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((c) => (c['subject'] ?? '').toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }
    if (_statusFilter != 'All') {
      filtered = filtered.where((c) => (c['status'] ?? '').toString().toUpperCase() == _statusFilter.toUpperCase()).toList();
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Banner Card
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.electricCobalt.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LIVE SCHEDULE',
                            style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your Class Schedule',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join interactive live sessions, access lecture notes & check venue details.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.electricCobalt.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Subject Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Mathematics', 'Physics', 'Chemistry', 'Biology'].map((subject) {
                  final isSelected = _selectedFilter == subject;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(subject),
                      selected: isSelected,
                      selectedColor: AppTheme.electricCobalt,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textBody,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: AppTheme.surfaceWhite,
                      side: BorderSide(color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = subject);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Status Tabs
            Row(
              children: [
                _buildStatusTab('All', 'All Classes'),
                const SizedBox(width: 8),
                _buildStatusTab('LIVE', 'Live Now'),
                const SizedBox(width: 8),
                _buildStatusTab('SCHEDULED', 'Upcoming'),
              ],
            ),

            const SizedBox(height: 18),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.electricCobalt),
                ),
              )
            else if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    const Text('No classes found for this filter', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Check another subject or refresh schedule.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  final isLive = (c['status'] ?? '').toString().toUpperCase() == 'LIVE';
                  final subjectColor = _getSubjectColor(c['subject']);
                  final subjectBg = _getSubjectBg(c['subject']);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLive ? AppTheme.electricCobalt.withValues(alpha: 0.6) : AppTheme.borderSubtle,
                        width: isLive ? 1.5 : 1.0,
                      ),
                      boxShadow: AppTheme.level1Shadow,
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
                                color: subjectBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c['subject'] ?? '',
                                style: TextStyle(
                                  color: subjectColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLive ? AppTheme.urgentBg : AppTheme.successBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLive ? Icons.fiber_manual_record : Icons.schedule,
                                    size: 10,
                                    color: isLive ? AppTheme.urgentText : AppTheme.successText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    c['status'] ?? '',
                                    style: TextStyle(
                                      color: isLive ? AppTheme.urgentText : AppTheme.successText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          c['title'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(c['teacher'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                            const SizedBox(width: 16),
                            const Icon(Icons.room_outlined, size: 16, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(c['room'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppTheme.electricCobalt),
                            const SizedBox(width: 6),
                            Text(c['time'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.electricCobalt)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isLive ? AppTheme.urgentText : AppTheme.electricCobalt,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.videocam_rounded, size: 18),
                                label: Text(isLive ? 'Join Live Now' : 'Launch Meeting Link', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () => _joinMeeting(c['meet_url']),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFF10B981)),
                              ),
                              icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF059669)),
                              label: const Text('Check In', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () async {
                                final batchId = int.tryParse((c['batch_id'] ?? 1).toString()) ?? 1;
                                final sessionId = int.tryParse((c['session_id'] ?? c['id'] ?? 1).toString()) ?? 1;
                                await StudentDashboardService.submitClassCheckIn(
                                  classSessionId: sessionId,
                                  batchId: batchId,
                                  subject: c['subject'] ?? c['title'] ?? 'Class Session',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Attendance check-in submitted for ${c['title']}. Waiting for faculty confirmation!'),
                                      backgroundColor: AppTheme.successText,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(String status, String label) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricCobalt.withValues(alpha: 0.12) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.electricCobalt : AppTheme.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.electricCobalt : AppTheme.textBody,
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String? subject) {
    switch ((subject ?? '').toLowerCase()) {
      case 'mathematics': return const Color(0xFF2563EB);
      case 'physics': return const Color(0xFF7C3AED);
      case 'chemistry': return const Color(0xFF059669);
      case 'biology': return const Color(0xFFD97706);
      default: return AppTheme.electricCobalt;
    }
  }

  Color _getSubjectBg(String? subject) {
    switch ((subject ?? '').toLowerCase()) {
      case 'mathematics': return const Color(0xFFEFF6FF);
      case 'physics': return const Color(0xFFF5F3FF);
      case 'chemistry': return const Color(0xFFECFDF5);
      case 'biology': return const Color(0xFFFFFBEB);
      default: return AppTheme.surfaceSubtle;
    }
  }
}
