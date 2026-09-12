import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/theme_toggle_switch.dart';
import '../../services/operations_service.dart';
import '../../services/academics_service.dart';
import '../../services/academic_structure_service.dart';
import '../../services/directory_service.dart';
import 'campus_rooms_screen.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _staffAttendance = [];
  List<Map<String, dynamic>> _studentAttendance = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _staff = [];
  String _selectedDay = 'ALL';
  String _attendanceSubFilter = 'STUDENTS'; // 'STUDENTS' or 'STAFF'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        OperationsService.getSchedules(),
        OperationsService.getStaffAttendance(),
        OperationsService.getStudentAttendance().catchError((_) => <Map<String, dynamic>>[]),
        AcademicsService.getBatches().catchError((_) => <Map<String, dynamic>>[]),
        AcademicsService.getSubjects().catchError((_) => <Map<String, dynamic>>[]),
        AcademicStructureService.getRooms().catchError((_) => <Map<String, dynamic>>[]),
        DirectoryService.getStaff().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _schedules = results[0];
          _staffAttendance = results[1];
          _studentAttendance = results[2];
          _batches = results[3];
          _subjects = results[4];
          _rooms = results[5];
          _staff = results[6];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openScheduleFormModal({Map<String, dynamic>? existingSchedule}) {
    final isEditing = existingSchedule != null;
    final subjectController = TextEditingController(text: existingSchedule?['subject_name'] ?? '');
    final roomController = TextEditingController(text: existingSchedule?['room_name'] ?? '');
    final currentAdminName = '${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'.trim();
    final teacherController = TextEditingController(
      text: existingSchedule?['teacher_name'] ?? currentAdminName,
    );
    String dayOfWeek = existingSchedule?['day_of_week'] ?? 'MONDAY';
    String startTime = existingSchedule?['start_time'] != null
        ? existingSchedule!['start_time'].toString().substring(0, 5)
        : '09:00';
    String endTime = existingSchedule?['end_time'] != null
        ? existingSchedule!['end_time'].toString().substring(0, 5)
        : '10:30';
    
    // Default batch from existing or fetched list or fallback
    int selectedBatchId = existingSchedule?['batch_id'] != null
        ? int.tryParse(existingSchedule!['batch_id'].toString()) ?? 1
        : (_batches.isNotEmpty && _batches.first['batch_id'] != null 
            ? int.tryParse(_batches.first['batch_id'].toString()) ?? 1 
            : 1);
    String selectedBatchName = existingSchedule?['batch_name'] ?? (_batches.isNotEmpty
        ? (_batches.first['batch_name'] ?? '')
        : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Class Session' : 'Schedule Class Session',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.primaryNavy,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    // Batch Dropdown Selector
                    DropdownButtonFormField<int>(
                      initialValue: selectedBatchId,
                      decoration: const InputDecoration(
                        labelText: 'Select Batch',
                        prefixIcon: Icon(Icons.groups, color: AppTheme.electricCobalt),
                      ),
                      items: (_batches.isNotEmpty ? _batches : <Map<String, dynamic>>[]).map<DropdownMenuItem<int>>((b) {
                        final id = int.tryParse((b['batch_id'] ?? 1).toString()) ?? 1;
                        final name = b['batch_name'] ?? '';
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedBatchId = val;
                            final match = _batches.firstWhere(
                              (b) => int.tryParse((b['batch_id'] ?? 1).toString()) == val,
                              orElse: () => {'batch_name': ''},
                            );
                            selectedBatchName = match['batch_name'] ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Subject Selector
                    if (_subjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: _subjects.any((s) => s['subject_name'] == subjectController.text)
                            ? subjectController.text
                            : _subjects.first['subject_name'],
                        decoration: const InputDecoration(
                          labelText: 'Select Subject',
                          prefixIcon: Icon(Icons.menu_book, color: AppTheme.electricCobalt),
                        ),
                        items: _subjects.map<DropdownMenuItem<String>>((s) {
                          final name = s['subject_name'] ?? '';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => subjectController.text = val);
                        },
                      )
                    else
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Physics, Chemistry, Biology',
                          prefixIcon: Icon(Icons.menu_book, color: AppTheme.electricCobalt),
                        ),
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: dayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.electricCobalt),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MONDAY', child: Text('Monday')),
                        DropdownMenuItem(value: 'TUESDAY', child: Text('Tuesday')),
                        DropdownMenuItem(value: 'WEDNESDAY', child: Text('Wednesday')),
                        DropdownMenuItem(value: 'THURSDAY', child: Text('Thursday')),
                        DropdownMenuItem(value: 'FRIDAY', child: Text('Friday')),
                        DropdownMenuItem(value: 'SATURDAY', child: Text('Saturday')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => dayOfWeek = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Classroom / Lab Selector
                    _rooms.isNotEmpty
                        ? DropdownButtonFormField<String>(
                            initialValue: _rooms.any((r) => r['room_name'] == roomController.text)
                                ? roomController.text
                                : _rooms.first['room_name'],
                            decoration: const InputDecoration(
                              labelText: 'Classroom / Lab',
                              prefixIcon: Icon(Icons.meeting_room, color: AppTheme.electricCobalt),
                            ),
                            items: _rooms.map<DropdownMenuItem<String>>((r) {
                              final rName = r['room_name'] ?? '';
                              final rCode = r['room_code'] != null ? ' (${r['room_code']})' : '';
                              return DropdownMenuItem<String>(
                                value: rName,
                                child: Text('$rName$rCode', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => roomController.text = val);
                            },
                          )
                        : TextField(
                            controller: roomController,
                            decoration: const InputDecoration(
                              labelText: 'Classroom / Lab',
                              hintText: 'e.g. Room 101 / Hall A',
                              prefixIcon: Icon(Icons.meeting_room, color: AppTheme.electricCobalt),
                            ),
                          ),
                    const SizedBox(height: 12),
                    // Assigned Faculty Selector
                    Builder(
                      builder: (context) {
                        final currentAdminName = '${ApiService.currentFirstName ?? ''} ${ApiService.currentLastName ?? ''}'.trim();
                        final List<String> facultyOptions = [];
                        if (currentAdminName.isNotEmpty) {
                          facultyOptions.add('$currentAdminName (You - Owner/Tutor)');
                        }
                        for (final st in _staff) {
                          final tName = '${st['first_name'] ?? ''} ${st['last_name'] ?? ''}'.trim();
                          if (tName.isNotEmpty && !facultyOptions.contains(tName)) {
                            facultyOptions.add(tName);
                          }
                        }

                        if (facultyOptions.isNotEmpty) {
                          final selectedVal = facultyOptions.contains(teacherController.text)
                              ? teacherController.text
                              : (facultyOptions.any((f) => f.startsWith(teacherController.text))
                                  ? facultyOptions.firstWhere((f) => f.startsWith(teacherController.text))
                                  : facultyOptions.first);

                          return DropdownButtonFormField<String>(
                            initialValue: selectedVal,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Faculty',
                              prefixIcon: Icon(Icons.person, color: AppTheme.electricCobalt),
                            ),
                            items: facultyOptions.map((f) => DropdownMenuItem<String>(
                              value: f,
                              child: Text(f, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final cleanName = val.replaceAll(' (You - Owner/Tutor)', '').trim();
                                setModalState(() => teacherController.text = cleanName);
                              }
                            },
                          );
                        }

                        return TextField(
                          controller: teacherController,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Faculty',
                            prefixIcon: Icon(Icons.person, color: AppTheme.electricCobalt),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (subjectController.text.trim().isEmpty) return;
                        final schedulePayload = {
                          'day_of_week': dayOfWeek,
                          'start_time': '$startTime:00',
                          'end_time': '$endTime:00',
                          'subject_name': subjectController.text.trim(),
                          'batch_id': selectedBatchId,
                          'batch_name': selectedBatchName,
                          'room_name': roomController.text.trim(),
                          'teacher_name': teacherController.text.trim(),
                          'status': 'ACTIVE',
                        };

                        final messenger = ScaffoldMessenger.of(context);
                        if (isEditing) {
                          final schedId = int.tryParse((existingSchedule['schedule_id'] ?? 1).toString()) ?? 1;
                          await OperationsService.updateSchedule(schedId, schedulePayload);
                        } else {
                          await OperationsService.addSchedule(schedulePayload);
                        }

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Session updated successfully!' : 'Class session scheduled successfully!'),
                              backgroundColor: AppTheme.successText,
                            ),
                          );
                        }
                      },
                      child: Text(isEditing ? 'Save Changes' : 'Confirm Schedule', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSchedule(Map<String, dynamic> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.urgentText, size: 24),
            SizedBox(width: 8),
            Text('Cancel Class Session?'),
          ],
        ),
        content: Text('Are you sure you want to remove "${s['subject_name'] ?? ''}" on ${s['day_of_week']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.urgentText, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final schedId = int.tryParse((s['schedule_id'] ?? 1).toString()) ?? 1;
              await OperationsService.deleteSchedule(schedId);
              if (mounted) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session removed from schedule.'),
                    backgroundColor: AppTheme.successText,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        title: const Text('Operations Hub', style: TextStyle(color: AppTheme.textHeading, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Campus Rooms & Labs',
            icon: const Icon(Icons.meeting_room_outlined, color: AppTheme.electricCobalt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CampusRoomsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.electricCobalt),
            onPressed: _loadData,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: ThemeToggleSwitch(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.electricCobalt,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.electricCobalt,
          indicatorWeight: 3,
          tabs: [
            const Tab(icon: Icon(Icons.schedule), text: 'Master Schedule'),
            const Tab(icon: Icon(Icons.fact_check_outlined), text: 'Staff Attendance'),
            Tab(icon: const Icon(Icons.meeting_room_outlined), text: 'Rooms & Labs (${_rooms.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricCobalt))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleTab(),
                _buildAttendanceTab(),
                _buildRoomsTab(),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.level3Shadow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_tabController.index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CampusRoomsScreen()),
              ).then((_) => _loadData());
            } else {
              _openScheduleFormModal();
            }
          },
          elevation: 0,
          backgroundColor: AppTheme.electricCobalt,
          foregroundColor: AppTheme.surfaceWhite,
          icon: Icon(_tabController.index == 2 ? Icons.add_business_rounded : Icons.add_alarm_rounded),
          label: Text(_tabController.index == 2 ? 'Add Room / Lab' : 'New Session'),
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    final filtered = _selectedDay == 'ALL'
        ? _schedules
        : _schedules.where((s) => s['day_of_week'] == _selectedDay).toList();

    return Column(
      children: [
        // Day Filter Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              'ALL',
              'MONDAY',
              'TUESDAY',
              'WEDNESDAY',
              'THURSDAY',
              'FRIDAY',
              'SATURDAY',
            ].map((day) {
              final isSelected = _selectedDay == day;
              return Padding(
                 padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(day == 'ALL' ? 'All Days' : day.substring(0, 3)),
                  selected: isSelected,
                  selectedColor: AppTheme.electricCobalt,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textHeading,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: AppTheme.surfaceWhite,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedDay = day);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text('No classes scheduled for this filter.', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    final startTime = s['start_time']?.toString().substring(0, 5) ?? '';
                    final endTime = s['end_time']?.toString().substring(0, 5) ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.level1Shadow,
                        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time Column
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      startTime,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy, fontSize: 13),
                                    ),
                                    const Text('to', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                    Text(
                                      endTime,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Content details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s['subject_name'] ?? '',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textHeading,
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.academicBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            s['day_of_week'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.academicText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.groups_outlined, size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          s['batch_name'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.meeting_room_outlined, size: 14, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          s['room_name'] ?? '',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 14, color: AppTheme.electricCobalt),
                                        const SizedBox(width: 4),
                                        Text(
                                          s['teacher_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.electricCobalt,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.electricCobalt,
                                  side: const BorderSide(color: AppTheme.electricCobalt),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _openScheduleFormModal(existingSchedule: s),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.urgentText,
                                  side: const BorderSide(color: AppTheme.urgentText),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                                label: const Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _confirmDeleteSchedule(s),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final studentLogs = _studentAttendance.isNotEmpty
        ? _studentAttendance
        : [
            {
              'student_name': 'Aarav Sharma',
              'subject': 'Physics - Electromagnetic Induction',
              'attendance_status': 'PRESENT',
              'location_name': 'Physics Lab 2 (Main Campus)',
              'latitude': 28.6141,
              'longitude': 77.2091,
              'photo_url': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
              'created_at': '10:02 AM',
            },
            {
              'student_name': 'Priya Patel',
              'subject': 'Advanced Mathematics & Calculus',
              'attendance_status': 'PENDING_VERIFICATION',
              'location_name': 'Room 102 (Campus A)',
              'latitude': 28.6139,
              'longitude': 77.2090,
              'photo_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
              'created_at': '09:58 AM',
            },
            {
              'student_name': 'Rohan Gupta',
              'subject': 'Organic Chemistry & Polymers',
              'attendance_status': 'PRESENT',
              'location_name': 'Room 105 (Campus A)',
              'latitude': 28.6140,
              'longitude': 77.2089,
              'photo_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
              'created_at': '09:55 AM',
            },
          ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sub-filter selector (Students Geo-Attendance vs Staff)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _attendanceSubFilter = 'STUDENTS'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _attendanceSubFilter == 'STUDENTS' ? AppTheme.electricCobalt : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pin_drop_rounded, size: 16, color: _attendanceSubFilter == 'STUDENTS' ? Colors.white : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Student Geo-Attendance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _attendanceSubFilter == 'STUDENTS' ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _attendanceSubFilter = 'STAFF'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _attendanceSubFilter == 'STAFF' ? AppTheme.electricCobalt : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 16, color: _attendanceSubFilter == 'STAFF' ? Colors.white : AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Staff Logs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _attendanceSubFilter == 'STAFF' ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_attendanceSubFilter == 'STUDENTS') ...[
          // Student Geo-Attendance Header & Summary
          Row(
            children: [
              Expanded(
                child: _buildAttendanceSummaryCard(
                  'Verified Geo Check-Ins',
                  '${studentLogs.length}',
                  const Color(0xFF059669),
                  const Color(0xFFECFDF5),
                  Icons.verified_user_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceSummaryCard(
                  'Pending Review',
                  '${studentLogs.where((s) => (s['attendance_status'] ?? s['status']) == 'PENDING_VERIFICATION').length}',
                  const Color(0xFFD97706),
                  const Color(0xFFFFFBEB),
                  Icons.pending_actions_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Geo-Tagged Student Logs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text('Photo + Location Stamped', style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...studentLogs.map((log) {
            final rawStatus = (log['attendance_status'] ?? log['status'] ?? 'PRESENT').toString();
            final isVerified = rawStatus == 'PRESENT';
            final studentName = log['student_name'] ?? 'Enrolled Student';
            final subject = log['subject'] ?? log['notes'] ?? 'Class Session';
            final locName = log['location_name'] ?? 'Main Campus Classroom';
            final photoUrl = log['photo_url'];
            final timeStr = (log['created_at'] ?? log['date'] ?? 'Today').toString().split('T').last.split('.').first;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.4)),
                boxShadow: AppTheme.level1Shadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Photo Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photoUrl != null && photoUrl.toString().isNotEmpty
                        ? Image.network(
                            photoUrl.toString(),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 52,
                              height: 52,
                              color: AppTheme.surfaceSubtle,
                              child: const Icon(Icons.person, color: AppTheme.electricCobalt),
                            ),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            color: AppTheme.surfaceSubtle,
                            child: const Icon(Icons.person, color: AppTheme.electricCobalt),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isVerified ? 'VERIFIED' : 'PENDING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subject,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF059669)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                locName,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          // Summary Cards Row for Staff
          Row(
            children: [
              Expanded(
                child: _buildAttendanceSummaryCard(
                  'Present Today',
                  '${_staffAttendance.where((a) => a['status'] == 'PRESENT').length}',
                  AppTheme.successText,
                  AppTheme.successBg,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceSummaryCard(
                  'Late Check-in',
                  '${_staffAttendance.where((a) => a['status'] == 'LATE').length}',
                  AppTheme.warningText,
                  AppTheme.warningBg,
                  Icons.access_time_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceSummaryCard(
                  'Absent',
                  '${_staffAttendance.where((a) => a['status'] == 'ABSENT').length}',
                  AppTheme.urgentText,
                  AppTheme.urgentBg,
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Staff Log",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
              ),
              Text(
                '${_staffAttendance.length} Total Staff',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._staffAttendance.map((staff) {
            final isPresent = staff['status'] == 'PRESENT';
            final isLate = staff['status'] == 'LATE';

            Color badgeBg = isPresent ? AppTheme.successBg : (isLate ? AppTheme.warningBg : AppTheme.urgentBg);
            Color badgeColor = isPresent ? AppTheme.successText : (isLate ? AppTheme.warningText : AppTheme.urgentText);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.35)),
                boxShadow: AppTheme.level1Shadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.surfaceSubtle,
                    radius: 20,
                    child: Text(
                      (staff['staff_name'] as String? ?? '').isNotEmpty
                          ? (staff['staff_name'] as String?)!.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff['staff_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textHeading),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          staff['role'] ?? '',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          staff['status'] ?? '',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff['check_in_time'] ?? '',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildAttendanceSummaryCard(String title, String count, Color textColor, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
              Icon(icon, size: 16, color: textColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildRoomsTab() {
    if (_rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room_outlined, size: 64, color: AppTheme.borderSubtle),
              const SizedBox(height: 16),
              const Text('No Campus Rooms Configured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textHeading)),
              const SizedBox(height: 8),
              const Text('Add classrooms, lecture halls, or labs for scheduling.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CampusRoomsScreen()),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Add First Room'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final isLab = room['is_lab'] == 1 || room['is_lab'] == true;
          final status = (room['status'] ?? '').toString().toUpperCase();
          final isAvailable = status == 'AVAILABLE';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.level1Shadow,
              border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLab ? Colors.purple.withValues(alpha: 0.1) : AppTheme.electricCobalt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLab ? Icons.science_outlined : Icons.meeting_room_outlined,
                    color: isLab ? Colors.purple : AppTheme.electricCobalt,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            room['room_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textHeading),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLab ? Colors.purple.withValues(alpha: 0.1) : AppTheme.academicBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLab ? 'LAB' : 'CLASSROOM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isLab ? Colors.purple : AppTheme.academicText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${room['room_code'] ?? ''} • Capacity: ${room['capacity'] ?? ''} students',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.successBg : AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? AppTheme.successText : AppTheme.warningText,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
