import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/student_dashboard_service.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedule = [];
  String _selectedDay = 'All';

  final List<String> _days = ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    final data = await StudentDashboardService.getClasses();
    if (mounted) {
      setState(() {
        _schedule = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _schedule;
    if (_selectedDay != 'All') {
      filtered = filtered.where((s) {
        final title = (s['title'] ?? '').toString().toLowerCase();
        final day = (s['day_of_week'] ?? '').toString().toLowerCase();
        return title.contains(_selectedDay.toLowerCase()) || day.contains(_selectedDay.toLowerCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('My Class Timetable & Schedule'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : RefreshIndicator(
              onRefresh: _loadSchedule,
              color: AppTheme.electricCobalt,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Schedule Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
                                    'ACADEMIC CALENDAR',
                                    style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Weekly Batch Timetable',
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Explore assigned lectures, classroom venues, and live session slots.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.electricCobalt.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Day Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _days.map((day) {
                          final isSelected = _selectedDay == day;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(day),
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
                                if (selected) setState(() => _selectedDay = day);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.event_note_rounded, size: 44, color: AppTheme.textMuted),
                            SizedBox(height: 10),
                            Text('No scheduled sessions for this filter', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                            SizedBox(height: 4),
                            Text('Select "All" to view your complete weekly class routine.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      )
                    else
                      ...filtered.map((item) {
                        final isLive = (item['status'] ?? '').toString().toUpperCase() == 'LIVE';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isLive ? AppTheme.urgentBg : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isLive ? Icons.sensors_rounded : Icons.access_time_filled_rounded,
                                  color: isLive ? AppTheme.urgentText : AppTheme.electricCobalt,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Class Lecture',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textHeading),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['teacher'] ?? 'Faculty'} • Room: ${item['room'] ?? 'Hall A'}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item['time'] ?? '10:00 AM',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLive ? AppTheme.urgentBg : AppTheme.successBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['status'] ?? 'SCHEDULED',
                                      style: TextStyle(
                                        color: isLive ? AppTheme.urgentText : AppTheme.successText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
    );
  }
}
