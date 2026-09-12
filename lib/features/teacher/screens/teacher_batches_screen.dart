import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/teacher_dashboard_service.dart';

class TeacherBatchesScreen extends StatefulWidget {
  const TeacherBatchesScreen({super.key});

  @override
  State<TeacherBatchesScreen> createState() => _TeacherBatchesScreenState();
}

class _TeacherBatchesScreenState extends State<TeacherBatchesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _batches = [];
  Map<String, dynamic>? _selectedBatch;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    final batchList = await TeacherDashboardService.getBatches();
    if (mounted) {
      setState(() {
        _batches = batchList;
        if (_batches.isNotEmpty) {
          _selectedBatch = _batches.first;
        }
      });
      if (_selectedBatch != null) {
        final stuList = await TeacherDashboardService.getBatchStudents(_selectedBatch!['batch_id']);
        if (mounted) {
          setState(() {
            _students = stuList;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchBatch(Map<String, dynamic> batch) async {
    setState(() {
      _selectedBatch = batch;
      _isLoading = true;
    });
    final stuList = await TeacherDashboardService.getBatchStudents(batch['batch_id']);
    if (mounted) {
      setState(() {
        _students = stuList;
        _isLoading = false;
      });
    }
  }

  void _showMarkAttendanceModal() {
    final records = _students.map((s) => Map<String, dynamic>.from(s)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.how_to_reg_rounded, color: AppTheme.electricCobalt, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live Session Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textHeading)),
                          Text(_selectedBatch?['batch_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Roster (${records.length} Students)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  TextButton.icon(
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark All Present'),
                    onPressed: () {
                      setModalState(() {
                        for (var r in records) {
                          r['status'] = 'PRESENT';
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final stu = records[idx];
                    final status = stu['status'] ?? '';
                    final studentName = (stu['name'] ?? '').toString();
                    final isCheckedIn = status == 'PENDING_VERIFICATION' || status == 'CHECKED_IN';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCheckedIn ? const Color(0xFF10B981).withValues(alpha: 0.05) : AppTheme.canvasBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isCheckedIn ? const Color(0xFF10B981).withValues(alpha: 0.3) : AppTheme.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isCheckedIn ? const Color(0xFF10B981).withValues(alpha: 0.15) : AppTheme.surfaceSubtle,
                            child: Text(
                              studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : '',
                              style: TextStyle(fontWeight: FontWeight.bold, color: isCheckedIn ? const Color(0xFF10B981) : AppTheme.electricCobalt, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                                    if (isCheckedIn) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('⏳ Student Check-in', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(stu['roll_no'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          _buildAttendanceToggle('PRESENT', 'P', isCheckedIn ? 'PRESENT' : status, const Color(0xFF10B981), (val) {
                            setModalState(() => stu['status'] = val);
                          }),
                          const SizedBox(width: 6),
                          _buildAttendanceToggle('LATE', 'L', status, const Color(0xFFF59E0B), (val) {
                            setModalState(() => stu['status'] = val);
                          }),
                          const SizedBox(width: 6),
                          _buildAttendanceToggle('ABSENT', 'A', status, const Color(0xFFEF4444), (val) {
                            setModalState(() => stu['status'] = val);
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Confirm & Save Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  // Convert pending verification to PRESENT on teacher confirmation
                  for (var r in records) {
                    if (r['status'] == 'PENDING_VERIFICATION' || r['status'] == 'CHECKED_IN') {
                      r['status'] = 'PRESENT';
                    }
                  }

                  final batchId = _selectedBatch?['batch_id'] ?? 0;
                  await TeacherDashboardService.markAttendance(
                    batchId: batchId,
                    attendanceRecords: records,
                  );

                  setState(() {
                    _students = records;
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Attendance verified and confirmed successfully!'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceToggle(String value, String label, String groupVal, Color color, Function(String) onSelect) {
    final isSelected = value == groupVal;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppTheme.borderSubtle),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textBody,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _batches.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt));
    }

    return RefreshIndicator(
      onRefresh: _loadBatches,
      color: AppTheme.electricCobalt,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BATCH MANAGEMENT',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'My Batches & Rosters',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your coaching batch to inspect student rosters and mark live classroom attendance.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 30),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Batches Switcher Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _batches.map((b) {
                  final isSelected = _selectedBatch?['batch_id'] == b['batch_id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(b['batch_name']),
                      selected: isSelected,
                      selectedColor: const Color(0xFF3730A3),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textBody,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: AppTheme.surfaceWhite,
                      side: BorderSide(color: isSelected ? const Color(0xFF3730A3) : AppTheme.borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) _switchBatch(b);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Batch Overview Details Card
            if (_selectedBatch != null) ...[
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedBatch!['batch_name'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.electricCobalt,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                          label: const Text('Take Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: _showMarkAttendanceModal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(_selectedBatch!['timing'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                        const SizedBox(width: 14),
                        const Icon(Icons.room_rounded, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(_selectedBatch!['room'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Student Roster
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enrolled Students (${_students.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading)),
                const Text('Live Status', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final stu = _students[index];
                  final isPresent = (stu['status'] ?? '') == 'PRESENT';
                  final studentName = (stu['name'] ?? '').toString();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: AppTheme.level1Shadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.surfaceSubtle,
                          child: Text(
                            studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : '',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.electricCobalt),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading)),
                              Text('Roll: ${stu['roll_no'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? AppTheme.successBg : AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stu['status'] ?? '',
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
                },
              ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
